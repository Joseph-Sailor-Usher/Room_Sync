## Core primitives
- PeerID (128-bit)
- RoomID
- Endpoint { ip, port, proto }
- Candidate { type: host|srflx|relay, endpoint, priority }
- SessionKey (AEAD)
- TransportParams { mtu, congestion, pacing, reliable:boolean, ordered:boolean }
- SignalingMsg { type, payload } (JSON/CBOR/Proto)
- GameMsg { channel, reliable:boolean, seq, payload }
- ClockSync { t0, t1, t2, skew }

# Core services
- Identity: issue(), refresh()
- Directory: register(peer|room), lookup(room|peer), list()
- Signaling: publish(msg), subscribe(room|peer), requestPairing(a,b)
- NAT: gatherCandidates(), holePunch(a,b), keepalive()
- Relay: allocate(), bind(peer), send(packet), stats()
- Authority: createRoom(), assignHost(), kick(), snapshot()
- Transport: send(bytes, params), onMessage(cb), rtt(), pathStats()
- Reliability: sendReliable(ch), sendUnreliable(ch), resend(), acks()
- Security: handshake(), rekey(), verify()
- Time: sync(), nowMono()
