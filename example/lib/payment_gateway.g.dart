// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_gateway.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const PaymentGateway._(int rawValue) {
  static const PaymentGateway stripe = PaymentGateway._(0x10000001);
  static const PaymentGateway applePay = PaymentGateway._(0x20000002);
  static const PaymentGateway googlePay = PaymentGateway._(0x30000003);

  /// Creates a [PaymentGateway] instance from [rawValue] at runtime.
  const factory PaymentGateway.fromRawValue(int rawValue) = PaymentGateway._;

  /// Safely parses [rawValue] into a [PaymentGateway], returning `null` if unknown.
  ///
  /// Use this when parsing untrusted external inputs (API responses, JSON,
  /// databases) to prevent runtime exceptions.
  static PaymentGateway? tryFromRawValue(int rawValue) {
    return switch (rawValue) {
      0x10000001 => stripe,
      0x20000002 => applePay,
      0x30000003 => googlePay,
      _ => null,
    };
  }

  static const List<PaymentGateway> values = <PaymentGateway>[
    stripe,
    applePay,
    googlePay,
  ];

  /// Whether this instance holds a recognized constant value.
  bool get isValid => PaymentGateway.values.contains(this);

  /// Serializes this [PaymentGateway] to its raw integer value for JSON/storage.
  ///
  /// Operates entirely on raw integers with zero string overhead in compiled binaries.
  int toJson() => rawValue;

  /// Deserializes a [PaymentGateway] from a raw JSON integer.
  ///
  /// Returns `null` if [rawValue] does not match any recognized variant.
  static PaymentGateway? fromJson(int rawValue) => tryFromRawValue(rawValue);

  /// Exhaustive compile-time condition flow.
  ///
  /// Every case must be handled — adding a new value to the source enum
  /// breaks compilation here until handled. Inlined by AOT into raw integer
  /// comparisons; the method itself is stripped from the binary.
  @pragma('vm:prefer-inline')
  T when<T>({
    required T Function() stripe,
    required T Function() applePay,
    required T Function() googlePay,
  }) {
    return switch (rawValue) {
      0x10000001 => stripe(),
      0x20000002 => applePay(),
      0x30000003 => googlePay(),
      _ => throw StateError(''),
    };
  }

  /// Partial condition flow with required [orElse] fallback.
  @pragma('vm:prefer-inline')
  T maybeWhen<T>({
    T Function()? stripe,
    T Function()? applePay,
    T Function()? googlePay,
    required T Function() orElse,
  }) {
    return switch (rawValue) {
      0x10000001 when stripe != null => stripe(),
      0x20000002 when applePay != null => applePay(),
      0x30000003 when googlePay != null => googlePay(),
      _ => orElse(),
    };
  }
}
