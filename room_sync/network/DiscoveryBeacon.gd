extends Node

## Emits a periodic LAN discovery broadcast with throttling to avoid flooding.
signal beacon_sent(sequence_number: int)
signal beacon_skipped(reason: String)

@export var broadcast_port: int = 47845
@export var broadcast_addresses: PackedStringArray = ["255.255.255.255"]
@export var throttle_window_seconds: float = 5.0
@export var max_packets_per_window: int = 5
@export var payload: Dictionary = {
    "protocol": "room_sync",
    "version": "0.1.0"
}
@export var autostart: bool = false
@export_range(0.1, 10.0, 0.1, "or_greater") var broadcast_interval_seconds: float = 1.5:
    set(value):
        set_broadcast_interval(value)
    get:
        return get_broadcast_interval()

var _broadcast_interval: float = 1.5

var _udp := PacketPeerUDP.new()
var _timer := Timer.new()
var _window_start_time := 0.0
var _sent_in_window := 0
var _sequence := 0
var _active := false

func _ready() -> void:
    add_child(_timer)
    _timer.wait_time = _broadcast_interval
    _timer.one_shot = false
    _timer.timeout.connect(_on_timer_timeout)
    if autostart and not Engine.is_editor_hint():
        start()

func start() -> void:
    if _active:
        return
    _active = true
    _prepare_socket()
    _reset_window(Time.get_ticks_msec() / 1000.0)
    _timer.start()

func stop() -> void:
    if not _active:
        return
    _active = false
    _timer.stop()
    _udp.close()

func set_payload(data: Dictionary) -> void:
    payload = data.duplicate(true)

func set_broadcast_interval(seconds: float) -> void:
    _broadcast_interval = max(seconds, 0.1)
    if is_instance_valid(_timer):
        _timer.wait_time = _broadcast_interval

func get_broadcast_interval() -> float:
    return _broadcast_interval

func _prepare_socket() -> void:
    _udp = PacketPeerUDP.new()
    _udp.set_broadcast_enabled(true)

func _on_timer_timeout() -> void:
    if not _active:
        return
    var now := Time.get_ticks_msec() / 1000.0
    if now - _window_start_time >= throttle_window_seconds:
        _reset_window(now)
    if _sent_in_window >= max_packets_per_window:
        beacon_skipped.emit("throttled")
        return
    _send_beacon()

func _reset_window(now_seconds: float) -> void:
    _window_start_time = now_seconds
    _sent_in_window = 0

func _send_beacon() -> void:
    var serialized := JSON.stringify(_build_payload()).to_utf8_buffer()
    if broadcast_addresses.is_empty():
        beacon_skipped.emit("no_addresses")
        return
    var sent := false
    for address in broadcast_addresses:
        var err := _udp.set_dest_address(address, broadcast_port)
        if err != OK:
            beacon_skipped.emit("set_dest_failed:%s" % address)
            continue
        err = _udp.put_packet(serialized)
        if err == OK:
            sent = true
        else:
            beacon_skipped.emit("send_failed:%s" % address)
    if sent:
        _sent_in_window += 1
        _sequence += 1
        beacon_sent.emit(_sequence)

func _build_payload() -> Dictionary:
    var result := payload.duplicate(true)
    result["timestamp"] = Time.get_ticks_msec()
    result["sequence"] = _sequence + 1
    return result
