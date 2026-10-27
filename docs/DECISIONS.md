# Decisions

One line per decided open point of [IMS-SRS](IMS-SRS.md) (v0.7). Do not reopen; if one blocks work, ask the owner.

- **IMS-OP-03** (2026-10-26): Rust; one Cargo workspace with a crate per entity (`pcscf`, `scscf`, `hss`) and shared protocol crates (`sip`, `diameter`); separate repository from `mcx-platform`. Source: IMS-SRS §IMS-OP-03.
- **IMS-OP-05** (2026-10-26): the HSS is the master for which users exist where the deployment has one; otherwise the platform's network profile is. Source: IMS-SRS §IMS-OP-05, IMS-HSS-007.
- **IMS-OP-07** (2026-10-26): the platform's release set Rel-13 to Rel-20, one release selected at start with no default, release numbers in exactly one module (`crates/release`); access bindings the release cannot carry refuse startup. Boundaries are extracted from the 3GPP originals, never from memory. Source: IMS-SRS §IMS-OP-07, IMS-GEN-005.
- **IMS-OP-08** (2026-10-26): Kamailio (IMS modules) is the third-party CSCF and PyHSS the third-party HSS in the test bed. Source: IMS-SRS §IMS-OP-08.
- **IMS-OP-09** (2026-10-26, roadmap): Sh is a later phase, provisionally I3. Until then the generated snapshot of IMS-OP-05 is how HSS data reaches the platform. Source: IMS-SRS §IMS-OP-09, IMS-HSS-008.

## Owner rulings

- **2026-10-27, one implementation per protocol.** Each protocol is implemented once, in a protocol crate; one protocol library or one per protocol, either is acceptable (one per protocol chosen: `sip`, `diameter`, and `sdp` when it is split out). Covers the Cargo workspace only: the conformance suite may use any language and library. Source: `CONTRIBUTING.md` (Architecture).
- **2026-10-27, external libraries** are decided when each one is needed, not in advance. Source: `CONTRIBUTING.md` (Architecture).
- **2026-10-27, agents work by pull request** and never push to `main`; the owner merges. Source: `CLAUDE.md` (Making a change).
- **2026-10-27, mutation testing and independent review** are required for parsers, protocol state machines, trust-domain, authentication and credential code, and the gate scripts; optional elsewhere. Source: `CONTRIBUTING.md` (Verification).
- **2026-10-27, `CLAUDE.md`** is committed, on the platform's model, and points to `CONTRIBUTING.md` instead of repeating it. Agent memory (`kb/`) stays local and git-ignored, as in the platform. `docs/IMS-SRS.md` in this repository is the authoritative copy of the requirements.

## Known future exception

`unsafe_code = "forbid"` (workspace lint) will need one reviewed exception for the IPsec XFRM netlink code in I2 (IMS-REG-004). It is **not** created yet.
