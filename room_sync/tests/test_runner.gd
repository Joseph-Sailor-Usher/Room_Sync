extends SceneTree

var _current_test_passed := true
var _tests_run := 0
var _tests_failed := 0

class MockPacketPeerUDP:
    var destinations: Array = []
    var payloads: Array = []
    var dest_failures: Dictionary = {}
    var send_failures: Dictionary = {}
    var broadcast_enabled := false
    var closed := false
    var _current_address := ""
    var ports: Array = []

    func set_broadcast_enabled(enabled: bool) -> void:
        broadcast_enabled = enabled

    func set_dest_address(address: String, port: int) -> int:
        _current_address = address
        if dest_failures.has(address):
            return dest_failures[address]
        destinations.append({"address": address, "port": port})
        ports.append(port)
        return OK

    func put_packet(packet: PackedByteArray) -> int:
        if send_failures.has(_current_address):
            return send_failures[_current_address]
        payloads.append({"address": _current_address, "data": packet})
        return OK

    func close() -> void:
        closed = true

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var tests := [
        "test_discovery_single_host",
        "test_discovery_multiple_hosts",
        "test_discovery_blocked_broadcast",
        "test_lan_manager_serialization_round_trip",
        "test_manual_join_integration_flow",
    ]

    for name in tests:
        _current_test_passed = true
        _tests_run += 1
        var state = self.call(name)
        if state is GDScriptFunctionState:
            await state
        if _current_test_passed:
            print("[PASS] %s" % name)
        else:
            _tests_failed += 1
            print("[FAIL] %s" % name)

    print("Tests passed: %d/%d" % [_tests_run - _tests_failed, _tests_run])
    quit(_tests_failed)

func _assert(condition: bool, message: String = "") -> bool:
    if condition:
        return true
    _current_test_passed = false
    push_error(message if not message.is_empty() else "Assertion failed")
    return false

func _create_beacon() -> DiscoveryBeacon:
    var beacon := DiscoveryBeacon.new()
    get_root().add_child(beacon)
    await beacon.ready
    beacon.autostart = false
    beacon.max_packets_per_window = 10
    beacon.throttle_window_seconds = 1.0
    return beacon

func _teardown_node(node: Node) -> void:
    if node and node.get_parent():
        node.queue_free()
        await get_tree().process_frame

func test_discovery_single_host() -> void:
    var beacon := await _create_beacon()
    var mock_peer := MockPacketPeerUDP.new()
    beacon.set_udp_factory(func():
        return mock_peer
    )
    beacon.broadcast_addresses = ["192.168.1.255"]
    var sent_sequences := []
    var skipped := []
    beacon.beacon_sent.connect(func(sequence): sent_sequences.append(sequence))
    beacon.beacon_skipped.connect(func(reason): skipped.append(reason))
    beacon.start()
    beacon._on_timer_timeout()

    _assert(mock_peer.broadcast_enabled, "Broadcast flag should be enabled on UDP socket")
    _assert(mock_peer.payloads.size() == 1, "Expected a single payload to be sent")
    _assert(sent_sequences == [1], "Sequence should increment to 1 after first send")
    _assert(skipped.is_empty(), "No skips expected for successful send")

    beacon.stop()
    await _teardown_node(beacon)

func test_discovery_multiple_hosts() -> void:
    var beacon := await _create_beacon()
    var mock_peer := MockPacketPeerUDP.new()
    beacon.set_udp_factory(func():
        return mock_peer
    )
    beacon.broadcast_addresses = ["192.168.1.255", "10.0.0.255"]
    var sent_sequences := []
    beacon.beacon_sent.connect(func(sequence): sent_sequences.append(sequence))
    beacon.start()
    beacon._on_timer_timeout()

    _assert(mock_peer.payloads.size() == 2, "Should send a payload for each destination")
    _assert(sent_sequences == [1], "Sequence should still only advance once per interval")
    _assert(mock_peer.destinations.size() == 2, "Both destinations should be attempted")

    beacon.stop()
    await _teardown_node(beacon)

func test_discovery_blocked_broadcast() -> void:
    var beacon := await _create_beacon()
    var mock_peer := MockPacketPeerUDP.new()
    mock_peer.dest_failures["255.255.255.255"] = ERR_UNAVAILABLE
    beacon.set_udp_factory(func():
        return mock_peer
    )
    beacon.broadcast_addresses = ["255.255.255.255"]
    var skipped := []
    beacon.beacon_skipped.connect(func(reason): skipped.append(reason))
    beacon.start()
    beacon._on_timer_timeout()

    _assert(mock_peer.payloads.is_empty(), "No payloads should be recorded when broadcast is blocked")
    _assert(skipped.has("set_dest_failed:255.255.255.255"), "Blocked broadcast should surface failure reason")

    beacon.stop()
    await _teardown_node(beacon)

func test_lan_manager_serialization_round_trip() -> void:
    var manager := LanRoomManager.new()
    get_root().add_child(manager)
    await manager.ready
    manager.require_local_candidate = false
    manager.set_local_peer_id("peer_alpha")

    var descriptor_alpha := {
        "performance_score": 9.5,
        "battery_level": 0.9,
        "latency_ms": 40.0,
        "session": {
            "id": "session-123",
            "version": "1.2.0",
            "peers": ["peer_alpha"]
        },
        "peer_id": "peer_alpha"
    }
    var descriptor_beta := {
        "performance_score": 8.0,
        "battery_level": 0.8,
        "latency_ms": 35.0,
        "session": {
            "id": "session-123",
            "version": "1.2.0",
            "peers": ["peer_alpha", "peer_beta"]
        },
        "peer_id": "peer_beta"
    }

    manager.register_candidate("peer_alpha", descriptor_alpha)
    manager.register_candidate("peer_beta", descriptor_beta)

    var snapshot := manager.snapshot_room()
    var json := JSON.stringify(snapshot)
    var parsed := JSON.parse_string(json)

    _assert(parsed is Dictionary, "Snapshot should decode to a dictionary")
    _assert(parsed["host_id"] == manager.get_current_host_id(), "Host id should survive serialization round-trip")
    _assert(parsed["candidates"].has("peer_alpha"), "Alpha candidate should persist")
    _assert(parsed["candidates"]["peer_beta"]["session"]["peers"].has("peer_beta"), "Peer roster should serialize correctly")

    parsed["candidates"]["peer_alpha"]["session"]["id"] = "mutated"
    _assert(manager.get_candidate("peer_alpha")["session"]["id"] == "session-123", "Original descriptor should remain unchanged after mutation")

    await _teardown_node(manager)

func test_manual_join_integration_flow() -> void:
    var host_manager := LanRoomManager.new()
    host_manager.require_local_candidate = false
    host_manager.set_local_peer_id("host")
    get_root().add_child(host_manager)
    await host_manager.ready

    var guest_manager := LanRoomManager.new()
    guest_manager.require_local_candidate = false
    guest_manager.set_local_peer_id("guest")
    get_root().add_child(guest_manager)
    await guest_manager.ready

    var host_descriptor := {
        "performance_score": 10.0,
        "battery_level": 1.0,
        "latency_ms": 10.0,
        "session": {
            "id": "room-xyz",
            "version": "1.0",
            "peers": ["host"]
        },
        "peer_id": "host"
    }
    host_manager.register_candidate("host", host_descriptor)

    var panel_scene: PackedScene = load("res://ui/ManualJoinPanel.tscn")
    var panel: ManualJoinPanel = panel_scene.instantiate()
    get_root().add_child(panel)
    await panel.ready

    var ip_field: LineEdit = panel.get_node("%IpLineEdit")
    var port_field: LineEdit = panel.get_node("%PortLineEdit")
    var join_button: Button = panel.get_node("%JoinButton")
    var error_label: Label = panel.get_node("%ErrorLabel")

    panel.reset_form("", panel.default_port)

    ip_field.text = ""
    port_field.text = ""
    panel.call("_on_join_pressed")
    await get_tree().process_frame

    _assert(error_label.visible, "Error label should display when join validation fails")
    _assert(error_label.text.find("Enter an address") != -1, "Empty address should surface guidance")

    panel.reset_form("", panel.default_port)
    var join_events: Array = []
    panel.join_requested.connect(func(address: String, port: int):
        join_events.append({"address": address, "port": port})
        if address == "192.168.0.10":
            var guest_descriptor := {
                "performance_score": 7.5,
                "battery_level": 0.9,
                "latency_ms": 25.0,
                "session": {
                    "id": "room-xyz",
                    "version": "1.0",
                    "peers": ["host", "guest"]
                },
                "peer_id": "guest"
            }
            host_manager.register_candidate("guest", guest_descriptor)
            guest_manager.register_candidate("host", host_descriptor)
        else:
            panel.set_busy(false)
            panel.show_error("Room unavailable")
    )

    ip_field.text = "192.168.0.10"
    port_field.text = "47845"
    panel.call("_update_state")
    _assert(not join_button.disabled, "Join button should enable for valid IPv4 input")
    panel.call("_on_join_pressed")
    await get_tree().process_frame

    _assert(join_events.size() == 1, "Successful submission should emit join_requested")
    _assert(host_manager.get_candidate("guest").get("peer_id", "") == "guest", "Guest descriptor should register with host manager")

    ip_field.text = "ROOM1"
    port_field.text = str(panel.default_port)
    panel.call("_update_state")
    panel.call("_on_join_pressed")
    await get_tree().process_frame

    _assert(join_events.size() == 2, "Second submission should still emit join_requested")
    _assert(error_label.text == "Room unavailable", "Rejected join should report error from integration harness")
    _assert(error_label.visible, "Rejected join should surface error label")

    await _teardown_node(panel)
    await _teardown_node(host_manager)
    await _teardown_node(guest_manager)
