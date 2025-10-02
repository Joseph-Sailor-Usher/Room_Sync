extends Node

## Tracks LAN room candidates and elects a host using simple heuristics.
signal host_changed(peer_id: String, descriptor: Dictionary)
signal roster_updated(candidates: Dictionary)

@export var local_peer_id: String = ""
@export var require_local_candidate: bool = true

var _candidates: Dictionary = {}
var _current_host_id: String = ""

func set_local_peer_id(peer_id: String) -> void:
	local_peer_id = peer_id
	if require_local_candidate and not _candidates.has(peer_id):
		push_warning("Local peer updated but not present in candidate list")

func register_candidate(peer_id: String, descriptor: Dictionary) -> void:
	if peer_id.is_empty():
		push_warning("Attempted to register candidate without peer_id")
		return
	_candidates[peer_id] = descriptor.duplicate(true)
	_evaluate_host()
	roster_updated.emit(_candidates.duplicate(true))

func remove_candidate(peer_id: String) -> void:
	if not _candidates.has(peer_id):
		return
	_candidates.erase(peer_id)
	_evaluate_host()
	roster_updated.emit(_candidates.duplicate(true))

func clear_candidates() -> void:
	_candidates.clear()
	_evaluate_host()
	roster_updated.emit(_candidates.duplicate(true))

func get_current_host_id() -> String:
	return _current_host_id

func get_candidate(peer_id: String) -> Dictionary:
	return _candidates.get(peer_id, {}).duplicate(true)

func _evaluate_host() -> void:
	if _candidates.is_empty():
		_set_host("")
		return
	var ranked := []
	for peer_id in _candidates.keys():
		var descriptor: Dictionary = _candidates[peer_id]
		ranked.append({
			"peer_id": peer_id,
			"score": _score_candidate(peer_id, descriptor),
			"latency": descriptor.get("latency_ms", 0.0)
		})
	ranked.sort_custom(func(a, b):
		if a.score == b.score:
			if a.latency == b.latency:
				return a.peer_id < b.peer_id
			return a.latency < b.latency
		return a.score > b.score
	)
	# var best := ranked.front()
	if require_local_candidate and not _candidates.has(local_peer_id):
		push_warning("Local peer is not registered; host election may be stale")
	_set_host(ranked.front().peer_id)

func _score_candidate(peer_id: String, descriptor: Dictionary) -> float:
	var performance := float(descriptor.get("performance_score", 0.0))
	var battery := float(descriptor.get("battery_level", 0.0))
	var latency := float(descriptor.get("latency_ms", 0.0))
	# var favors_local := peer_id == local_peer_id ? 5.0 : 0.0
	# Placeholder heuristic:
	# - prioritize higher performance and battery
	# - penalize latency modestly
	# - nudge toward the local peer if scores tie to speed up testing
	# return (performance * 0.6) + (battery * 0.3) - (latency * 0.1) + favors_local
	return (performance * 0.6) + (battery * 0.3) - (latency * 0.1)

func _set_host(peer_id: String) -> void:
	if _current_host_id == peer_id:
		return
	_current_host_id = peer_id
	var descriptor: String = _candidates.get(peer_id, {}).duplicate(true)
	host_changed.emit(peer_id, descriptor)

func snapshot_room() -> Dictionary:
	return {
		"host_id": _current_host_id,
		"candidates": _candidates.duplicate(true)
	}
