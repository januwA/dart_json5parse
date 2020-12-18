import 'dart:io';

import 'package:dart_json5parse/dart_json5parse.dart';

String __filename = Platform.script.path.replaceFirst('/', '');
String __dirname = Directory(__filename).parent.path;

void main() async {
  var f = File(__dirname + '/test.json5');
  var json5Str = await f.readAsString();

  Map r = json5Parse(json5Str);
  r.forEach((key, value) {
    print(
        '${key.toString().padRight(20, ' ')} | ${value.toString().padRight(40, ' ')} | ${value.runtimeType}');
  });
}
