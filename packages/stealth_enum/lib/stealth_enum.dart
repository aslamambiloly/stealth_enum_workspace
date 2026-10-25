/// Stealth Enum — eliminate Dart enum metadata from Flutter AOT binaries.
///
/// Import this library in your `dependencies` and annotate private enums with
/// [StealthEnum]. Run `build_runner` to generate zero-cost Dart 3 extension
/// types backed by randomized 32-bit integers.
library stealth_enum;

export 'src/stealth_enum_annotation.dart';
