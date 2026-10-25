// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const SubscriptionStatus._(int rawValue) {
  static const SubscriptionStatus trial = SubscriptionStatus._(0x4B91E20A);
  static const SubscriptionStatus active = SubscriptionStatus._(0x7C104F8B);
  static const SubscriptionStatus expired = SubscriptionStatus._(0x1D55A9C3);
  static const SubscriptionStatus cancelled = SubscriptionStatus._(0x6E82B119);

  /// Creates a [SubscriptionStatus] instance from [rawValue] at runtime.
  const factory SubscriptionStatus.fromRawValue(int rawValue) =
      SubscriptionStatus._;

  static const List<SubscriptionStatus> values = <SubscriptionStatus>[
    trial,
    active,
    expired,
    cancelled,
  ];

  @pragma('vm:prefer-inline')
  T when<T>({
    required T Function() trial,
    required T Function() active,
    required T Function() expired,
    required T Function() cancelled,
  }) {
    return switch (rawValue) {
      0x4B91E20A => trial(),
      0x7C104F8B => active(),
      0x1D55A9C3 => expired(),
      _ => cancelled(),
    };
  }

  @pragma('vm:prefer-inline')
  T maybeWhen<T>({
    T Function()? trial,
    T Function()? active,
    T Function()? expired,
    T Function()? cancelled,
    required T Function() orElse,
  }) {
    return switch (rawValue) {
      0x4B91E20A => trial != null ? trial() : orElse(),
      0x7C104F8B => active != null ? active() : orElse(),
      0x1D55A9C3 => expired != null ? expired() : orElse(),
      0x6E82B119 => cancelled != null ? cancelled() : orElse(),
      _ => orElse(),
    };
  }
}
