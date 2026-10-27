//! Exit-code and start-record tests for the hss binary (IMS-GEN-004/006).
#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::indexing_slicing)
)]

use std::process::{Command, Output};

fn run(vars: &[(&str, &str)]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_hss"))
        .env_clear()
        .envs(vars.iter().copied())
        .output()
        .unwrap()
}

#[test]
fn no_variables_exits_2_naming_both_defects() {
    let out = run(&[]);
    let err = String::from_utf8(out.stderr).unwrap();
    assert_eq!(out.status.code(), Some(2));
    assert!(err.contains("IMS_RELEASE"), "{err}");
    assert!(err.contains("IMS_ACCESS_BINDING"), "{err}");
}

#[test]
fn valid_variables_exit_0_with_full_start_record() {
    let out = run(&[("IMS_RELEASE", "17"), ("IMS_ACCESS_BINDING", "none")]);
    let err = String::from_utf8(out.stderr).unwrap();
    assert_eq!(out.status.code(), Some(0), "{err}");
    for field in [
        "\"entity\":\"hss\"",
        "\"version\":\"",
        "\"git_commit\":\"",
        "\"release\":\"17\"",
        "\"access_binding\":\"none\"",
    ] {
        assert!(err.contains(field), "missing {field} in {err}");
    }
}

#[test]
fn epc_exits_2() {
    let out = run(&[("IMS_RELEASE", "17"), ("IMS_ACCESS_BINDING", "epc")]);
    assert_eq!(out.status.code(), Some(2));
}
