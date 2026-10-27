# Test bed

Third-party peers for the I1 interop tests (IMS-OP-08): Kamailio with its IMS modules as CSCF, PyHSS (with Redis) as HSS.

## Status

| Part | State |
|---|---|
| Redis `7.0.15-alpine` | defined in `compose.yaml` |
| PyHSS (`hss` role) | defined; image built from upstream commit `953dc480a3497753c1c0a618a0c0f932df82526f` (nickvsnetworking/pyhss, 2026-10-22) by `pyhss/build.sh` |
| Kamailio IMS (P-, S-, I-CSCF) | **next task**, not part of the bootstrap |

Not yet verified: the image build and the compose start have not been run.

## Bring up

```sh
testbed/pyhss/build.sh                     # builds localhost/mcx-ims-core-pyhss:953dc480a349
podman compose -f testbed/compose.yaml up -d
podman compose -f testbed/compose.yaml ps
podman compose -f testbed/compose.yaml logs pyhss_hss
podman compose -f testbed/compose.yaml down
```

The network is private (`internal: true`); no port is published. The Diameter and API roles of PyHSS are added when the CSCF side exists.

## Next task: Kamailio IMS

A substantial configuration of its own: P-, S- and I-CSCF, with Cx through its Diameter peer module towards PyHSS. Pin the Kamailio image by version or digest.
