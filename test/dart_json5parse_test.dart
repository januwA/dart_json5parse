import 'package:dart_json5parse/dart_json5parse.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('number Test', () {
      expect(json5Parse('123'), 123);
      expect(json5Parse('12.3'), 12.3);
      expect(json5Parse('-123'), -123);
      expect(json5Parse('-12.3'), -12.3);
      expect(json5Parse('-123.12e2'), -12312);
      expect(json5Parse('-123.12e+2'), -12312);
      expect(json5Parse('-123.12e-2'), -1.2312);
      expect(json5Parse('.8'), 0.8);
      expect(json5Parse('1.'), 1.0);
      expect(json5Parse('1e2'), 100.0);
      expect(json5Parse('1e-2'), 0.01);
    });

    test('other Test', () {
      expect(json5Parse(' "hello" '), 'hello');
      expect(json5Parse(' /* c */ "hello"/* c */ // c'), 'hello');
      expect(json5Parse(' "" '), '');
      expect(json5Parse(" '' "), '');
      expect(json5Parse('null'), isNull);
      expect(json5Parse('false'), isFalse);
      expect(json5Parse('true'), isTrue);
    });

    test('unicode Test', () {
      expect(json5Parse(''' "❤️" '''), '❤️');
      expect(json5Parse(''' "\u2764" '''), '\u2764');
      expect(json5Parse(''' "\u{2764}" '''), '\u{2764}');
    });

    test('space Test', () {
      expect(json5Parse(' "   " '), '   ');
      final data = json5Parse(" { data: '  ' } ");
      expect(data['data'], '  ');
    });

    test('object Test', () {
      var data = json5Parse('''
      {
        name: "Ajanuw",
        array: [1, "x", [], { name: 'ajanuw' }],
        k: {
          name: "Ajanuw",
        }
      }
      ''');
      expect(data['name'], 'Ajanuw');
      expect(data['array'][0], 1);
      expect(data['array'][1], 'x');
      expect(data['array'][2], isList);
      expect(data['array'][3], isMap);
      expect(data['array'][3]['name'], 'ajanuw');
      expect(data['k'], isMap);
      expect(data['k']['name'], 'Ajanuw');
    });

    test('array Test', () {
      var data = json5Parse('''
      [
        1,
        "2",
        {
          name: "Ajanuw",
        },
        [1],
      ]
      ''');
      expect(data[0], 1);
      expect(data[1], '2');
      expect(data[2], isMap);
      expect(data[2]['name'], 'Ajanuw');
      expect(data[3], isList);
      expect(data[3][0], 1);
    });
  });
}
