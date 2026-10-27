#!/bin/sh
# Gate: independence from mcx-platform (IMS-GEN-003).
# Fails if any Cargo.toml has a path dependency leaving the repository or any
# git dependency, if Cargo.lock has a git source, or if any file other than
# README.md, docs/, CONTRIBUTING.md, tools/gates/ and the local, untracked
# BOOTSTRAP-ims-core.md mentions mcx-platform.
# Known misses: dependencies written as multi-line tables with the path on a
# line that does not contain `path =`; non-text files are not scanned.
# Usage: independence.sh [ROOT]
set -u
root=$(cd "${1:-$(dirname "$0")/../..}" && pwd)
fail=0

manifests=$(find "$root" -name target -prune -o -name .git -prune -o -name Cargo.toml -print)
for m in $manifests; do
    dir=$(dirname "$m")
    if grep -nE '^[^#]*\bgit[[:space:]]*=' "$m" >/dev/null; then
        echo "independence: git dependency in $m" >&2
        fail=1
    fi
    grep -oE '\bpath[[:space:]]*=[[:space:]]*"[^"]*"' "$m" | sed -E 's/.*"([^"]*)"/\1/' |
    while read -r p; do
        case "$p" in
            /*) full=$(realpath -m "$p") ;;
            *) full=$(realpath -m "$dir/$p") ;;
        esac
        case "$full" in
            "$root"|"$root"/*) ;;
            *) echo "independence: path dependency outside repository in $m: $p" >&2; exit 1 ;;
        esac
    done || fail=1
done

for l in $(find "$root" -name target -prune -o -name .git -prune -o -name Cargo.lock -print); do
    if grep -q 'source = "git+' "$l"; then
        echo "independence: git source in $l" >&2
        fail=1
    fi
done

hits=$(grep -rIl 'mcx-platform' "$root" \
    --exclude-dir=.git --exclude-dir=target --exclude-dir=docs --exclude-dir=gates \
    --exclude=README.md --exclude=CONTRIBUTING.md --exclude=BOOTSTRAP-ims-core.md 2>/dev/null)
if [ -n "$hits" ]; then
    echo "independence: mcx-platform referenced in:" >&2
    echo "$hits" >&2
    fail=1
fi

[ "$fail" -eq 0 ] && echo "independence: ok"
exit "$fail"
