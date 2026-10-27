#!/bin/sh
# Self-test for the gates: each gate must pass on a clean copy of the
# repository and must fail on a copy with a planted violation.
# Usage: selftest.sh [independence|release_literals|no_defaults|all]
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fresh() {
    rm -rf "$tmp/copy"
    mkdir "$tmp/copy"
    tar -C "$repo" --exclude=./target --exclude=./fuzz/target --exclude=./.git -cf - . | tar -C "$tmp/copy" -xf -
}

expect_pass() {
    fresh
    if ! "$here/$1.sh" "$tmp/copy" >/dev/null 2>&1; then
        echo "selftest: $1 fails on a clean copy" >&2
        fail=1
    fi
}

# expect_fail GATE DESCRIPTION FILE TEXT: append TEXT to FILE in a fresh copy
expect_fail() {
    fresh
    mkdir -p "$(dirname "$tmp/copy/$3")"
    printf '%s\n' "$4" >>"$tmp/copy/$3"
    if "$here/$1.sh" "$tmp/copy" >/dev/null 2>&1; then
        echo "selftest: $1 did NOT fail on planted violation: $2" >&2
        fail=1
    else
        echo "selftest: $1 correctly failed on: $2"
    fi
}

t_independence() {
    expect_pass independence
    expect_fail independence "absolute path dependency" crates/sip/Cargo.toml 'evil = { path = "/opt/evil" }'
    expect_fail independence "path leaving the repository" crates/sip/Cargo.toml 'evil = { path = "../../../evil" }'
    expect_fail independence "git dependency" crates/sip/Cargo.toml 'evil = { git = "https://example.invalid/evil" }'
    expect_fail independence "mcx-platform reference in source" crates/sip/src/lib.rs '// see mcx-platform'
    expect_fail independence "mcx-platform in a nested README" crates/sip/README.md 'see mcx-platform'
    expect_fail independence "mcx-platform in a nested docs/" crates/sip/docs/notes.md 'see mcx-platform'
    expect_fail independence "mcx-platform in a nested CLAUDE.md" crates/sip/CLAUDE.md 'see mcx-platform'
}
t_release_literals() {
    expect_pass release_literals
    expect_fail release_literals "Release(17)" crates/sip/src/lib.rs 'const X: u8 = Release(17);'
    expect_fail release_literals "Rel-17 in a comment" crates/config/src/lib.rs '// Rel-17'
    expect_fail release_literals "Release::Rel18 outside crate" crates/hss/src/main.rs 'fn f() { let _ = Release::Rel18; }'
}
t_no_defaults() {
    expect_pass no_defaults
    expect_fail no_defaults "impl Default for Release" crates/binding/src/lib.rs 'impl Default for Release { fn default() -> Self { loop {} } }'
    expect_fail no_defaults "impl Default for AccessBinding" crates/binding/src/lib.rs 'impl Default for AccessBinding { fn default() -> Self { loop {} } }'
    expect_fail no_defaults "derive(Default) on AccessBinding" crates/binding/src/lib.rs '#[derive(Default)]
pub enum AccessBinding { A }'
    expect_fail no_defaults "unwrap_or on IMS_RELEASE" crates/config/src/lib.rs 'fn g() { let _ = std::env::var("IMS_RELEASE").unwrap_or_default(); }'
}

case "${1:-all}" in
    independence) t_independence ;;
    release_literals) t_release_literals ;;
    no_defaults) t_no_defaults ;;
    all) t_independence; t_release_literals; t_no_defaults ;;
    *) echo "usage: selftest.sh [independence|release_literals|no_defaults|all]" >&2; exit 2 ;;
esac
[ "$fail" -eq 0 ] && echo "selftest: ok"
exit "$fail"
