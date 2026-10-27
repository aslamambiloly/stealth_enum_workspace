import 'dart:math';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:stealth_enum/stealth_enum.dart';

/// Generates a zero-cost Dart 3 `extension type` for each `@StealthEnum`
/// annotated private enum.
///
/// ### Security design decisions
/// * Values are **deterministic** (seeded from enum + field name hash) so
///   repeated `build_runner` runs don't dirty Git diffs, yet look completely
///   non-sequential in Ghidra ARM64 assembly.
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
  /// Creates a [StealthEnumGenerator] instance.
  const StealthEnumGenerator();

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

    // Determine the public generated name.
    final String? nameOverride = annotation.peek('name')?.stringValue;
    final String publicName = nameOverride ??
        (sourceName.startsWith('_')
            ? sourceName.substring(1) // '_UserFlow' → 'UserFlow'
            : '${sourceName}Stealth'); // 'UserFlow' → 'UserFlowStealth'

    final bool generateWhen =
        annotation.peek('generateWhen')?.boolValue ?? true;
    final bool generateLabel =
        annotation.peek('generateLabel')?.boolValue ?? false;
    final int? seedOverride = annotation.peek('seed')?.intValue;

    // ── Extract enum constants ────────────────────────────────────────────────
    // Use .constants (the proper EnumElement API) to avoid synthetic fields
    // like `index`, `values`, `_name`, etc.
    final List<FieldElement> constants =
        enumEl.fields.where((f) => f.isEnumConstant).toList();

    if (constants.isEmpty) {
      throw InvalidGenerationSourceError(
        '@StealthEnum enum must have at least one constant.',
        element: element,
      );
    }

    // ── Generate collision-free 32-bit hex values ─────────────────────────────
    final List<String> fieldNames =
        constants.map((f) => f.name ?? f.displayName).toList();
    final Map<String, int> valueMap =
        _generateValues(publicName, fieldNames, seedOverride);

    // ── Emit code ─────────────────────────────────────────────────────────────
    final buffer = StringBuffer();
    _writeExtensionType(
        buffer, publicName, fieldNames, valueMap, generateWhen, generateLabel);
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Value generation
  // ---------------------------------------------------------------------------

  /// Generates a deterministic, collision-free 32-bit hex integer for each
  /// enum constant. Values are in the range [0x10000000, 0x7FFFFFFF] (positive
  /// 32-bit, high nibble ≥ 1 to avoid trivially small constants).
  Map<String, int> _generateValues(
    String publicName,
    List<String> fieldNames,
    int? seedOverride,
  ) {
    final usedValues = <int>{};
    final result = <String, int>{};

    for (final fieldName in fieldNames) {
      // Deterministic seed: combine public type name, field name, and a fixed
      // salt so even common names like `active` produce unique distributions
      // across different enum types.
      final int baseSeed = seedOverride ??
          (publicName.hashCode ^ fieldName.hashCode ^ 0xDEADBEEF);

      var rng = Random(baseSeed);
      int value;
      int attempts = 0;
      do {
        // Stay in the range [0x10000000 .. 0x7FFFFFFF] for human-readable hex.
        value = rng.nextInt(0x6FFFFFFF) + 0x10000000;
        attempts++;
        // Re-seed slightly on collision to find a different value deterministically.
        if (attempts > 1) {
          rng = Random(baseSeed ^ attempts);
        }
      } while (usedValues.contains(value));

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
    bool generateLabel,
  ) {
    buf.writeln('extension type const $publicName._(int rawValue) {');

    // Static constants
    for (final name in fieldNames) {
      final hex = '0x${valueMap[name]!.toRadixString(16).toUpperCase()}';
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
      final hex = '0x${valueMap[name]!.toRadixString(16).toUpperCase()}';
      buf.writeln('      $hex => $name,');
    }
    buf.writeln('      _ => null,');
    buf.writeln('    };');
    buf.writeln('  }');
    buf.writeln();

    // values list
    buf.writeln(
        '  static const List<$publicName> values = <$publicName>[');
    for (final name in fieldNames) {
      buf.writeln('    $name,');
    }
    buf.writeln('  ];');
    buf.writeln();

    // isValid getter
    buf.writeln(
        '  /// Whether this instance holds a recognized constant value.');
    buf.writeln(
        '  bool get isValid => $publicName.values.contains(this);');

    if (generateLabel) {
      buf.writeln();
      _writeLabelHelpers(buf, publicName, fieldNames, valueMap);
    }

    if (generateWhen) {
      buf.writeln();
      _writeWhen(buf, publicName, fieldNames, valueMap);
      buf.writeln();
      _writeMaybeWhen(buf, publicName, fieldNames, valueMap);
    }

    buf.writeln('}');
  }

  void _writeLabelHelpers(
    StringBuffer buf,
    String publicName,
    List<String> fieldNames,
    Map<String, int> valueMap,
  ) {
    buf.writeln(
        '  // ── Label helpers (generateLabel: true) ─────────────────────────');
    buf.writeln('  //');
    buf.writeln(
        '  // NOTE: These helpers emit plain-text string literals into the compiled');
    buf.writeln(
        '  // binary. The private source enum strings are fully erased, but these');
    buf.writeln(
        '  // generated labels re-introduce readable names. Use only when you need');
    buf.writeln(
        '  // serialization or logging and you understand the security trade-off.');
    buf.writeln();

    // .label getter
    buf.writeln(
        "  /// The human-readable label for this variant (e.g. `'admin'`).");
    buf.writeln('  ///');
    buf.writeln('  /// Equivalent to `.name` on a standard Dart `enum`.');
    buf.writeln(
        '  /// **Note**: This string will be present in AOT binaries (see `generateLabel`).');
    buf.writeln('  String get label => switch (rawValue) {');
    for (final name in fieldNames) {
      final hex = '0x${valueMap[name]!.toRadixString(16).toUpperCase()}';
      buf.writeln("    $hex => '$name',");
    }
    buf.writeln("    _ => 'unknown(\$rawValue)',");
    buf.writeln('  };');
    buf.writeln();

    // byLabel()
    buf.writeln(
        '  /// Looks up a [$publicName] variant by its [label] string.');
    buf.writeln('  ///');
    buf.writeln(
        '  /// Returns `null` if [label] does not match any known variant.');
    buf.writeln(
        '  /// Equivalent to `$publicName.byName(label)` on a standard `enum`.');
    buf.writeln('  static $publicName? byLabel(String label) {');
    buf.writeln('    return switch (label) {');
    for (final name in fieldNames) {
      buf.writeln("      '$name' => $name,");
    }
    buf.writeln('      _ => null,');
    buf.writeln('    };');
    buf.writeln('  }');
    buf.writeln();

    // toJson / fromJson
    buf.writeln(
        '  /// Serializes this [$publicName] to its raw integer value for JSON/storage.');
    buf.writeln('  ///');
    buf.writeln(
        '  /// Always persist [toJson] values alongside a version stamp so you can');
    buf.writeln('  /// migrate if you ever regenerate with a new seed.');
    buf.writeln('  int toJson() => rawValue;');
    buf.writeln();
    buf.writeln(
        '  /// Deserializes a [$publicName] from a raw JSON integer.');
    buf.writeln('  ///');
    buf.writeln(
        '  /// Returns `null` if [json] is not a recognized value.');
    buf.writeln('  /// Alias for [tryFromRawValue].');
    buf.writeln(
        '  static $publicName? fromJson(int json) => tryFromRawValue(json);');
  }

  void _writeWhen(
    StringBuffer buf,
    String publicName,
    List<String> fieldNames,
    Map<String, int> valueMap,
  ) {
    buf.writeln('  /// Exhaustive compile-time condition flow.');
    buf.writeln('  ///');
    buf.writeln(
        '  /// Every case must be handled — adding a new value to the source enum');
    buf.writeln(
        '  /// breaks compilation here until handled. Inlined by AOT into raw integer');
    buf.writeln(
        '  /// comparisons; the method itself is stripped from the binary.');
    buf.writeln("  @pragma('vm:prefer-inline')");
    buf.writeln('  T when<T>({');
    for (final name in fieldNames) {
      buf.writeln('    required T Function() $name,');
    }
    buf.writeln('  }) {');
    buf.writeln('    return switch (rawValue) {');

    for (final name in fieldNames) {
      final hex = '0x${valueMap[name]!.toRadixString(16).toUpperCase()}';
      buf.writeln('      $hex => $name(),');
    }
    // Fail-closed fallback: never execute any branch on an unknown or corrupted value.
    buf.writeln("      _ => throw StateError(''),");

    buf.writeln('    };');
    buf.writeln('  }');
  }

  void _writeMaybeWhen(
    StringBuffer buf,
    String publicName,
    List<String> fieldNames,
    Map<String, int> valueMap,
  ) {
    buf.writeln(
        '  /// Partial condition flow with required [orElse] fallback.');
    buf.writeln("  @pragma('vm:prefer-inline')");
    buf.writeln('  T maybeWhen<T>({');
    for (final name in fieldNames) {
      buf.writeln('    T Function()? $name,');
    }
    buf.writeln('    required T Function() orElse,');
    buf.writeln('  }) {');
    buf.writeln('    return switch (rawValue) {');
    for (final name in fieldNames) {
      final hex = '0x${valueMap[name]!.toRadixString(16).toUpperCase()}';
      buf.writeln('      $hex when $name != null => $name(),');
    }
    buf.writeln('      _ => orElse(),');
    buf.writeln('    };');
    buf.writeln('  }');
  }
}
