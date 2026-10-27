# CLAUDE.md — project context

Read this before touching anything. It is the shared context for every task in
this repository. The rules that bind everyone, people and agents alike, are in
[`CONTRIBUTING.md`](CONTRIBUTING.md): read it too, it is not repeated here. This
file adds what an agent needs on top: the context, the commands, how a change is
made and verified, and when to stop.

**Then read `kb/AGENT.md` if `kb/` exists.** `kb/` is the agent memory for this
project, kept on the owner's host and out of git, as in the platform.

## What this is

An in-house SIP/IMS core in Rust: P-CSCF, S-CSCF and HSS, with I-CSCF and IBCF
later. It is the SIP core of a mission-critical push-to-talk platform
([`mcx-platform`](https://github.com/lucianpopovici/mcx-platform), Python),
and a **separate product** from it. The platform must keep working with any SIP
core: Kamailio and Asterisk stay in its interop matrix, and this core is added
as a third. Whether it ever replaces Kamailio is decided on evidence later
(IMS-OP-01), never assumed.

Requirements: [`docs/IMS-SRS.md`](docs/IMS-SRS.md). This repository's copy is the
authoritative one. Settled points: [`docs/DECISIONS.md`](docs/DECISIONS.md).

**Current state: bootstrap.** The workspace, toolchain, CI gates and test bed
exist. **No protocol is implemented**: `sip::parse` and `diameter::decode` are
stubs that refuse everything, the three entities validate their configuration,
log a start record and exit. The I1 conformance statement and verification plan
are not written yet.

## The rules that shape everything

1. **One implementation per protocol.** SIP, SDP, Diameter base, each Diameter
   application, each XML body, and SIP URI and identity canonicalisation are each
   implemented once, in a protocol crate, encoder and decoder together. Entities
   use those crates and never parse, build or re-check wire format themselves. A
   gap is fixed in the crate, never worked around in an entity. The platform
   learned why: three layers each reading an identity their own way were three
   ways in (PLT-VP-R1 RES-OP-01). `entity_deps` checks that nothing depends on
   an entity; `one_implementation` looks for wire text outside its protocol
   crate, and is a heuristic: passing it is not proof.
2. **A separate product.** No code, path or git dependency shared with
   `mcx-platform`, in either direction, even for tests (IMS-GEN-003). Nothing here
   may depend on the platform being the MC server above it, and the platform must
   not need to know which core it is behind (IMS-SRS §3.3).
3. **No default for the release or the access binding.** Both are chosen at start
   or the process refuses to start (IMS-GEN-004/005). Release numbers exist only
   in `crates/release`.
4. **Profile-agnostic.** The core does not know whether the MC system above it is
   an MCX or an FRMCS deployment (IMS-SRS §3.3).
5. **Every failure says where it began.** Each entity and role emits a record for
   every procedure it takes part in, and a failed one names its origin: here,
   a named peer, a peer that did not answer, or a broken link (IMS-SRS §14A).
   Someone reading only the telemetry must be able to point at the entity and
   step, or the link, where a failed call or registration went wrong.

These are enforced by gates (`tools/gates/`). **If a gate blocks you, it is
probably right.** Fix the code. If you believe the gate is wrong, stop and say
so: a gate change is its own change, with its self-test extended to show the
case, and the owner reviews it. Never weaken a gate, a self-test or a lint to
get a change through.

## Commands

```bash
cargo fmt --all --check
cargo clippy --workspace --all-targets -- -D warnings
cargo nextest run --workspace && cargo test --workspace --doc
cargo deny check
tools/gates/selftest.sh all        # every gate fails on its planted violations
tools/gates/independence.sh && tools/gates/release_literals.sh && tools/gates/no_defaults.sh \
  && tools/gates/one_implementation.sh && tools/gates/entity_deps.sh
# run an entity: both variables are required, neither has a default
IMS_RELEASE=17 IMS_ACCESS_BINDING=none cargo run -p scscf
# fuzzing (fuzz/ has its own pinned nightly and is not a workspace member)
(cd fuzz && cargo fuzz run sip_parse -- -max_total_time=60)
# mutation testing of changed code (see Verification)
cargo mutants --in-diff <(git diff origin/main...) --test-tool nextest
# test bed: PyHSS + Redis (Kamailio IMS not configured yet)
testbed/pyhss/build.sh && podman compose -f testbed/compose.yaml up -d
```

Pinned versions of everything are in [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).
A tool you install for the first time gets its version pinned there in the same
change.

## Layout

```
crates/release/    the only place release numbers exist
crates/binding/    access binding none | epc | 5gc; release thresholds not yet extracted
crates/config/     startup configuration from IMS_* variables; every defect reported together
crates/sip/        SIP (and SDP until it has its own crate); stub
crates/diameter/   Diameter base and its applications (Cx now; Rx, Sh later); stub
crates/pcscf/  crates/scscf/  crates/hss/     the entities (binaries)
fuzz/              cargo-fuzz targets, one or more per parser
conformance/       the conformance suite (not written yet), outside the workspace
testbed/           third-party peers: PyHSS + Redis now, Kamailio IMS next
tools/gates/       CI gate scripts and their self-test
docs/              IMS-SRS, DECISIONS, DEVELOPMENT, 3GPP originals
```

## Making a change

- **Branch and pull request.** Work on a branch and open a pull request to
  `main`. Never push to `main`, never force-push a shared branch, never merge
  your own pull request, never change repository settings. The owner merges.
- **Green before the pull request**, with the output to show for it: every
  command under Commands, run locally, pasted or summarised with counts in the
  pull request description.
- **Commit messages** as `CONTRIBUTING.md` says, citing the IMS-SRS requirements
  served.
- **Documents in the same change.** An IMS-SRS change gets a revision history
  row; a decision gets its line in `docs/DECISIONS.md`; a new pin goes in
  `docs/DEVELOPMENT.md`.
- **Stay in scope.** A defect found on the way is reported. It is fixed in the
  same change only when it is inside the task; otherwise it becomes an open point.

## Decisions and open points

- **An agent never decides a question that is the owner's.** When the
  requirements, the specification or a task brief leave a choice open, add an
  open point to IMS-SRS §16 with the next free number (`IMS-OP-nn`), the options,
  their consequences and a recommendation, and stop.
- **A closed open point is not reopened.** If one blocks you, say so.
- **A conflict between the code, IMS-SRS and the specification is reported,
  never resolved silently.**
- **When the specification does not answer something, record it as an open point
  rather than guessing quietly.** On the platform, several open points were
  interface defects found exactly that way, and they were worth more written down
  than resolved by assumption.
- **External libraries are decided when they are needed**, by the owner. Propose
  one with what it is for, the alternatives, its licence and maintenance, and
  whether it uses `unsafe`; wait for the answer; record it in `docs/DECISIONS.md`.
  The conformance suite is exempt: it may use any language and library.

## Specifications

Every one of these comes from the platform's experience, where nine of the ten
constant sets checked against their specification had been wrong.

- **Read the original.** `docs/3GPP/` holds the 3GPP archives, one per release;
  each holds the Word original (`.doc` for most, `.docx` for some). Convert it
  to text with `soffice --headless --convert-to txt:Text`. Never read a PDF:
  automated extraction of a PDF table does not fail loudly, it returns a
  plausible invented table. The archive name gives the version
  (`24229-k10` is V20.1.0, `24229-dn0` is V13.23.0).
- **Cite it.** Every protocol value (method, header, AVP code, result code,
  cause, timer, feature tag) carries its source next to it: specification,
  version and clause, e.g. `TS 29.229 V18.1.0 §6.3.x`. Nothing comes from memory.
- **A value can be right in one release and wrong in another.** Anything that
  may differ between releases is extracted across all eight, by a tool committed
  under `tools/spec/`, with its output committed. Add the release alongside the
  value. An interpolated boundary is a guess with a citation attached.
- **A missing rule is worse than a wrong value.** A wrong value fails the first
  time it meets a conformant peer; an absent length or presence rule never fails,
  it just accepts what it should not. Read the rules around a value, not only the
  value.
- **Write message bodies from the schema**, extracted verbatim, never from this
  repository's own code or tests.
- **A specification you cannot read blocks the work.** Say so in the code and in
  the report; do not assert conformance to it. Missing today (2026-10-27):
  TS 29.229 Rel-20, and TS 23.228, TS 23.280 and TS 24.379 for every release.

## Verification

- **New behaviour needs a test that fails without it.** Break the guard on
  purpose, see a test go red, restore it. A guard masked by another layer needs
  a test that isolates it with the other disabled.
- **A defect fix comes with the test that would have caught it.**
- **A test that pins a constant spells the value out as a literal.** If it
  imports the constant it checks, code and test move together and the test
  proves nothing.
- **Test names carry what they verify**: the requirement or verification case,
  e.g. `ims_reg_005_path_inserted_on_register`.
- **Parsers, protocol state machines, trust-domain, authentication and credential
  code, and the gate scripts** additionally need, in every change that touches
  them:
  1. **Mutation testing** of the changed code (`cargo mutants`). Every
     non-equivalent mutant is killed; equivalent mutants are listed in the pull
     request with the reason each is equivalent.
  2. **An independent review** by a separate agent that has not seen the work,
     given only the diff, the requirements and the specification clauses. Its
     findings are fixed or recorded as open points, and the review and its
     outcome are in the pull request. Repeat until a round finds nothing new.
- **The suite tests what it builds.** Once the entities run, a green unit suite
  says nothing about the deployed process. Wire behaviour is checked against the
  test bed's third-party peers (IMS-VER-004) and the platform's VP1-SIG-001
  (IMS-VER-003). On the platform, the shipped process could not complete a call
  and every in-process test still passed.
- **The conformance suite is independent by construction.** It imports nothing
  from this workspace (IMS-VER-002). Its checks are derived from the
  specification, never from the code they check: on the platform, an
  independent checker written from the same recollection as the encoder shared
  its wrong belief and endorsed the defect.

## Stop and ask when

- a question is the owner's (see Decisions);
- a new external library is needed;
- a gate blocks and you believe the gate is wrong;
- a specification is missing or does not answer the question;
- something would be published, pushed to `main`, or would change repository
  settings or anything outside this repository;
- a system package needs installing;
- the task conflicts with IMS-SRS (IMS-SRS wins until the owner says otherwise).

## Reporting

End every task with: what changed; what was verified and how, with the command
output or its counts; what was not verified, and why; every place you departed
from the instructions; and every open point you opened. Say "passing" only with
the output that shows it. A task with a known failure or a skipped check is not
done, and is reported as not done.

## Status and honesty

Nothing protocol-related exists yet, so nothing here conforms to anything.
Specifically: the `MAX_*` bounds in `sip` and `diameter` are placeholders; the
release thresholds for the `epc` and `5gc` bindings are not extracted (IMS-OP-07),
so both bindings refuse to start; the test bed runs PyHSS and Redis only, on a
network with no way in yet; Kamailio IMS is not configured. Say so rather than
building on any of it as if it were real.
