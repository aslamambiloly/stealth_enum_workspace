// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_clearance.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const SecurityClearance._(int rawValue) {
  static const SecurityClearance guest = SecurityClearance._(0x15ACBCE3);
  static const SecurityClearance operator = SecurityClearance._(0x502489ED);
  static const SecurityClearance admin = SecurityClearance._(0x1F385104);
  static const SecurityClearance superAdmin = SecurityClearance._(0x181FC89B);

  /// Creates a [SecurityClearance] instance from [rawValue] at runtime.
  const factory SecurityClearance.fromRawValue(int rawValue) =
      SecurityClearance._;

  /// Safely parses [rawValue] into a [SecurityClearance], returning `null` if unknown.
  ///
  /// Use this when parsing untrusted external inputs (API responses, JSON,
  /// databases) to prevent runtime exceptions.
  static SecurityClearance? tryFromRawValue(int rawValue) {
    return switch (rawValue) {
      0x15ACBCE3 => guest,
      0x502489ED => operator,
      0x1F385104 => admin,
      0x181FC89B => superAdmin,
      _ => null,
    };
  }

  static const List<SecurityClearance> values = <SecurityClearance>[
    guest,
    operator,
    admin,
    superAdmin,
  ];

  /// Whether this instance holds a recognized constant value.
  bool get isValid => SecurityClearance.values.contains(this);

  /// Serializes this [SecurityClearance] to its raw integer value for JSON/storage.
  ///
  /// Operates entirely on raw integers with zero string overhead in compiled binaries.
  int toJson() => rawValue;

  /// Deserializes a [SecurityClearance] from a raw JSON integer.
  ///
  /// Returns `null` if [rawValue] does not match any recognized variant.
  static SecurityClearance? fromJson(int rawValue) => tryFromRawValue(rawValue);

  /// Exhaustive compile-time condition flow.
  ///
  /// Every case must be handled — adding a new value to the source enum
  /// breaks compilation here until handled. Inlined by AOT into raw integer
  /// comparisons; the method itself is stripped from the binary.
  @pragma('vm:prefer-inline')
  T when<T>({
    required T Function() guest,
    required T Function() operator,
    required T Function() admin,
    required T Function() superAdmin,
  }) {
    return switch (rawValue) {
      0x15ACBCE3 => guest(),
      0x502489ED => operator(),
      0x1F385104 => admin(),
      0x181FC89B => superAdmin(),
      _ => throw StateError(''),
    };
  }

  /// Partial condition flow with required [orElse] fallback.
  @pragma('vm:prefer-inline')
  T maybeWhen<T>({
    T Function()? guest,
    T Function()? operator,
    T Function()? admin,
    T Function()? superAdmin,
    required T Function() orElse,
  }) {
    return switch (rawValue) {
      0x15ACBCE3 when guest != null => guest(),
      0x502489ED when operator != null => operator(),
      0x1F385104 when admin != null => admin(),
      0x181FC89B when superAdmin != null => superAdmin(),
      _ => orElse(),
    };
  }
}
