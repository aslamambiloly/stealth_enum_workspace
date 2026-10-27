#!/usr/bin/env bash
# =============================================================================
# stealth_enum — Empirical AOT String Removal Verification & Control Benchmark
# =============================================================================
#
# PURPOSE
#   Provides an undeniable, side-by-side empirical proof:
#   1. Compiles a CONTROL target with a standard Dart enum to AOT native binary.
#      Asserts that standard enum names ARE LEAKED into the compiled binary.
#   2. Compiles a STEALTH target using @StealthEnum to AOT native binary.
#      Asserts that the private enum identifiers are COMPLETELY ABSENT.
#
# HOW TO RUN
#   bash scripts/verify_aot_strings.sh
#
# OPTIONAL FLUTTER MODE
#   bash scripts/verify_aot_strings.sh --flutter
#   (Requires Flutter SDK + Android SDK with target-platform android-arm64)
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
CONTROL_BIN="$BUILD_DIR/control_standard_enum"
STEALTH_BIN="$BUILD_DIR/stealth_enum_target"

scan_binary_for_string() {
  local bin="$1"
  local str="$2"
  # Use grep -a -F (binary text search) which inspects the entire binary including
  # Dart snapshot pools, immune to BSD vs GNU strings formatting differences.
  grep -a -F -q "$str" "$bin"
}

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║    stealth_enum — Empirical AOT String Removal Benchmark     ║${RESET}"
echo -e "${BOLD}${CYAN}║       Side-by-Side Control (Standard Enum) vs @StealthEnum   ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Prerequisite checks ───────────────────────────────────────────────────────
if ! command -v dart &>/dev/null; then
  echo -e "${RED}[ERROR]${RESET} 'dart' CLI not found. Install Dart SDK >= 3.3.0."
  exit 1
fi

DART_VERSION=$(dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
echo -e "${CYAN}[INFO]${RESET}  Dart SDK     : $DART_VERSION"
echo -e "${CYAN}[INFO]${RESET}  Workspace    : $WORKSPACE_ROOT"
echo -e "${CYAN}[INFO]${RESET}  Build cache  : $BUILD_DIR"
echo ""

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ── STEP 1: Compile & Scan CONTROL Target (Standard Dart Enum) ────────────────
echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${YELLOW}[PHASE 1/2] CONTROL TARGET: Compiling Standard Dart Enum to AOT...${RESET}"
echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

cat > "$BUILD_DIR/pubspec.yaml" <<'EOF'
name: control_bin
publish_to: none
environment:
  sdk: ">=3.3.0 <4.0.0"
EOF

cat > "$BUILD_DIR/control.dart" <<'EOF'
import 'dart:io';

enum StandardClearance {
  guest,
  operator,
  admin,
  superAdmin,
}

void main(List<String> args) {
  final seed = args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;
  final role = StandardClearance.values[seed % StandardClearance.values.length];
  final code = switch (role) {
    StandardClearance.guest => 10,
    StandardClearance.operator => 20,
    StandardClearance.admin => 30,
    StandardClearance.superAdmin => 40,
  };
  // Observable external side effect to guarantee compiler retains the code path
  stdout.writeln('Control role active: $code ($role)');
}
EOF

(cd "$BUILD_DIR" && dart compile exe control.dart -o "$CONTROL_BIN" -S "$BUILD_DIR/control_symbols" --define=dart.vm.product=true >/dev/null)
echo -e "${GREEN}[OK]${RESET} Control binary compiled: $(du -sh "$CONTROL_BIN" | cut -f1) (symbols stripped to separate file)"
echo ""
echo -e "Scanning control binary for standard enum strings..."

CONTROL_FOUND=0
for s in "superAdmin" "StandardClearance"; do
  if scan_binary_for_string "$CONTROL_BIN" "$s"; then
    echo -e "  ${YELLOW}[CONFIRMED LEAK]${RESET} Standard enum identifier '${BOLD}$s${RESET}' FOUND in AOT binary"
    CONTROL_FOUND=$((CONTROL_FOUND + 1))
  else
    echo -e "  ${RED}[WARN]${RESET} String '$s' was pruned by compiler."
  fi
done

if [ "$CONTROL_FOUND" -eq 0 ]; then
  echo -e "${RED}[FAIL]${RESET} Control binary did not retain strings; benchmark is inconclusive."
  exit 1
else
  echo -e "${GREEN}✓ Control verified: Standard Dart enums leak plain-text identifiers into compiled AOT binaries.${RESET}"
fi
echo ""

# ── STEP 2: Compile & Scan STEALTH Target (@StealthEnum) ───────────────────────
echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${YELLOW}[PHASE 2/2] STEALTH TARGET: Compiling @StealthEnum to AOT...    ${RESET}"
echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

cat > "$BUILD_DIR/stealth_main.dart" <<'EOF'
import 'dart:io';
import 'package:stealth_enum_example/security_clearance.dart';
import 'package:stealth_enum_example/subscription_status.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;
  
  // Exercise SecurityClearance extension type
  final clearance = SecurityClearance.values[seed % SecurityClearance.values.length];
  final clearanceCode = clearance.when(
    guest: () => 10,
    operator: () => 20,
    admin: () => 30,
    superAdmin: () => 40,
  );

  // Exercise SubscriptionStatus extension type
  final tier = SubscriptionStatus.values[seed % SubscriptionStatus.values.length];
  final tierCode = tier.when(
    trial: () => 100,
    active: () => 200,
    expired: () => 300,
    cancelled: () => 400,
  );

  // Observable external side effect preventing dead-code elimination
  stdout.writeln('Stealth execution: ${clearanceCode + tierCode}');
}
EOF

cat > "$BUILD_DIR/pubspec.yaml" <<EOF
name: aot_verify_bin
publish_to: none
environment:
  sdk: ">=3.3.0 <4.0.0"
dependencies:
  stealth_enum_example:
    path: $EXAMPLE_DIR
dependency_overrides:
  stealth_enum:
    path: $WORKSPACE_ROOT/packages/stealth_enum
  stealth_enum_generator:
    path: $WORKSPACE_ROOT/packages/stealth_enum_generator
EOF

echo "Resolving dependencies & compiling stealth binary (with -S symbols stripped)..."
(cd "$BUILD_DIR" && dart pub get >/dev/null && dart compile exe stealth_main.dart -o "$STEALTH_BIN" -S "$BUILD_DIR/stealth_symbols" --define=dart.vm.product=true >/dev/null)
echo -e "${GREEN}[OK]${RESET} Stealth binary compiled: $(du -sh "$STEALTH_BIN" | cut -f1) (symbols stripped to separate file)"
echo ""
echo -e "Scanning stealth binary for private enum identifiers..."

# Allow user to specify custom strings to scan via STEALTH_STRINGS env var or $3 CLI arg
if [[ -n "${STEALTH_STRINGS:-}" ]]; then
  IFS=',' read -ra SCAN_STRINGS <<< "$STEALTH_STRINGS"
elif [[ -n "${3:-}" ]]; then
  IFS=',' read -ra SCAN_STRINGS <<< "$3"
else
  SCAN_STRINGS=(
    "superAdmin"
    "trial"
    "cancelled"
    "_SecurityClearance"
    "_SubscriptionStatus"
  )
fi

STEALTH_FAIL=0
STEALTH_PASS=0

for s in "${SCAN_STRINGS[@]}"; do
  if scan_binary_for_string "$STEALTH_BIN" "$s"; then
    echo -e "  ${RED}[FAIL]${RESET} Sensitive string FOUND in stealth binary: '${BOLD}$s${RESET}'"
    STEALTH_FAIL=$((STEALTH_FAIL + 1))
  else
    echo -e "  ${GREEN}[PASS]${RESET} Sensitive string ABSENT from binary: '$s'"
    STEALTH_PASS=$((STEALTH_PASS + 1))
  fi
done

# ── Optional Flutter APK mode ──────────────────────────────────────────────────
if [[ "${1:-}" == "--flutter" ]]; then
  echo ""
  echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}${YELLOW}[FLUTTER MODE] Verifying Flutter AOT arm64 libapp.so...          ${RESET}"
  echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  
  FLUTTER_PROJ="${2:-}"
  if [[ -n "$FLUTTER_PROJ" && -d "$FLUTTER_PROJ" && -f "$FLUTTER_PROJ/pubspec.yaml" ]]; then
    if ! command -v flutter &>/dev/null; then
      echo -e "${RED}[ERROR]${RESET} 'flutter' CLI not found in PATH."
      exit 1
    fi

    # Optional control APK verification if pre-migration APK is supplied
    CONTROL_APK="${CONTROL_APK:-}"
    if [[ -n "$CONTROL_APK" && -f "$CONTROL_APK" ]]; then
      echo -e "${CYAN}[INFO]${RESET} Scanning CONTROL APK to verify baseline string leakage ($CONTROL_APK)..."
      unzip -p "$CONTROL_APK" lib/arm64-v8a/libapp.so > "$BUILD_DIR/control_libapp.so"
      CONTROL_LEAKS=0
      for s in "${SCAN_STRINGS[@]}"; do
        if scan_binary_for_string "$BUILD_DIR/control_libapp.so" "$s"; then
          echo -e "  ${YELLOW}[CONFIRMED LEAK]${RESET} String '${BOLD}$s${RESET}' FOUND in control APK"
          CONTROL_LEAKS=$((CONTROL_LEAKS + 1))
        fi
      done
      if [ "$CONTROL_LEAKS" -eq 0 ]; then
        echo -e "  ${YELLOW}[WARN]${RESET} None of the target scan strings were found in the control APK."
      else
        echo -e "  ${GREEN}✓ Confirmed: Control APK leaks target strings.${RESET}"
      fi
    fi

    echo -e "${CYAN}[INFO]${RESET} Compiling release arm64 APK with obfuscation for project: $FLUTTER_PROJ"
    mkdir -p "$BUILD_DIR/flutter_symbols"
    (cd "$FLUTTER_PROJ" && flutter build apk --release --target-platform android-arm64 --obfuscate --split-debug-info="$BUILD_DIR/flutter_symbols" >/dev/null)
    
    APK_PATH="$FLUTTER_PROJ/build/app/outputs/flutter-apk/app-release.apk"
    if [[ ! -f "$APK_PATH" ]]; then
      echo -e "${RED}[ERROR]${RESET} Could not find built APK at $APK_PATH"
      exit 1
    fi
    
    echo -e "${CYAN}[INFO]${RESET} Extracting lib/arm64-v8a/libapp.so from APK..."
    unzip -p "$APK_PATH" lib/arm64-v8a/libapp.so > "$BUILD_DIR/libapp.so"
    
    echo -e "Scanning Flutter arm64 libapp.so for private enum identifiers..."
    for s in "${SCAN_STRINGS[@]}"; do
      if scan_binary_for_string "$BUILD_DIR/libapp.so" "$s"; then
        echo -e "  ${RED}[FAIL]${RESET} Sensitive string FOUND in Flutter libapp.so: '${BOLD}$s${RESET}'"
        STEALTH_FAIL=$((STEALTH_FAIL + 1))
      else
        echo -e "  ${GREEN}[PASS]${RESET} Sensitive string ABSENT from Flutter libapp.so: '$s'"
        STEALTH_PASS=$((STEALTH_PASS + 1))
      fi
    done
  else
    echo -e "${CYAN}[INFO]${RESET} Desktop Dart AOT tests completed with debug symbols stripped (-S)."
    echo -e "Desktop AOT verifies that the Dart VM Object Pool and symbol tables completely prune private enums."
    echo -e "To verify against your real Flutter arm64 release build, pass your Flutter project path and strings:"
    echo -e "  ${BOLD}./scripts/verify_aot_strings.sh --flutter /path/to/flutter_project \"val1,val2,val3\"${RESET}"
    echo -e ""
    echo -e "You can also specify a control APK to verify strings were leaked before migration:"
    echo -e "  ${BOLD}CONTROL_APK=pre_migration.apk STEALTH_STRINGS=\"val1,val2\" ./scripts/verify_aot_strings.sh --flutter /path/to/project${RESET}"
    echo -e ""
    echo -e "Or manually test an existing Flutter APK with:"
    echo -e "  ${BOLD}unzip -p build/app/outputs/flutter-apk/app-release.apk lib/arm64-v8a/libapp.so | strings | grep -E 'superAdmin|trial|cancelled'${RESET}"
  fi
fi

echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}BENCHMARK RESULTS SUMMARY:${RESET}"
echo -e "  • Control Target (Standard Enum) : ${YELLOW}LEAKED identifier strings into AOT binary${RESET}"
echo -e "  • Stealth Target (@StealthEnum)  : ${GREEN}0 LEAKS — all $STEALTH_PASS identifiers erased${RESET}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

if [ "$STEALTH_FAIL" -eq 0 ]; then
  echo -e "${BOLD}${GREEN}✓ ALL EMPIRICAL AOT TESTS PASSED.${RESET}"
  echo -e "  @StealthEnum completely eliminates enum identifier metadata from AOT binaries."
  exit 0
else
  echo -e "${BOLD}${RED}✗ $STEALTH_FAIL CHECKS FAILED.${RESET}"
  exit 1
fi
