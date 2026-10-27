# Development

Linux with a C toolchain, `pkg-config` and git. Container work needs podman (or docker) with compose.

## Toolchain (pinned)

| What | Version |
|---|---|
| Rust stable (`rust-toolchain.toml`) | 1.99.1 |
| Rust nightly, fuzzing only (`fuzz/rust-toolchain.toml`) | nightly-2026-10-26 (rustc 1.101.0-nightly) |
| cargo-nextest | 0.9.150 |
| cargo-deny | 0.20.2 |
| cargo-fuzz | 0.13.2 |
| cargo-llvm-cov | 0.9.1 (coverage, informational in I1) |
| actions/checkout | v7.0.1 (`3d3c42e5aac5ba805825da76410c181273ba90b1`) |
| taiki-e/install-action | v2.87.32 (`5488ac5a951645ce95062214902ac4b6bc1a1037`) |

```sh
rustup toolchain install 1.99.1 --profile minimal -c rustfmt -c clippy -c llvm-tools
rustup toolchain install nightly-2026-10-26 --profile minimal -c llvm-tools
cargo install --locked cargo-nextest@0.9.150 cargo-deny@0.20.2 cargo-fuzz@0.13.2 cargo-llvm-cov@0.9.1
```

## Gates locally

```sh
cargo fmt --all --check
cargo clippy --workspace --all-targets -- -D warnings
cargo nextest run --workspace && cargo test --workspace --doc
cargo deny check
tools/gates/selftest.sh all
tools/gates/independence.sh && tools/gates/release_literals.sh && tools/gates/no_defaults.sh
```

## Running a bin

Both variables are required; there is no default.

```sh
IMS_RELEASE=17 IMS_ACCESS_BINDING=none cargo run -p hss
```

## Fuzzing

```sh
cd fuzz
cargo fuzz run sip_parse -- -max_total_time=60
cargo fuzz run diameter_decode -- -max_total_time=60
```

`fuzz/` is not a workspace member and uses its own pinned nightly.

## Test bed

See [testbed/README.md](../testbed/README.md).

## Test-bed images (pinned)

| What | Pin |
|---|---|
| Redis | `docker.io/library/redis:7.0.15-alpine@sha256:0a34d7c44fe60c6ba273c0cddc26d1571a5ccd69280623a66b70393231a9eed9` |
| PyHSS | built from `nickvsnetworking/pyhss` commit `953dc480a3497753c1c0a618a0c0f932df82526f`, tagged `localhost/mcx-ims-core-pyhss:953dc480a349` |
