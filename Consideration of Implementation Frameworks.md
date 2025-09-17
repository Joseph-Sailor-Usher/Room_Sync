# Pure Directory
Clients learn each other’s public endpoints from a directory and connect directly (no STUN/TURN/ICE).
Pros: Simple; zero relay cost.
Cons: Fails on many NATs; brittle across enterprise/campus/CGNAT (Needs ICE).
Why it struggles: Hole-punch is not universally reliable; certain NAT mappings break it (address/port-dependent). TURN exists because of that. 
``` mermaid
flowchart TD
  subgraph Cloud
    MM[Directory / Matchmaker<br/>HTTPS+DB]
  end
  C1[Client A] -- HTTPS 443 --> MM
  C2[Client B] -- HTTPS 443 --> MM
  MM -- returns IP:port --> C1
  MM -- returns IP:port --> C2
  C1 <-. UDP gameplay .-> C2
```

``` mermaid
sequenceDiagram
  participant A as Client A
  participant MM as Matchmaker
  participant B as Client B
  A->>MM: POST /join(room)
  B->>MM: POST /join(room)
  MM-->>A: B's public IP:port
  MM-->>B: A's public IP:port
  A->>B: UDP SYN/first packet
  B->>A: UDP reply (session established)
```

# Directory + UDP Hole-Punch (STUN)
Add STUN so peers discover their server-reflexive (public) address and try to punch through.
Pros: Cheap; often works; keeps latency low by staying P2P.
Cons: Not a complete solution; still fails with stricter NATs/firewalls; you end up hand-rolling parts of ICE.
Standards: STUN tells you your public IP:port, does keep-alives, and can check basic connectivity—but is not a full traversal solution. 
``` mermaid
flowchart TD
  subgraph Cloud
    MM[Directory / Matchmaker]
    STUN1((STUN))
    STUN2((STUN))
  end
  C1[Client A] -- "Binding" --> STUN1
  C2[Client B] -- "Binding" --> STUN2
  C1 -- "HTTPS 443" --> MM
  C2 -- "HTTPS 443" --> MM
  MM -- "exchange srflx IP:ports" --> C1
  MM -- "exchange srflx IP:ports" --> C2
  C1 -. "UDP hole-punch" .-> C2
  C2 -. "UDP hole-punch" .-> C1
```


``` mermaid
sequenceDiagram
  participant A as Client A
  participant S as STUN
  participant MM as Matchmaker
  participant B as Client B
  A->>S: STUN Binding Request
  S-->>A: srflx IP:port(A)
  B->>S: STUN Binding Request
  S-->>B: srflx IP:port(B)
  A->>MM: POST /offer srflx(A)
  B->>MM: POST /offer srflx(B)
  MM-->>A: srflx(B)
  MM-->>B: srflx(A)
  par Punch
    A->>B: simultaneous UDP to srflx(B)
    B->>A: simultaneous UDP to srflx(A)
  end
  A-->>B: gameplay packets
```

# WebRTC Signaling (ICE with STUN; no TURN)
What it is: Proper ICE candidate gathering/priority checks + DTLS/SCTP data channels, but you refuse to use relays.
Pros: Correct connection logic; faster with Trickle ICE; great APIs and libs (libwebrtc).
Cons: You’ll still lose a non-trivial % of players behind hard NATs if you refuse TURN.
Use when: You want best-effort P2P with modern stack and can accept some drop-offs.
Standards: ICE (RFC 8445) orchestrates host/srflx (STUN) checks; Trickle ICE improves setup time. 
``` mermaid
flowchart TD
  subgraph Cloud
    SIG[Signaling / HTTPS WSS + DB]
    STUN1((STUN))
    STUN2((STUN))
  end

  C1[ClientA - WebRTC] -- WSS 443 --> SIG
  C2[ClientB - WebRTC] -- WSS 443 --> SIG

  C1 -- ICE gather --> STUN1
  C2 -- ICE gather --> STUN2

  %% Bidirectional ICE connectivity checks
  C1 -. ICE checks (UDP) .-> C2
  C2 -. ICE checks (UDP) .-> C1

  %% Final data path (solid)
  C1 ---|DataChannel - DTLS/SCTP| C2

  %% This is the 7th edge (0-based index = 6)
  linkStyle 6 stroke-width:3px,stroke:#0aa

```

# Hybrid: STUN first, TURN/Relay fallback
What it is: Full ICE with both STUN and TURN enabled. If direct fails, relay via TURN.
Pros: Highest NAT success; you keep P2P latency where possible and pay for relay only on failures; privacy/IP shielding via relay.
Cons: You must run/buy TURN; bandwidth for relayed sessions.
Use when: Default recommendation for small–mid rooms (2–10); real-time titles that value reach + low OPEX.
Standards: TURN is the IETF relay protocol designed to pair with ICE; modern spec is RFC 8656 (obsoletes 5766). Also consider consent freshness if you’re using WebRTC. 

``` mermaid
flowchart LR
  subgraph Cloud
    SIG[Signaling]
    TURN1(((STUN/TURN)))
    TURN2(((STUN/TURN)))
  end
  C1[Client A] -- Gather --> TURN1
  C2[Client B] -- Gather --> TURN2
  C1 -- WSS 443 --> SIG
  C2 -- WSS 443 --> SIG
  SIG -- exchange ICE --> C1
  SIG -- exchange ICE --> C2
  C1 <-. direct UDP if OK .-> C2
  C1 -- relay path --> TURN1
  TURN1 -- relay path --> C2
```

# Dedicated Game Server Per Room (Server-Authoritative)
What it is: Clients connect to a room server that owns truth (hit reg, anti-cheat logic, physics arbitration).
Pros: Deterministic, cheat-resistant, easier QoS control; simpler client NAT story (clients dial out).
Cons: Ongoing hosting cost; more backend engineering; you manage scaling/updates.
Use when: Competitive games, larger rooms, authoritative sim required.
Managed hosting: PlayFab Multiplayer Servers/Multiplay gives autoscaling, containerized builds, and allocation APIs. 
``` mermaid
flowchart LR
  subgraph Cloud
    ALLOC[Matchmaker / Allocator]
    GS1[Game Server #1]
    GS2[Game Server #2]
    DB[(DB/Redis)]
    METRICS[(Metrics/Logs)]
  end
  C1[Client A] -- HTTPS 443 --> ALLOC
  C2[Client B] -- HTTPS 443 --> ALLOC
  ALLOC --> GS1
  ALLOC -- ticket: ip:port(GS1) --> C1
  ALLOC -- ticket: ip:port(GS1) --> C2
  C1 <== UDP/TCP ==> GS1
  C2 <== UDP/TCP ==> GS1
  GS1 --> DB
  GS1 --> METRICS
```

``` mermaid
sequenceDiagram
  participant C as Client
  participant MM as Matchmaker/Allocator
  participant GS as Game Server
  C->>MM: Find/Join room
  MM->>GS: Allocate/start (if needed)
  MM-->>C: Connect info + session ticket
  C->>GS: Auth with ticket
  GS-->>C: Welcome; start tick stream (UDP)
```

# Relay-Only Matchmaking (App-Level Relay, non-TURN)
What it is: You build a custom relay/proxy (or use a vendor’s non-TURN relay) and force all traffic through it.
Pros: Hides IPs; simpler client code than ICE; single place to meter/inspect traffic.
Cons: All traffic pays the relay tax (latency + bandwidth ); you reinvent congestion/reliability; no standards leverage.
Use when: You want control and simplicity and can afford always-on relaying.
``` mermaid
flowchart TD
  subgraph Cloud
    MM[Matchmaker]
    R1[[Relay Node A]]
    R2[[Relay Node B]]
  end
  C1[Client A] -- HTTPS 443 --> MM
  C2[Client B] -- HTTPS 443 --> MM
  MM -- assign relay & room key --> C1
  MM -- assign relay & room key --> C2
  C1 <== UDP ==> R1
  C2 <== UDP ==> R1
  R1 -- multiplex/forward --> R1
```
