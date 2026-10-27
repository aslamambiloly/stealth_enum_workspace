// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_status.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const SubscriptionStatus._(int rawValue) {
  static const SubscriptionStatus trial = SubscriptionStatus._(0x42DA8D3E);
  static const SubscriptionStatus active = SubscriptionStatus._(0x7C67AA27);
  static const SubscriptionStatus expired = SubscriptionStatus._(0x353C2DFD);
  static const SubscriptionStatus cancelled = SubscriptionStatus._(0x6CCA1684);

  /// Creates a [SubscriptionStatus] instance from [rawValue] at runtime.
  const factory SubscriptionStatus.fromRawValue(int rawValue) =
      SubscriptionStatus._;

  /// Safely parses [rawValue] into a [SubscriptionStatus], returning `null` if unknown.
  ///
  /// Use this when parsing untrusted external inputs (API responses, JSON,
  /// databases) to prevent runtime exceptions.
  static SubscriptionStatus? tryFromRawValue(int rawValue) {
    return switch (rawValue) {
      0x42DA8D3E => trial,
      0x7C67AA27 => active,
      0x353C2DFD => expired,
      0x6CCA1684 => cancelled,
      _ => null,
    };
  }

  /// Returns `true` if this instance represents a valid, recognized constant.
  bool get isValid => tryFromRawValue(rawValue) != null;

  /// Serializes this [SubscriptionStatus] to its integer [rawValue].
  ///
  /// Integer serialization leaks zero string identifiers into compiled AOT binaries.
  int toJson() => rawValue;

  /// Deserializes an integer [rawValue] into a [SubscriptionStatus], returning `null` on unknown value.
  static SubscriptionStatus? fromJson(int rawValue) =>
      tryFromRawValue(rawValue);

  /// All recognized constants of [SubscriptionStatus].
  static const List<SubscriptionStatus> values = [
    trial,
    active,
    expired,
    cancelled,
  ];

  /// Exhaustive pattern matching across all variants.
  ///
  /// Marked with `@pragma('vm:prefer-inline')` to inline
  /// branch dispatch directly at the call site, eliminating helper
  /// symbols from the compiled binary symbol table.
  @pragma('vm:prefer-inline')
  R when<R>({
    required R Function() trial,
    required R Function() active,
    required R Function() expired,
    required R Function() cancelled,
  }) {
    return switch (rawValue) {
      0x42DA8D3E => trial(),
      0x7C67AA27 => active(),
      0x353C2DFD => expired(),
      0x6CCA1684 => cancelled(),
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
    R Function()? trial,
    R Function()? active,
    R Function()? expired,
    R Function()? cancelled,
    required R Function() orElse,
  }) {
    return switch (rawValue) {
      0x42DA8D3E when trial != null => trial(),
      0x7C67AA27 when active != null => active(),
      0x353C2DFD when expired != null => expired(),
      0x6CCA1684 when cancelled != null => cancelled(),
      _ => orElse(),
    };
  }
}
