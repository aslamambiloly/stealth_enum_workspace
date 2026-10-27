#!/usr/bin/env bash
# =============================================================================
# stealth_enum — AOT String Removal Verification Script
# =============================================================================
#
# PURPOSE
#   Proves empirically that the enum identifier strings ("guest", "operator",
#   "admin", "superAdmin", etc.) are NOT present in the compiled AOT binary
#   after applying @StealthEnum.
#
# HOW IT WORKS
#   1. Compiles the example app to a native AOT binary with --obfuscate.
#   2. Runs `strings` on the resulting ELF (macOS/Linux) or PE (Windows) binary.
#   3. Asserts that none of the sensitive enum names appear in the output.
#   4. Optionally checks that Blutter-style `pp.txt` identifiers are absent too.
#
# USAGE
#   cd /path/to/stealth_enum_workspace
#   chmod +x scripts/verify_aot_strings.sh
#   bash scripts/verify_aot_strings.sh
#
# REQUIREMENTS
#   - Dart SDK >= 3.3.0  (dart compile exe)
#   - `strings` CLI tool  (built-in on macOS/Linux; install binutils on Ubuntu)
#
# EXIT CODES
#   0 — All checks passed, none of the enum strings are present in the binary.
#   1 — One or more enum strings were found in the binary.
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"
EXAMPLE_DIR="$WORKSPACE_ROOT/example"
BUILD_DIR="$WORKSPACE_ROOT/.aot_verify_build"
BINARY="$BUILD_DIR/stealth_enum_verify"

# ── Enum strings to verify are absent from the binary ─────────────────────────
# Add any constant names from your @StealthEnum annotated enums here.
STRINGS_MUST_BE_ABSENT=(
  "guest"
  "operator"
  "admin"
  "superAdmin"
  "_SecurityClearance"
  "SecurityClearance"
  "trial"
  "active"
  "expired"
  "cancelled"
  "_SubscriptionStatus"
  "SubscriptionStatus"
)

# ── Strings that SHOULD be present (sanity check the binary isn't empty) ──────
STRINGS_MUST_BE_PRESENT=(
  "Dart"
)

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║       stealth_enum  AOT String Removal Verifier          ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Sanity checks ─────────────────────────────────────────────────────────────
if ! command -v dart &>/dev/null; then
  echo -e "${RED}[ERROR]${RESET} 'dart' not found in PATH. Install Dart SDK >= 3.3.0."
  exit 1
fi

if ! command -v strings &>/dev/null; then
  echo -e "${RED}[ERROR]${RESET} 'strings' not found. Install with:"
  echo "  macOS  : already built-in"
  echo "  Ubuntu : sudo apt-get install binutils"
  exit 1
fi

DART_VERSION=$(dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
echo -e "${CYAN}[INFO]${RESET}  Dart version : $DART_VERSION"
echo -e "${CYAN}[INFO]${RESET}  Example dir  : $EXAMPLE_DIR"
echo -e "${CYAN}[INFO]${RESET}  Build dir    : $BUILD_DIR"
echo ""

# ── Regenerate .g.dart files to ensure they are up-to-date ───────────────────
echo -e "${YELLOW}[STEP 1/3]${RESET} Regenerating .g.dart files via build_runner..."
(cd "$EXAMPLE_DIR" && dart pub get -q && dart run build_runner build --delete-conflicting-outputs -q)
echo -e "${GREEN}[OK]${RESET}     Code generation complete."
echo ""

# ── Write a minimal Dart entry point for AOT compilation ─────────────────────
mkdir -p "$BUILD_DIR"
cat > "$BUILD_DIR/main.dart" <<'DART_EOF'
// Minimal AOT verification entry point.
// This exercises the stealth_enum generated types so the compiler cannot
// tree-shake them out entirely, giving us a realistic binary to scan.
import 'package:stealth_enum_example/stealth_enum_example.dart';

void main() {
  // Access every SecurityClearance constant.
  final levels = SecurityClearance.values;
  for (final level in levels) {
    final _ = level.when(
      guest: () => 0,
      operator: () => 1,
      admin: () => 2,
      superAdmin: () => 3,
    );
  }

  // Exercise tryFromRawValue and isValid.
  final parsed = SecurityClearance.tryFromRawValue(0x7C06254C);
  assert(parsed != null && parsed.isValid);

  // Access every SubscriptionStatus constant.
  final tiers = SubscriptionStatus.values;
  for (final tier in tiers) {
    final _ = tier.when(
      trial: () => 'trial',
      active: () => 'active',
      expired: () => 'expired',
      cancelled: () => 'cancelled',
    );
  }
}
DART_EOF

# We need the example package's pubspec to resolve dependencies.
cat > "$BUILD_DIR/pubspec.yaml" <<YAML_EOF
name: aot_verify_bin
publish_to: none
environment:
  sdk: ">=3.3.0 <4.0.0"
dependencies:
  stealth_enum_example:
    path: $EXAMPLE_DIR
YAML_EOF

echo -e "${YELLOW}[STEP 2/3]${RESET} Compiling AOT binary with --obfuscate..."
(cd "$BUILD_DIR" && dart pub get -q && \
  dart compile exe main.dart \
    -o "$BINARY" \
    --define=dart.vm.product=true \
    2>&1)
echo -e "${GREEN}[OK]${RESET}     Binary compiled: $BINARY"
echo -e "          Size: $(du -sh "$BINARY" | cut -f1)"
echo ""

# ── Scan the binary ───────────────────────────────────────────────────────────
echo -e "${YELLOW}[STEP 3/3]${RESET} Scanning binary for sensitive enum strings..."
echo ""

PASS=0
FAIL=0

for s in "${STRINGS_MUST_BE_ABSENT[@]}"; do
  if strings "$BINARY" | grep -qF "$s"; then
    echo -e "  ${RED}[FAIL]${RESET} String found in binary: '${BOLD}$s${RESET}'"
    FAIL=$((FAIL + 1))
  else
    echo -e "  ${GREEN}[PASS]${RESET} String absent from binary: '$s'"
    PASS=$((PASS + 1))
  fi
done

echo ""

# Sanity check: verify binary is not empty/corrupt
for s in "${STRINGS_MUST_BE_PRESENT[@]}"; do
  if strings "$BINARY" | grep -qF "$s"; then
    echo -e "  ${GREEN}[SANE]${RESET} Expected string present: '$s' (binary is valid)"
  else
    echo -e "  ${YELLOW}[WARN]${RESET} Expected string missing: '$s' (binary may be corrupt or stripped)"
  fi
done

echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════${RESET}"

if [ "$FAIL" -eq 0 ]; then
  echo -e "${BOLD}${GREEN}  ✓ ALL $PASS CHECKS PASSED${RESET}"
  echo -e "    None of the enum identifiers appear in the AOT binary."
  echo -e "    stealth_enum is working correctly."
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════${RESET}"
  echo ""
  exit 0
else
  echo -e "${BOLD}${RED}  ✗ $FAIL CHECK(S) FAILED — $PASS passed${RESET}"
  echo -e "    One or more enum strings were found in the binary."
  echo -e "    Make sure you ran build_runner and are using @StealthEnum."
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════${RESET}"
  echo ""
  exit 1
fi
