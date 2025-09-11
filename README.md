# Room_Sync
Room-based matchmaking &amp; node sync with priority and ownership for Godot.

## Vision
Enable developers to add matchmaking and node sync to their Godot projects with minimal setup.

## Values
Affordability, Performance, Low-Complexity.

## Inspiration
- The Tribes Engine Networking Model (Mark Frohnmayer, Tom Gift)
- (Original Paper)[https://www.gamedevs.org/uploads/tribes-networking-model.pdf]
- 

## Consideration of Implementation Options
- Pure Directory
- Directory + UDP Hole-Punch (STUN)
- WebRTC Signaling (ICE with STUN; no TURN)
- Hybrid: STUN first, TURN/Relay fallback
- Dedicated Game Server Per Room (Server-Authoritative)
- Relay-Only Matchmaking (App-Level Relay, non-TURN)
- Managed Platforms (Steamworks, Epic Online Services, PlayFab/Multiplay, Photon)



## User stories
- As a developer, I can follow a simple tutorial to set up network infrastructure and call the necessary functions in my client-side code to allow players to create, join, leave, and close rooms, and connect to other players in the same room and remove users from a room.
- As a developer I can tell Room_Sync which nodes need to be STATIC, DYNAMIC, DYNAMIC_OWNED, set ownership in the editor or via script, and set networked priority of DYNAMIC and DYNAMiC_OWNED nodes in the editor or via script.

## Feature Requirements
### Matchmaking (Connection phase)
- Create/Join/Leave/Close room via API; emits success/failure events.
- Room codes: 4 characters of base-36 means ~1.5 million rooms, collision detection, capacity limit, reasoned errors.
- Join returns host endpoint; client auto-connects; retries + timeout
### Session (Gameplay phase)
- Host-authoritative transport (ENet/WbSocket), peers connect to host.
- Player roster: join/leave notifications; remove player; set player's team.
- Scene Manager owned by host: level, gametype, teams, start/end.
### Node Sync (Metadata)
- Behavior: STATIC, DYNAMIC, DYNAMIC_OWNED.
- Priority: LOW, MEDIUM, HIGH
- Prioritization Manager 
