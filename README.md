# Room_Sync
Room-based matchmaking &amp; node sync with priority and ownership for Godot.

## Vision
Enable developers to add matchmaking and node sync to their Godot projects with minimal setup.

## Values
Affordability, Fairness, Performance, Low-Complexity.

## Inspiration
General Interest
- [A Survey and Taxonomy of Latency Compensation Techniques for Network Computer Games](https://dl.acm.org/doi/10.1145/3519023?utm_source=chatgpt.com)
- [Comparing Interest Management Algorithm for Massively Multiplayer Games](https://dl.acm.org/doi/10.1145/1230040.1230069?utm_source=chatgpt.com)
- [Networked Physics in Virtual Reality: Unity Sample](https://github.com/fbsamples/oculus-networked-physics-sample)
- [Networked Physics in Virtual Reality (Article)](https://gafferongames.com/post/networked_physics_in_virtual_reality/)

The Tribes Engine Networking Model (Mark Frohnmayer, Tom Gift)
- [Original Paper](https://www.gamedevs.org/uploads/tribes-networking-model.pdf)
- [Netcode Architectures Part 4: Tribes](https://www.snapnet.dev/blog/netcode-architectures-part-4-tribes/)

Networking for the Game Halo Franchise
- [I Shot You First: Networking the Gameplay of Halo: Reach](https://www.youtube.com/watch?v=h47zZrqjgLc)
- [GDC Session Summary: Halo Networking](https://www.wolfire.com/blog/2011/03/GDC-Session-Summary-Halo-networking/)
- [A Traffic Model for the Xbox Game Halo 2](https://www.wolfire.com/blog/2011/03/GDC-Session-Summary-Halo-networking/)
- [Running the Halo Multiplayer Experience at 60fps: A Technical Art Perspective](https://www.youtube.com/watch?v=65_lBJbAxnk)

Networking for the Half Life Franchise
- [Latency Compensating Methods in Client/Server In-game Protocol Design and Optimization](https://www.gamedevs.org/uploads/latency-compensation-in-client-server-protocols.pdf?utm_source=chatgpt.com)

Networking for the DOOM Franchise
- [The DOOM III Network Architecture](https://mrelusive.com/publications/papers/The-DOOM-III-Network-Architecture.pdf?utm_source=chatgpt.com)

Networking for the Overwatch Franchise
- [Overwatch Gameplay Architecture and Netcode](https://www.gdcvault.com/play/1024001/-Overwatch-Gameplay-Architecture-and?utm_source=chatgpt.com)


## Consideration of Implementation Options
- Pure Directory
- Directory + UDP Hole-Punch (STUN)
- WebRTC Signaling (ICE with STUN; no TURN)
- Hybrid: STUN first, TURN/Relay fallback
- Dedicated Game Server Per Room (Server-Authoritative)
- Relay-Only Matchmaking (App-Level Relay, non-TURN)
- Managed Platforms (Steamworks, Epic Online Services, PlayFab/Multiplay, Photon)

