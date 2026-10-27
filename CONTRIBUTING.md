# Contributing

## Gates

Every push and pull request runs these jobs; all are required (`.github/workflows/ci.yml`):

| Job | Command |
|---|---|
| fmt | `cargo fmt --all --check` |
| clippy | `cargo clippy --workspace --all-targets -- -D warnings` |
| test | `cargo nextest run --workspace` and `cargo test --workspace --doc` |
| deny | `cargo deny check` |
| independence | `tools/gates/selftest.sh independence`, then `tools/gates/independence.sh` |
| release-literals | `tools/gates/selftest.sh release_literals`, then `tools/gates/release_literals.sh` |
| no-defaults | `tools/gates/selftest.sh no_defaults`, then `tools/gates/no_defaults.sh` |
| one-implementation | `tools/gates/selftest.sh one_implementation`, then `tools/gates/one_implementation.sh` |
| entity-deps | `tools/gates/selftest.sh entity_deps`, then `tools/gates/entity_deps.sh` (python3 ≥ 3.11) |
| fuzz-smoke | every fuzz target for 60 s on the pinned nightly |
| exit-codes | the bin integration tests |

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) to run them locally.

## Rules

### Architecture

- **One implementation per protocol.** SIP, SDP, Diameter base, each Diameter application (Cx, later Rx and Sh), each XML body, and SIP URI and identity canonicalisation are each implemented exactly once, in a protocol crate, encoder and decoder together. Entities (`pcscf`, `scscf`, `hss`, and later ones) use those crates; they never parse, build or re-check wire format themselves. A gap is fixed in the crate, never worked around in an entity. The rule covers the Cargo workspace; the conformance suite is outside it and may use any language and library.
- **Independence.** No code, path or git dependency shared with `mcx-platform`, in either direction, even for tests (IMS-GEN-003). Dependencies come from crates.io only.
- **No default for release or access binding.** `Release` and `AccessBinding` have no `Default`, and `IMS_RELEASE` / `IMS_ACCESS_BINDING` are never read with `unwrap_or*`. Release numbers exist only in `crates/release`.
- **External libraries** are decided by the owner when each one is needed, and recorded in `docs/DECISIONS.md`. None is added in passing.

### Code

- **Lints.** `unsafe_code` is forbidden; no `unwrap`, `expect`, `panic!`, indexing or unchecked arithmetic in production code. Tests may opt out of `unwrap_used`, `expect_used` and `indexing_slicing` only.
- **Untrusted input.** Every parser bounds message size, element count and nesting, and rejects rather than truncates (IMS-SEC-002). Numbers from a peer accept ASCII digits only. Peer text is clipped where it enters an error, a log line or an audit record.
- **Protocol state machines** are enums matched exhaustively: no `_` arm over states or events, so a new state or event is a compile error wherever it is not handled.
- **No secrets in logs.** Credentials, authentication vectors, keys and message bodies are never logged by default (IMS-SEC-004).
- **Deviations.** Any departure from a specification is recorded in `docs/`, with its reason; when it is a setting, it is also reported at startup.
- **Protocol values cite their source**: specification, version and clause, read from the original in `docs/3GPP/`.

### Verification

- **Fuzzing.** Every parser of untrusted input gets a fuzz target in the same change (IMS-SEC-003).
- **Tests.** New behaviour needs a test that fails without it, and a defect fix comes with the test that would have caught it. A test that pins a constant spells the value out as a literal. Test names carry the requirement or verification case they verify.
- **Critical code.** A change to a parser, a protocol state machine, trust-domain, authentication or credential code, or a gate script also needs mutation testing of the changed code (every non-equivalent mutant killed, equivalents listed with the reason) and an independent review by someone who has not seen the work.
- **Gates.** A gate, its self-test or a lint is never weakened to get a change through. A gate change is a change of its own, with its self-test extended.

### Commits

- Imperative one-line subject, then a body citing the IMS-SRS requirements served.
