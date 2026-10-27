#!/bin/sh
# Build the PyHSS image from a pinned upstream commit using upstream's own
# docker/Dockerfile. No maintained image with a pinned tag exists upstream
# (only the moving `development` tag).
# Usage: testbed/pyhss/build.sh
set -eu
COMMIT=953dc480a3497753c1c0a618a0c0f932df82526f   # nickvsnetworking/pyhss master, 2026-10-22
TAG=localhost/mcx-ims-core-pyhss:953dc480a349
exec podman build -f docker/Dockerfile -t "$TAG" \
    "https://github.com/nickvsnetworking/pyhss.git#${COMMIT}"
