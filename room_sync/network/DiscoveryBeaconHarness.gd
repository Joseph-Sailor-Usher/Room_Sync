extends Node

@onready var beacon = $DiscoveryBeacon

func _ready() -> void:
	beacon.beacon_sent.connect(_on_beacon_sent)
	beacon.beacon_skipped.connect(_on_beacon_skipped)
	if not beacon.is_processing():
		beacon.start()

func _on_beacon_sent(sequence: int) -> void:
	print("Beacon sent, sequence =", sequence)
	print(JSON.stringify(beacon._build_payload()))

func _on_beacon_skipped(reason: String) -> void:
	push_warning("Beacon skipped: %s" % reason)
