//! Access binding (IMS-GEN-004). There is deliberately no `Default`: the
//! binding is chosen at start.
#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::indexing_slicing)
)]

use core::fmt;
use release::Release;

/// How the IMS core attaches to the access network.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum AccessBinding {
    /// No access network interaction.
    None,
    /// EPC (4G) access.
    Epc,
    /// 5GC access.
    FiveGc,
}

/// A binding string was refused.
#[derive(Debug, Clone, Copy, PartialEq, Eq, thiserror::Error)]
pub enum ParseError {
    /// Not exactly `none`, `epc` or `5gc`.
    #[error("not a known access binding (expected none, epc or 5gc)")]
    Unknown,
}

/// A binding is not usable with the selected release.
#[derive(Debug, Clone, Copy, PartialEq, Eq, thiserror::Error)]
pub enum BindingError {
    /// Not implemented in I1.
    #[error("access binding not yet implemented")]
    NotYetImplemented,
}

impl AccessBinding {
    /// Parse a binding name. Accepts exactly `none`, `epc` and `5gc`.
    pub fn parse(s: &str) -> Result<AccessBinding, ParseError> {
        match s {
            "none" => Ok(AccessBinding::None),
            "epc" => Ok(AccessBinding::Epc),
            "5gc" => Ok(AccessBinding::FiveGc),
            _ => Err(ParseError::Unknown),
        }
    }

    /// The canonical name.
    pub fn name(self) -> &'static str {
        match self {
            AccessBinding::None => "none",
            AccessBinding::Epc => "epc",
            AccessBinding::FiveGc => "5gc",
        }
    }
}

impl fmt::Display for AccessBinding {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.name())
    }
}

/// Whether `binding` may be used with `release`.
pub fn binding_allowed(binding: AccessBinding, _release: Release) -> Result<(), BindingError> {
    match binding {
        AccessBinding::None => Ok(()),
        // threshold: to be extracted (IMS-OP-07)
        AccessBinding::Epc | AccessBinding::FiveGc => Err(BindingError::NotYetImplemented),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_exact_names_only() {
        assert_eq!(AccessBinding::parse("none"), Ok(AccessBinding::None));
        assert_eq!(AccessBinding::parse("epc"), Ok(AccessBinding::Epc));
        assert_eq!(AccessBinding::parse("5gc"), Ok(AccessBinding::FiveGc));
        for s in ["", "None", "EPC", " epc", "5GC", "5g", "epc "] {
            assert_eq!(AccessBinding::parse(s), Err(ParseError::Unknown), "{s:?}");
        }
    }

    #[test]
    fn names_round_trip() {
        for b in [
            AccessBinding::None,
            AccessBinding::Epc,
            AccessBinding::FiveGc,
        ] {
            assert_eq!(AccessBinding::parse(&b.to_string()), Ok(b));
        }
    }

    #[test]
    fn only_none_is_allowed_in_i1() {
        for r in release::SUPPORTED {
            assert_eq!(binding_allowed(AccessBinding::None, r), Ok(()));
            assert_eq!(
                binding_allowed(AccessBinding::Epc, r),
                Err(BindingError::NotYetImplemented)
            );
            assert_eq!(
                binding_allowed(AccessBinding::FiveGc, r),
                Err(BindingError::NotYetImplemented)
            );
        }
    }
}
