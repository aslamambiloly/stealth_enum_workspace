// ignore_for_file: unused_element, unused_field

import 'package:stealth_enum/stealth_enum.dart';

part 'example.g.dart';

/// 1. Define a private enum annotated with `@StealthEnum()`.
@StealthEnum()
enum _SubscriptionStatus {
  trial,
  active,
  expired,
  cancelled,
}

/// 2. Use the generated `SubscriptionStatus` extension type with zero runtime cost.
void main() {
  const status = SubscriptionStatus.active;

  // Exhaustive pattern matching (fully inlined at compile time):
  final message = status.when(
    trial: () => 'Enjoy your free trial!',
    active: () => 'Welcome back, active subscriber!',
    expired: () => 'Your subscription has expired.',
    cancelled: () => 'We hope to see you again.',
  );
  print(message);

  // Partial matching with required orElse fallback:
  final isPaid = status.maybeWhen(
    active: () => true,
    orElse: () => false,
  );
  print('Is paid user: $isPaid');

  // Direct integer representation check (zero heap allocation):
  print('Raw value: 0x${status.rawValue.toRadixString(16).toUpperCase()}');
}
