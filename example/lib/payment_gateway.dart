import 'package:stealth_enum/stealth_enum.dart';

part 'payment_gateway.g.dart';

/// Example of an enum with explicit [@StealthValue] annotations.
///
/// Use this when exact raw integer values must be preserved across renames
/// or matched against external databases and payment API schemas.
@StealthEnum()
enum _PaymentGateway {
  @StealthValue(0x10000001)
  stripe,

  @StealthValue(0x20000002)
  applePay,

  @StealthValue(0x30000003)
  googlePay,
}
