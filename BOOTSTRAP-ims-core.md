# Bootstrap: MC SIP/IMS core repository and development environment

**For:** Claude Code
**Owner:** Lucian (github.com/lucianpopovici)
**Requirements source:** `docs/IMS-SRS.md` (v0.7). It is supplied alongside this file; place it in the repo as step 3.2 says.
**Date:** 2026-10-27

---

## 0. Read this first

You are setting up a **new, empty repository**: the repository, the toolchain, the workspace skeleton, the CI gates and the development environment for an in-house SIP/IMS core written in Rust. **You are not implementing any protocol.** No SIP parsing, no Diameter, no CSCF logic. Every crate in this task is a stub that compiles, is tested and is gated, so that the first real code lands into a repository whose rules are already enforced.

### 0.1 What this product is

A SIP/IMS core (P-CSCF, S-CSCF, HSS; I-CSCF and IBCF later) for a mission-critical push-to-talk platform (MCX/FRMCS). It is a **separate product** from that platform, which lives at `github.com/lucianpopovici/mcx-platform` (Python). The decisions below are settled in IMS-SRS. Do not reopen them; if one blocks you, stop and ask.

| Decision | Source |
|---|---|
| Rust, one Cargo workspace, a crate per entity plus shared protocol crates | IMS-OP-03 |
| Separate repository from `mcx-platform` | IMS-OP-03 |
| **No code, path or git dependency shared with `mcx-platform`, in either direction** | IMS-GEN-003 |
| Release set Rel-13 to Rel-20, one selected at start, **no default**; release numbers in exactly one module | IMS-OP-07, IMS-GEN-005 |
| Access binding `none`, `epc` or `5gc`, selected at start, **no default**; I1 implements `none` only | IMS-GEN-004 |
| Third-party test peers: Kamailio (IMS modules) as CSCF, PyHSS as HSS | IMS-OP-08 |
| Every parser of untrusted input is fuzzed in CI | IMS-SEC-003 |

### 0.2 Stop and ask the owner when

- **The repository name** is not confirmed. Proposed: `mcx-ims-core`. Do not create anything under another name without confirmation.
- **The licence** is not given. Do not choose one.
- Anything would be **published**: creating the GitHub repository, pushing, or opening a PR. Prepare everything locally, then ask.
- A **system package** needs installing (dnf/apt/brew). List what is missing and ask; user-level tools (rustup, cargo installs) you may install.
- A step here conflicts with IMS-SRS. IMS-SRS wins; report the conflict.

### 0.3 Do not

- Create `CLAUDE.md`, `AGENTS.md` or any agent memory or instruction file in the repository. The owner keeps that registry outside the repository, deliberately.
- Add a dependency on anything from `mcx-platform`, even for tests.
- Add protocol dependencies (SIP, Diameter, ASN.1 or XML crates). Choosing them is a later, reviewed decision.
- Write a release number (13 to 20) or an access binding name as a default anywhere.
- Download 3GPP specifications. The owner places them (§3.6).

---

## 1. Preconditions

Check each and report the result in one table before changing anything.

| Item | Check | If missing |
|---|---|---|
| git | `git --version` | ask (system package) |
| GitHub CLI, authenticated | `gh auth status` | ask the owner to run `gh auth login` |
| rustup | `rustup --version` | install from rustup.rs (user-level) |
| A C toolchain and pkg-config | `cc --version`, `pkg-config --version` | ask (system package) |
| Container runtime | `podman --version` or `docker --version` | ask; podman preferred on Fedora |
| Compose | `podman compose version` or `docker compose version` | ask |
| Python ≥ 3.11 | `python3 --version` | ask (needed later for the conformance suite) |
| sipp | `sipp -v` | ask; optional for this task, needed for I1 |
| tshark | `tshark --version` | ask; optional for this task |

---

## 2. Toolchain

1. Pin the toolchain to the **current stable at the time you run this** (`rustup check`). Do not guess a version. Write it to `rust-toolchain.toml`:

   ```toml
   [toolchain]
   channel = "<current stable, e.g. 1.xx.y>"
   components = ["rustfmt", "clippy", "llvm-tools"]
   profile = "minimal"
   ```

2. Install a nightly toolchain **only for fuzzing** (`cargo-fuzz` needs it). Pin it by date in `fuzz/rust-toolchain.toml`, never in the workspace root.
3. Install the user-level tools, pinning each to the version you install and recording it in `docs/DEVELOPMENT.md`:
   - `cargo-nextest` (test runner)
   - `cargo-deny` (licences, advisories, bans, sources)
   - `cargo-fuzz`
   - `cargo-llvm-cov` (coverage, informational in I1)
4. Edition: `2024`. `rust-version` in the workspace equals the pinned toolchain.

---

## 3. Repository

### 3.1 Create

`git init` in the confirmed directory name, default branch `main`. Create nothing on GitHub until §8.

### 3.2 Layout

```
<repo>/
├── Cargo.toml                 # workspace only, no package
├── Cargo.lock                 # committed
├── rust-toolchain.toml
├── deny.toml
├── rustfmt.toml
├── .gitignore
├── README.md
├── CONTRIBUTING.md
├── LICENSE                    # only once the owner names one
├── crates/
│   ├── release/               # lib: the ONLY place release numbers exist
│   ├── binding/               # lib: access binding (none | epc | 5gc)
│   ├── config/                # lib: startup configuration, validated, all defects reported together
│   ├── sip/                   # lib: SIP/SDP (stub in this task)
│   ├── diameter/              # lib: Diameter base + Cx (stub in this task)
│   ├── pcscf/                 # bin
│   ├── scscf/                 # bin
│   └── hss/                   # bin
├── fuzz/                      # cargo-fuzz, NOT a workspace member
│   ├── rust-toolchain.toml    # pinned nightly
│   └── fuzz_targets/
│       ├── sip_parse.rs
│       └── diameter_decode.rs
├── conformance/               # NOT part of the workspace (IMS-VER-001/002)
│   └── README.md
├── testbed/                   # Kamailio IMS + PyHSS, containers
│   ├── README.md
│   └── compose.yaml
├── tools/
│   └── gates/                 # CI gate scripts
├── docs/
│   ├── IMS-SRS.md             # copy of the supplied file, unchanged
│   ├── DECISIONS.md
│   ├── DEVELOPMENT.md
│   └── 3GPP/README.md
└── .github/workflows/ci.yml
```

### 3.3 Workspace `Cargo.toml`

- `members = ["crates/*"]`, `resolver = "3"`.
- `[workspace.package]`: edition, rust-version, licence (left out until the owner names it), repository URL.
- `[workspace.lints]`, inherited by every crate (`[lints] workspace = true`):
  - `rust`: `unsafe_code = "forbid"`, `missing_docs = "warn"`, `unused_must_use = "deny"`.
  - `clippy`: `all = "deny"`, `unwrap_used = "deny"`, `expect_used = "deny"`, `panic = "deny"`, `indexing_slicing = "deny"`, `arithmetic_side_effects = "deny"`, `dbg_macro = "deny"`, `todo = "deny"`, `print_stdout = "deny"`.
  - Tests may opt out of `unwrap_used`, `expect_used` and `indexing_slicing` with `#![cfg_attr(test, allow(...))]`; production code may not.
  - `unsafe_code = "forbid"` will need one reviewed exception for the IPsec netlink code in I2 (IMS-REG-004). Do not create the exception now; note it in `docs/DECISIONS.md` as a known future exception.
- `[profile.release]`: `overflow-checks = true`, `panic = "abort"`, `lto = "thin"`, `debug = "line-tables-only"`.
- `[workspace.dependencies]`: only what this task needs (`thiserror` for errors; `tracing` and `tracing-subscriber` with JSON output for the bins; `tokio` only if a bin needs it, which in this task none should).

### 3.4 Crate contents in this task

**`release`.** An enum `Release { Rel13, …, Rel20 }`, `Release::parse(&str) -> Result<Release, ReleaseError>` accepting exactly `13`..`20` as ASCII digits (the platform's SIP-OP-19 lesson: no other script's digits, no sign, no whitespace, no leading zeros), `Display`, `SUPPORTED: [Release; 8]`. **No `Default` impl.** Tests: every supported value, then `0`, `12`, `21`, `""`, `" 17"`, `"017"`, `"+17"`, `"١٧"` (Arabic-Indic), `"１７"` (fullwidth): each refused.

**`binding`.** An enum `AccessBinding { None, Epc, FiveGc }`, `parse` accepting exactly `none`, `epc`, `5gc`. **No `Default` impl.** A function `binding_allowed(binding, release) -> Result<(), BindingError>` whose release thresholds are **not filled in**: it returns `Ok` for `None` and `Err(BindingError::NotYetImplemented)` for the others in I1. IMS-OP-07 requires the thresholds to be extracted from the specifications, not written from memory, so leave a `// threshold: to be extracted (IMS-OP-07)` marker and nothing else.

**`config`.** `Config::from_env()` reading `IMS_RELEASE` and `IMS_ACCESS_BINDING`, both required, no default. It collects **every** defect before failing (IMS-GEN-006): one error type holding a list, with a test where both variables are missing and both are reported. Unknown `IMS_*` variables are a defect too, listed by name.

**`sip`, `diameter`.** A public `parse` (`decode`) function taking `&[u8]` and returning `Err(NotImplemented)`, plus the `MAX_*` bounds as constants (message size, header count; values to be set in I1 design, use obvious placeholders and mark them). They exist so the fuzz targets and CI have something real to call.

**`pcscf`, `scscf`, `hss`.** Each `main`:
1. initialises JSON logging to stderr, timestamps in UTC (IMS-GEN-009);
2. loads `Config::from_env()`; on error, logs every defect and exits **with status 2**, opening no socket;
3. logs one start record carrying entity name, crate version, git commit (from `build.rs` or `option_env!`), release and access binding (IMS-OAM-001);
4. exits 0 (no listener in this task).

Integration tests per bin (`assert_cmd` or `std::process::Command`): no variables → exit 2 with both defects named; valid variables → exit 0 and a start record with all five fields; `IMS_ACCESS_BINDING=epc` → exit 2 (not implemented in I1).

### 3.5 Fuzz scaffold

`cargo fuzz init`, then two targets calling `sip::parse` and `diameter::decode`. Both must build and run for 30 s locally without crashing. Seed corpora directories exist and are committed (empty is fine).

### 3.6 Docs

- `docs/IMS-SRS.md`: the supplied file, byte for byte.
- `docs/DECISIONS.md`: one line per decided open point (IMS-OP-03, 05, 07, 08, and the IMS-OP-09 roadmap entry), each citing IMS-SRS, plus the `unsafe_code` exception expected in I2.
- `docs/DEVELOPMENT.md`: how to install the toolchain and tools (with the pinned versions), run each gate locally, run fuzzing, bring the testbed up.
- `docs/3GPP/README.md`: the list of specification originals the owner will place there, per release Rel-13 to Rel-20: TS 24.229, TS 29.228, TS 29.229, TS 33.203, TS 23.228, TS 23.280, TS 24.379 (for third-party registration behaviour), and from I3 TS 29.214, 29.514, 29.562, 29.328, 29.329. State that release boundaries are extracted from these files (IMS-OP-07) and that nothing may cite a clause not checked against them.
- `README.md`: what this is (two paragraphs), its relation to `mcx-platform` (separate product; the platform must keep passing against Kamailio and Asterisk too), and the status: bootstrap, no protocol implemented.
- `CONTRIBUTING.md`: the gates of §4, the "no default for release or binding" rule, the independence rule, and that every parser of untrusted input gets a fuzz target in the same change.

### 3.7 `conformance/`

A `README.md` only: the suite is written from the specifications (IMS-VER-001), imports nothing from this repository's `sip` or `diameter` crates (IMS-VER-002), and is expected to use an independent decoder (the owner's Python Diameter parser is the candidate; ask the owner for its location before referencing it). Do not create code here.

### 3.8 `testbed/`

The I1 test bed is Kamailio with its IMS modules (P-, S-, I-CSCF) and PyHSS with Redis. In this task:
- write `compose.yaml` with the services, a private network, and **pinned image digests or versions** (no `latest`);
- bring up **PyHSS and Redis only** and show PyHSS starts;
- leave the Kamailio IMS configuration as a documented next task in `testbed/README.md`. It is a substantial configuration of its own and is not part of the bootstrap.

If no maintained PyHSS image exists, build one from a pinned upstream commit in `testbed/pyhss/Containerfile`, and say which commit.

---

## 4. CI gates

`.github/workflows/ci.yml`, on every push and pull request, every job required, no `continue-on-error`, no path or branch filters. **Pin every action by commit SHA**, with the version as a comment.

| Job | What it runs | Requirement |
|---|---|---|
| `fmt` | `cargo fmt --all --check` | — |
| `clippy` | `cargo clippy --workspace --all-targets -- -D warnings` | lints of §3.3 |
| `test` | `cargo nextest run --workspace` and `cargo test --doc` | — |
| `deny` | `cargo deny check` (advisories, bans, licences, sources) | — |
| `independence` | `tools/gates/independence.sh` | IMS-GEN-003 |
| `release-literals` | `tools/gates/release_literals.sh` | IMS-GEN-005, IMS-OP-07 |
| `no-defaults` | `tools/gates/no_defaults.sh` | IMS-GEN-004/005 |
| `fuzz-smoke` | build every fuzz target on the pinned nightly; run each 60 s | IMS-SEC-003 |
| `exit-codes` | the bin integration tests of §3.4 (part of `test`; listed so it cannot be dropped) | IMS-GEN-004/006 |

**Gate scripts** (`tools/gates/`, POSIX shell or Python standard library only, each with a self-test that plants a violation in a temporary copy and shows the gate fails, run in CI before the gate itself):

- `independence.sh`: fails if any `Cargo.toml` or `Cargo.lock` has a `path` dependency outside the repository or any `git` dependency, or if any file references `mcx-platform` other than the README and docs. `deny.toml` also restricts sources to crates.io.
- `release_literals.sh`: fails if a release number 13 to 20 appears as a release (patterns such as `Rel-17`, `rel17`, `release == 17`, `Release(17)`) in any `.rs` file outside `crates/release/`. It is a heuristic; state its known misses in a comment, as the platform's gates do.
- `no_defaults.sh`: fails if `impl Default` appears for `Release` or `AccessBinding`, if `#[derive(Default)]` appears on either, or if `unwrap_or`, `unwrap_or_default` or `unwrap_or_else` is applied to the reading of `IMS_RELEASE` or `IMS_ACCESS_BINDING`.

`deny.toml`: advisories deny; licences allow-list limited to permissive licences (MIT, Apache-2.0, BSD-2/3-Clause, ISC, Unicode-3.0, Zlib), anything else refused until the owner allows it; duplicate versions warn; sources crates.io only.

---

## 5. Commit plan

Commit in this order, each commit passing every gate that exists at that point:

1. toolchain, workspace skeleton, lints, `.gitignore`, README
2. `release`, `binding`, `config` with tests
3. the three bins with integration tests
4. `sip`, `diameter` stubs and the fuzz scaffold
5. gate scripts with their self-tests, `deny.toml`, CI workflow
6. docs and `conformance/` README
7. testbed (PyHSS + Redis running; Kamailio documented)

Commit messages: imperative, one line, then a body citing the IMS-SRS requirements the commit serves.

---

## 6. Definition of done

All of these, run locally, with the output shown to the owner:

- [ ] `cargo fmt --all --check`, `cargo clippy … -D warnings`, `cargo nextest run --workspace`, `cargo deny check` pass
- [ ] each gate script passes, and its self-test shows it failing on a planted violation
- [ ] both fuzz targets run 60 s without a crash
- [ ] each bin: no variables → exit 2, both defects named, no socket opened; valid variables → exit 0 with a start record carrying all five fields; `epc` → exit 2
- [ ] `grep -rn "mcx-platform"` finds only the README and docs
- [ ] no `impl Default` or `derive(Default)` for `Release` or `AccessBinding`
- [ ] PyHSS and Redis start in the testbed
- [ ] every pinned version (toolchain, nightly, tools, images, actions) recorded in `docs/DEVELOPMENT.md`

---

## 7. Report

When done, report to the owner in one message:
- the preconditions table from §1;
- the pinned versions;
- the commit list;
- the definition-of-done checklist with the result of each item;
- anything you could not do, and why;
- every place you departed from this document, and why.

---

## 8. Publishing (only after the owner says yes)

1. `gh repo create lucianpopovici/<repo> --private --source . --remote origin`
2. `git push -u origin main`
3. Confirm the CI run is green, and report its URL.
4. Ask the owner whether to enable branch protection on `main` requiring every job of §4. Do not change repository settings without that yes.

---

## 9. Not in this task

- Any SIP, SDP, Diameter or CSCF logic (I1 work, after the I1 conformance statement and IMS-VP-I1).
- Choosing protocol crates.
- The Kamailio IMS configuration (next task, `testbed/README.md`).
- The conformance suite.
- The release thresholds for `epc` and `5gc` (extraction from the specifications, IMS-OP-07).
- Any change to `mcx-platform`.
