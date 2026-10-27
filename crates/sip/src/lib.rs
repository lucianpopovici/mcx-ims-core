//! SIP/SDP (stub). Nothing is implemented in the bootstrap; the entry point exists so
//! that the fuzz target and CI have something real to call (IMS-SEC-003).
#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::indexing_slicing)
)]

/// Placeholder bound on message size in bytes; to be set in I1 design.
pub const MAX_MESSAGE_BYTES: usize = 65_536;
/// Placeholder bound on header count; to be set in I1 design.
pub const MAX_HEADERS: usize = 128;

/// Errors from [`parse`].
#[derive(Debug, Clone, Copy, PartialEq, Eq, thiserror::Error)]
pub enum Error {
    /// Not implemented yet.
    #[error("not implemented")]
    NotImplemented,
}

/// Parse a SIP message from untrusted bytes.
pub fn parse(_input: &[u8]) -> Result<(), Error> {
    Err(Error::NotImplemented)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stub_refuses_everything() {
        assert_eq!(parse(b""), Err(Error::NotImplemented));
        assert_eq!(parse(&[0xff; 16]), Err(Error::NotImplemented));
    }
}
