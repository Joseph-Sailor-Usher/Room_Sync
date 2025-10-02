# Halo 2 Networking Notes: Prioritization vs. Packetization

The Halo 2 postmortems emphasize maintaining two distinct responsibilities inside the networking stack:

- **PrioritizationManager** picks which entities and state channels deserve bandwidth each tick.
- **PacketManager** serializes those chosen states into network frames, manages reliable/unreliable channels, and submits them to the transport.

Keeping these roles separated prevents priority heuristics from knowing about transport internals while letting packet assembly swap between ENet, custom UDP, or future transports.

## Responsibilities

### PrioritizationManager
- Maintain per-client visibility buckets, distance and relevance scores.
- Track last-sent tick per entity/component so deltas are scheduled only when their priority score clears a configurable threshold.
- Hand back an ordered list of `ReplicationRequest { entity_id, component_mask, priority, desired_budget_bytes }`.
- Persist priority state (decay, boosts) independently of packetization cadence, so changing MTU or transport framing does not skew scheduling decisions.

### PacketManager
- Consume the ordered replication requests and slice them into packets respecting MTU, channel reliability, and QoS constraints.
- Perform delta compression/bit-packing and attach baselines/acks as required by the transport.
- Defer to `MultiplayerAPI`/ENet for delivery but expose hooks for bandwidth accounting and telemetry.
- Issue callbacks when requests are dropped due to budget exhaustion so the prioritizer can react (e.g., boost an entity next tick).

## Interaction Flow
1. Server tick calls `PrioritizationManager::gather(client_id, tick)` to obtain prioritized replication requests.
2. The ordered requests are fed into `PacketManager::write_packets(client_id, requests, tick)`.
3. Packet manager emits one or more transport frames, tracking ack baselines separately.
4. If packetization cannot fit a request, it notifies the prioritizer with the drop context so the next gather can react.

## Alignment with Tribes-Inspired Plan
- The Phase 2 work item "Implement Tribes-style prioritized replication" should instantiate the **PrioritizationManager** described above and keep it independent from delta encoding logic.
- Delta compression and client baseline bookkeeping sit inside the **PacketManager**, aligning with Halo 2's split between scheduling and encoding.
- This layout makes it easier to add Halo-style "channel budgets" or to experiment with different transports without perturbing prioritization heuristics.

Keeping the boundary explicit gives us room to experiment with Halo 2's interest management tricks (e.g., priority decay, threat boosts) while letting the packetizer evolve alongside transport upgrades.
