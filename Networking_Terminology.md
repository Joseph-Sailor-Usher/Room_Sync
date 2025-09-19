# Glossary (Matchmaking & Networking)

## Addressing
NAT — Network Address Translation: router maps private IP:port pairs to its public IP:ports (aka NAPT/PAT).<br>
CGNAT — Carrier-Grade NAT: your ISP NATs you too; true public inbound ports often impossible.<br>
Port Forwarding — Manual rule on a NAT to route an external port to a specific device/port inside.<br>
UPnP / NAT-PMP — Protocols to auto-create port-forward rules on home routers.<br>
Public vs Private IP — Public is internet-routable; private (RFC1918) works only inside local networks.<br>
Firewall — Policy that blocks/permits traffic by port/protocol/address.<br>

## Matchmaking & Session Setup
Signaling — Out-of-band messages (usually WebSocket/HTTP) to exchange session setup info (IPs, ICE).<br>
Directory — Minimal service mapping room_code → endpoint(s) (host IP/port or ICE info).<br>
Room / Lobby — A discoverable match context (players, metadata) before/while playing.<br>
Endpoint — Network address clients connect to (IP:port or ICE candidate).<br>
Allocator — Service that picks or spins a dedicated game server for a room.<br>

## Transports & NAT Traversal
UDP — Unreliable, unordered transport; low latency; you build reliability where needed.<br>
TCP — Reliable, ordered stream; simple but adds head-of-line blocking and latency spikes.<br>
ENet — Thin UDP library offering channels, reliability, sequencing—good default for native Godot.<br>
WebRTC (DataChannel) — Encrypted, UDP-like transport with ICE (STUN/TURN); works in browsers.<br>
ICE — Interactive Connectivity Establishment: tries many candidate paths to connect peers.<br>
STUN — Session Traversal Utilities for NAT is a service that tells a client its public IP:port; helps UDP hole-punching.<br>
TURN — Relay server that forwards data when P2P fails (reliable but adds cost/latency).<br>
Hole Punching — Technique to open matching NAT bindings so two peers can talk directly.<br>

## Topologies & Authority
Host-Authoritative — One peer (host) is the source of truth; clients send inputs, host validates state.<br>
Peer-to-Peer (P2P) — Clients connect to each other (often host-centric in games).<br>
Dedicated Server — Stand-alone server authoritative for the match; no client hosts.<br>
Relay — Middlebox that forwards gameplay traffic (TURN or custom).<br>

## Replication, Ownership & Delivery
Ownership — Who can author updates for a networked node (host can reassign).<br>
Replication — Propagating object state to peers according to behavior/priority rules.<br>
Priority — Scheduling weight/target Hz for what to send first (e.g., players > props).<br>
Reliability Class — Choice per message: unreliable, reliable, ordered, “most-recent wins,” etc.<br>

## Simulation Timing & Compression
Tick Rate — Simulation/update frequency (e.g., 30 Hz) that bounds network send cadence.<br>
Snapshot — Periodic full (or partial) state of objects for replication.<br>
Delta Compression — Send only changes since last acknowledged state.<br>

## Smoothing & Correction
Interpolation — Render between known states to hide network gaps.<br>
Client Prediction — Client simulates immediate input locally; later corrected by host.<br>
Reconciliation — Client reapplies unacknowledged inputs after a host correction to reduce rubber-banding.<br>

## Network Quality & Budgets
Jitter — Variability in packet latency; causes stutter without buffering/interpolation.<br>
Packet Loss — Dropped packets; mitigate with redundancy or selective reliability.<br>
MTU — Maximum packet payload before IP fragmentation; stay under to avoid loss/latency spikes.
Bandwidth Budget — Per-client cap (bytes/s or packets/s) to prevent spikes and fairness issues.

## Security & Eposure
TLS/DTLS — Encryption for TCP/UDP (WebRTC uses DTLS); ENet itself is unencrypted.
DoS Surface — Risk from exposing host IP/port; mitigations include rate limits and relays.
