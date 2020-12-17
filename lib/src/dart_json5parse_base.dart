var _string_a = r'''"[^"]*"''';
var _string_b = r"""'[^']*'""";
var _string_true = 'true';
var _string_false = 'false';
var _string_null = 'null';
var _string_num = r'-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?';
var _string_double = r'-?\d+\.\d*(?:[eE][+\-]?\d+)?';
var _string_int = r'-?\d+';
var _string_hex = r'0x[a-fA-F0-9]+';

var _not_map_key = RegExp(r'[^a-zA-Z0-9_]', dotAll: true);
var _line_comment = RegExp(r'\/\/[^]*?\n', dotAll: true);
var _multi_line_comments = RegExp(r'\/\*[^]*?\*\/', dotAll: true);
var _map_start = RegExp(r'^\s*\{\s*');
var _map_end = RegExp(r'^\s*\}\s*(,)?\s*');
var _map_key = RegExp(r'([^]+?)\s*:\s*');

var _list_start = RegExp(r'^\s*\[\s*');
var _list_end = RegExp(r'^\s*\]\s*,?\s*');

/// map_value or list_value
var _value = RegExp(
    '''($_string_true|$_string_false|$_string_null|$_string_hex|$_string_num|$_string_a|$_string_b)\s*(,)?\s*''');

class ParseResult {
  dynamic /* List or Map */ result;
  String text;
  ParseResult(this.result, this.text);
}

/// 将字符串转为对应的dart类型
dynamic _t(String v, {bool isKey = false}) {
  if (RegExp(_string_a).hasMatch(v)) {
    return v.replaceAll(RegExp(r'^"'), '').replaceAll(RegExp(r'"$'), '');
  }

  if (RegExp(_string_b).hasMatch(v)) {
    return v.replaceAll(RegExp(r"^'"), '').replaceAll(RegExp(r"'$"), '');
  }

  if (RegExp(_string_true).hasMatch(v)) {
    return true;
  }

  if (RegExp(_string_false).hasMatch(v)) {
    return false;
  }

  if (RegExp(_string_null).hasMatch(v)) {
    return null;
  }

  if (RegExp(_string_double).hasMatch(v)) {
    return double.parse(v);
  }

  if (RegExp(_string_int).hasMatch(v) || RegExp(_string_hex).hasMatch(v)) {
    return int.parse(v);
  }

  // is map key
  if (isKey) {
    // v = name
    // v = n ame
    if (_not_map_key.hasMatch(v.trim())) {
      // error
      throw 'key error';
    } else {
      return v.trim();
    }
  }

  // throw 'not find parse: ' + v;
}

ParseResult _evalMap(String text) {
  var r = {};
  void parseMapStart() {
    var m = _map_start.firstMatch(text);
    if (m != null) text = text.substring(m.end);
  }

  bool parseMapEnd() {
    var m = _map_end.firstMatch(text);

    if (m != null) {
      text = text.substring(m.end);
      return true;
    }
    return false;
  }

  parseMapStart();
  while (text.isNotEmpty) {
    if (parseMapEnd()) break;

    var m_k = _map_key.firstMatch(text);
    if (m_k != null) {
      String k = _t(m_k[1], isKey: true);
      text = text.substring(m_k.end);
      var p = _json5Parse(text);
      r[k.trim()] = p.result;
      text = p.text;
    }
  }
  return ParseResult(r, text);
}

ParseResult _evalList(String text) {
  var r = [];

  void parseListStart() {
    var m = _list_start.firstMatch(text);
    if (m != null) {
      text = text.substring(m.end);
    }
  }

  bool parseListEnd() {
    var m = _list_end.firstMatch(text);
    if (m != null) {
      text = text.substring(m.end);
      return true;
    }
    return false;
  }

  parseListStart();
  while (text.isNotEmpty) {
    if (parseListEnd()) break;
    var p = _json5Parse(text);
    r.add(p.result);
    text = p.text;
  }
  return ParseResult(r, text);
}

ParseResult _json5Parse(String text) {
  var result;

  if (_map_start.hasMatch(text)) {
    result = _evalMap(text);
  } else if (_list_start.hasMatch(text)) {
    result = _evalList(text);
  } else {
    // bool, nulber, string
    var m = _value.firstMatch(text);
    if (m != null) {
      text = text.substring(m.end);
      if (m[2] == null &&
          !_map_end.hasMatch(text) &&
          !_list_end.hasMatch(text)) {
        // 逗号匹配错误
        throw 'parse error: ' + text;
      }
      result = ParseResult(_t(m[1]), text);
    } else {
      throw 'parse error: ' + text;
    }
  }

  return result;
}

dynamic json5Parse(String text) {
  // 斩掉单行和多行注释
  text =
      text.replaceAll(_line_comment, '').replaceAll(_multi_line_comments, '');

  // 斩掉首尾空格，和多余的回车换行符
  // text = text.replaceAll(RegExp(r'[\r\n]'), '');
  text =
      text.replaceAll(RegExp(r'[\r\n]'), '').replaceAll(RegExp(r'\\n'), '\n');

  if (!_map_start.hasMatch(text) && !_list_start.hasMatch(text)) {
    text = text.trim();
    var m = _value.firstMatch(text);
    if (m != null) {
      var v = m[1];
      text = text.substring(m.end);
      if (text.isEmpty) return _t(v);
    } else {
      throw 'parse error: ' + text;
    }
  }
  return _json5Parse(text).result;
}
