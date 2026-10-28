import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:source_gen/source_gen.dart';
import 'package:stealth_enum/stealth_enum.dart';

/// Generates a zero-cost Dart 3 `extension type` for each `@StealthEnum`
/// annotated private enum.
///
/// ### Security design decisions
/// * Values are derived using **HMAC-SHA256** keyed with an optional user-supplied
///   secret [StealthEnum.key], [StealthEnum.seed], or default salt over `'$publicName::$fieldName'`.
///   Because HMAC-SHA256 satisfies the strict avalanche criterion and is a
///   cryptographically secure pseudorandom function (PRF), XOR differential
///   attacks (such as XORing pairs of constants) cannot cancel out the key or
///   recover enum or constant names.
/// * Constants annotated with `@StealthValue(int)` use explicit, frozen 32-bit
///   integers, providing guaranteed backwards compatibility with databases
///   and external APIs.
/// * Every case in `.when()` matches an explicit hex constant. The wildcard `_`
///   branch fails closed by throwing `StateError('')` without leaking strings,
///   preventing invalid/tampered values from executing privileged branches.
/// * `@pragma('vm:prefer-inline')` on `.when` / `.maybeWhen` forces AOT to
///   inline the branch at the call site, stripping the helper method itself
///   from the binary.
/// * When `generateLabel: false` (the default), **zero string literals** from
///   the enum domain appear in the binary — the only strings are those you
///   write yourself in your own business logic.
class StealthEnumGenerator extends GeneratorForAnnotation<StealthEnum> {
  /// Default secret key supplied via builder options (`build.yaml`) or environment.
  final String? defaultKey;

  /// Whether a secret key is strictly required. If true and no secret key is provided
  /// (neither on the annotation nor via builder config / environment), code generation fails.
  final bool requireKey;

  /// Creates a [StealthEnumGenerator] instance.
  const StealthEnumGenerator({this.defaultKey, this.requireKey = false});

  static const Set<String> _reservedNames = {
    'when',
    'maybeWhen',
    'rawValue',
    'values',
    'isValid',
    'fromRawValue',
    'tryFromRawValue',
    'fromJson',
    'toJson',
    'label',
    'byLabel',
    'orElse',
  };

  static const Set<String> _publicPlaceholders = {
    'your-project-secret-salt-here-or-env',
    'YOUR_HIGH_ENTROPY_BUILD_SECRET',
  };

  @override
  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // ── Validation ────────────────────────────────────────────────────────────
    if (element is! EnumElement) {
      throw InvalidGenerationSourceError(
        '@StealthEnum can only be applied to an enum declaration.',
        element: element,
        todo: 'Remove @StealthEnum from non-enum element.',
      );
    }

    final EnumElement enumEl = element;
    final String sourceName =
        enumEl.name ?? enumEl.displayName; // e.g. '_UserFlow'

    // Enforce private enum declaration to guarantee AOT tree-shaking
    if (!sourceName.startsWith('_')) {
      throw InvalidGenerationSourceError(
        '@StealthEnum can only be applied to private enum declarations starting with a leading underscore (e.g. "_$sourceName").\n'
        'Public enums are preserved in Dart AOT binaries to support .name and reflection, defeating obfuscation.\n'
        'Rename the enum to "_$sourceName" so the Dart compiler can completely tree-shake the original enum metadata.',
        element: element,
        todo: 'Add a leading underscore to the enum name: "_$sourceName".',
      );
    }

    // Determine the public generated name.
    final String? nameOverride = annotation.peek('name')?.stringValue;
    final String publicName = nameOverride ?? sourceName.substring(1);

    final bool generateWhen =
        annotation.peek('generateWhen')?.boolValue ?? true;
    final bool generateLabel =
        annotation.peek('generateLabel')?.boolValue ?? false;
    final int? seedOverride = annotation.peek('seed')?.intValue;
    final String? rawKeyOverride =
        annotation.peek('key')?.stringValue ?? defaultKey;
    final String? keyOverride =
        (rawKeyOverride != null && rawKeyOverride.trim().isNotEmpty)
            ? rawKeyOverride.trim()
            : null;

    // ── Extract enum constants ────────────────────────────────────────────────
    final List<FieldElement> constants =
        enumEl.fields.where((f) => f.isEnumConstant).toList();

    if (constants.isEmpty) {
      throw InvalidGenerationSourceError(
        '@StealthEnum enum must have at least one constant.',
        element: element,
      );
    }

    final bool allExplicit =
        constants.every((f) => _readExplicitValue(f) != null);

    if (!allExplicit) {
      if (requireKey && keyOverride == null) {
        throw InvalidGenerationSourceError(
          'Enum "$publicName" requires a secret key for cryptographic security, but none was provided.\n'
          'Provide a key via @StealthEnum(key: "secret"), build.yaml (options: {key: "secret"}), '
          'or the STEALTH_ENUM_KEY environment variable.',
          element: element,
          todo: 'Provide a high-entropy secret key or remove require_key.',
        );
      }

      if (keyOverride != null) {
        if (_publicPlaceholders.contains(keyOverride)) {
          throw InvalidGenerationSourceError(
            'Enum "$publicName" is configured with a documented public placeholder key ("$keyOverride").\n'
            'Do not use README/documentation example keys in actual code. '
            'Generate a private random key: python3 -c "import secrets;print(secrets.token_urlsafe(24))"',
            element: element,
            todo:
                'Replace the placeholder with a secure high-entropy secret key.',
          );
        }

        if (requireKey && keyOverride.length < 24) {
          throw InvalidGenerationSourceError(
            'Enum "$publicName" has require_key enabled, but the provided key is only ${keyOverride.length} characters long.\n'
            'Keys must be at least 24 characters to prevent offline dictionary confirmation.',
            element: element,
            todo:
                'Provide a key with at least 24 characters (e.g. via python3 -c "import secrets;print(secrets.token_urlsafe(24))").',
          );
        }

        if (keyOverride.length < 24) {
          log.warning(
            'stealth_enum: key for "$publicName" is under 24 chars; '
            'use python3 -c "import secrets;print(secrets.token_urlsafe(24))"',
          );
        }
      } else if (seedOverride != null) {
        log.warning(
          'stealth_enum: Enum "$publicName" is using a 32-bit integer seed. '
          'Seeds have low entropy (~1.7h search space); for cryptographic secrecy against dictionary recovery, '
          'provide a secret key via @StealthEnum(key: "..."), build.yaml, or STEALTH_ENUM_KEY.',
        );
      } else {
        log.warning(
          'stealth_enum: Enum "$publicName" is using the public default salt. '
          'For cryptographic security against dictionary recovery, provide a secret key '
          'via @StealthEnum(key: "..."), build.yaml, or STEALTH_ENUM_KEY.',
        );
      }
    }

    // Validate that constant names do not collide with generated member names
    for (final field in constants) {
      final fieldName = field.name ?? field.displayName;
      if (_reservedNames.contains(fieldName)) {
        throw InvalidGenerationSourceError(
          'Enum constant "$fieldName" in enum "$publicName" collides with a generated extension type member or parameter.\n'
          'Reserved names: ${_reservedNames.join(', ')}.',
          element: field,
          todo:
              'Rename the constant "$fieldName" to avoid collision with generated members.',
        );
      }
    }

    // ── Generate collision-free 32-bit hex values ─────────────────────────────
    final List<String> fieldNames =
        constants.map((f) => f.name ?? f.displayName).toList();
    final Map<String, int> valueMap = _generateValues(
      publicName,
      constants,
      keyOverride,
      seedOverride,
    );

    // ── Emit code ─────────────────────────────────────────────────────────────
    final buffer = StringBuffer();
    _writeExtensionType(
      buffer,
      publicName,
      fieldNames,
      valueMap,
      generateWhen,
      generateLabel,
      keyOverride,
      !allExplicit,
    );
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Hash & Value generation
  // ---------------------------------------------------------------------------

  static int? _readExplicitValue(FieldElement field) {
    final dynamic meta = field.metadata;
    final Iterable annotations =
        meta is Iterable ? meta : (meta.annotations as Iterable);
    for (final dynamic item in annotations) {
      if (item is ElementAnnotation) {
        final value = item.computeConstantValue();
        if (value != null && value.type?.element?.name == 'StealthValue') {
          return value.getField('value')?.toIntValue();
        }
      }
    }
    return null;
  }

  /// Normalizes a 32-bit integer into the positive hex range [0x10000000 .. 0x7FFFFFFF].
  ///
  /// This avoids negative numbers on 32-bit platforms/Web, ensures a non-zero high nibble,
  /// and produces clean, human-readable 8-character hex constants (e.g. `0x373D1B37`).
  static int _toPositive32(int hash) {
    final positive = hash & 0x7FFFFFFF;
    if (positive < 0x10000000) {
      return positive + 0x10000000;
    }
    return positive;
  }

  /// Formats an integer as a clean 8-character uppercase hexadecimal constant.
  static String _formatHex(int value) =>
      '0x${value.toRadixString(16).toUpperCase().padLeft(8, '0')}';

  /// Computes a cryptographically keyed 32-bit integer for a given constant using HMAC-SHA256.
  ///
  /// Key precedence:
  /// 1. Explicit [keyOverride] string in `@StealthEnum(key: '...')`
  /// 2. Explicit [seedOverride] integer in `@StealthEnum(seed: ...)`
  /// 3. Default salt: `stealth_enum:default_salt:0xDEADBEEF`
  ///
  /// Because HMAC-SHA256 is a cryptographically secure pseudorandom function (PRF)
  /// that satisfies the strict avalanche criterion, XOR differential attacks
  /// (e.g. `valA ^ valB`) cannot cancel out the key or enum name.
  static int _computeKeyedHash(
    String publicName,
    String fieldName, {
    String? keyOverride,
    int? seedOverride,
  }) {
    final List<int> keyBytes;
    if (keyOverride != null && keyOverride.isNotEmpty) {
      keyBytes = utf8.encode(keyOverride);
    } else if (seedOverride != null) {
      keyBytes = utf8.encode('stealth_enum:seed:$seedOverride');
    } else {
      keyBytes = utf8.encode('stealth_enum:default_salt:0xDEADBEEF');
    }

    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(utf8.encode('$publicName::$fieldName'));
    final bytes = digest.bytes;
    final raw = ((bytes[0] & 0xFF) << 24) |
        ((bytes[1] & 0xFF) << 16) |
        ((bytes[2] & 0xFF) << 8) |
        (bytes[3] & 0xFF);
    return _toPositive32(raw);
  }

  /// Generates deterministic, collision-free 32-bit hex integers for each
  /// enum constant.
  ///
  /// 1. Constants annotated with `@StealthValue(int)` use their explicit values.
  /// 2. Other constants derive their value from keyed HMAC-SHA256 of their name,
  ///    the public enum name, and an optional secret key or seed.
  ///
  /// Because each constant's value is derived independently via HMAC-SHA256,
  /// adding, removing, or reordering other constants will NOT shift the values
  /// of existing constants, and XOR differential attacks cannot recover names.
  Map<String, int> _generateValues(
    String publicName,
    List<FieldElement> constants,
    String? keyOverride,
    int? seedOverride,
  ) {
    final usedValues = <int>{};
    final explicitValues = <String, int>{};
    final result = <String, int>{};

    // 1. Pass 1: Collect and validate explicit @StealthValue annotations
    for (final field in constants) {
      final fieldName = field.name ?? field.displayName;
      final explicitValue = _readExplicitValue(field);
      if (explicitValue != null) {
        if (explicitValue < 0 || explicitValue > 0xFFFFFFFF) {
          throw InvalidGenerationSourceError(
            '@StealthValue($explicitValue) on constant "$fieldName" in enum "$publicName" is invalid. '
            'Values must be positive 32-bit unsigned integers between 0x0 and 0xFFFFFFFF.',
            element: field,
            todo:
                'Specify a positive 32-bit integer, e.g. @StealthValue(0x10000001).',
          );
        }
        if (explicitValue < 0x1000) {
          throw InvalidGenerationSourceError(
            '@StealthValue($explicitValue) on constant "$fieldName" in enum "$publicName" is too small. '
            'Values below 0x1000 defeat reverse-engineering resistance by creating low sequential jump tables. '
            'Use high-entropy constants (>= 0x10000).',
            element: field,
            todo:
                'Choose a high-entropy hex constant, e.g. @StealthValue(0x10000001).',
          );
        }
        if (usedValues.contains(explicitValue)) {
          throw InvalidGenerationSourceError(
            'Duplicate @StealthValue(${_formatHex(explicitValue)}) '
            'found on constant "$fieldName" in enum "$publicName". All values must be unique.',
            element: field,
          );
        }
        usedValues.add(explicitValue);
        explicitValues[fieldName] = explicitValue;
        result[fieldName] = explicitValue;
      }
    }

    // 2. Pass 2: Derive keyed HMAC-SHA256 values for un-annotated constants
    for (final field in constants) {
      final fieldName = field.name ?? field.displayName;
      if (explicitValues.containsKey(fieldName)) continue;

      int value = _computeKeyedHash(
        publicName,
        fieldName,
        keyOverride: keyOverride,
        seedOverride: seedOverride,
      );
      int probe = 0;
      while (usedValues.contains(value)) {
        probe++;
        final hmac = Hmac(sha256, utf8.encode('stealth_probe:$probe'));
        final digest =
            hmac.convert(utf8.encode('$publicName::$fieldName::$value'));
        final b = digest.bytes;
        final raw = ((b[0] & 0xFF) << 24) |
            ((b[1] & 0xFF) << 16) |
            ((b[2] & 0xFF) << 8) |
            (b[3] & 0xFF);
        value = _toPositive32(raw);
      }

      usedValues.add(value);
      result[fieldName] = value;
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Code emission
  // ---------------------------------------------------------------------------

  void _writeExtensionType(
    StringBuffer buf,
    String publicName,
    List<String> fieldNames,
    Map<String, int> valueMap,
    bool generateWhen,
    bool generateLabel, [
    String? keyOverride,
    bool emitFingerprint = true,
  ]) {
    if (emitFingerprint && keyOverride != null && keyOverride.isNotEmpty) {
      final fp = Hmac(sha256, utf8.encode(keyOverride))
          .convert(utf8.encode('stealth_enum:fingerprint:v1'))
          .toString()
          .substring(0, 8);
      buf.writeln('// Key fingerprint: $fp');
    }
    buf.writeln('extension type const $publicName._(int rawValue) {');

    // Static constants
    for (final name in fieldNames) {
      final hex = _formatHex(valueMap[name]!);
      buf.writeln('  static const $publicName $name = $publicName._($hex);');
    }

    buf.writeln();
    buf.writeln(
        '  /// Creates a [$publicName] instance from [rawValue] at runtime.');
    buf.writeln(
        '  const factory $publicName.fromRawValue(int rawValue) = $publicName._;');
    buf.writeln();
    buf.writeln(
        '  /// Safely parses [rawValue] into a [$publicName], returning `null` if unknown.');
    buf.writeln('  ///');
    buf.writeln(
        '  /// Use this when parsing untrusted external inputs (API responses, JSON,');
    buf.writeln('  /// databases) to prevent runtime exceptions.');
    buf.writeln('  static $publicName? tryFromRawValue(int rawValue) {');
    buf.writeln('    return switch (rawValue) {');
    for (final name in fieldNames) {
      final hex = _formatHex(valueMap[name]!);
      buf.writeln('      $hex => $name,');
    }
    buf.writeln('      _ => null,');
    buf.writeln('    };');
    buf.writeln('  }');
    buf.writeln();
    buf.writeln(
        '  /// Returns `true` if this instance represents a valid, recognized constant.');
    buf.writeln('  bool get isValid => tryFromRawValue(rawValue) != null;');
    buf.writeln();
    buf.writeln(
        '  /// Serializes this [$publicName] to its integer [rawValue].');
    buf.writeln('  ///');
    buf.writeln(
        '  /// Integer serialization leaks zero string identifiers into compiled AOT binaries.');
    buf.writeln('  int toJson() => rawValue;');
    buf.writeln();
    buf.writeln(
        '  /// Deserializes an integer [rawValue] into a [$publicName], returning `null` on unknown value.');
    buf.writeln(
        '  static $publicName? fromJson(int rawValue) => tryFromRawValue(rawValue);');
    buf.writeln();

    // Constant values list
    buf.writeln('  /// All recognized constants of [$publicName].');
    buf.writeln('  static const List<$publicName> values = [');
    for (final name in fieldNames) {
      buf.writeln('    $name,');
    }
    buf.writeln('  ];');

    // Label helpers (if enabled)
    if (generateLabel) {
      _writeLabelHelpers(buf, publicName, fieldNames);
    }

    // Exhaustive pattern matching helpers (if enabled)
    if (generateWhen) {
      _writeWhenHelpers(buf, publicName, fieldNames, valueMap);
    }

    buf.writeln('}');
  }

  void _writeLabelHelpers(
    StringBuffer buf,
    String publicName,
    List<String> fieldNames,
  ) {
    buf.writeln();
    buf.writeln('  // '
        '─────────────────────────────────────────────────────────────────────────');
    buf.writeln('  // Label Ergonomics (generateLabel: true)');
    buf.writeln('  //');
    buf.writeln('  // [SECURITY WARNING]');
    buf.writeln(
        '  // These helpers emit human-readable string literals into the generated file.');
    buf.writeln(
        '  // These strings WILL be retained in the compiled AOT binary (libapp.so).');
    buf.writeln('  // '
        '─────────────────────────────────────────────────────────────────────────');
    buf.writeln();
    buf.writeln(
        '  /// Returns the original enum constant name as a string (equivalent to `enum.name`).');
    buf.writeln('  ///');
    buf.writeln(
        '  /// **Note**: This emits plain-text string literals into the compiled binary.');
    buf.writeln('  String get label => switch (this) {');
    for (final name in fieldNames) {
      buf.writeln("        $name => '$name',");
    }
    buf.writeln("        _ => 'unknown',");
    buf.writeln('      };');
    buf.writeln();
    buf.writeln(
        '  /// Looks up a [$publicName] by its [label] string (equivalent to `values.byName`).');
    buf.writeln('  ///');
    buf.writeln('  /// Returns `null` if no variant matches the given label.');
    buf.writeln(
        '  static $publicName? byLabel(String label) => switch (label) {');
    for (final name in fieldNames) {
      buf.writeln("        '$name' => $name,");
    }
    buf.writeln('        _ => null,');
    buf.writeln('      };');
  }

  void _writeWhenHelpers(
    StringBuffer buf,
    String publicName,
    List<String> fieldNames,
    Map<String, int> valueMap,
  ) {
    // ── when() ───────────────────────────────────────────────────────────────
    buf.writeln();
    buf.writeln('  /// Exhaustive pattern matching across all variants.');
    buf.writeln('  ///');
    buf.writeln('  /// Marked with `@pragma(\'vm:prefer-inline\')` to inline');
    buf.writeln(
        '  /// branch dispatch directly at the call site, eliminating helper');
    buf.writeln('  /// symbols from the compiled binary symbol table.');
    buf.writeln('  @pragma(\'vm:prefer-inline\')');
    buf.writeln('  R when<R>({');
    for (final name in fieldNames) {
      buf.writeln('    required R Function() $name,');
    }
    buf.writeln('  }) {');
    buf.writeln('    return switch (rawValue) {');
    for (final name in fieldNames) {
      final hex = _formatHex(valueMap[name]!);
      buf.writeln('      $hex => $name(),');
    }
    // Fail-closed wildcard branch: throws without leaking string identifiers
    buf.writeln('      _ => throw StateError(\'\'),');
    buf.writeln('    };');
    buf.writeln('  }');

    // ── maybeWhen() ───────────────────────────────────────────────────────────
    buf.writeln();
    buf.writeln(
        '  /// Partial pattern matching with a required [orElse] fallback.');
    buf.writeln('  ///');
    buf.writeln('  /// Marked with `@pragma(\'vm:prefer-inline\')` to inline');
    buf.writeln(
        '  /// branch dispatch directly at the call site, eliminating helper');
    buf.writeln('  /// symbols from the compiled binary symbol table.');
    buf.writeln('  @pragma(\'vm:prefer-inline\')');
    buf.writeln('  R maybeWhen<R>({');
    for (final name in fieldNames) {
      buf.writeln('    R Function()? $name,');
    }
    buf.writeln('    required R Function() orElse,');
    buf.writeln('  }) {');
    buf.writeln('    return switch (rawValue) {');
    for (final name in fieldNames) {
      final hex = _formatHex(valueMap[name]!);
      buf.writeln('      $hex when $name != null => $name(),');
    }
    buf.writeln('      _ => orElse(),');
    buf.writeln('    };');
    buf.writeln('  }');
  }
}
