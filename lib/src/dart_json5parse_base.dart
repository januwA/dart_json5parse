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
final _string_int = r'-?\d+(?:[eE][+\-]?\d+)?';
final _string_hex = r'0x[a-fA-F0-9]+';

final _string_double_exp = RegExp(_string_double);
final _string_int_exp = RegExp(_string_int);
final _string_hex_exp = RegExp(_string_hex);

// 处理 1e2 或 1e-2 只能只用double
final _is_int_exponent = RegExp(r'[eE]', dotAll: true);

final _err_map_key_exp = RegExp(r'[^a-zA-Z0-9_]', dotAll: true);
final _line_comment_exp = RegExp(r'\/\/[^]*?\n', dotAll: true);
final _multi_line_comments_exp = RegExp(r'\/\*[^]*?\*\/', dotAll: true);
final _map_start_exp = RegExp(r'^\s*\{\s*');
final _map_end_exp = RegExp(r'^\s*\}\s*(,)?\s*');
final _map_key_exp = RegExp(r'([^]+?)\s*:\s*');

final _list_start_exp = RegExp(r'^\s*\[\s*');
final _list_end_exp = RegExp(r'^\s*\]\s*,?\s*');

/// map_value or list_value
final _value_exp = RegExp(
    '''($_string_true|$_string_false|$_string_null|$_string_hex|$_string_double|$_string_int|$_string_a|$_string_b)\s*(,)?\s*''');

final _quotes_start_exp = RegExp(r'''^["']''');
final _quotes_end_exp = RegExp(r'''["']$''');

class ParseResult {
  dynamic /* List or Map */ result;
  String text;
  ParseResult(this.result, this.text);
}

/// 将字符串转为对应的dart类型
dynamic _t(String v, {bool isKey = false}) {
  if (_string_a_exp.hasMatch(v) || _string_b_exp.hasMatch(v)) {
    return v.replaceAll(_quotes_start_exp, '').replaceAll(_quotes_end_exp, '');
  }

  if (_string_true_exp.hasMatch(v)) return true;
  if (_string_false_exp.hasMatch(v)) return false;
  if (_string_null_exp.hasMatch(v)) return null;
  if (_string_double_exp.hasMatch(v)) return double.parse(v);

  if (_string_int_exp.hasMatch(v) || _string_hex_exp.hasMatch(v)) {
    if (_is_int_exponent.hasMatch(v)) return double.parse(v);
    return int.parse(v);
  }

  // is map key
  if (isKey) {
    // v = name -> success
    // v = n ame -> error
    if (_err_map_key_exp.hasMatch(v.trim())) {
      throw 'map key error: ' + v;
    } else {
      return v.trim();
    }
  }

  return v;
}

ParseResult _evalMap(String text) {
  var r = {};
  void parseMapStart() {
    final m = _map_start_exp.firstMatch(text);
    if (m != null) text = text.substring(m.end);
  }

  bool parseMapEnd() {
    final m = _map_end_exp.firstMatch(text);
    final ok = m != null;
    if (ok) text = text.substring(m.end);
    return ok;
  }

  parseMapStart();
  while (text.isNotEmpty) {
    if (parseMapEnd()) break;

    var m_k = _map_key_exp.firstMatch(text);
    if (m_k != null) {
      String k = _t(m_k[1], isKey: true);
      text = text.substring(m_k.end);
      final p = _json5Parse(text);
      r[k.trim()] = p.result;
      text = p.text;
    }
  }
  return ParseResult(r, text);
}

ParseResult _evalList(String text) {
  var r = [];

  void parseListStart() {
    final m = _list_start_exp.firstMatch(text);
    if (m != null) text = text.substring(m.end);
  }

  bool parseListEnd() {
    final m = _list_end_exp.firstMatch(text);
    final ok = m != null;
    if (ok) text = text.substring(m.end);
    return ok;
  }

  parseListStart();
  while (text.isNotEmpty) {
    if (parseListEnd()) break;
    final p = _json5Parse(text);
    r.add(p.result);
    text = p.text;
  }
  return ParseResult(r, text);
}

ParseResult _json5Parse(String text) {
  if (_map_start_exp.hasMatch(text)) {
    return _evalMap(text);
  } else if (_list_start_exp.hasMatch(text)) {
    return _evalList(text);
  } else {
    final m = _value_exp.firstMatch(text);
    if (m != null) {
      text = text.substring(m.end);
      if (m[2] == null &&
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
  // 斩掉单行和多行注释
  text = text
      .replaceAll(_line_comment_exp, '')
      .replaceAll(_multi_line_comments_exp, '');

  // 斩掉首尾空格，和多余的回车换行符
  // text = text.replaceAll(RegExp(r'[\r\n]'), '');
  text =
      text.replaceAll(RegExp(r'[\r\n]'), '').replaceAll(RegExp(r'\\n'), '\n');

  if (!_map_start_exp.hasMatch(text) && !_list_start_exp.hasMatch(text)) {
    text = text.trim();
    final m = _value_exp.firstMatch(text);
    if (m != null) {
      text = text.substring(m.end);
      if (text.isEmpty) return _t(m[1]);
    } else {
      throw 'Value parse error: ' + text;
    }
  }
  return _json5Parse(text).result;
}
