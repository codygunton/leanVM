#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CRATE="$ROOT/repro/charon-pf-ef-cycle"
OUT="$ROOT/target/charon-pf-ef-cycle-repro"

CHARON_FLAKE="${CHARON_FLAKE:-github:AeneasVerif/charon/19e3f85a32e02ef00664fa325bbbf157678be530#charon}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-180}"

mkdir -p "$OUT"

require() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "missing required command: $1" >&2
        exit 2
    fi
}

run_charon() {
    local name="$1"
    local start_from="$2"
    local log="$OUT/$name.log"
    local llbc="$OUT/$name.llbc"

    rm -f "$log" "$llbc"
    echo "==> Charon crate::$start_from"

    local cmd=(
        nix --extra-experimental-features "nix-command flakes"
        run "$CHARON_FLAKE" --
        cargo
        --preset=fast
        --start-from "crate::$start_from"
        --no-normalize
        --dest-file "$llbc"
        --
        --manifest-path "$CRATE/Cargo.toml"
        --lib
    )

    if command -v timeout >/dev/null 2>&1; then
        timeout "$TIMEOUT_SECONDS" "${cmd[@]}" >"$log" 2>&1
    else
        "${cmd[@]}" >"$log" 2>&1
    fi
}

expect_ok() {
    local name="$1"
    local start_from="$2"
    local log="$OUT/$name.log"
    local llbc="$OUT/$name.llbc"

    if ! run_charon "$name" "$start_from"; then
        echo "expected Charon success for crate::$start_from, but it failed" >&2
        tail -n 80 "$log" >&2 || true
        exit 1
    fi

    if [ ! -s "$llbc" ]; then
        echo "expected nonempty LLBC at $llbc" >&2
        exit 1
    fi
}

expect_stack_overflow() {
    local name="$1"
    local start_from="$2"
    local log="$OUT/$name.log"

    set +e
    run_charon "$name" "$start_from"
    local status=$?
    set -e

    if [ "$status" -eq 0 ]; then
        echo "expected Charon to fail for crate::$start_from, but it succeeded" >&2
        exit 1
    fi

    if ! grep -q "has overflowed its stack" "$log"; then
        echo "Charon failed, but not with the expected stack overflow message" >&2
        echo "exit status: $status" >&2
        tail -n 80 "$log" >&2 || true
        exit 1
    fi

    echo "observed expected Charon stack overflow for crate::$start_from"
    tail -n 12 "$log"
}

require cargo
require nix

echo "==> Rust typecheck"
cargo check --manifest-path "$CRATE/Cargo.toml" --lib

expect_ok "explicit-self-base" "explicit_self_base_case"
expect_ok "explicit-generic-base" "explicit_generic_base_case"
expect_stack_overflow "pf-associated-projection" "pf_associated_projection_case"

echo
echo "validated repro; logs are in $OUT"
