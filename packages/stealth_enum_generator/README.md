# stealth_enum_generator

`build_runner` code generator for [`stealth_enum`](../stealth_enum/README.md).

Add to `dev_dependencies` alongside `build_runner`. See the
[stealth_enum README](../stealth_enum/README.md) for full usage documentation.

```yaml
dev_dependencies:
  stealth_enum_generator: ^0.1.0
  build_runner: ^2.4.0
```

## How it works

`StealthEnumGenerator` extends `GeneratorForAnnotation<StealthEnum>` from
`source_gen`. For each `@StealthEnum`-annotated `EnumElement` it:

1. Validates the annotated element is an `EnumElement`.
2. Determines the public type name (strips leading `_`, or uses `name:` override).
3. Generates **collision-free, deterministic 32-bit hex integers** for each constant using a seeded `Random` (seed = `enumName.hashCode ^ fieldName.hashCode ^ 0xDEADBEEF`, or the user-supplied `seed:`).
4. Emits an `extension type const Foo._(int rawValue)` block with static constants, `values` list, and optionally `when`/`maybeWhen` helpers.
5. The final `when` branch uses a wildcard `_ =>` to avoid `StateError` strings in the binary.

Uses `SharedPartBuilder` so the output participates in the standard `.g.dart`
combining pipeline alongside `json_serializable`, `freezed`, etc.

## License

MIT © stealth_enum contributors
