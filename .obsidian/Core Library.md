
# Core primitives
- PeerID (128-bit) <br>
- RoomID <br>
- Endpoint { ip, port, proto } <br>
- Candidate { type: host|srflx|relay, endpoint, priority } <br>
- SessionKey (AEAD) <br>
- TransportParams { mtu, congestion, pacing, reliable:boolean, ordered:boolean } <br>
- SignalingMsg { type, payload } (JSON/CBOR/Proto) <br>
- GameMsg { channel, reliable:boolean, seq, payload } <br>
- ClockSync { t0, t1, t2, skew } <br>

# Core services
- Identity: issue(), refresh() <br>
- Directory: register(peer|room), lookup(room|peer), list() <br>
- Signaling: publish(msg), subscribe(room|peer), requestPairing(a,b) <br>
- NAT: gatherCandidates(), holePunch(a,b), keepalive() <br>
- Relay: allocate(), bind(peer), send(packet), stats() <br>
- Authority: createRoom(), assignHost(), kick(), snapshot() <br>
- Transport: send(bytes, params), onMessage(cb), rtt(), pathStats() <br>
- Reliability: sendReliable(ch), sendUnreliable(ch), resend(), acks() <br>
- Security: handshake(), rekey(), verify() <br>
- Time: sync(), nowMono() <br>
