// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const AppTheme._(int rawValue) {
  static const AppTheme light = AppTheme._(0x50D0DC69);
  static const AppTheme dark = AppTheme._(0x6C3AAB03);
  static const AppTheme system = AppTheme._(0x7B53C8DA);

  /// Creates a [AppTheme] instance from [rawValue] at runtime.
  const factory AppTheme.fromRawValue(int rawValue) = AppTheme._;

  /// Safely parses [rawValue] into a [AppTheme], returning `null` if unknown.
  ///
  /// Use this when parsing untrusted external inputs (API responses, JSON,
  /// databases) to prevent runtime exceptions.
  static AppTheme? tryFromRawValue(int rawValue) {
    return switch (rawValue) {
      0x50D0DC69 => light,
      0x6C3AAB03 => dark,
      0x7B53C8DA => system,
      _ => null,
    };
  }

  static const List<AppTheme> values = <AppTheme>[
    light,
    dark,
    system,
  ];

  /// Whether this instance holds a recognized constant value.
  bool get isValid => AppTheme.values.contains(this);

  /// Serializes this [AppTheme] to its raw integer value for JSON/storage.
  ///
  /// Operates entirely on raw integers with zero string overhead in compiled binaries.
  int toJson() => rawValue;

  /// Deserializes a [AppTheme] from a raw JSON integer.
  ///
  /// Returns `null` if [rawValue] does not match any recognized variant.
  static AppTheme? fromJson(int rawValue) => tryFromRawValue(rawValue);

  // ── Label helpers (generateLabel: true) ─────────────────────────
  //
  // NOTE: These helpers emit plain-text string literals into the compiled
  // binary. The private source enum strings are fully erased, but these
  // generated labels re-introduce readable names. Use only when you need
  // display labels or logging and you understand the security trade-off.

  /// The human-readable label for this variant (e.g. `'admin'`).
  ///
  /// Equivalent to `.name` on a standard Dart `enum`.
  /// **Note**: This string will be present in AOT binaries (see `generateLabel`).
  String get label => switch (rawValue) {
        0x50D0DC69 => 'light',
        0x6C3AAB03 => 'dark',
        0x7B53C8DA => 'system',
        _ => 'unknown($rawValue)',
      };

  /// Looks up a [AppTheme] variant by its [label] string.
  ///
  /// Returns `null` if [label] does not match any known variant.
  /// Equivalent to `AppTheme.byName(label)` on a standard `enum`.
  static AppTheme? byLabel(String label) {
    return switch (label) {
      'light' => light,
      'dark' => dark,
      'system' => system,
      _ => null,
    };
  }

  /// Exhaustive compile-time condition flow.
  ///
  /// Every case must be handled — adding a new value to the source enum
  /// breaks compilation here until handled. Inlined by AOT into raw integer
  /// comparisons; the method itself is stripped from the binary.
  @pragma('vm:prefer-inline')
  T when<T>({
    required T Function() light,
    required T Function() dark,
    required T Function() system,
  }) {
    return switch (rawValue) {
      0x50D0DC69 => light(),
      0x6C3AAB03 => dark(),
      0x7B53C8DA => system(),
      _ => throw StateError(''),
    };
  }

  /// Partial condition flow with required [orElse] fallback.
  @pragma('vm:prefer-inline')
  T maybeWhen<T>({
    T Function()? light,
    T Function()? dark,
    T Function()? system,
    required T Function() orElse,
  }) {
    return switch (rawValue) {
      0x50D0DC69 when light != null => light(),
      0x6C3AAB03 when dark != null => dark(),
      0x7B53C8DA when system != null => system(),
      _ => orElse(),
    };
  }
}
