#!/bin/sh
# Gate: release numbers exist only in crates/release (IMS-GEN-005, IMS-OP-07).
# Fails if a release number 13 to 20 appears as a release in any .rs file
# outside crates/release/: Rel-17, rel17, Rel_17, Release17, `release == 17`,
# `Release(17)`.
# Known misses: a release held in a bare number (`let n = 17;`), a release
# built by arithmetic, a number split across tokens or lines, and releases in
# non-Rust files.
# Usage: release_literals.sh [ROOT]
set -u
root=$(cd "${1:-$(dirname "$0")/../..}" && pwd)
n='(1[3-9]|20)'
pat="\\brel(ease)?[-_ ]?${n}\\b|\\brelease[[:space:]]*(==|!=|=)[[:space:]]*${n}\\b|\\bRelease\\(${n}\\)"
hits=$(find "$root" \( -name target -o -name .git -o -path "$root/crates/release" \) -prune -o -name '*.rs' -print |
    xargs -r grep -nEi "$pat")
if [ -n "$hits" ]; then
    echo "release_literals: release number outside crates/release:" >&2
    echo "$hits" >&2
    exit 1
fi
echo "release_literals: ok"
