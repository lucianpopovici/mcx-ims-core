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
| fuzz-smoke | every fuzz target for 60 s on the pinned nightly |
| exit-codes | the bin integration tests |

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) to run them locally.

## Rules

- **No default for release or access binding.** `Release` and `AccessBinding` have no `Default`, and `IMS_RELEASE` / `IMS_ACCESS_BINDING` are never read with `unwrap_or*`. Release numbers exist only in `crates/release`.
- **Independence.** No code, path or git dependency shared with `mcx-platform`, in either direction, even for tests (IMS-GEN-003). Dependencies come from crates.io only.
- **Fuzzing.** Every parser of untrusted input gets a fuzz target in the same change (IMS-SEC-003).
- **Lints.** `unsafe_code` is forbidden; no `unwrap`, `expect`, `panic!`, indexing or unchecked arithmetic in production code. Tests may opt out of `unwrap_used`, `expect_used` and `indexing_slicing` only.
- **Protocol dependencies** (SIP, Diameter, ASN.1, XML crates) are a reviewed decision, not a drive-by addition.
- Commit messages: imperative one-line subject, then a body citing the IMS-SRS requirements served.
