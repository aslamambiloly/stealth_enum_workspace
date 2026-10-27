# stealth_enum_generator Example

To use `stealth_enum_generator`, add it to your `dev_dependencies`:

```yaml
dependencies:
  stealth_enum: ^2.0.0

dev_dependencies:
  build_runner: ^2.4.0
  stealth_enum_generator: ^2.0.0
```

Annotate private enums with `@StealthEnum()`, then run:

```bash
dart run build_runner build
```
