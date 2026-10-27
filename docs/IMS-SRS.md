# MC SIP/IMS core — Software Requirements Specification

**Document:** IMS-SRS
**Version:** 0.8 (draft)
**Date:** 2026-10-27
**Status:** Draft for review — not baselined

---

## 1. Purpose and scope

### 1.1 Purpose

This document specifies the requirements for a SIP/IMS core built for the
mission-critical services platform (PLT-SRS). It provides the TS 23.280 *SIP
core* that the MC service servers sit behind: registration and authentication of
MC clients, identity assertion, routing to the MC application servers, priority
handling and, in later phases, policy control and interconnection.

### 1.2 Relation to PLT-SRS

PLT-SRS §1.2 places the SIP/IMS core out of scope, and PLT-SIG-001 requires the
platform to work with any third-party SIP core. Both stand. This core is a
**separate product** built alongside the platform. It is neither a dependency of
the platform nor a component inside it:

- The platform shall continue to pass VP1-SIG-001 against third-party cores.
  Kamailio and Asterisk stay in the interoperability matrix as reference
  implementations, and this core is added as a third.
- Whether this core later replaces Kamailio in deployments is decided on
  evidence once the I1 and I2 exit criteria are met (IMS-OP-01). It is not
  assumed here.

PLT-SRS §1.2 and OP-05 need a one-line amendment recording that an in-house
core exists as one candidate (IMS-OP-02).

### 1.3 Product concept

The core implements the minimum IMS functions an MC system needs, and nothing
for its own sake. It needs no voice telephony services, no CS interworking, no
E-CSCF (MC emergency is an MC service, not IMS emergency), and no charging
beyond records. Functions are separable by reference point so that each one
can be swapped for a third-party equivalent and tested against it.

As with the platform, the core is **profile-agnostic**. It does not know whether
the MC system above it is an MCX or an FRMCS deployment. What does differ
between deployments is the **access binding** (none, EPC or 5GC), selected at
deployment time.

### 1.4 Functional entities

| Entity | Role here | Phase |
|---|---|---|
| P-CSCF | UE-facing edge: transport security, identity assertion, header policing, priority policing, policy control towards PCRF/PCF | I1 (policy I3) |
| S-CSCF | Registrar, authentication, iFC evaluation, third-party registration, routing to the MC servers | I1 |
| HSS | Subscriber store: IMPI, IMPU, credentials, service profiles with iFC, S-CSCF assignment | I1 |
| I-CSCF | Entry point when more than one S-CSCF exists, or for inbound interconnection | I3 |
| IBCF | Border towards partner MC systems' SIP cores (SIP-3) | I3 |

### 1.5 Definitions

| Term | Meaning |
|---|---|
| MC server | Any MC service server of the platform acting as IMS application server |
| Access binding | The deployment's access network type: `none` (SIP over IP), `epc` or `5gc` |
| Trust domain | The set of entities that may assert identity to each other (RFC 3325) |
| iFC | Initial filter criteria (TS 29.228) |
| ICSI | IMS communication service identifier |

### 1.6 Requirement notation

`IMS-<AREA>-<nnn>`, with the same modal verbs and verification methods as
PLT-SRS §1.5 (**T** test, **D** demonstration, **A** analysis, **I** inspection).

### 1.7 Release phases

The phases are aligned with the platform's R phases. The core is never the
reason a platform phase cannot exit.

| Phase | Content | Exit criterion |
|---|---|---|
| **I1** | P-CSCF, S-CSCF and HSS over SIP/TLS with access binding `none`; digest authentication; iFC to the MC servers; third-party registration; identity assertion and policing | Platform VP1-SIG-001 passes against this core, with no platform configuration specific to it, and still passes against Kamailio and Asterisk. IMS conformance suite green. |
| **I2** | Priority and Resource-Priority, registration event package, overload control, redundancy and restart without loss of registrations, IMS-AKA | Emergency group call (platform R2) set up through this core under the configured load, with priority honoured end to end |
| **I3** | Access bindings `epc` (Gm, Rx) and `5gc` (N5, Nhss), I-CSCF and multiple S-CSCFs, IBCF for interconnection | FRMCS profile's R3 suite green over 5GC through this core; a partner core reaches the platform only through the IBCF |
| **I4** | As required by platform R4 (interworking, MBS); scope to be set at R4 planning | — |

---

## 2. Applicable documents

### 2.1 3GPP

| Ref | Title |
|---|---|
| TS 23.228 | IMS stage 2 |
| TS 23.280 | Common functional architecture for MC services (SIP core, SIP-1/2/3) |
| TS 23.379 | Functional architecture for MCPTT |
| TS 24.229 | IP multimedia call control protocol based on SIP and SDP (stage 3) |
| TS 24.379 | MCPTT call control protocol |
| TS 29.228 / 29.229 | Cx/Dx interface: signalling flows and Diameter protocol details |
| TS 29.214 | Rx reference point (policy and charging control) |
| TS 29.514 | Npcf_PolicyAuthorization (N5) |
| TS 29.562 | Nhss IMS services (HSS in 5GC) |
| TS 33.203 | Access security for IMS (IMS-AKA, sec-agree) |
| TS 33.210 | Network domain security (IP) |
| TS 23.003 | Numbering, addressing and identification |
| TS 32.409 | Telecommunication management; Performance Management (PM); performance measurements for the IMS (exact title to be confirmed from the original) |
| TS 32.454 | Telecommunication management; Key Performance Indicators (KPI) for the IMS; Definitions |

### 2.2 IETF

| Ref | Title |
|---|---|
| RFC 3261 | SIP |
| RFC 3263 | Locating SIP servers |
| RFC 3325 | Asserted identity within trusted networks |
| RFC 3327 / 3608 | Path / Service-Route |
| RFC 3329 | Security mechanism agreement |
| RFC 3455 | P-headers for 3GPP |
| RFC 3680 | Registration event package |
| RFC 4412 / 8101 | Resource-Priority / MCPTT namespaces |
| RFC 5627 | GRUU |
| RFC 6050 | P-Asserted-Service and P-Preferred-Service |
| RFC 6733 | Diameter base protocol |
| RFC 7339 | SIP overload control |

---

## 3. System context

### 3.1 External interfaces

| Interface | Between | Protocol | Phase |
|---|---|---|---|
| SIP-1 (Gm) | MC client ↔ P-CSCF | SIP over TLS (I1); IPsec with sec-agree (I2) | I1 |
| SIP-2 (ISC) | S-CSCF ↔ MC servers | SIP over TLS | I1 |
| SIP-3 | IBCF ↔ partner SIP core | SIP over TLS | I3 |
| Cx | CSCFs ↔ HSS | Diameter (RFC 6733, TS 29.229) | I1 |
| Rx / N5 | P-CSCF ↔ PCRF / PCF | Diameter / HTTP/2 | I3 |
| Sh | HSS ↔ MC servers | Diameter (TS 29.329) | I3 (IMS-OP-09) |
| Nhss_ims | CSCFs ↔ HSS in 5GC | HTTP/2 (TS 29.562) | I3 |
| OAM | Operator ↔ every entity | HTTPS | I1 |

### 3.2 Internal reference points

| Reference point | Between | Phase |
|---|---|---|
| Mw | P-CSCF ↔ S-CSCF (and I-CSCF) | I1 |

### 3.3 Architectural constraints

1. **The core shall not know which MC profile is in use.** Any requirement here
   that appears to need it is a defect in this document.
2. **The platform shall not know which SIP core it is behind.** No platform
   behaviour, test or configuration value may depend on this core being the
   one in use.

---

## 4. General (IMS-GEN)

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-GEN-001 | I1 | P-CSCF, S-CSCF and HSS shall be separately deployable, communicating only over their standard reference points (Mw, Cx). A single-process build combining them may exist for test, but shall use the same reference-point code. | I |
| IMS-GEN-002 | I1 | Each entity shall be replaceable by a third-party equivalent over its reference point with no change to the others' code. | D |
| IMS-GEN-003 | I1 | Source code of the core shall not import, link or copy code from the platform repository's `core/` or `service/` trees, and the platform shall not import from the core. Enforced as a CI gate. | I |
| IMS-GEN-004 | I1 | The core shall select exactly one access binding (`none`, `epc`, `5gc`) at start, from deployment configuration, with no default; it shall refuse to start otherwise. | T |
| IMS-GEN-005 | I1 | The core shall select exactly one 3GPP release at start, with no default, on the model of PLT-REL-001/002. | T |
| IMS-GEN-006 | I1 | Configuration shall be validated at start: unknown keys, unresolved references and missing values refuse startup, and all defects are reported together. | T |
| IMS-GEN-007 | I1 | The core shall provide no plaintext SIP or Diameter transport outside a development mode that is refused when a production indicator is set. | T |
| IMS-GEN-008 | I1 | Internal module boundaries corresponding to a 3GPP reference point shall be named after it (as PLT-PRF-032). | I |
| IMS-GEN-009 | I1 | All time values in configuration and logs shall be UTC; durations as PLT-GEN-011. | I |

---

## 5. Registration and authentication (IMS-REG)

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-REG-001 | I1 | The S-CSCF shall act as registrar for the public user identities of its served domains, and shall refuse registration for any other domain. | T |
| IMS-REG-002 | I1 | The S-CSCF shall authenticate every initial registration, and every re-registration when credentials or the binding change. No identity shall be registered unauthenticated. | T |
| IMS-REG-003 | I1 | The core shall support SIP digest authentication over TLS (TS 24.229, TS 33.203). | T |
| IMS-REG-004 | I2 | The core shall support IMS-AKA with IPsec security association set-up via sec-agree (RFC 3329, TS 33.203). | T |
| IMS-REG-005 | I1 | The P-CSCF shall insert a Path header and the S-CSCF shall return Service-Route (RFC 3327, RFC 3608), and the P-CSCF shall enforce the Service-Route on subsequent requests from that UE. | T |
| IMS-REG-006 | I1 | On successful registration, the S-CSCF shall perform third-party registration towards each MC server whose iFC matches (TS 24.229 5.4.1.7). | T |
| IMS-REG-007 | I1 | Third-party registration shall include the UE's original REGISTER request and/or the S-CSCF's 200 OK as message bodies where the iFC requests it (IncludeRegisterRequest, IncludeRegisterResponse, TS 29.228), so that the MC server receives the client's MC service information body. | T |
| IMS-REG-008 | I1 | Third-party de-registration shall be sent when a registration expires, is removed by the UE, or is removed administratively. | T |
| IMS-REG-009 | I1 | A failed third-party registration shall be handled per the iFC's default handling (session continued or terminated) and shall be recorded. | T |
| IMS-REG-010 | I2 | The core shall support the registration event package (RFC 3680) for UEs and for MC servers. | T |
| IMS-REG-011 | I2 | The core shall support public GRUU (RFC 5627) assigned per TS 24.229. | T |
| IMS-REG-012 | I2 | Registration state shall survive the restart of any single S-CSCF instance without requiring UEs to re-register. | T |
| IMS-REG-013 | I1 | A UE shall be able to register more than one public user identity under one private identity, each independently routable to the MC servers. | T |

---

## 6. Identity and trust (IMS-IDN)

These requirements make the core meet the **deployment requirements** that
PLT-ICD-001 places on any trusted core (ICD-OP-08, ICD-OP-10, ICD-NET-003/004),
which neither interop reference meets today.

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-IDN-001 | I1 | The P-CSCF shall remove any P-Asserted-Identity received from a UE, and from any peer outside the trust domain, before forwarding. | T |
| IMS-IDN-002 | I1 | The P-CSCF shall assert P-Asserted-Identity only with an identity registered and authenticated for the UE that sent the request, choosing from P-Preferred-Identity where it names one of those identities. | T |
| IMS-IDN-003 | I1 | A request from a UE that is not registered, or that arrives on a connection or security association other than the one bound to its registration, shall be rejected and not forwarded. | T |
| IMS-IDN-004 | I1 | The trust domain shall be declared explicitly in configuration as a list of peers authenticated by TLS certificate. A peer shall not be in the trust domain by IP address alone. | T |
| IMS-IDN-005 | I1 | The S-CSCF and P-CSCF shall present certificates from the deployment's core CA on SIP-2, and shall present no certificate asserting a user identity. | I |
| IMS-IDN-006 | I1 | The core shall remove P-Asserted-Identity, P-Asserted-Service and other trust-domain headers (RFC 3455, RFC 6050) on any hop leaving the trust domain. | T |
| IMS-IDN-007 | I1 | The P-CSCF shall assert P-Asserted-Service with the MCPTT, MCData or MCVideo ICSI only when the request carries the corresponding feature tags and the user's service profile includes that service; otherwise it shall reject the request. | T |
| IMS-IDN-008 | I1 | The core shall not alter the MC service feature tags, Accept-Contact header fields or MC service bodies of a request (PLT-CONF-AUDIT CA-06). | T |

---

## 7. Routing (IMS-ROU)

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-ROU-001 | I1 | The S-CSCF shall evaluate the served user's iFC in priority order for originating and terminating requests (TS 29.228), and shall route to the MC server named by the first match. | T |
| IMS-ROU-002 | I1 | iFC shall be able to trigger on method, on Request-URI, and on the feature tags and ICSI that identify each MC service. | T |
| IMS-ROU-003 | I1 | A request matching no iFC and addressed to an MC service shall be rejected, not routed by default. | T |
| IMS-ROU-004 | I1 | Requests from an MC server towards users shall be routed by the S-CSCF to the users' registered contacts through the P-CSCF recorded in Path. | T |
| IMS-ROU-005 | I1 | The core shall record-route so that every in-dialog request traverses the same entities, and shall pass session timer headers and in-dialog UPDATE and re-INVITE unchanged (RFC 4028). | T |
| IMS-ROU-006 | I1 | The core shall route requests addressed to a GRUU the MC server issued (per-session focus URIs) to that MC server. | T |
| IMS-ROU-007 | I1 | Server location shall use RFC 3263 (NAPTR, SRV, A/AAAA), with static configuration as an alternative. | T |
| IMS-ROU-008 | I3 | With more than one S-CSCF, the I-CSCF shall select one per TS 29.228 server assignment, and the HSS shall record it. | T |

---

## 8. Priority (IMS-PRI)

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-PRI-001 | I2 | The P-CSCF shall accept a Resource-Priority header (RFC 4412) only for namespaces and values the user's subscription authorises, and shall remove or reject it otherwise, per TS 24.229 priority handling. | T |
| IMS-PRI-002 | I2 | Priority namespaces and their values shall be configuration, not code. No namespace string shall appear as a literal outside the configuration loader (PLT-CONF-AUDIT CA-06c). | I |
| IMS-PRI-003 | I2 | Priority requests shall be processed ahead of others under load at every entity, and shall be exempt from overload throttling up to a configured reserved capacity. | T |
| IMS-PRI-004 | I2 | The core shall implement SIP overload control (RFC 7339) towards its peers. | T |

---

## 9. Subscriber store (IMS-HSS)

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-HSS-001 | I1 | The HSS shall store, per subscription: private identities, public identities, credentials, implicit registration sets, and the service profile with its iFC. | I |
| IMS-HSS-002 | I1 | The HSS shall implement Cx (UAR/UAA, SAR/SAA, MAR/MAA, LIR/LIA, RTR/RTA, PPR/PPA) over Diameter, with TLS or IPsec per TS 33.210. | T |
| IMS-HSS-003 | I1 | The CSCFs shall interoperate over Cx with at least one third-party HSS, and the HSS with at least one third-party CSCF (IMS-GEN-002). | D |
| IMS-HSS-004 | I1 | Credentials shall be stored only in a form from which the secret cannot be recovered where the authentication scheme permits, and shall never be logged. | I |
| IMS-HSS-005 | I1 | A change to a service profile shall be pushed to the assigned S-CSCF (PPR) without requiring re-registration. | T |
| IMS-HSS-007 | I1 | The HSS shall export the public user identities of its subscriptions in a form from which a tool, kept in this repository and importing nothing from the platform, generates the `users` of a platform network profile (IMS-OP-05). The tool shall refuse when a group member in the network profile is not in the export, and shall report every difference from the network profile in force. | T |
| IMS-HSS-008 | I3 | The HSS shall expose Sh (TS 29.328/29.329) to the MC servers: user data read (UDR), subscription to notifications (SNR) and notification of change (PNR), subject to IMS-OP-09. | T |
| IMS-HSS-006 | I3 | With access binding `5gc`, the HSS shall additionally expose Nhss_ims (TS 29.562). | T |

---

## 10. Policy control (IMS-POL)

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-POL-001 | I3 | With access binding `epc`, the P-CSCF shall support Rx towards the PCRF (TS 29.214); with `5gc`, N5 towards the PCF (TS 29.514). With `none` it shall make no policy request. | T |
| IMS-POL-002 | I3 | Which entity requests media QoS (the P-CSCF from SDP, or the MC server directly) shall be a deployment decision, and the two shall never both request for the same session (IMS-OP-04). | T |
| IMS-POL-003 | I3 | Loss of the signalling bearer reported by the PCRF/PCF shall trigger de-registration of the affected UE. | T |

---

## 11. Interconnection (IMS-ICX)

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-ICX-001 | I3 | Every request to or from a partner SIP core shall pass through the IBCF. | T |
| IMS-ICX-002 | I3 | The IBCF shall authenticate each partner core by TLS certificate, and shall admit only declared partners. | T |
| IMS-ICX-003 | I3 | The IBCF shall apply topology hiding, and shall strip trust-domain headers from partners not declared trusted. | T |
| IMS-ICX-004 | I3 | The IBCF shall pass nothing that would let a partner bypass the platform's PLT-ICX policy; priority asserted by a partner shall be carried, not mapped. Mapping is the platform's job (PLT-ICX-004). | A |

---

## 12. Security (IMS-SEC)

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-SEC-001 | I1 | All SIP and Diameter interfaces shall use TLS (or IPsec where specified), with mutual authentication between network entities. | T |
| IMS-SEC-002 | I1 | Every parser of untrusted input (SIP, SDP, Diameter, XML bodies) shall bound message size, header count and nesting, and shall reject rather than truncate. | T |
| IMS-SEC-003 | I1 | Every parser of untrusted input shall be fuzzed in CI. | I |
| IMS-SEC-004 | I1 | The core shall not log credentials, authentication vectors, keys or message bodies by default. | I |
| IMS-SEC-005 | I1 | Operational interfaces shall be authenticated separately from subscribers. | T |

---

## 13. Performance and availability (IMS-NFR)

> Provisional. To be set against PLT-NFR once OP-07 (load profile) is defined.

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-NFR-001 | I2 | The core shall add no more than a configured bound (initially 20 ms) to INVITE processing, P-CSCF in to S-CSCF out to the MC server, at the specified load. | T |
| IMS-NFR-002 | I2 | The core's contribution to group call setup shall leave PLT-NFR-001 achievable at the same load. | A |
| IMS-NFR-003 | I2 | Failure of a single instance of any entity shall not release established dialogs or lose registrations. | T |
| IMS-NFR-004 | I2 | Performance figures shall be measured under a documented load profile. | T |

---

## 14. Operations and audit (IMS-OAM)

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-OAM-001 | I1 | Every entity shall log its configuration identity (name, version, content hash), release and access binding at start, and expose them on its health endpoint. | T |
| IMS-OAM-002 | I1 | Registrations, de-registrations, authentication failures, third-party registration outcomes and rejected requests shall be recorded with reason. | T |
| IMS-OAM-003 | I1 | Logs shall be structured, with a correlation identifier that follows a request across entities: the ICID, as §14A specifies (IMS-TEL-003). | T |
| IMS-OAM-004 | I1 | Every entity shall expose liveness and readiness endpoints; readiness is false until configuration is validated and peers are reachable. | T |
| IMS-OAM-005 | I2 | Metrics: registrations by state, request rates and latency per method and entity, Cx latency, rejections by reason, overload state; and the TS 32.409 measurements and TS 32.454 KPIs of §14A.4. | T |

---

## 14A. Telemetry and failure location (IMS-TEL)

Every entity, and every role an entity plays, reports what happened to each
procedure it took part in. From those reports alone it shall be possible to say,
for a failed call or procedure, **where the failure began**: in which entity, at
which step, or on which link, as opposed to everywhere it was passed on.

A failure is usually seen in several places. A REGISTER refused because the HSS
does not know the user is answered 403 by the S-CSCF and relayed by the P-CSCF;
all three see a failure, and only one is its origin. The requirements below make
each entity say which of the three cases it is in, so that following the reports
leads to exactly one origin.

### 14A.1 Correlation

IMS already carries one key across its entities. TS 24.229 §4.5.2: the first IMS
entity on a transaction generates the IMS charging identifier (ICID) in
P-Charging-Vector; for a dialog it is generated on the initial request and used
for every later message of the dialog; the P-CSCF generates one for each
REGISTER (§5.2.2.1); the S-CSCF sends the same ICID in the third-party REGISTER
to the application server (§5.4.1.7, for initial registration and user-initiated
reregistration); and the P-CSCF removes P-Charging-Vector from everything it
receives from or sends to the UE, so an ICID is never taken from a UE (§5.2.1).
All five checked in V13.23.0 and V20.1.0; the releases between are to be
confirmed by the extraction of IMS-OP-07.

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-TEL-001 | I1 | Every entity shall emit a telemetry record for every procedure instance it takes part in, whether it succeeds or fails, naming the entity, the role it played, its instance, its configuration identity, release and access binding (IMS-OAM-001). An entity playing several roles (a combined test build, IMS-GEN-001) shall emit the records of each role under that role's name. | T |
| IMS-TEL-002 | I1 | Procedures and their steps shall be a closed, documented vocabulary: at least registration, reregistration, deregistration (UE-, network- and administratively initiated), third-party registration, session establishment, in-dialog request, session release, each Cx command (UAR, MAR, SAR, LIR, RTR, PPR), Diameter peer connection and watchdog, and TLS connection set-up. Every record shall name the procedure and the last step it reached. | I |
| IMS-TEL-003 | I1 | Every record of a SIP procedure shall carry its ICID. The core shall generate the ICID where TS 24.229 assigns that to it, and where a request reaches the core from inside the trust domain without one, the first entity of this core to handle it shall generate one. An ICID received from outside the trust domain shall not be used (§5.2.1). | T |
| IMS-TEL-004 | I1 | A record of a Diameter procedure shall carry its Session-Id and, at the CSCF that sent the request, the ICID of the SIP procedure it was made for, so the HSS's records join the SIP procedure without the HSS knowing the ICID. | T |
| IMS-TEL-005 | I1 | Every record of a request sent to an MC server shall carry its Call-ID and the ICID it carried, so that a procedure can be joined with the platform's own records by Call-ID without any change to the platform (§3.3 constraint 2). | T |
| IMS-TEL-006 | I1 | A record shall name each peer by its authenticated identity (the DNS name of its TLS certificate, or its Diameter Origin-Host), never by address alone. | T |

### 14A.2 Failure attribution

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-TEL-010 | I1 | Every record of a procedure that did not succeed shall state exactly one origin: **local** (this entity refused or failed it, with a reason code from a closed vocabulary that tells a policy refusal from a fault, and the step where it happened); **peer** (a named peer answered with a failure, with what it answered: SIP status and Warning, or Diameter Result-Code or Experimental-Result); **no-response** (a named peer did not answer, with the timer that expired); or **transport** (the connection to a named peer failed, with the TLS or transport error). | T |
| IMS-TEL-011 | I1 | When an entity passes a failure on, its record shall state both what it received and what it sent, so a translation (a Diameter result mapped to a SIP status, a status changed on the way) is visible where it happened. | T |
| IMS-TEL-012 | I1 | From the records of one procedure, the origin of a failure shall be determined mechanically: by following each **peer** origin to that peer's record, until a record states **local**, **no-response** or **transport**. Where the chain leads to a peer that emits no records (a third-party peer, the platform, a UE), the origin shall be reported as that peer, named. | T |
| IMS-TEL-013 | I1 | This repository shall provide a tool that, given telemetry and a key (an ICID, a Call-ID, a Diameter Session-Id, or a user identity and a time window), lists the records of the procedure in causal order and names the origin of its failure as IMS-TEL-012 defines it. | T |
| IMS-TEL-014 | I1 | Attribution shall not depend on comparing clocks between entities. The order of records is taken from what they reference (peer, transaction, ICID, Session-Id), and timestamps (UTC, milliseconds) only order the records of one entity. | A |

### 14A.3 Telemetry must not harm the service

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-TEL-020 | I1 | Emitting telemetry shall never block, delay or fail a procedure. Records wait in a bounded buffer; when it is full or the destination is unavailable, records are dropped, not waited for. | T |
| IMS-TEL-021 | I1 | Every dropped record shall be counted, and the count reported as a gap record (when, how many, of which procedures) as soon as records can be sent again, and on the health endpoint meanwhile. A missing record shall be distinguishable from a procedure that did not happen. | T |
| IMS-TEL-022 | I1 | Records shall carry no credential, authentication vector, key or message body (IMS-SEC-004). Subscriber identities shall be recorded as IMS-OP-11 decides. | I |
| IMS-TEL-023 | I1 | Telemetry sent off the host shall be sent over TLS with the destination authenticated. Its format and transport are as IMS-OP-10 decides. | T |

### 14A.4 Performance measurements and KPIs

TS 32.409 defines the standard performance measurements of the IMS functional
entities, and TS 32.454 the IMS key performance indicators built from them. Using
them means this core reports what an operator's management system already
expects, in the same terms as any other IMS. **Neither specification has been
read for this document**: until their originals are in `docs/3GPP/`, the
requirements below name no measurement and no KPI, and none is to be written
from memory.

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-TEL-030 | I2 | Each entity shall produce the performance measurements TS 32.409 defines for its function (P-CSCF, S-CSCF and HSS; I-CSCF and IBCF in I3), with the names, triggers and sub-counters the specification gives, read from its original for the configured release. | T |
| IMS-TEL-031 | I2 | Measurements shall be derived from the telemetry records of §14A.1 and §14A.2, not counted separately, so that a counter and the records of the procedures it counts cannot disagree. Each measurement's trigger shall be written as a procedure, step and outcome of IMS-TEL-002 and IMS-TEL-010; a trigger the records cannot express is a gap in the records, to be fixed there. | I |
| IMS-TEL-032 | I2 | The TS 32.454 KPIs that apply to the functions this core provides shall be computable from those measurements, each with its formula cited to its clause. KPIs that need data from outside the core (the UE, the access network, the MC servers) shall be listed with what they need, not approximated. | T |
| IMS-TEL-033 | I2 | A measurement or KPI that the specification version in use does not define shall not be produced. Which version is in use for each configured release is as IMS-OP-12 decides, and shall be reported at startup and in every measurement report. | T |
| IMS-TEL-034 | I2 | The measurement granularity period shall be a required deployment setting with no default. | T |

---

## 15. Verification (IMS-VER)

| ID | Phase | Requirement | V |
|---|---|---|---|
| IMS-VER-001 | I1 | The core shall have its own conformance suite, written from TS 24.229 and TS 29.228/29.229, independent of the platform's suites. | I |
| IMS-VER-002 | I1 | The conformance suite shall import nothing from the core's own SIP or Diameter code; its encoders and decoders are separate (as PLT-VP-R1's comparator). | I |
| IMS-VER-003 | I1 | The platform's VP1-SIG-001 run shall include this core alongside Kamailio and Asterisk on every change to either product, each repository's CI using a pinned build of the other. A failure against this core alone is a defect of the core until shown otherwise. | I |
| IMS-VER-004 | I1 | Each entity shall be exercised against a third-party peer over its reference point (IMS-GEN-002, IMS-HSS-003). | D |
| IMS-VER-005 | I1 | The trust-domain requirements of §6 shall each have a negative test: a forged, a missing and an unauthorised identity are each refused. | T |
| IMS-VER-006 | I2 | Each requirement shall trace to at least one verification artefact. | I |
| IMS-VER-007 | I1 | For each class of failure, a test shall cause it at each entity and on each link where it can occur, and shall show that the tool of IMS-TEL-013 names that entity and step, or that link, as the origin, and nothing else. The classes include at least: user unknown to the HSS; authentication failure; HSS unreachable; Diameter watchdog failure; TLS handshake failure; no iFC match; identity policing refusal at the P-CSCF; an MC server refusing a third-party REGISTER or an INVITE; a UE that does not answer; and telemetry lost in the middle of a procedure (IMS-TEL-021). | T |

---

## 16. Open points

| # | Question | Needed by |
|---|---|---|
| IMS-OP-01 | Criteria for this core replacing Kamailio in deployments. Proposed: I1 and I2 exit met, plus a defined soak period with no core-attributed defect. | I2 exit |
| IMS-OP-02 | Amend PLT-SRS §1.2 and OP-05 to record the in-house core as a candidate, without changing PLT-SIG-001. | now |
| IMS-OP-03 | **Language decided 2026-10-26: Rust.** Reasons: every entity parses untrusted SIP, SDP, Diameter and XML (IMS-SEC-002/003), where memory safety and `cargo-fuzz` matter most; the latency bound of IMS-NFR-001; protocol state machines as exhaustively matched enums; and a language other than the platform's makes IMS-GEN-003 structural. Layout: one Cargo workspace, a crate per entity (`pcscf`, `scscf`, `hss`) and shared protocol crates (`sip`, `diameter`), so shared code exists only at the protocol layer (IMS-GEN-001/002). The conformance suite stays outside the workspace and may use the existing Python Diameter parser as its independent Cx decoder (IMS-VER-002). Accepted costs: no mature Rust SIP or Diameter stack, so transaction layer and Diameter peer state machine are written here; kernel IPsec (XFRM over netlink) for IMS-AKA in I2 has thinner library support. If PLT-SRS OP-03 brings the core into SIL scope, a qualified toolchain (Ferrocene) is the route to evaluate. **Repository decided 2026-10-26: separate from `mcx-platform`.** The platform's reviewed build gates (PLT-VP-R1 VP1-BND batch D) stay untouched, IMS-GEN-003 holds by construction, and each repository's CI pulls a pinned build of the other for IMS-VER-003, so this core is tested the way Kamailio and Asterisk are. | closed |
| IMS-OP-04 | Who requests media QoS: the P-CSCF from SDP (classic IMS) or the MC server over Rx/N5 (PLT-SRS §3.1 gives Rx/N5 to the platform, and the platform's bearer selector hook returns QoS). Pick one per deployment, or one for all. | I3 start |
| IMS-OP-05 | **Decided 2026-10-26: the HSS is the master where the deployment has one; otherwise the network profile is.** Read with the platform's existing rules, which it does not change: the network profile stays the platform's only directory (PLT-VP-R1 SIP-OP-05, ICD-NET-005), and the platform never queries an HSS (§3.3 constraint 2). Where an HSS exists, the network profile's `users` are **generated** from it as a snapshot and redeployed, so every change is a new network identifier in the audit trail (ICD-NET-002); where none exists, they are written by hand as today. The HSS is master for which users exist only. Groups and functional aliases are MC data with no HSS equivalent and stay authored in the network profile; a group member absent from the HSS export is a generation error. A stale snapshot fails closed both ways: a user added to the HSS can register but is not callable (404/145), and a user removed from it cannot authenticate. See IMS-HSS-007. | closed |
| IMS-OP-06 | Whether an in-house replacement for Asterisk's role is needed at all, and as what: an IBCF (§11), an interworking gateway for platform R4, or none. | I3 planning |
| IMS-OP-07 | **Decided 2026-10-26: the platform's release set, Rel-13 to Rel-20, selected per deployment.** The core adopts the platform's release model: one release at start with no default (IMS-GEN-005), release numbers in exactly one module (as PLT-REL-008), and a well-formed construct the release does not define reported apart from malformed input (as PLT-REL-006). The core does not read or check the platform's release (§3.3); running both at the same release is a deployment rule. CI runs the interop matrix at matched releases, every release from 13 to 20; a mismatched pair is permitted but untested, and stated as such. An access binding the release cannot carry refuses startup, as `MCX_STRICT_RELEASE` does for call types: provisionally, `5gc` (N5) from Rel-15 and Nhss_ims from Rel-16. **These boundaries, and every other first-release boundary the core relies on, shall be extracted from the TS 24.229, 29.229, 29.514 and 29.562 originals in each release, not taken from this table** (the PLT-CONF-AUDIT lesson: an interpolated boundary is a guess with a citation attached). | closed |
| IMS-OP-08 | **CSCF decided 2026-10-26: Kamailio,** with its IMS modules (P-CSCF, S-CSCF, I-CSCF, Cx through its Diameter peer module). This is a second Kamailio configuration, separate from the plain record-routing proxy that VP1-SIG-001 uses today, and both are kept. **HSS decided 2026-10-26: PyHSS** (Kamailio provides none). It implements Cx and Sh and has been run with Kamailio's S-CSCF, so it is also the third-party Sh peer when IMS-HSS-008 arrives. The test pairs for IMS-GEN-002 and IMS-HSS-003 are therefore: our CSCFs with PyHSS, and Kamailio's CSCFs with our HSS. | closed |
| IMS-OP-10 | Telemetry format and transport (IMS-TEL-023). (a) OpenTelemetry, OTLP: procedures as spans, a standard collector and viewers (Jaeger, Tempo), at the cost of new external libraries (`opentelemetry`, `tracing-opentelemetry`); (b) structured JSON lines, collected by whatever the deployment uses (journald, Vector, Fluent Bit), read by this repository's tool, with no new library; (c) JSON lines now, an OTLP exporter added when a deployment needs one. **Recommended: (c).** The record schema is this project's either way and maps one to one onto spans, so (c) loses nothing later and adds no dependency now. | I1 start |
| IMS-OP-11 | Subscriber identities in telemetry (IMS-TEL-022). Telemetry is personal data: it says who registered, from where, when. (a) In clear; (b) pseudonymised with a keyed hash under a per-deployment key, so that whoever holds the key can search for a user (the tool hashes the identity given) but a reader of the telemetry cannot see who it is; (c) a required deployment setting choosing (a) or (b), with no default, the choice reported at startup. **Recommended: (c).** Troubleshooting needs to find one user's failures, which (b) still allows; retention and access are for the deployment to set. | I1 start |
| IMS-OP-12 | Which version of TS 32.409 and TS 32.454 applies at each configured release. These are SA5 specifications, versioned per release but not always issued for every one: as of 2026-10-27 the 3GPP portal lists TS 32.454 up to Rel-19 (V19.0.0) and none for Rel-20. (a) The latest version not later than the configured release; (b) refuse to produce measurements when no version matches. **Recommended: (a)**, with the version used reported (IMS-TEL-033). The same question will arise for any other SA5 specification. Also to settle with IMS-OP-10: how measurements are delivered (the 3GPP PM file and streaming formats, or the same channel as the records). | I2 start |
| IMS-OP-09 | **Roadmap decision 2026-10-26: Sh later.** The platform reading the HSS over Sh (TS 29.328/29.329) is planned for a later phase, provisionally I3 with platform R3; until then IMS-OP-05's generated snapshot is how HSS data reaches the platform. Sh reopens the platform's SIP-OP-05 for that phase, and three things must be settled before it is built: (1) a directory answer that changes without redeployment is outside the network identifier (ICD-NET-002), so the audit record must name what Sh returned and its version (e.g. the repository data sequence number); (2) whether Sh replaces the snapshot or checks it; (3) behaviour when the HSS is unreachable, which must fail closed. §3.3 constraint 2 still holds: Sh is a standard interface any HSS may offer. | I3 planning |

---

## 17. Revision history

| Version | Date | Change |
|---|---|---|
| 0.8 | 2026-10-27 | §14A added (IMS-TEL, 20 requirements): every entity and role emits a record per procedure, correlated by ICID (TS 24.229 §4.5.2, §5.2.1, §5.2.2.1, §5.4.1.7, checked in V13.23.0 and V20.1.0), Diameter Session-Id and Call-ID; each failure states one origin, and a tool names where a failure began; telemetry never harms the service, and loss is counted. IMS-VER-007 added. IMS-OAM-003 points to IMS-TEL-003. IMS-OP-10 (format) and IMS-OP-11 (identities) opened. §14A.4 (IMS-TEL-030 to 034): TS 32.409 measurements and TS 32.454 KPIs, derived from the records; TS 32.409 and TS 32.454 added to §2.1; IMS-OAM-005 points to them; IMS-OP-12 opened (which version per release, and delivery). |
| 0.7 | 2026-10-26 | IMS-OP-08 closed: PyHSS as the third-party HSS; test pairs stated. |
| 0.6 | 2026-10-26 | IMS-OP-08: Kamailio (IMS modules) as the third-party CSCF; HSS still open, PyHSS proposed. IMS-OP-09 opened: Sh on the roadmap (provisionally I3), with what it must settle. IMS-HSS-008 (Sh) added. Sh added to §3.1. |
| 0.5 | 2026-10-26 | IMS-OP-07 closed: the platform's release set (Rel-13 to 20) and release model; matched-release interop matrix; access bindings gated by release. |
| 0.4 | 2026-10-26 | IMS-OP-05 closed: the HSS is the master for users where one exists, through a generated network profile; otherwise the network profile. IMS-HSS-007 added. |
| 0.3 | 2026-10-26 | IMS-OP-03 closed: separate repository. IMS-VER-003 states the cross-repository pinned builds. |
| 0.2 | 2026-10-26 | IMS-OP-03: implementation language decided (Rust) with the workspace layout; repository still open. |
| 0.1 | 2026-10-26 | Initial draft. In-house core added as a third SIP core alongside the Kamailio and Asterisk interop references. |
