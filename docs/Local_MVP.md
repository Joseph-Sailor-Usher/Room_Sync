# Quest III Local MVP Goals & Architecture

## Overview
This document outlines the minimum viable product for synchronizing Quest III headsets over a local network. It focuses on LAN-first functionality that can evolve toward the broader matchmaking and synchronization vision of Room_Sync. The content below frames decisions against the repository's stated vision of enabling matchmaking and node synchronization across diverse Godot projects and the core values of affordability, fairness, performance, and low-complexity.

## Project Goals & Extensibility Requirements
- **Deliver a LAN-ready experience for Quest III headsets** that allows a small group to discover each other, elect a host, and synchronize shared state with minimal setup.
- **Respect the existing vision and values** by prioritizing low-cost self-hosted flows, keeping the implementation lightweight for experimentation, and ensuring fairness/performance through predictable authority hand-offs.
- **Ensure forward compatibility** so that LAN-specific systems can be extended toward mixed LAN/WAN deployments, cloud-hosted relays, or managed services without rearchitecting core components.
- **Abstract platform-specific capabilities** (e.g., Oculus APIs for device discovery or low-level transport) to allow reuse in other Godot targets when the project expands beyond Quest hardware.

## Peer Discovery Options
| Approach | Description | Pros | Cons |
| --- | --- | --- | --- |
| **Broadcast/Multicast Beacon** | Host periodically sends UDP broadcast or multicast packets announcing session availability. Clients listen passively. | - Zero manual input for players.<br>- Fast convergence on small LANs.<br>- Aligns with low-complexity value. | - Broadcast may be blocked on segmented networks or by AP isolation.<br>- Requires handling of noisy environments (multiple hosts). |
| **mDNS/Service Discovery** | Advertise a service (e.g., `_roomsync._udp.local`) using mDNS. Clients query for available services. | - Standardized service discovery protocol.<br>- Works across many consumer routers.<br>- Reusable beyond Quest via generic libraries. | - Some enterprise or guest networks disable mDNS.<br>- Slightly higher implementation complexity than raw broadcast. |
| **Join Code / Manual IP** | Host displays a code or direct IP:port; clients enter manually. | - Works even when discovery traffic is blocked.<br>- Enables remote/WAN testing using port forwarding or VPN. | - Adds user friction and UI needs.<br>- Risk of mis-typed entries; needs validation UX. |

**Recommendation:** Implement broadcast/multicast beacons as the default, with mDNS as a pluggable alternative. Provide a manual join fallback in the UI to preserve playability when automatic discovery fails.

## Connection Flow
1. **Host Selection**
   - First player to create a room becomes the host/server for the LAN session.
   - Host advertises availability via the chosen discovery mechanism.
   - Additional logic can evaluate device performance or battery level if multiple potential hosts exist.
2. **Session Setup**
   - Client selects a discovered host (or enters join code/IP) and requests to join.
   - Host responds with session metadata (protocol version, gameplay configuration, player slots).
   - Once accepted, client establishes the primary transport channel (reliable/unreliable sockets) and syncs initial state snapshot.
3. **Future Cloud Matchmaking Handoff**
   - Define interfaces so that discovery/selection logic can be replaced by a cloud directory or relay.
   - Maintain a session descriptor format compatible with remote matchmaking services (room ID, host token, relay endpoint).
   - Plan for optional transfer of authority from LAN host to a cloud-managed session when players migrate from local to global play.

## Synchronization Protocol Choices
- **Transport for LAN**
  - Use UDP as the baseline for low-latency updates, with reliability layers built on top for critical messages (e.g., host acceptance, authoritative state corrections).
  - Optionally expose a TCP fallback for networks where UDP is blocked or unreliable.
- **Extensibility Toward WAN**
  - Design transport abstraction to support relay services (e.g., WebRTC data channels, QUIC) without changing higher-level sync logic.
  - Include hooks for encryption/authentication when moving beyond trusted LAN environments.
- **Synchronization Strategy**
  - Start with host-authoritative state replication, employing delta compression or event-based updates aligned with the "performance" value.
  - Support interest management hooks to maintain scalability for larger player counts in future iterations.

## Message Format Guidelines
- **Serialization**: Use a compact binary format (e.g., Godot `PackedByteArray`, FlatBuffers, or custom bitpacking) for high-frequency data, while allowing JSON/CBOR for debugging or infrequent configuration payloads.
- **Versioning**: Prefix messages with protocol and schema version numbers so mismatched clients can gracefully reject connections.
- **Reliability Flags**: Tag each message type with reliability requirements (e.g., `critical`, `state_delta`, `event`) to drive transport-level decisions such as retransmission or ordering.
- **Security Considerations**: Include optional authentication tokens or checksums to guard against tampering when extending to WAN scenarios.

## Authority Models
- **Current LAN Host/Server Model**
  - Host device runs authoritative game logic, applies client inputs, and replicates results.
  - Clients predict locally for responsiveness but reconcile against host updates.
  - Implement host migration support (elect a new host if original disconnects) to reduce session disruption.
- **Evolvable Models for Global Deployment**
  - Prepare for cloud-hosted dedicated servers that assume full authority, with LAN host acting as a temporary relay/controller.
  - Support hybrid peer-to-peer with delegated authority zones (e.g., per-room or per-entity ownership) for scalability while maintaining fairness.
  - Ensure consistency mechanisms (lockstep, deterministic rollback, or snapshot interpolation) can switch based on deployment mode.

## Next Steps & Open Questions
- Prototype UDP broadcast discovery on Quest III hardware and measure compatibility across common router configurations.
- Define the session descriptor schema shared between discovery, connection, and synchronization layers.
- Validate serialization options within Godot to balance performance and developer ergonomics.
- Explore host migration algorithms suited for small LAN parties (e.g., priority by latency or device capability).
- Investigate requirements for a cloud matchmaking API to smoothly transition from LAN discovery to global play.
- Document testing procedures for multi-headset LAN scenarios to uphold the project's core values.

