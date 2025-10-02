extends Control

@onready var manager: Node = $LanRoomManager
@onready var snapshot_label: RichTextLabel = %Snapshot
@onready var event_log: RichTextLabel = %EventLog

@export var demo_delay: float = 1.2

var _start_time: float = 0.0

func _ready() -> void:
        if not manager:
                push_warning("LanRoomManager node not found in scene")
                return
        manager.host_changed.connect(_on_host_changed)
        manager.roster_updated.connect(_on_roster_updated)
        snapshot_label.bbcode_enabled = true
        event_log.bbcode_enabled = true
        _start_time = Time.get_ticks_msec() / 1000.0
        _update_snapshot()
        _log_event("LanRoomManager harness initialised")
        call_deferred("_run_demo")

func _run_demo() -> void:
        # Provide a predictable demo of candidate updates to visualise behaviour.
        _register_demo_candidate("alpha", {"performance_score": 0.8, "battery_level": 0.7, "latency_ms": 30})
        manager.set_local_peer_id("alpha")
        await _wait()
        _register_demo_candidate("bravo", {"performance_score": 0.9, "battery_level": 0.6, "latency_ms": 55})
        await _wait()
        _register_demo_candidate("charlie", {"performance_score": 0.6, "battery_level": 0.9, "latency_ms": 20})
        await _wait(2.0)
        _log_event("Updating bravo's latency to demonstrate re-election")
        manager.register_candidate("bravo", {"performance_score": 0.9, "battery_level": 0.6, "latency_ms": 10})
        await _wait(2.0)
        _log_event("Removing current host to trigger a new election")
        manager.remove_candidate(manager.get_current_host_id())

func _register_demo_candidate(peer_id: String, descriptor: Dictionary) -> void:
        _log_event("Registering %s" % peer_id)
        manager.register_candidate(peer_id, descriptor)

func _wait(duration: float = demo_delay) -> void:
        await get_tree().create_timer(duration).timeout

func _on_host_changed(peer_id: String, descriptor: Dictionary) -> void:
        var details := ""
        if not descriptor.is_empty():
                details = " " + JSON.stringify(descriptor)
        _log_event("[color=yellow]Host changed to %s[/color]%s" % (peer_id if not peer_id.is_empty() else "<none>", details))
        _update_snapshot()

func _on_roster_updated(_candidates: Dictionary) -> void:
        _update_snapshot()

func _update_snapshot() -> void:
        var snapshot: Dictionary = manager.snapshot_room()
        var host_id: String = str(snapshot.get("host_id", ""))
        var candidates: Dictionary = snapshot.get("candidates", {})
        var lines: Array[String] = []
        lines.append("[b]Current host:[/b] %s" % (host_id if not host_id.is_empty() else "<none>"))
        lines.append("[b]Candidates:[/b]")
        var peer_ids: Array = candidates.keys()
        peer_ids.sort()
        for peer_id in peer_ids:
                var descriptor: Dictionary = candidates.get(peer_id, {})
                lines.append("  • %s -> %s" % [peer_id, JSON.stringify(descriptor)])
        snapshot_label.text = "\n".join(lines)

func _log_event(message: String) -> void:
        var timestamp := Time.get_ticks_msec() / 1000.0 - _start_time
        event_log.append_text("[b]%.2f[/b]s  %s\n" % [timestamp, message])
        var line := max(event_log.get_line_count() - 1, 0)
        event_log.scroll_to_line(line)
