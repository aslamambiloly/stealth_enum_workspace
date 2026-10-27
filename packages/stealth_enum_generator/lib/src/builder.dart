import 'dart:io';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:stealth_enum_generator/src/stealth_enum_generator.dart';

/// Entry point called by `build_runner` via `build.yaml`.
///
/// Uses [SharedPartBuilder] so the generated `*.g.dart` file is shared with
/// other part-based generators (json_serializable, freezed, riverpod, etc.).
Builder stealthEnumBuilder(BuilderOptions options) {
  final rawKey = options.config['key']?.toString() ??
      Platform.environment['STEALTH_ENUM_KEY'];
  final trimmedKey = rawKey?.trim();
  final defaultKey =
      (trimmedKey != null && trimmedKey.isNotEmpty) ? trimmedKey : null;

  final requireKey = options.config['require_key'] == true ||
      options.config['require_key'] == 'true' ||
      Platform.environment['STEALTH_ENUM_REQUIRE_KEY'] == '1' ||
      Platform.environment['STEALTH_ENUM_REQUIRE_KEY'] == 'true';

  return SharedPartBuilder(
    [
      StealthEnumGenerator(
        defaultKey: defaultKey,
        requireKey: requireKey,
      ),
    ],
    'stealth_enum',
  );
}
