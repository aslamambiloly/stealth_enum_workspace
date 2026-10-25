# stealth_enum Example

This example demonstrates how to use `stealth_enum` with `@StealthEnum()`:

1. Annotate a private enum (`_SubscriptionStatus`).
2. Run `dart run build_runner build` (via `stealth_enum_generator`).
3. Use the generated `SubscriptionStatus` extension type with exhaustive `.when()` pattern matching.
