# RhythmDebugger.gd
extends Node

@export var notifier_path: NodePath
var r: RhythmNotifier
@onready var slides := %Slides

func _ready() -> void:
	# Resolve the RhythmNotifier
	if notifier_path != NodePath():
		r = get_node(notifier_path) as RhythmNotifier
	else:
		r = $"Rythm Debugger/RythmNotifier"

	assert(r != null, "RhythmDebugger: RhythmNotifier not found")

	# If no audio is playing, let it free-run so signals emit.
	if not r.running and not _stream_is_playing():
		r.running = true

	# Once per beat
	r.beat.connect(func(current_beat: int) -> void:
		_print_snapshot("BEAT", current_beat)
		slides.next()
	)

	# Every 4 beats (0,4,8,...) — prints the measure number (1-indexed)
	r.beats(4).connect(func(group_idx: int) -> void:
		_print_snapshot("MEASURE", group_idx + 1)
	)

	# A single off-beat example (8.5)
	r.beats(0, false, 8.5).connect(func(_i): 
		_print_snapshot("SPECIAL 8.5", r.current_beat)
	)

func _print_snapshot(tag: String, idx: int) -> void:
	# Grab live info from the notifier and print a compact line.
	var pos := r.current_position
	var beat_len := r.beat_length
	var bpm := r.bpm
	var cur_beat := r.current_beat
	print("[%s] t=%.3f  bpm=%.2f  beat_len=%.3f  current_beat=%s  idx=%s"
		% [tag, pos, bpm, beat_len, str(cur_beat), str(idx)]
	)

func _stream_is_playing() -> bool:
	return r.audio_stream_player != null and r.audio_stream_player.playing
