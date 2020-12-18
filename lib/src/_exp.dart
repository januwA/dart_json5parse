final line_comment = r'''\s*\/\/[^\n]*\s*''';
final multi_line_comments = r'\s*\/\*[^]*?\*\/\s*';
final comment_exp = RegExp('''^($line_comment|$multi_line_comments)''');

final string_a = r'''"[^"]*"''';
final string_b = r"""'[^']*'""";
final string_true = r'true';
final string_false = r'false';
final string_null = r'null';

final string_a_exp = RegExp(string_a);
final string_b_exp = RegExp(string_b);
final string_true_exp = RegExp(string_true);
final string_false_exp = RegExp(string_false);
final string_null_exp = RegExp(string_null);

// 1.0  0.1  1. .1
final string_double = r'-?\d*\.\d*(?:[eE][+\-]?\d+)?';

// 1 1e2 1e-2
final string_int = r'-?\d+(?:[eE][+\-]?\d+)?';

// 0x0A
final string_hex = r'0x[a-fA-F0-9]+';

final string_double_exp = RegExp(string_double);
final string_int_exp = RegExp(string_int);
final string_hex_exp = RegExp(string_hex);

// 处理 1e2 或 1e-2 只能只用double
final is_int_exponent = RegExp(r'[eE]', dotAll: true);

final map_start_exp = RegExp(r'^\s*\{\s*');
final map_end_exp = RegExp('''^\\s*\\}($multi_line_comments)*(?<comma>,)?''');

// map key
final map_key_exp = RegExp('''^([^]+?)($multi_line_comments)*\\s*:\\s*''');

final list_start_exp = RegExp(r'^\s*\[\s*');
final list_end_exp = RegExp('''^\\s*\\]($multi_line_comments)*(?<comma>,)?''');

// emoji
// https://stackoverflow.com/questions/55433185/how-to-detect-emojis-in-a-string-in-flutter-using-dart
// final emoji_exp = RegExp(
//     r'\s*(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+\s*');

/// map_value or list_value
final value_exp = RegExp(
    '''($string_true|$string_false|$string_null|$string_hex|$string_double|$string_int|$string_a|$string_b)($multi_line_comments)*(?<comma>,)?\\s*''');

final quotes_start_exp = RegExp(r'''^["']''');
final quotes_end_exp = RegExp(r'''["']$''');
