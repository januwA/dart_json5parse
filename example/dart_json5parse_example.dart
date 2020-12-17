import 'dart:io';

import 'package:dart_json5parse/dart_json5parse.dart';

String __filename = Platform.script.path.replaceFirst('/', '');
String __dirname = Directory(__filename).parent.path;
void main() async {
  var f = File(__dirname + '/test.json5');
  var r = json5Parse(await f.readAsString());
  print(r);
  // print(r['unquoted']);
  // print(r['singleQuotes']);
  // print(r['lineBreaks']);
  // print(r['hexadecimal']);
  // print(r['leadingDecimalPoint']);
  // print(r['andTrailing']);
  // print(r['positiveSign']);
  // print(r['andIn']);
  // print(r['andIn'][0]);
}
