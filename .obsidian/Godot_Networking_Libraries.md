## Core Networking Stack Overview
Godot provides multiple layers for networking functionality that can be combined to support different matchmaking and session models:

- **High-Level Multiplayer API (SceneTree Multiplayer)** – A scene replication system built on top of the low-level transport APIs. It manages RPCs, RSETs, authority assignment, and synchronizing nodes across peers. Godot 4 exposes this via `MultiplayerAPI` and associated `MultiplayerPeer` implementations.
- **ENet (`ENetMultiplayerPeer`)** – A reliable UDP-based transport offering ordered and unordered packet channels, sequencing, and bandwidth control. Suited for real-time games that need fine control over reliability without TCP head-of-line blocking.
- **WebSocket (`WebSocketMultiplayerPeer`)** – A TCP-based transport that works inside browsers or wherever WebSockets are required. Useful when communicating with existing WebSocket servers or browser-only deployments.
- **WebRTC (`WebRTCMultiplayerPeer`)** – A UDP-focused transport with built-in congestion control, NAT traversal (ICE/STUN/TURN), and data channels. Required when targeting browser-to-browser or cross-platform P2P connectivity.
- **Custom Low-Level Sockets (`PacketPeerUDP`, `StreamPeerTCP`, `WebSocketServer`, etc.)** – For bespoke protocols, Godot exposes raw socket APIs that can be wrapped by custom peers to plug into the multiplayer API or used standalone.
- **Multiplayer Replication Utilities** – Features such as scene replication, `MultiplayerSpawner`, `MultiplayerSynchronizer`, and authority management help implement deterministic state sharing regardless of transport.

## Building the Implementation Options

### Pure Directory (Matchmaking Directory + Direct Connections)
- Use a lightweight discovery service implemented with `HTTPRequest` or `WebSocketClient` for lobby listings.
- Clients exchange public addresses and bootstrap direct connections using `ENetMultiplayerPeer` for UDP-based sessions or `StreamPeerTCP`/`WebSocketMultiplayerPeer` for TCP.
- Authority can be assigned per room via the high-level multiplayer API to coordinate host migration or peer-to-peer roles.

### Directory + UDP Hole-Punch (STUN)
- Combine the directory service with `PacketPeerUDP` to perform custom hole-punch exchanges.
- Once UDP paths are negotiated, instantiate `ENetMultiplayerPeer` or a custom `PacketPeerUDP`-backed `MultiplayerPeer` to carry game traffic.
- Leverage Godot's multiplayer authority tools to register which peer acts as host after the punch succeeds.

### WebRTC Signaling (ICE with STUN, No TURN)
- Use Godot's built-in `WebRTCMultiplayerPeer` along with `WebRTCDataChannel` support.
- Implement the signaling server using `WebSocketServer` or `HTTPRequest` to exchange SDP offers/answers and ICE candidates.
- Configure the peer with STUN server addresses via `WebRTCPeerConnection` before starting ICE gathering.

### Hybrid: STUN First, TURN/Relay Fallback
- Extend the WebRTC setup by registering both STUN and TURN credentials with `WebRTCPeerConnection`.
- Handle ICE callbacks to detect when TURN relays are selected; fallback to managed relays while maintaining the same `WebRTCMultiplayerPeer`.
- Integrate with the multiplayer API to monitor latency and adjust authority if relay latency is high.

### Dedicated Game Server Per Room (Server-Authoritative)
- Run a headless Godot instance utilizing `ENetMultiplayerPeer` or `WebSocketServer` to host rooms.
- Clients connect via `MultiplayerAPI` configured in client-server mode with the server marked as the unique authority.
- Use `MultiplayerSpawner` and `MultiplayerSynchronizer` to replicate entities from the server to all clients, enforcing authoritative simulation.

### Relay-Only Matchmaking (App-Level Relay, Non-TURN)
- Implement a relay node using a headless Godot server with `PacketPeerUDP` or `WebSocketServer` to forward packets between clients.
- Clients connect to the relay using `ENetMultiplayerPeer` or `WebSocketMultiplayerPeer`, treating the relay as the host while it redistributes data.
- Integrate custom routing logic using low-level peers to enforce rate limits, prioritization, or per-room routing tables.

### Managed Platforms (Steamworks, Epic Online Services, PlayFab/Multiplay, Photon)
- Wrap the provider SDK's transport into a custom `MultiplayerPeer` by subclassing `MultiplayerPeerExtension` (Godot 4) or bridging through GDNative/GDExtension modules.
- Use the managed platform for matchmaking and session establishment while still relying on Godot's scene replication utilities for gameplay synchronization.
- For platforms exposing WebSockets or WebRTC (e.g., Photon Fusion WebSockets), integrate via the corresponding Godot transport and configure the high-level API accordingly.

## Additional Considerations

- **Latency Compensation** – Combine transport choice with Godot's high-level APIs for client prediction and reconciliation. Custom RPC reliability can be tuned by channel configuration in ENet or WebRTC data channel ordering flags.
- **Security & Authentication** – Godot's HTTP and TLS support allows secure token exchange before establishing peers. Managed platforms can provide built-in auth that is surfaced through custom peers.
- **Tooling & Debugging** – Godot's profiler and multiplayer debugger help inspect RPC traffic, bandwidth, and authority assignments irrespective of the underlying transport.

