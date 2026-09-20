#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$ROOT/nix-software-center"
LOG="$ROOT/acceptance.log"
CATALOG="$ROOT/module-catalog-smoke.json"

exec > >(tee "$LOG") 2>&1

echo "=== NSC Generated Modules Codespaces Acceptance ==="
date -u
echo

if [[ ! -d "$SOURCE/.git" ]]; then
  bash "$ROOT/BOOTSTRAP.sh"
fi

cd "$SOURCE"

echo "=== Versions ==="
nix --version
git rev-parse HEAD
echo

echo "=== Patch proof ==="
git apply --reverse --check "$ROOT/nix-software-center-generated-modules-ui.patch"
echo "PATCH_APPLIED=PASS"
echo

echo "=== Git flake visibility proof ==="
# Nix excludes untracked files from Git-backed flake sources. The patch adds
# new Rust modules, so stage the patched tree before any Nix evaluation/build.
git add -A
git ls-files --error-unmatch src/parse/modules.rs
git ls-files --error-unmatch src/ui/modulepage.rs
git ls-files --error-unmatch src/bin/nsc-module-index.rs
echo "NEW_MODULES_TRACKED=PASS"
echo

echo "=== Nix flake evaluation ==="
nix flake show
echo

echo "=== Authoritative Nix build ==="
nix build -L
echo

echo "=== Rust formatting ==="
nix develop -c cargo fmt --check
echo

echo "=== Module compiler tests ==="
nix develop -c cargo test parse::modules::tests
nix develop -c cargo test parse::modules::managed_tests
echo

echo "=== Helper tests ==="
nix develop -c cargo test -p nsc-helper
echo

echo "=== Full target check ==="
nix develop -c cargo check --all-targets
echo

echo "=== Module-index smoke run ==="
rm -f "$CATALOG"
nix develop -c cargo run --bin nsc-module-index -- "$ROOT/options-smoke.json" "$CATALOG"
test -s "$CATALOG"
grep -q '"services.openssh"' "$CATALOG"
grep -q '"virtualisation.docker"' "$CATALOG"
echo "MODULE_INDEX_SMOKE=PASS"
echo

echo "========================================"
echo "=== NSC BUILD ACCEPTANCE PASS ==="
echo "========================================"
