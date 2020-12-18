import './_exp.dart';

/// Map和List计数
var _con_textCount = 0;

/// json5 String
var _text = '';

/// 将字符串转为对应的dart类型
dynamic _t(String v, {bool isKey = false}) {
  if (string_a_exp.hasMatch(v) || string_b_exp.hasMatch(v) || isKey) {
    return v
        .trim()
        .replaceAll(quotes_start_exp, '')
        .replaceAll(quotes_end_exp, '');
  }

  if (string_true_exp.hasMatch(v)) return true;
  if (string_false_exp.hasMatch(v)) return false;
  if (string_null_exp.hasMatch(v)) return null;
  if (string_double_exp.hasMatch(v)) return double.parse(v);

  if (string_int_exp.hasMatch(v) || string_hex_exp.hasMatch(v)) {
    if (is_int_exponent.hasMatch(v)) return double.parse(v);
    return int.parse(v);
  }

  return v;
}

/// 匹配注释，并删除
void _removeCommet() {
  var m = comment_exp.firstMatch(_text);
  while (m != null) {
    _text = _text.substring(m.end);
    m = comment_exp.firstMatch(_text);
  }
}

/// 测试逗号是否正确
void _testComa(RegExpMatch m) {
  if (m.namedGroup('comma') == null &&
      !map_end_exp.hasMatch(_text) &&
      !list_end_exp.hasMatch(_text) &&
      _con_textCount != 0) {
    // 逗号匹配错误
    throw 'Comma parse error: ' + _text;
  }
}

void Function() _gStart(RegExp exp) {
  return () {
    final m = exp.firstMatch(_text);
    if (m != null) {
      _con_textCount++;
      _text = _text.substring(m.end);
    }
  };
}

bool Function() _gEnd(RegExp exp) {
  return () {
    final m = exp.firstMatch(_text);
    final ok = m != null;
    if (ok) {
      _con_textCount--;
      _text = _text.substring(m.end);
      _testComa(m);
    }
    return ok;
  };
}

bool _isMap() {
  return map_start_exp.hasMatch(_text);
}

bool _isList() {
  return list_start_exp.hasMatch(_text);
}

/// parse Map
Map _evalMap() {
  var mapStart = _gStart(map_start_exp);
  var mapEnd = _gEnd(map_end_exp);
  final r = {};
  mapStart();
  while (_text.isNotEmpty) {
    _removeCommet();
    if (mapEnd()) break;

    var m_k = map_key_exp.firstMatch(_text);
    if (m_k != null) {
      String k = _t(m_k[1], isKey: true);
      _text = _text.substring(m_k.end);
      r[k.trim()] = _json5Parse();
    } else {
      throw 'parse map key error: ' + _text;
    }
  }
  return r;
}

/// parse List
List _evalList() {
  var listStart = _gStart(list_start_exp);
  var listEnd = _gEnd(list_end_exp);
  final r = [];
  listStart();
  while (_text.isNotEmpty) {
    _removeCommet();
    if (listEnd()) break;
    r.add(_json5Parse());
  }
  return r;
}

dynamic _json5Parse() {
  _removeCommet();
  if (_isMap()) {
    return _evalMap();
  } else if (_isList()) {
    return _evalList();
  } else {
    var m = value_exp.firstMatch(_text);
    if (m != null) {
      _text = _text.substring(m.end);
      _removeCommet(); // 清理一下注释，在判断逗号是否被正确添加
      _testComa(m);
      return _t(m[1]);
    } else {
      throw 'Value parse error: ' + _text;
    }
  }
}

dynamic json5Parse(String text) {
  _text = text;
  _removeCommet();
  if (!_isMap() && !_isList()) {
    _text = _text.trim();
    var m = value_exp.firstMatch(_text);
    if (m != null) {
      _text = _text.substring(m.end);
      _removeCommet();
      if (_text.isEmpty) return _t(m[1]);
    } else {
      throw 'Value parse error: ' + _text;
    }
  }
  return _json5Parse();
}
