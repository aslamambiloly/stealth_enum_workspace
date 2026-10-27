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

  /// Returns `true` if this instance represents a valid, recognized constant.
  bool get isValid => tryFromRawValue(rawValue) != null;

  /// Serializes this [PaymentGateway] to its integer [rawValue].
  ///
  /// Integer serialization leaks zero string identifiers into compiled AOT binaries.
  int toJson() => rawValue;

  /// Deserializes an integer [rawValue] into a [PaymentGateway], returning `null` on unknown value.
  static PaymentGateway? fromJson(int rawValue) => tryFromRawValue(rawValue);

  /// All recognized constants of [PaymentGateway].
  static const List<PaymentGateway> values = [
    stripe,
    applePay,
    googlePay,
  ];

  /// Exhaustive pattern matching across all variants.
  ///
  /// Marked with `@pragma('vm:prefer-inline')` to inline
  /// branch dispatch directly at the call site, eliminating helper
  /// symbols from the compiled binary symbol table.
  @pragma('vm:prefer-inline')
  R when<R>({
    required R Function() stripe,
    required R Function() applePay,
    required R Function() googlePay,
  }) {
    return switch (rawValue) {
      0x10000001 => stripe(),
      0x20000002 => applePay(),
      0x30000003 => googlePay(),
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
    R Function()? stripe,
    R Function()? applePay,
    R Function()? googlePay,
    required R Function() orElse,
  }) {
    return switch (rawValue) {
      0x10000001 when stripe != null => stripe(),
      0x20000002 when applePay != null => applePay(),
      0x30000003 when googlePay != null => googlePay(),
      _ => orElse(),
    };
  }
}
