//! Startup configuration read from the environment. Every variable is
//! required and has no default; every defect is reported together
//! (IMS-GEN-004, IMS-GEN-006).
#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::indexing_slicing)
)]

use binding::{AccessBinding, binding_allowed};
use core::fmt;
use release::Release;
use std::ffi::OsString;

/// Environment variable naming the 3GPP release.
pub const VAR_RELEASE: &str = "IMS_RELEASE";
/// Environment variable naming the access binding.
pub const VAR_ACCESS_BINDING: &str = "IMS_ACCESS_BINDING";
/// Prefix reserved for this product's variables.
pub const VAR_PREFIX: &str = "IMS_";

/// One defect found in the configuration.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum Defect {
    /// A required variable is not set.
    #[error("{0}: required variable is not set")]
    Missing(&'static str),
    /// A variable is set but is not valid UTF-8.
    #[error("{0}: value is not valid UTF-8")]
    NotUnicode(&'static str),
    /// A variable has a value that is not accepted.
    #[error("{var}: {reason}")]
    Invalid {
        /// The variable.
        var: &'static str,
        /// Why the value was refused.
        reason: String,
    },
    /// An `IMS_*` variable that this product does not know.
    #[error("{0}: unknown variable")]
    Unknown(String),
}

/// All defects found; never empty.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConfigError {
    /// The defects, in a stable order.
    pub defects: Vec<Defect>,
}

impl fmt::Display for ConfigError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        for (i, d) in self.defects.iter().enumerate() {
            if i > 0 {
                f.write_str("; ")?;
            }
            write!(f, "{d}")?;
        }
        Ok(())
    }
}

impl std::error::Error for ConfigError {}

/// Validated startup configuration.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Config {
    /// Selected 3GPP release.
    pub release: Release,
    /// Selected access binding.
    pub binding: AccessBinding,
}

impl Config {
    /// Read the configuration from the process environment.
    pub fn from_env() -> Result<Config, ConfigError> {
        Config::from_vars(std::env::vars_os())
    }

    /// Build the configuration from explicit variables.
    pub fn from_vars<I>(vars: I) -> Result<Config, ConfigError>
    where
        I: IntoIterator<Item = (OsString, OsString)>,
    {
        let mut release_raw: Option<OsString> = None;
        let mut binding_raw: Option<OsString> = None;
        let mut defects = Vec::new();

        for (k, v) in vars {
            let name = k.to_string_lossy();
            if name == VAR_RELEASE {
                release_raw = Some(v);
            } else if name == VAR_ACCESS_BINDING {
                binding_raw = Some(v);
            } else if name.starts_with(VAR_PREFIX) {
                defects.push(Defect::Unknown(name.into_owned()));
            }
        }
        defects.sort_by_key(|d| d.to_string());

        let mut head = Vec::new();
        let release = match release_raw {
            None => {
                head.push(Defect::Missing(VAR_RELEASE));
                None
            }
            Some(raw) => match raw.to_str() {
                None => {
                    head.push(Defect::NotUnicode(VAR_RELEASE));
                    None
                }
                Some(s) => match Release::parse(s) {
                    Ok(r) => Some(r),
                    Err(e) => {
                        head.push(Defect::Invalid {
                            var: VAR_RELEASE,
                            reason: e.to_string(),
                        });
                        None
                    }
                },
            },
        };
        let binding = match binding_raw {
            None => {
                head.push(Defect::Missing(VAR_ACCESS_BINDING));
                None
            }
            Some(raw) => match raw.to_str() {
                None => {
                    head.push(Defect::NotUnicode(VAR_ACCESS_BINDING));
                    None
                }
                Some(s) => match AccessBinding::parse(s) {
                    Ok(b) => Some(b),
                    Err(e) => {
                        head.push(Defect::Invalid {
                            var: VAR_ACCESS_BINDING,
                            reason: e.to_string(),
                        });
                        None
                    }
                },
            },
        };

        if let (Some(r), Some(b)) = (release, binding)
            && let Err(e) = binding_allowed(b, r)
        {
            head.push(Defect::Invalid {
                var: VAR_ACCESS_BINDING,
                reason: e.to_string(),
            });
        }

        head.extend(defects);
        match (release, binding, head.is_empty()) {
            (Some(release), Some(binding), true) => Ok(Config { release, binding }),
            _ => Err(ConfigError { defects: head }),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn vars(pairs: &[(&str, &str)]) -> Vec<(OsString, OsString)> {
        pairs
            .iter()
            .map(|(k, v)| (OsString::from(k), OsString::from(v)))
            .collect()
    }

    #[test]
    fn valid_configuration() {
        let c = Config::from_vars(vars(&[
            ("IMS_RELEASE", "17"),
            ("IMS_ACCESS_BINDING", "none"),
        ]));
        assert_eq!(
            c,
            Ok(Config {
                release: Release::parse("17").unwrap(),
                binding: AccessBinding::None
            })
        );
    }

    #[test]
    fn both_missing_both_reported() {
        let e = Config::from_vars(vars(&[("PATH", "/bin")])).unwrap_err();
        assert_eq!(
            e.defects,
            vec![
                Defect::Missing(VAR_RELEASE),
                Defect::Missing(VAR_ACCESS_BINDING)
            ]
        );
        let text = e.to_string();
        assert!(text.contains("IMS_RELEASE") && text.contains("IMS_ACCESS_BINDING"));
    }

    #[test]
    fn unknown_ims_variables_are_defects_listed_by_name() {
        let e = Config::from_vars(vars(&[
            ("IMS_RELEASE", "17"),
            ("IMS_ACCESS_BINDING", "none"),
            ("IMS_BOGUS", "1"),
            ("IMS_AAA", "1"),
        ]))
        .unwrap_err();
        assert_eq!(
            e.defects,
            vec![
                Defect::Unknown("IMS_AAA".into()),
                Defect::Unknown("IMS_BOGUS".into())
            ]
        );
    }

    #[test]
    fn invalid_values_and_unknown_all_reported() {
        let e = Config::from_vars(vars(&[
            ("IMS_RELEASE", "21"),
            ("IMS_ACCESS_BINDING", "lte"),
            ("IMS_X", "1"),
        ]))
        .unwrap_err();
        assert_eq!(e.defects.len(), 3);
    }

    #[test]
    fn epc_is_refused_in_i1() {
        let e = Config::from_vars(vars(&[
            ("IMS_RELEASE", "17"),
            ("IMS_ACCESS_BINDING", "epc"),
        ]))
        .unwrap_err();
        assert_eq!(e.defects.len(), 1);
        assert!(matches!(
            e.defects[0],
            Defect::Invalid {
                var: VAR_ACCESS_BINDING,
                ..
            }
        ));
    }

    #[cfg(unix)]
    #[test]
    fn non_utf8_value_is_a_defect() {
        use std::os::unix::ffi::OsStringExt;
        let e = Config::from_vars(vec![
            (
                OsString::from("IMS_RELEASE"),
                OsString::from_vec(vec![0xff, 0xfe]),
            ),
            (OsString::from("IMS_ACCESS_BINDING"), OsString::from("none")),
        ])
        .unwrap_err();
        assert_eq!(e.defects, vec![Defect::NotUnicode(VAR_RELEASE)]);
    }
}
