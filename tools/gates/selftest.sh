#!/bin/sh
# Self-test for the gates: each gate must pass on a clean copy of the
# repository and must fail on a copy with a planted violation.
# Usage: selftest.sh [independence|release_literals|no_defaults|one_implementation|entity_deps|all]
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

# expect_pass_with GATE DESCRIPTION FILE TEXT: TEXT is allowed there; the gate must still pass
expect_pass_with() {
    fresh
    mkdir -p "$(dirname "$tmp/copy/$3")"
    printf '%s\n' "$4" >>"$tmp/copy/$3"
    if "$here/$1.sh" "$tmp/copy" >/dev/null 2>&1; then
        echo "selftest: $1 correctly passed: $2"
    else
        echo "selftest: $1 wrongly failed on allowed text: $2" >&2
        fail=1
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
t_one_implementation() {
    expect_pass one_implementation
    expect_fail one_implementation "SIP status line in an entity" crates/pcscf/src/main.rs 'const L: &str = "SIP/2.0 200 OK";'
    expect_fail one_implementation "SIP method compared in an entity" crates/scscf/src/main.rs 'fn m(s: &str) -> bool { s == "REGISTER" }'
    expect_fail one_implementation "IMS header name in an entity" crates/pcscf/src/main.rs 'const H: &str = "p-asserted-identity";'
    expect_fail one_implementation "header line in a support crate" crates/config/src/lib.rs 'const H: &str = "Via: SIP/2.0/TLS";'
    expect_fail one_implementation "SDP in the HSS" crates/hss/src/main.rs 'const S: &str = "v=0\r\n";'
    expect_fail one_implementation "3GPP Vendor-Id in an entity" crates/scscf/src/main.rs 'const V: u32 = 10_415;'
    expect_fail one_implementation "Cx Application-Id in the SIP crate" crates/sip/src/lib.rs 'const CX: u32 = 16777216;'
    expect_fail one_implementation "SIP in the Diameter crate" crates/diameter/src/lib.rs 'const M: &str = "INVITE";'
    expect_pass_with one_implementation "SIP in the SIP crate" crates/sip/src/lib.rs 'const L: &str = "SIP/2.0"; const M: &str = "INVITE"; const H: &str = "Via:";'
    expect_pass_with one_implementation "Cx Application-Id in the Diameter crate" crates/diameter/src/lib.rs 'const CX: u32 = 16_777_216; const V: u32 = 10415;'
    expect_pass_with one_implementation "SIP test data under tests/" crates/pcscf/tests/wire.rs 'const R: &str = "REGISTER sip:ims.example SIP/2.0";'
}
t_entity_deps() {
    expect_pass entity_deps
    expect_fail entity_deps "entity depends on an entity" crates/scscf/Cargo.toml '[build-dependencies]
pcscf = { path = "../pcscf" }'
    expect_fail entity_deps "library dev-depends on an entity" crates/sip/Cargo.toml "[target.'cfg(unix)'.dev-dependencies]
hss = { path = \"../hss\" }"
    expect_fail entity_deps "entity in workspace.dependencies" Cargo.toml '[workspace.dependencies.pcscf]
path = "crates/pcscf"'
    expect_fail entity_deps "unreadable manifest" crates/hss/Cargo.toml 'this is not toml ='
    expect_pass_with entity_deps "entity depends on a library" crates/hss/Cargo.toml '[build-dependencies]
release = { path = "../release" }'
}

case "${1:-all}" in
    independence) t_independence ;;
    release_literals) t_release_literals ;;
    no_defaults) t_no_defaults ;;
    one_implementation) t_one_implementation ;;
    entity_deps) t_entity_deps ;;
    all) t_independence; t_release_literals; t_no_defaults; t_one_implementation; t_entity_deps ;;
    *) echo "usage: selftest.sh [independence|release_literals|no_defaults|one_implementation|entity_deps|all]" >&2; exit 2 ;;
esac
[ "$fail" -eq 0 ] && echo "selftest: ok"
exit "$fail"
