//! The scscf entity. Bootstrap stub: no listener, no protocol.

use config::Config;
use std::process::ExitCode;

const ENTITY: &str = "scscf";
const GIT_COMMIT: &str = env!("BUILD_GIT_COMMIT");

fn main() -> ExitCode {
    // JSON records on stderr; the default timer formats timestamps in UTC.
    let _ = tracing_subscriber::fmt()
        .json()
        .with_writer(std::io::stderr)
        .try_init();

    let cfg = match Config::from_env() {
        Ok(cfg) => cfg,
        Err(e) => {
            for defect in &e.defects {
                tracing::error!(entity = ENTITY, defect = %defect, "invalid configuration");
            }
            return ExitCode::from(2);
        }
    };

    tracing::info!(
        entity = ENTITY,
        version = env!("CARGO_PKG_VERSION"),
        git_commit = GIT_COMMIT,
        release = %cfg.release,
        access_binding = %cfg.binding,
        "start"
    );
    ExitCode::SUCCESS
}
