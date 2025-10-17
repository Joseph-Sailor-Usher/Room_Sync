extends Node

var _slides: Array[Node] = []
var _i := -1

func _ready():
	_slides = get_children()
	if _slides.is_empty(): return
	goto_slide(0)

func next(): goto_slide(_i + 1)
func prev(): goto_slide(_i - 1)
func count() -> int: return _slides.size()

func goto_slide(i: int):
	print("Going to slide: " + str(i))
	if _slides.is_empty(): return
	if _i == _slides.size() - 1 and i == _slides.size():
		i = 0
	elif _i == 0 and i == -1:
		i = _slides.size() - 1
	else:
		i = clamp(i, 0, _slides.size() - 1)
	if i == _i: return
	
	# deactivate all
	for s in _slides:
		_set_active(s, false)

	# activate target
	_set_active(_slides[i], true)
	_i = i

func _set_active(n: Node, on: bool):
	if n is CanvasItem: n.visible = on
	n.set_process(on)
	n.set_physics_process(on)
	for c in n.get_children():
		_set_active(c, on)

func _on_back_button_down() -> void:
	prev()

func _on_next_button_down() -> void:
	next()
