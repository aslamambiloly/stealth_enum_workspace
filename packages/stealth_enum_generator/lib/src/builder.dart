import 'dart:io';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:stealth_enum_generator/src/stealth_enum_generator.dart';

/// Entry point called by `build_runner` via `build.yaml`.
///
/// Uses [SharedPartBuilder] so the generated `*.g.dart` file is shared with
/// other part-based generators (json_serializable, freezed, riverpod, etc.).
Builder stealthEnumBuilder(BuilderOptions options) {
  final defaultKey = options.config['key'] as String? ??
      Platform.environment['STEALTH_ENUM_KEY'];
  return SharedPartBuilder(
    [StealthEnumGenerator(defaultKey: defaultKey)],
    'stealth_enum',
  );
}
