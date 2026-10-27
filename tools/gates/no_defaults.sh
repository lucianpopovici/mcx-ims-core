#!/bin/sh
# Gate: no default for release or access binding (IMS-GEN-004/005).
# Fails on `impl Default for Release|AccessBinding`, on `#[derive(.. Default ..)]`
# directly above either type, and on unwrap_or* applied to a line that reads
# IMS_RELEASE or IMS_ACCESS_BINDING (or the constants naming them).
# Known misses: the read and the unwrap_or* split across lines, a Default
# provided through a macro or a wrapper type.
# Usage: no_defaults.sh [ROOT]
set -u
root=$(cd "${1:-$(dirname "$0")/../..}" && pwd)
fail=0
files=$(find "$root" \( -name target -o -name .git \) -prune -o -name '*.rs' -print)
[ -n "$files" ] || { echo "no_defaults: ok"; exit 0; }

# shellcheck disable=SC2086
if grep -nE 'impl[^{]*\bDefault\b[^{]*\bfor[[:space:]]+(Release|AccessBinding)\b' $files; then
    echo "no_defaults: impl Default for Release/AccessBinding" >&2
    fail=1
fi

# shellcheck disable=SC2086
if grep -nE '(IMS_RELEASE|IMS_ACCESS_BINDING|VAR_RELEASE|VAR_ACCESS_BINDING).*unwrap_or|unwrap_or.*(IMS_RELEASE|IMS_ACCESS_BINDING|VAR_RELEASE|VAR_ACCESS_BINDING)' $files; then
    echo "no_defaults: unwrap_or* on a release/binding variable" >&2
    fail=1
fi

for f in $files; do
    awk -v file="$f" '
        /^[[:space:]]*#\[derive\(/ { if ($0 ~ /Default/) pend = 1; next }
        /^[[:space:]]*(#\[|\/\/)/ { next }
        /(enum|struct)[[:space:]]+(Release|AccessBinding)([^[:alnum:]_]|$)/ && pend { print file ":" NR ": derive(Default) on " $0; bad = 1 }
        { pend = 0 }
        END { exit bad }
    ' "$f" >&2 || fail=1
done

[ "$fail" -eq 0 ] && echo "no_defaults: ok"
exit "$fail"
