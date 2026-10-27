// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_clearance.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const SecurityClearance._(int rawValue) {
  static const SecurityClearance guest = SecurityClearance._(0x5B7DA15D);
  static const SecurityClearance operator = SecurityClearance._(0x44EE678C);
  static const SecurityClearance admin = SecurityClearance._(0x18C38206);
  static const SecurityClearance superAdmin = SecurityClearance._(0x59EA165F);

  /// Creates a [SecurityClearance] instance from [rawValue] at runtime.
  const factory SecurityClearance.fromRawValue(int rawValue) =
      SecurityClearance._;

  /// Safely parses [rawValue] into a [SecurityClearance], returning `null` if unknown.
  ///
  /// Use this when parsing untrusted external inputs (API responses, JSON,
  /// databases) to prevent runtime exceptions.
  static SecurityClearance? tryFromRawValue(int rawValue) {
    return switch (rawValue) {
      0x5B7DA15D => guest,
      0x44EE678C => operator,
      0x18C38206 => admin,
      0x59EA165F => superAdmin,
      _ => null,
    };
  }

  /// Returns `true` if this instance represents a valid, recognized constant.
  bool get isValid => tryFromRawValue(rawValue) != null;

  /// Serializes this [SecurityClearance] to its integer [rawValue].
  ///
  /// Integer serialization leaks zero string identifiers into compiled AOT binaries.
  int toJson() => rawValue;

  /// Deserializes an integer [rawValue] into a [SecurityClearance], returning `null` on unknown value.
  static SecurityClearance? fromJson(int rawValue) => tryFromRawValue(rawValue);

  /// All recognized constants of [SecurityClearance].
  static const List<SecurityClearance> values = [
    guest,
    operator,
    admin,
    superAdmin,
  ];

  /// Exhaustive pattern matching across all variants.
  ///
  /// Marked with `@pragma('vm:prefer-inline')` to inline
  /// branch dispatch directly at the call site, eliminating helper
  /// symbols from the compiled binary symbol table.
  @pragma('vm:prefer-inline')
  R when<R>({
    required R Function() guest,
    required R Function() operator,
    required R Function() admin,
    required R Function() superAdmin,
  }) {
    return switch (rawValue) {
      0x5B7DA15D => guest(),
      0x44EE678C => operator(),
      0x18C38206 => admin(),
      0x59EA165F => superAdmin(),
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
    R Function()? guest,
    R Function()? operator,
    R Function()? admin,
    R Function()? superAdmin,
    required R Function() orElse,
  }) {
    return switch (rawValue) {
      0x5B7DA15D when guest != null => guest(),
      0x44EE678C when operator != null => operator(),
      0x18C38206 when admin != null => admin(),
      0x59EA165F when superAdmin != null => superAdmin(),
      _ => orElse(),
    };
  }
}
