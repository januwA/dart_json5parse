import 'package:dart_json5parse/dart_json5parse.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('false Test', () {
      expect(json5Parse('false'), isFalse);
    });

    test('true Test', () {
      expect(json5Parse('true'), isTrue);
    });

    test('null Test', () {
      expect(json5Parse('null'), isNull);
    });
    test('int Test', () {
      expect(json5Parse('123'), 123);
    });
    test('negative Test', () {
      expect(json5Parse('-123'), -123);
    });

    test('decimal Test', () {
      expect(json5Parse('-123.12'), -123.12);
    });
    test('e-num Test', () {
      expect(json5Parse('-123.12e2'), -12312);
    });

    test('string Test', () {
      expect(json5Parse(' "hello" '), 'hello');
    });
    test('empty string Test', () {
      expect(json5Parse(' "" '), '');
    });
  });
}
