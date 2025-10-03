## Architecture Overview
- The MVP targets LAN sessions that elect a host, advertise availability over broadcast/mDNS, and remain extensible toward cloud matchmaking while honoring the project’s affordability, fairness, performance, and low-complexity values.
- Core domain primitives (peer IDs, room IDs, endpoints, transport parameters, session keys) and services (identity, directory, signaling, NAT, relay, authority, transport, reliability, security, time) structure the data model and subsystem responsibilities across discovery, negotiation, and synchronization layers.
- A networking layer abstraction must default to UDP with optional TCP fallback, expose hooks for future relays/WebRTC, and respect reliability flags per message type to balance latency with correctness.
- The replication stack stays host-authoritative with prediction/reconciliation on clients today, but the authority module needs clear seams for host migration, delegated ownership, or eventual dedicated servers/relays.
- Message serialization, versioning, and optional authentication guard against schema drift and prepare for untrusted WAN deployments, tying into the glossary’s definitions of transports, NAT traversal, and reliability classes used during implementation.

## Sprint Plan

### Sprint 1: LAN Discovery & Session Bootstrapping
#### Objectives
- Deliver UDP broadcast discovery with mDNS and manual join fallback, alongside host election and session descriptor exchange that records protocol versions and player slots.
- Instantiate the core primitives for peer/room IDs and endpoints to persist lobby metadata.

#### Key Scripts / Scenes
- `DiscoveryBeacon.gd` & `DiscoveryListener.gd` – broadcast/multicast beacons with suppression logic for noisy LANs.
- `MdnsService.gd` – service discovery wrapper exposing `_roomsync._udp.local` announcements as pluggable transport.
- `ManualJoinPanel.tscn` + `ManualJoinPanel.gd` – UI fallback for codes/IP entry when discovery fails.
- `LanRoomManager.gd` – orchestrates host selection, room metadata, and initial handshake using the directory primitives.
- `SessionDescriptor.gd` – serializes version, transport hints, and capacity for reuse in later matchmaking.

#### Test Focus
- Simulated LAN discovery cases (single host, multiple hosts, blocked broadcast) using mocked UDP sockets.
- Serialization unit tests to verify versioned session descriptors and peer identifiers survive round-trips.
- Integration harness that spins up two Godot headless peers to validate join/reject paths and error messaging.

#### Kanban Seeds
- **To Do**
  - Implement `DiscoveryBeacon` broadcast cadence and throttling.
  - Build `LanRoomManager` host election with tie-breakers (battery/perf heuristics placeholder).
  - Create manual join UI and validation flow for IP/port codes.
- **In Progress / Done** – populate as the sprint executes.

### Sprint 2: State Synchronization & Authority Resilience
#### Objectives
- Establish transport abstraction favoring UDP/ENet with TCP fallback, integrate reliability flags, and wire host-authoritative replication with prediction hooks.
- Implement host migration and ownership reassignment pathways for fairness during disconnects.

#### Key Scripts
- `TransportFactory.gd` – selects ENet/WebSocket/WebRTC peers based on session descriptor and platform capabilities.
- `ReliableChannel.gd` & `UnreliableChannel.gd` – encode reliability modes, sequencing, and retransmission using Godot’s peers or custom UDP wrappers.
- `StateReplicator.gd` – host-authoritative snapshot/delta broadcaster with interest hooks for future prioritization.
- `AuthorityManager.gd` – assigns ownership, triggers host migration, and emits corrective snapshots.

#### Test Focus
- Transport unit tests verifying channel negotiation (reliable/unreliable) and fallback logic under simulated UDP failure.
- Host migration scenario tests using three peers to ensure state continuity and ownership reassignment.
- Replication performance smoke tests measuring tick cadence, bandwidth budget, and loss handling at small player counts.

#### Kanban Seeds
- **To Do**
  - Implement `TransportFactory` decision matrix covering ENet, WebRTC stub, and TCP fallback.
  - Prototype `StateReplicator` delta encoding & replay buffer.
  - Add host migration workflow with new-host election trigger and resync broadcast.
- **In Progress / Done** – update during sprint ceremonies.

### Sprint 3: Extensibility, Security & UX Hardening
#### Objectives
- Prepare interfaces for cloud matchmaking handoff, relay support, and encryption hooks while polishing LAN UX and documentation.
- Finalize testing guidelines and telemetry needed for multi-headset LAN certification.

#### Key Scripts / Services
- `CloudDirectoryClient.gd` – optional adapter that consumes REST/WebSocket APIs for remote room listings and candidate exchange.
- `RelayEndpoint.gd` – wraps relay allocations and TURN-style fallbacks for constrained networks.
- `SecurityContext.gd` – manages session keys, handshakes, and authentication tokens before enabling gameplay channels.
- `DiagnosticsPanel.tscn` – displays network quality metrics, discovery status, and troubleshooting tips aligned with glossary definitions (jitter, loss, MTU).

#### Test Focus
- Contract tests for signaling/directory interfaces that ensure schema compatibility across LAN and future cloud environments.
- Security regression tests validating handshake failures, replay protection, and version mismatches.
- UX acceptance tests covering discovery fallbacks, error messaging, and diagnostics visibility.

#### Kanban Seeds
- **To Do**
  - Draft interface docs & mocks for external directory/relay integrations.
  - Implement `SecurityContext` AEAD key exchange and token verification pipeline.
  - Author LAN multi-headset test checklist and capture telemetry requirements.
- **In Progress / Done** – populate during sprint execution.
