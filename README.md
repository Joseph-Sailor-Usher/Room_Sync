# Room_Sync
Room-based matchmaking &amp; node sync with priority and ownership for Godot.

## Vision
Enable developers to add matchmaking and node synchronization to Godot projects spanning titles like [_Among Us_](https://www.innersloth.com/games/among-us/) to titles similar to [_The Finals_](https://www.reachthefinals.com/) with minimal setup.

## Values
Affordability, Fairness, Performance, Low-Complexity.

## Inspiration
General Interest
- [Steam Matchmaking & Lobbies](https://partner.steamgames.com/doc/features/multiplayer/matchmaking?)
- [Photon Engine](https://doc.photonengine.com/realtime/current/lobby-and-matchmaking/matchmaking-and-lobby?)
- [WebRTC Data Channels](https://www.ietf.org/proceedings/92/slides/slides-92-taps-2.pdf?)
- [TCP's Evolution : From Secure Networks to Gaming Exploits in Halo 2](https://www.ietf.org/proceedings/92/slides/slides-92-taps-2.pdf?)
- [A Survey and Taxonomy of Latency Compensation Techniques for Network Computer Games](https://dl.acm.org/doi/10.1145/3519023?)
- [Comparing Interest Management Algorithm for Massively Multiplayer Games](https://dl.acm.org/doi/10.1145/1230040.1230069?)
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
- [Latency Compensating Methods in Client/Server In-game Protocol Design and Optimization](https://www.gamedevs.org/uploads/latency-compensation-in-client-server-protocols.pdf?)

Networking for the DOOM Franchise
- [The DOOM III Network Architecture](https://mrelusive.com/publications/papers/The-DOOM-III-Network-Architecture.pdf?)

Networking for the Overwatch Franchise
- [Overwatch Gameplay Architecture and Netcode](https://www.gdcvault.com/play/1024001/-Overwatch-Gameplay-Architecture-and?)


## Consideration of Implementation Options
- Pure Directory
- Directory + UDP Hole-Punch (STUN)
- WebRTC Signaling (ICE with STUN; no TURN)
- Hybrid: STUN first, TURN/Relay fallback
- Dedicated Game Server Per Room (Server-Authoritative)
- Relay-Only Matchmaking (App-Level Relay, non-TURN)
- Managed Platforms (Steamworks, Epic Online Services, PlayFab/Multiplay, Photon)

