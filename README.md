## dart_json5parse

Parse json5 data in dart

## install
```yaml
dependencies:
 dart_json5parse:
```

## Example
```dart
import 'package:dart_json5parse/dart_json5parse.dart';

void main() async {
  var data = json5Parse('''
  {
    name: "Ajanuw",
    array: [1, "x", [], {}],
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
  expect(data['k'], isMap);
  expect(data['k']['name'], 'Ajanuw');
}
```

## test
```sh
$ dart test
```

## Note

Parse the int exponent, the returned type is double

```dart
expect(json5Parse('1e2'), 100.0);
expect(json5Parse('1e-2'), 0.01);
```