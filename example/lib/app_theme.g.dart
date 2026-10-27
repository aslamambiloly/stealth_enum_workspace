// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const AppTheme._(int rawValue) {
  static const AppTheme light = AppTheme._(0x2A2A80DD);
  static const AppTheme dark = AppTheme._(0x1017DFC2);
  static const AppTheme system = AppTheme._(0x4D227268);

  /// Creates a [AppTheme] instance from [rawValue] at runtime.
  const factory AppTheme.fromRawValue(int rawValue) = AppTheme._;

  /// Safely parses [rawValue] into a [AppTheme], returning `null` if unknown.
  ///
  /// Use this when parsing untrusted external inputs (API responses, JSON,
  /// databases) to prevent runtime exceptions.
  static AppTheme? tryFromRawValue(int rawValue) {
    return switch (rawValue) {
      0x2A2A80DD => light,
      0x1017DFC2 => dark,
      0x4D227268 => system,
      _ => null,
    };
  }

  /// Returns `true` if this instance represents a valid, recognized constant.
  bool get isValid => tryFromRawValue(rawValue) != null;

  /// Serializes this [AppTheme] to its integer [rawValue].
  ///
  /// Integer serialization leaks zero string identifiers into compiled AOT binaries.
  int toJson() => rawValue;

  /// Deserializes an integer [rawValue] into a [AppTheme], returning `null` on unknown value.
  static AppTheme? fromJson(int rawValue) => tryFromRawValue(rawValue);

  /// All recognized constants of [AppTheme].
  static const List<AppTheme> values = [
    light,
    dark,
    system,
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Label Ergonomics (generateLabel: true)
  //
  // [SECURITY WARNING]
  // These helpers emit human-readable string literals into the generated file.
  // These strings WILL be retained in the compiled AOT binary (libapp.so).
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the original enum constant name as a string (equivalent to `enum.name`).
  ///
  /// **Note**: This emits plain-text string literals into the compiled binary.
  String get label => switch (this) {
        light => 'light',
        dark => 'dark',
        system => 'system',
        _ => 'unknown',
      };

  /// Looks up a [AppTheme] by its [label] string (equivalent to `values.byName`).
  ///
  /// Returns `null` if no variant matches the given label.
  static AppTheme? byLabel(String label) => switch (label) {
        'light' => light,
        'dark' => dark,
        'system' => system,
        _ => null,
      };

  /// Exhaustive pattern matching across all variants.
  ///
  /// Marked with `@pragma('vm:prefer-inline')` to inline
  /// branch dispatch directly at the call site, eliminating helper
  /// symbols from the compiled binary symbol table.
  @pragma('vm:prefer-inline')
  R when<R>({
    required R Function() light,
    required R Function() dark,
    required R Function() system,
  }) {
    return switch (rawValue) {
      0x2A2A80DD => light(),
      0x1017DFC2 => dark(),
      0x4D227268 => system(),
      _ => throw StateError(''),
    };
  }

  /// Partial pattern matching with a required [orElse] fallback.
  ///
  /// Marked with `@pragma('vm:prefer-inline')` to inline
  /// branch dispatch directly at the call site, eliminating helper
  /// symbols from the compiled binary symbol table.
  @pragma('vm:prefer-inline')
  R maybeWhen<R>({
    R Function()? light,
    R Function()? dark,
    R Function()? system,
    required R Function() orElse,
  }) {
    return switch (rawValue) {
      0x2A2A80DD when light != null => light(),
      0x1017DFC2 when dark != null => dark(),
      0x4D227268 when system != null => system(),
      _ => orElse(),
    };
  }
}
