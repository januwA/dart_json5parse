final _line_comment = r'''\s*\/\/[^\n]*\s*''';
final _multi_line_comments = r'\s*\/\*[^]*?\*\/\s*';
final _comment_exp = RegExp('''^($_line_comment|$_multi_line_comments)''');

final _string_a = r'''"[^"]*"''';
final _string_b = r"""'[^']*'""";
final _string_true = r'true';
final _string_false = r'false';
final _string_null = r'null';

final _string_a_exp = RegExp(_string_a);
final _string_b_exp = RegExp(_string_b);
final _string_true_exp = RegExp(_string_true);
final _string_false_exp = RegExp(_string_false);
final _string_null_exp = RegExp(_string_null);

// 1.0  0.1  1. .1
final _string_double = r'-?\d*\.\d*(?:[eE][+\-]?\d+)?';

// 1 1e2 1e-2
final _string_int = r'-?\d+(?:[eE][+\-]?\d+)?';

// 0x0A
final _string_hex = r'0x[a-fA-F0-9]+';

final _string_double_exp = RegExp(_string_double);
final _string_int_exp = RegExp(_string_int);
final _string_hex_exp = RegExp(_string_hex);

// 处理 1e2 或 1e-2 只能只用double
final _is_int_exponent = RegExp(r'[eE]', dotAll: true);

final _map_start_exp = RegExp(r'^\s*\{\s*');
final _map_end_exp = RegExp(r'^\s*\}\s*(,)?\s*');

// map key
final _map_key_exp = RegExp('''^([^]+?)($_multi_line_comments)*\s*:\s*''');

final _list_start_exp = RegExp(r'^\s*\[\s*');
final _list_end_exp = RegExp(r'^\s*\]\s*,?\s*');

// emoji
// https://stackoverflow.com/questions/55433185/how-to-detect-emojis-in-a-string-in-flutter-using-dart
final _emoji_exp = RegExp(
    r'\s*(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+\s*');

/// map_value or list_value
final _value_exp = RegExp(
    '''($_string_true|$_string_false|$_string_null|$_string_hex|$_string_double|$_string_int|$_string_a|$_string_b)($_multi_line_comments)*(?<comma>,)?\s*''');

final _quotes_start_exp = RegExp(r'''^["']''');
final _quotes_end_exp = RegExp(r'''["']$''');

class ParseResult {
  dynamic result;
  String text;
  ParseResult(this.result, this.text);
}

/// 将字符串转为对应的dart类型
dynamic _t(String v, {bool isKey = false}) {
  if (_string_a_exp.hasMatch(v) || _string_b_exp.hasMatch(v) || isKey) {
    return v
        .trim()
        .replaceAll(_quotes_start_exp, '')
        .replaceAll(_quotes_end_exp, '');
  }

  if (_string_true_exp.hasMatch(v)) return true;
  if (_string_false_exp.hasMatch(v)) return false;
  if (_string_null_exp.hasMatch(v)) return null;
  if (_string_double_exp.hasMatch(v)) return double.parse(v);

  if (_string_int_exp.hasMatch(v) || _string_hex_exp.hasMatch(v)) {
    if (_is_int_exponent.hasMatch(v)) return double.parse(v);
    return int.parse(v);
  }

  return v;
}

/// 匹配 Map
ParseResult _evalMap(String text) {
  var r = {};
  void mapStart() {
    final m = _map_start_exp.firstMatch(text);
    if (m != null) text = text.substring(m.end);
  }

  bool mapEnd() {
    final m = _map_end_exp.firstMatch(text);
    final ok = m != null;
    if (ok) text = text.substring(m.end);
    return ok;
  }

  mapStart();
  while (text.isNotEmpty) {
    text = _removeCommet(text);
    if (mapEnd()) break;

    var m_k = _map_key_exp.firstMatch(text);
    if (m_k != null) {
      String k = _t(m_k[1], isKey: true);
      text = text.substring(m_k.end);
      final p = _json5Parse(text);
      r[k.trim()] = p.result;
      text = p.text;
    } else {
      throw 'parse map key error: ' + text;
    }
  }
  return ParseResult(r, text);
}

/// 匹配 List
ParseResult _evalList(String text) {
  var r = [];

  void listStart() {
    final m = _list_start_exp.firstMatch(text);
    if (m != null) text = text.substring(m.end);
  }

  bool listEnd() {
    final m = _list_end_exp.firstMatch(text);
    final ok = m != null;
    if (ok) text = text.substring(m.end);
    return ok;
  }

  listStart();
  while (text.isNotEmpty) {
    text = _removeCommet(text);
    var m = _comment_exp.firstMatch(text);
    while (m != null) {
      text = text.substring(m.end);
      m = _comment_exp.firstMatch(text);
    }

    if (listEnd()) break;
    final p = _json5Parse(text);
    r.add(p.result);
    text = p.text;
  }
  return ParseResult(r, text);
}

/// 匹配注释，并删除
String _removeCommet(String text) {
  var m = _comment_exp.firstMatch(text);
  while (m != null) {
    text = text.substring(m.end);
    m = _comment_exp.firstMatch(text);
  }
  return text;
}

ParseResult _json5Parse(String text) {
  text = _removeCommet(text);
  if (_map_start_exp.hasMatch(text)) {
    return _evalMap(text);
  } else if (_list_start_exp.hasMatch(text)) {
    return _evalList(text);
  } else {
    var m = _value_exp.firstMatch(text);
    if (m != null) {
      text = text.substring(m.end);
      text = _removeCommet(text); // 清理一下注释，在判断逗号是否被正确添加
      if (m.namedGroup('comma') == null &&
          !_map_end_exp.hasMatch(text) &&
          !_list_end_exp.hasMatch(text)) {
        // 逗号匹配错误
        throw 'Comma parse error: ' + text;
      }
      return ParseResult(_t(m[1]), text);
    } else {
      throw 'Value parse error: ' + text;
    }
  }
}

dynamic json5Parse(String text) {
  text = _removeCommet(text);
  if (!_map_start_exp.hasMatch(text) && !_list_start_exp.hasMatch(text)) {
    text = text.trim();
    var m = _value_exp.firstMatch(text);
    if (m != null) {
      text = text.substring(m.end);
      text = _removeCommet(text);
      if (text.isEmpty) return _t(m[1]);
    } else {
      throw 'Value parse error: ' + text;
    }
  }
  return _json5Parse(text).result;
}
