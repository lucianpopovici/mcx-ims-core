# Decisions

One line per decided open point of [IMS-SRS](IMS-SRS.md) (v0.7). Do not reopen; if one blocks work, ask the owner.

- **IMS-OP-03** (2026-10-26): Rust; one Cargo workspace with a crate per entity (`pcscf`, `scscf`, `hss`) and shared protocol crates (`sip`, `diameter`); separate repository from `mcx-platform`. Source: IMS-SRS §IMS-OP-03.
- **IMS-OP-05** (2026-10-26): the HSS is the master for which users exist where the deployment has one; otherwise the platform's network profile is. Source: IMS-SRS §IMS-OP-05, IMS-HSS-007.
- **IMS-OP-07** (2026-10-26): the platform's release set Rel-13 to Rel-20, one release selected at start with no default, release numbers in exactly one module (`crates/release`); access bindings the release cannot carry refuse startup. Boundaries are extracted from the 3GPP originals, never from memory. Source: IMS-SRS §IMS-OP-07, IMS-GEN-005.
- **IMS-OP-08** (2026-10-26): Kamailio (IMS modules) is the third-party CSCF and PyHSS the third-party HSS in the test bed. Source: IMS-SRS §IMS-OP-08.
- **IMS-OP-09** (2026-10-26, roadmap): Sh is a later phase, provisionally I3. Until then the generated snapshot of IMS-OP-05 is how HSS data reaches the platform. Source: IMS-SRS §IMS-OP-09, IMS-HSS-008.

## Known future exception

`unsafe_code = "forbid"` (workspace lint) will need one reviewed exception for the IPsec XFRM netlink code in I2 (IMS-REG-004). It is **not** created yet.
