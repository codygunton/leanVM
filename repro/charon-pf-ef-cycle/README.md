# Charon `PF<EF>` Repro

This is a minimized Charon reproducer for the stack overflow hit while trying to extract the sumcheck verifier.

Run from the repo root:

```bash
./repro/charon-pf-ef-cycle/reproduce.sh
```

The script checks three things:

1. Rust accepts the tiny repro crate.
2. Charon succeeds when the extension-field base is explicit.
3. Charon stack-overflows when the base is the associated type projection `PF<EF> = <EF as PrimeCharacteristicRing>::PrimeSubfield`.

By default the script runs Charon from pinned upstream main:

```text
github:AeneasVerif/charon/19e3f85a32e02ef00664fa325bbbf157678be530#charon
```

Override it with `CHARON_FLAKE` to test another Charon fork or branch.

Generated logs and LLBC files go under `target/charon-pf-ef-cycle-repro/`.
