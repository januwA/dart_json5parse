var _string_a = r'''"[^"]*"''';
var _string_b = r"""'[^']*'""";
var _string_true = 'true';
var _string_false = 'false';
var _string_null = 'null';
var _string_num = r'-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?';
var _string_double = r'-?\d+\.\d*(?:[eE][+\-]?\d+)?';
var _string_int = r'-?\d+';
var _string_hex = r'0x[a-zA-Z0-9]+';

var _not_map_key = RegExp(r'[^a-zA-Z0-9_]', dotAll: true);
var _line_comment = RegExp(r'\/\/[^]*?\n', dotAll: true);
var _multi_line_comments = RegExp(r'\/\*[^]*?\*\/', dotAll: true);
var _map_start = RegExp(r'^\s*\{\s*');
var _map_end = RegExp(r'^\s*\}\s*(,)?\s*');
var _map_key = RegExp(r'([^]+?)\s*:\s*');
var _map_value = RegExp(
    '''(true|false|null|$_string_hex|$_string_num|$_string_a|$_string_b)\s*(,)?\s*''');
var _list_start = RegExp(r'^\s*\[\s*');
var _list_end = RegExp(r'^\s*\]\s*,?\s*');
var _list_item = RegExp(r'\s*([^\[\],]*)\s*,?');

var _value = RegExp(
    '''\s*($_string_a|$_string_b|$_string_true|$_string_false|$_string_null|$_string_hex|$_string_num)\s*''');

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

  throw 'not find parse';
}

var _hasComma = true;
Map _evalMap(String text, [Function endCB]) {
  var r = {};
  String k;

  void parseMapStart() {
    var m = _map_start.firstMatch(text);
    while (m != null) {
      text = text.substring(m.end);
      m = _map_start.firstMatch(text);
    }
  }

  void parseMapEnd() {
    var m = _map_end.firstMatch(text);

    if (m == null && !_hasComma) {
      throw '逗号匹配错误。';
    }

    while (m != null) {
      _hasComma = m.group(1) != null;
      text = text.substring(m.end);
      if (endCB != null) {
        endCB({
          'map': r,
          'text': text,
        });
        text = '';
      }
      m = _map_end.firstMatch(text);
    }
  }

  // 匹配开头
  parseMapStart();
  while (text.isNotEmpty) {
    // 匹配结束
    parseMapEnd();
    var m_k = _map_key.firstMatch(text);
    if (m_k != null) {
      k = _t(m_k.group(1), isKey: true);
      text = text.substring(m_k.end);
    } else {
      k = null;
    }
    // 匹配value前，先查看是否为{}
    if (_map_start.hasMatch(text)) {
      _evalMap(text, (_r) {
        r[k.trim()] = _r['map'];
        text = _r['text'];
      });
    } else if (_list_start.hasMatch(text)) {
      _evalList(text, (_r) {
        r[k.trim()] = _r['list'];
        text = _r['text'];
      });
    } else {
      var m_v = _map_value.firstMatch(text);
      if (m_v != null && k != null) {
        var v = _t(m_v.group(1));
        r[k.trim()] = v;
        _hasComma = m_v.group(2) != null;
        k = null;
        text = text.substring(m_v.end);
      }
    }
  }
  return r;
}

List<dynamic> _evalList(String text, [Function endCB]) {
  var r = [];
  var i = 0;
  var isList = false;
  void parseListStart() {
    var m = _list_start.firstMatch(text);
    while (m != null) {
      // print('start before: ' + text);
      if (i != 0) {
        r.add([]);
        isList = true;
      }
      i++;
      text = text.substring(m.end);
      // print('start after: ' + text);
      m = _list_start.firstMatch(text);
    }
  }

  void parseListEnd() {
    var m = _list_end.firstMatch(text);
    while (m != null) {
      // print('end before: ' + text);
      if (i > 2) {
        var b = r[r.length - 2];
        b.add(r.removeLast());
      } else {
        isList = false;
      }
      i--;
      text = text.substring(m.end);

      if (endCB != null) {
        endCB({
          'list': r,
          'text': text,
        });
        text = '';
      }
      // print('end after: ' + text);
      m = _list_end.firstMatch(text);
    }
  }

  while (text.isNotEmpty) {
    // 匹配开头
    parseListStart();

    // 匹配结束
    parseListEnd();

    // 匹配item
    if (_map_start.hasMatch(text)) {
      _evalMap(text, (_r) {
        var v = _r['map'];
        if (isList) {
          r.last.add(v);
        } else {
          r.add(v);
        }
        text = _r['text'];
      });
    } else {
      var m = _list_item.firstMatch(text);
      if (m != null) {
        var v = m.group(1);
        if (v.isNotEmpty) {
          if (isList) {
            r.last.add(_t(v));
          } else {
            r.add(_t(v));
          }
        }

        text = text.substring(m.end);
      }
    }
  }
  return r;
}

dynamic json5Parse(String text) {
  // 斩掉单行和多行注释
  text =
      text.replaceAll(_line_comment, '').replaceAll(_multi_line_comments, '');

  // 斩掉首尾空格，和多余的回车换行符
  // text = text.replaceAll(RegExp(r'[\r\n]'), '');
  text =
      text.replaceAll(RegExp(r'[\r\n]'), '').replaceAll(RegExp(r'\\n'), '\n');
  var result;

  if (_map_start.hasMatch(text)) {
    result = _evalMap(text);
  } else if (_list_start.hasMatch(text)) {
    result = _evalList(text);
  } else {
    // bool, nulber, string的情况
    var m = _value.firstMatch(text);
    if (m != null) {
      var v = m.group(1);
      text = text.substring(m.end);
      result = _t(v);
      if (text.isNotEmpty) return result;
    } else {
      throw 'parse error';
    }
  }

  return result;
}
