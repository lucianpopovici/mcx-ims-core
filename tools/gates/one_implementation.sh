#!/bin/sh
# Gate: one implementation per protocol (CONTRIBUTING.md, Architecture).
# Wire format lives in its protocol crate. Fails when production source
# (crates/*/src/**.rs and crates/*/build.rs) outside the crate owning a
# protocol holds that protocol's wire text:
#  - SIP, owned by crates/sip: a string literal containing "SIP/2.0"; a
#    string literal that is exactly a SIP method; a string literal that is,
#    or starts with "<name>:", a SIP/IMS-specific header name (any case).
#  - SDP, owned by crates/sip (and crates/sdp once split out): a string
#    literal starting with v=0, m=audio|video|application, a=rtpmap:,
#    a=fmtp: or c=IN IP.
#  - Diameter, owned by crates/diameter: the 3GPP Vendor-Id 10415 or the
#    Application-Id of Cx (16777216), Sh (16777217) or Rx (16777236), with
#    or without digit separators.
# Known misses (it is a heuristic): header names shared with HTTP or too
# generic to tell apart (To, From, Route, Contact, Path, Expires,
# Authorization, Content-Length, ...); the method INFO (a log level too);
# wire text built by concatenation or format!; Diameter command and AVP
# codes (bare small integers); byte arrays; wire text in a non-Rust file.
# Not scanned: tests/, benches/, examples/ and fuzz/, which may hold wire
# text as test data. A #[cfg(test)] module inside src/ IS scanned: put SIP
# test messages under tests/.
# Usage: one_implementation.sh [ROOT]
set -u
root=$(cd "${1:-$(dirname "$0")/../..}" && pwd)
fail=0

files=$(find "$root/crates" -name target -prune -o -type f \( -path '*/src/*.rs' -o -name build.rs \) -print 2>/dev/null | sort)

# outside OWNER... : print the files not under any of the given crates
outside() {
    printf '%s\n' "$files" | while read -r f; do
        [ -n "$f" ] || continue
        keep=1
        for owner in "$@"; do
            case "$f" in "$root/crates/$owner/"*) keep=0 ;; esac
        done
        [ "$keep" -eq 1 ] && printf '%s\n' "$f"
    done
}

# check NAME FLAGS PATTERN OWNER...
check() {
    name=$1 flags=$2 pat=$3
    shift 3
    list=$(outside "$@")
    [ -n "$list" ] || return 0
    # shellcheck disable=SC2086
    hits=$(printf '%s\n' "$list" | xargs grep -nE $flags -- "$pat" 2>/dev/null)
    if [ -n "$hits" ]; then
        echo "one_implementation: $name wire text outside its protocol crate ($*):" >&2
        echo "$hits" >&2
        fail=1
    fi
}

methods='REGISTER|INVITE|ACK|BYE|CANCEL|OPTIONS|SUBSCRIBE|NOTIFY|PUBLISH|MESSAGE|UPDATE|PRACK|REFER'
headers='Via|Call-ID|CSeq|Max-Forwards|Record-Route|Service-Route|P-Asserted-Identity|P-Preferred-Identity|P-Asserted-Service|P-Preferred-Service|P-Access-Network-Info|P-Visited-Network-ID|P-Charging-Vector|P-Charging-Function-Addresses|P-Associated-URI|P-Called-Party-ID|Security-Client|Security-Server|Security-Verify|Accept-Contact|Reject-Contact|Resource-Priority|Session-Expires|Min-SE|Feature-Caps'

check SIP ''   '"[^"]*SIP/2\.0' sip
check SIP ''   "\"($methods)\"" sip
check SIP '-i' "\"($headers)(\"|[[:space:]]*:)" sip
check SDP ''   '"(v=0|m=(audio|video|application) |a=rtpmap:|a=fmtp:|c=IN IP)' sip sdp
check Diameter '' '\b(10_?415|16_?777_?216|16_?777_?217|16_?777_?236)\b' diameter

[ "$fail" -eq 0 ] && echo "one_implementation: ok"
exit "$fail"
