# mcx-ims-core

An in-house SIP/IMS core written in Rust: P-CSCF, S-CSCF and HSS, with I-CSCF and IBCF to follow. It is the IMS layer for a mission-critical push-to-talk platform (MCX/FRMCS). Requirements are in [`docs/IMS-SRS.md`](docs/IMS-SRS.md).

It is a separate product from [`mcx-platform`](https://github.com/lucianpopovici/mcx-platform) (Python) and shares no code, path or git dependency with it. The platform must keep passing against Kamailio and Asterisk as well.

## Status

Bootstrap. The workspace, toolchain, CI gates and development environment exist; **no protocol is implemented**.
