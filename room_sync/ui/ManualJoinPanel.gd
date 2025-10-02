extends Panel

## Collects manual connection details and validates address + port input.
signal join_requested(address: String, port: int)
signal dismissed()

@export var default_port: int = 47845
@export var room_code_min_length: int = 4
@export var room_code_max_length: int = 8

@onready var _ip_input: LineEdit = %IpLineEdit
@onready var _port_input: LineEdit = %PortLineEdit
@onready var _join_button: Button = %JoinButton
@onready var _cancel_button: Button = %CancelButton
@onready var _error_label: Label = %ErrorLabel

var _busy := false

func _ready() -> void:
	_ip_input.text_changed.connect(_on_input_changed)
	_port_input.text_changed.connect(_on_input_changed)
	_join_button.pressed.connect(_on_join_pressed)
	_cancel_button.pressed.connect(func():
		reset_form()
		hide()
		dismissed.emit()
	)
	_error_label.visible = false
	_error_label.text = ""
	reset_form(_ip_input.text, default_port)

func focus_ip() -> void:
	_ip_input.grab_focus()

func reset_form(address: String = "", port: int = default_port) -> void:
	_busy = false
	_cancel_button.disabled = false
	_ip_input.editable = true
	_port_input.editable = true
	_ip_input.text = address.strip_edges()
	_port_input.text = str(port)
	_error_label.text = ""
	_error_label.visible = false
	_update_state()

func set_busy(is_busy: bool) -> void:
	_busy = is_busy
	_cancel_button.disabled = is_busy
	_ip_input.editable = not is_busy
	_port_input.editable = not is_busy
	_update_state()

func _on_join_pressed() -> void:
	if _busy:
		return
	var address := _ip_input.text.strip_edges()
	var port_text := _port_input.text.strip_edges()
	var validation := _validate(address, port_text)
	if validation["ok"]:
		_error_label.visible = false
		_error_label.text = ""
		var port := int(port_text)
		emit_signal("join_requested", address, port)
	else:
		_error_label.text = validation["error"]
		_error_label.visible = true

func _on_input_changed(_text: String) -> void:
	_update_state()

func _update_state() -> void:
	var address := _ip_input.text.strip_edges()
	var port_text := _port_input.text.strip_edges()
	var validation := _validate(address, port_text)
	_join_button.disabled = _busy or not validation["ok"]
	if validation["ok"]:
		_error_label.text = ""
		_error_label.visible = false
	elif not _error_label.text.is_empty():
		_error_label.visible = true

func _validate(address: String, port_text: String) -> Dictionary:
	if address.is_empty():
		return {"ok": false, "error": "Enter an address or room code."}
	var port_valid := _is_valid_port(port_text)
	var address_valid := _is_valid_ipv4(address) or _is_valid_hostname(address) or _is_valid_room_code(address)
	if not port_valid:
		return {"ok": false, "error": "Port must be between 1 and 65535."}
	if not address_valid:
		return {"ok": false, "error": "Use a valid IPv4, hostname, or room code."}
	return {"ok": true}

func _is_valid_port(value: String) -> bool:
	if value.is_empty() or not value.is_valid_int():
		return false
	var number := int(value)
	return number > 0 and number < 65536

func _is_valid_ipv4(address: String) -> bool:
	var segments := address.split(".", false)
	if segments.size() != 4:
		return false
	for segment in segments:
		if segment.is_empty() or not segment.is_valid_int():
			return false
		var number := int(segment)
		if number < 0 or number > 255:
			return false
	return true

func _is_valid_hostname(address: String) -> bool:
	if address.length() > 253:
		return false
	var allowed := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-."
	for char in address:
		if not allowed.contains(char):
			return false
	if address.begins_with("-") or address.ends_with("-"):
		return false
	return true

func _is_valid_room_code(address: String) -> bool:
	if address.is_empty():
		return false
	var upper := address.strip_edges().to_upper()
	if upper.length() < room_code_min_length or upper.length() > room_code_max_length:
		return false
	for char in upper:
		var is_letter := char >= "A" and char <= "Z"
		var is_number := char >= "0" and char <= "9"
		if not (is_letter or is_number):
			return false
	return true
