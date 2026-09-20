#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$ROOT/nix-software-center"
PATCH="$ROOT/nix-software-center-generated-modules-ui.patch"
UPSTREAM="https://github.com/snowfallorg/nix-software-center.git"
BASELINE="181c1c61eab79130879257550dba0b36bd6bb8c9"
PATCH_SHA256="1eed2b1dfbb7ddc34f4858c9012745c87af4f70c21b0a0cffcba39c2520f8d43"

echo "=== NSC Codespaces bootstrap ==="

command -v git >/dev/null || { echo "git not found"; exit 1; }
command -v sha256sum >/dev/null || { echo "sha256sum not found"; exit 1; }

actual="$(sha256sum "$PATCH" | awk '{print $1}')"
if [[ "$actual" != "$PATCH_SHA256" ]]; then
  echo "Patch checksum mismatch."
  echo "expected: $PATCH_SHA256"
  echo "actual:   $actual"
  exit 1
fi

if [[ -d "$SOURCE/.git" ]]; then
  if git -C "$SOURCE" rev-parse HEAD >/dev/null 2>&1 &&
     git -C "$SOURCE" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
    echo "Patched source already prepared."
    exit 0
  fi
  rm -rf "$SOURCE"
fi

git clone "$UPSTREAM" "$SOURCE"
git -C "$SOURCE" checkout --detach "$BASELINE"

echo "Checking patch against pinned upstream baseline..."
git -C "$SOURCE" apply --check "$PATCH"

echo "Applying generated-modules UI patch..."
git -C "$SOURCE" apply "$PATCH"

echo
echo "Prepared source:"
git -C "$SOURCE" status --short
echo
echo "Bootstrap PASS."
echo "Run: bash ACCEPTANCE.sh"
