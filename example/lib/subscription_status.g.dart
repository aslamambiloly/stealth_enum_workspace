// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_status.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const SubscriptionStatus._(int rawValue) {
  static const SubscriptionStatus trial = SubscriptionStatus._(0x4C9A8C34);
  static const SubscriptionStatus active = SubscriptionStatus._(0x2F31E5AE);
  static const SubscriptionStatus expired = SubscriptionStatus._(0x414FE989);
  static const SubscriptionStatus cancelled = SubscriptionStatus._(0x25D2B67F);

  /// Creates a [SubscriptionStatus] instance from [rawValue] at runtime.
  const factory SubscriptionStatus.fromRawValue(int rawValue) =
      SubscriptionStatus._;

  static const List<SubscriptionStatus> values = <SubscriptionStatus>[
    trial,
    active,
    expired,
    cancelled,
  ];

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
      0x4C9A8C34 => trial(),
      0x2F31E5AE => active(),
      0x414FE989 => expired(),
      _ => cancelled(),
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
      0x4C9A8C34 when trial != null => trial(),
      0x2F31E5AE when active != null => active(),
      0x414FE989 when expired != null => expired(),
      0x25D2B67F when cancelled != null => cancelled(),
      _ => orElse(),
    };
  }
}
