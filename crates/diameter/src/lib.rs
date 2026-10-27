//! Diameter base and Cx (stub). Nothing is implemented in the bootstrap; the entry point exists so
//! that the fuzz target and CI have something real to call (IMS-SEC-003).
#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::indexing_slicing)
)]

/// Placeholder bound on message size in bytes; to be set in I1 design.
pub const MAX_MESSAGE_BYTES: usize = 65_536;
/// Placeholder bound on AVP count; to be set in I1 design.
pub const MAX_AVPS: usize = 128;

/// Errors from [`decode`].
#[derive(Debug, Clone, Copy, PartialEq, Eq, thiserror::Error)]
pub enum Error {
    /// Not implemented yet.
    #[error("not implemented")]
    NotImplemented,
}

/// Parse a Diameter message from untrusted bytes.
pub fn decode(_input: &[u8]) -> Result<(), Error> {
    Err(Error::NotImplemented)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stub_refuses_everything() {
        assert_eq!(decode(b""), Err(Error::NotImplemented));
        assert_eq!(decode(&[0xff; 16]), Err(Error::NotImplemented));
    }
}
