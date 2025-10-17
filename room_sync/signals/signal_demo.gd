extends Panel

@onready var slides := %Slides
@export var grab_focus_on_became_visible := false

func _ready():
	for child in get_children():
		if child is BaseButton:
			var b: BaseButton = child
			b.pressed.connect(_on_pressed.bind(b))
			b.button_down.connect(_on_button_down.bind(b))
			b.button_up.connect(_on_button_up.bind(b))
			b.mouse_entered.connect(_on_mouse_entered.bind(b))
			b.mouse_exited.connect(_on_mouse_exited.bind(b))
			b.focus_entered.connect(_on_focus_entered.bind(b))
			b.focus_exited.connect(_on_focus_exited.bind(b))
	assert(slides != null, "Slides not found. Use Unique Name or set slides_path.")
	visibility_changed.connect(_on_vis_changed)
	call_deferred("_on_vis_changed")

func _on_pressed(b):			print(b.name, " pressed")
func _on_button_down(b):		print(b.name, " down")
func _on_button_up(b):			print(b.name, " up")
func _on_mouse_entered(b):		print(b.name, " mouse entered")
func _on_mouse_exited(b):		print(b.name, " mouse exited")
func _on_focus_entered(b):		print(b.name, " focus entered")
func _on_focus_exited(b):		print(b.name, " focus exited")

func _on_vis_changed() -> void:
	if !is_visible_in_tree(): return
	await get_tree().process_frame
	await get_tree().process_frame
	var t := _first_focusable()
	if t:
		t.focus_mode = Control.FOCUS_ALL
		t.grab_focus()
		print("Focus ->", t.get_path())

func _first_focusable() -> Control:
	for n in self.find_children("*", "Control", true, false):
		var c := n as Control
		if c and c.is_visible_in_tree() and c.focus_mode != Control.FOCUS_NONE:
			if "disabled" in c and c.disabled:
				continue
			return c
	return null

# The result of get_signal_list on a button node
#[{ "name": "pressed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "button_up", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "button_down", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "toggled", "args": [{ "name": "toggled_on", "class_name": &"", "type": 1, "hint": 0, "hint_string": "", "usage": 6 }], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "resized", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "gui_input", "args": [{ "name": "event", "class_name": &"InputEvent", "type": 24, "hint": 17, "hint_string": "InputEvent", "usage": 6 }],"default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "mouse_entered", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "mouse_exited", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "focus_entered", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "focus_exited", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "size_flags_changed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "minimum_size_changed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "theme_changed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "draw", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "visibility_changed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "hidden", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "item_rect_changed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "ready", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "renamed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "tree_entered", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "tree_exiting", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "tree_exited", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "child_entered_tree", "args": [{ "name": "node", "class_name": &"Node", "type": 24, "hint": 0, "hint_string": "", "usage": 6 }], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "child_exiting_tree", "args": [{ "name": "node", "class_name": &"Node", "type": 24, "hint": 0, "hint_string": "", "usage": 6 }], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "child_order_changed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "replacing_by", "args": [{ "name": "node", "class_name": &"Node", "type": 24, "hint": 0, "hint_string": "", "usage": 6 }], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "editor_description_changed", "args": [{ "name": "node", "class_name": &"Node", "type": 24, "hint": 0, "hint_string": "", "usage": 6 }], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "editor_state_changed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "script_changed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } },
 #{ "name": "property_list_changed", "args": [], "default_args": [], "flags": 1, "id": 0, "return": { "name": "", "class_name": &"", "type": 0, "hint": 0, "hint_string": "", "usage": 6 } }]
