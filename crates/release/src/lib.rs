//! Supported 3GPP releases. This is the only module in the workspace where
//! release numbers appear (IMS-GEN-005, IMS-OP-07). There is deliberately no
//! `Default`: the release is chosen at start (IMS-OP-07).
#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::indexing_slicing)
)]

use core::fmt;

/// A supported 3GPP release.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum Release {
    /// Release 13.
    Rel13,
    /// Release 14.
    Rel14,
    /// Release 15.
    Rel15,
    /// Release 16.
    Rel16,
    /// Release 17.
    Rel17,
    /// Release 18.
    Rel18,
    /// Release 19.
    Rel19,
    /// Release 20.
    Rel20,
}

/// Every supported release, in ascending order.
pub const SUPPORTED: [Release; 8] = [
    Release::Rel13,
    Release::Rel14,
    Release::Rel15,
    Release::Rel16,
    Release::Rel17,
    Release::Rel18,
    Release::Rel19,
    Release::Rel20,
];

/// A release string was refused.
#[derive(Debug, Clone, Copy, PartialEq, Eq, thiserror::Error)]
pub enum ReleaseError {
    /// Not exactly one of the supported release numbers as ASCII digits.
    #[error("not a supported release (expected one of 13 to 20, ASCII digits only)")]
    Unsupported,
}

impl Release {
    /// Parse a release number. Accepts exactly the supported numbers as
    /// ASCII digits: no sign, no whitespace, no leading zeros, no other
    /// script's digits.
    pub fn parse(s: &str) -> Result<Release, ReleaseError> {
        match s {
            "13" => Ok(Release::Rel13),
            "14" => Ok(Release::Rel14),
            "15" => Ok(Release::Rel15),
            "16" => Ok(Release::Rel16),
            "17" => Ok(Release::Rel17),
            "18" => Ok(Release::Rel18),
            "19" => Ok(Release::Rel19),
            "20" => Ok(Release::Rel20),
            _ => Err(ReleaseError::Unsupported),
        }
    }

    /// The release number.
    pub fn number(self) -> u8 {
        match self {
            Release::Rel13 => 13,
            Release::Rel14 => 14,
            Release::Rel15 => 15,
            Release::Rel16 => 16,
            Release::Rel17 => 17,
            Release::Rel18 => 18,
            Release::Rel19 => 19,
            Release::Rel20 => 20,
        }
    }
}

impl fmt::Display for Release {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.number())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_supported_value_round_trips() {
        for r in SUPPORTED {
            assert_eq!(Release::parse(&r.to_string()), Ok(r));
        }
    }

    #[test]
    fn supported_is_ascending_and_complete() {
        let nums: Vec<u8> = SUPPORTED.iter().map(|r| r.number()).collect();
        assert_eq!(nums, (13..=20).collect::<Vec<u8>>());
    }

    #[test]
    fn refuses_everything_else() {
        for s in [
            "0",
            "12",
            "21",
            "",
            " 17",
            "17 ",
            "017",
            "+17",
            "-17",
            "17\n",
            "\u{0661}\u{0667}", // Arabic-Indic digits
            "\u{ff11}\u{ff17}", // fullwidth digits
        ] {
            assert_eq!(Release::parse(s), Err(ReleaseError::Unsupported), "{s:?}");
        }
    }
}
