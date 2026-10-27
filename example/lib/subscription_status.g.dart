// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_status.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const SubscriptionStatus._(int rawValue) {
  static const SubscriptionStatus trial = SubscriptionStatus._(0x67F266C7);
  static const SubscriptionStatus active = SubscriptionStatus._(0x13F0063B);
  static const SubscriptionStatus expired = SubscriptionStatus._(0x690B2926);
  static const SubscriptionStatus cancelled = SubscriptionStatus._(0x5ED86708);

  /// Creates a [SubscriptionStatus] instance from [rawValue] at runtime.
  const factory SubscriptionStatus.fromRawValue(int rawValue) =
      SubscriptionStatus._;

  /// Safely parses [rawValue] into a [SubscriptionStatus], returning `null` if unknown.
  ///
  /// Use this when parsing untrusted external inputs (API responses, JSON,
  /// databases) to prevent runtime exceptions.
  static SubscriptionStatus? tryFromRawValue(int rawValue) {
    return switch (rawValue) {
      0x67F266C7 => trial,
      0x13F0063B => active,
      0x690B2926 => expired,
      0x5ED86708 => cancelled,
      _ => null,
    };
  }

  static const List<SubscriptionStatus> values = <SubscriptionStatus>[
    trial,
    active,
    expired,
    cancelled,
  ];

  /// Whether this instance holds a recognized constant value.
  bool get isValid => SubscriptionStatus.values.contains(this);

  /// Serializes this [SubscriptionStatus] to its raw integer value for JSON/storage.
  ///
  /// Operates entirely on raw integers with zero string overhead in compiled binaries.
  int toJson() => rawValue;

  /// Deserializes a [SubscriptionStatus] from a raw JSON integer.
  ///
  /// Returns `null` if [rawValue] does not match any recognized variant.
  static SubscriptionStatus? fromJson(int rawValue) =>
      tryFromRawValue(rawValue);

  /// Exhaustive compile-time condition flow.
  ///
  /// Every case must be handled — adding a new value to the source enum
  /// breaks compilation here until handled. Inlined by AOT into raw integer
  /// comparisons; the method itself is stripped from the binary.
  @pragma('vm:prefer-inline')
  T when<T>({
    required T Function() trial,
    required T Function() active,
    required T Function() expired,
    required T Function() cancelled,
  }) {
    return switch (rawValue) {
      0x67F266C7 => trial(),
      0x13F0063B => active(),
      0x690B2926 => expired(),
      0x5ED86708 => cancelled(),
      _ => throw StateError(''),
    };
  }

  /// Partial condition flow with required [orElse] fallback.
  @pragma('vm:prefer-inline')
  T maybeWhen<T>({
    T Function()? trial,
    T Function()? active,
    T Function()? expired,
    T Function()? cancelled,
    required T Function() orElse,
  }) {
    return switch (rawValue) {
      0x67F266C7 when trial != null => trial(),
      0x13F0063B when active != null => active(),
      0x690B2926 when expired != null => expired(),
      0x5ED86708 when cancelled != null => cancelled(),
      _ => orElse(),
    };
  }
}
