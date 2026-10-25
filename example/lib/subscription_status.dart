import 'package:stealth_enum/stealth_enum.dart';

part 'subscription_status.g.dart';

/// A second example demonstrating the deterministic seed option.
/// With a fixed seed the generator always produces the same hex constants
/// so CI builds never produce git-dirty generated files.
@StealthEnum(seed: 42, generateWhen: true)
enum _SubscriptionStatus {
  trial,
  active,
  expired,
  cancelled,
}
