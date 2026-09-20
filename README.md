# NSC Build Test

This repository is a disposable Codespaces build harness for the generated-modules UI changes to `snowfallorg/nix-software-center`.

The harness pins the upstream baseline, applies the generated patch, and runs the build/acceptance checks without installing anything into a NixOS system.

## Codespaces

1. Open **Code → Codespaces → Create codespace on main**.
2. Wait for the post-create bootstrap to finish.
3. In the terminal run:

```bash
bash ACCEPTANCE.sh
```

The acceptance script stops at the first failing command and writes `acceptance.log`.
