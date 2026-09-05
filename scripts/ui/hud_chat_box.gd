## HUDChatBox — Controlador UI de la Caja de Chat en Pantalla (GDScript 2.0 / Godot 4).
##
## Muestra el historial de chat con BBCode coloreado y captura el foco de teclado al presionar 'Enter'.
## En plataformas móviles (Android/iOS), presenta un botón de Teclado Virtual que
## invoca OS.show_virtual_keyboard() para escribir y enviar mensajes sin teclado físico.

class_name HUDChatBox
extends Control

@onready var chat_history: RichTextLabel = get_node_or_null("%ChatHistory") as RichTextLabel
@onready var input_field: LineEdit        = get_node_or_null("%InputField") as LineEdit
@onready var btn_send: Button            = get_node_or_null("%BtnSend") as Button
@onready var era_banner: Label           = get_node_or_null("%EraBanner") as Label

# Botón de Teclado Virtual (auto-creado en plataformas móviles)
var _btn_keyboard: Button = null
var _is_mobile: bool = false

var ncm: NetworkChatManager = null

func _ready() -> void:
	add_to_group("hud_chat_box")
	process_mode = PROCESS_MODE_ALWAYS

	_is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

	ncm = NetworkChatManager.instance
	if not is_instance_valid(ncm):
		ncm = get_node_or_null("/root/NetworkChatManager") as NetworkChatManager

	if is_instance_valid(ncm):
		ncm.message_received.connect(_on_message_received)
		ncm.era_banner_announced.connect(_on_era_banner_announced)

	if is_instance_valid(btn_send):
		btn_send.pressed.connect(_send_current_text)

	if is_instance_valid(era_banner):
		era_banner.visible = false

	if is_instance_valid(chat_history):
		chat_history.bbcode_enabled = true
		chat_history.append_text("[color=#33FF66][SISTEMA]: Canal de Chat Multijugador activo. Presiona 'Enter' para escribir.[/color]\n")

	# Configurar entrada de texto para móvil
	if is_instance_valid(input_field):
		input_field.text_submitted.connect(_on_text_submitted)
		if _is_mobile:
			# Desactivar Enter como enviar en móvil (usa el botón en su lugar)
			input_field.virtual_keyboard_enabled = false

	if _is_mobile:
		_setup_virtual_keyboard_button()

func _unhandled_input(event: InputEvent) -> void:
	# Solo activar el chat por Enter en plataformas PC con teclado físico
	if _is_mobile:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
			_toggle_chat_focus()

func _on_text_submitted(_text: String) -> void:
	_send_current_text()

func _toggle_chat_focus() -> void:
	if not is_instance_valid(input_field):
		return

	if input_field.has_focus():
		_send_current_text()
		input_field.release_focus()
	else:
		input_field.grab_focus()

# ─── Teclado Virtual Móvil ────────────────────────────────────────────────────────
func _setup_virtual_keyboard_button() -> void:
	var row := find_child("InputRow", true, false) as Control
	if not is_instance_valid(row):
		row = self  # Fallback: añadir directamente en este Control

	_btn_keyboard = Button.new()
	_btn_keyboard.name = "BtnTeclado"
	_btn_keyboard.text = "⌨"
	_btn_keyboard.tooltip_text = "Abrir teclado virtual"
	_btn_keyboard.custom_minimum_size = Vector2(56.0, 56.0)
	_btn_keyboard.flat = false

	var style_kb := StyleBoxFlat.new()
	style_kb.bg_color = Color("#1A4060CC")  # Azul marino translúcido
	style_kb.corner_radius_top_left    = 8
	style_kb.corner_radius_top_right   = 8
	style_kb.corner_radius_bottom_left = 8
	style_kb.corner_radius_bottom_right = 8
	_btn_keyboard.add_theme_stylebox_override("normal",  style_kb)
	_btn_keyboard.add_theme_color_override("font_color", Color.WHITE)
	_btn_keyboard.add_theme_font_size_override("font_size", 26)

	row.add_child(_btn_keyboard)
	_btn_keyboard.pressed.connect(_on_btn_keyboard_pressed)

func _on_btn_keyboard_pressed() -> void:
	if not is_instance_valid(input_field):
		return
	# Desplegar el teclado nativo del sistema operativo móvil
	OS.show_virtual_keyboard(input_field.text)
	input_field.grab_focus()

	# Escuchar la entrada del teclado virtual y actualizar el campo de texto
	if not input_field.text_changed.is_connected(_on_virtual_keyboard_input):
		input_field.text_changed.connect(_on_virtual_keyboard_input)

func _on_virtual_keyboard_input(_new_text: String) -> void:
	# El teclado virtual actualiza directamente el text del LineEdit.
	# Al detectar '\n' (Return virtual), enviamos y limpiamos.
	if input_field.text.contains("\n"):
		input_field.text = input_field.text.replace("\n", "")
		_send_current_text()
		OS.hide_virtual_keyboard()

func _send_current_text() -> void:
	if not is_instance_valid(input_field):
		return
	var text := input_field.text.strip_edges()
	if not text.is_empty():
		if is_instance_valid(ncm):
			ncm.enviar_mensaje_local(text)
		input_field.text = ""

func _on_message_received(sender_name: String, text: String, color_code: String) -> void:
	if is_instance_valid(chat_history):
		var formatted := "[color=%s][b][%s]:[/b] %s[/color]\n" % [color_code, sender_name, text]
		chat_history.append_text(formatted)

func _on_era_banner_announced(player_name: String, era_id: int) -> void:
	if not is_instance_valid(era_banner):
		return

	var era_names := ["Prehistórica", "Piedra", "Bronce", "Hierro", "Medieval", "Renacimiento", "Industrial", "Atómica", "Digital", "Nano-Futurista"]
	var era_str := era_names[era_id] if (era_id >= 0 and era_id < era_names.size()) else "Nueva Era"

	era_banner.text = "📜 ¡%s HA AVANZADO A LA ERA %s!" % [player_name.to_upper(), era_str.to_upper()]
	era_banner.visible = true

	var tw := create_tween()
	tw.tween_property(era_banner, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.5)
	tw.tween_property(era_banner, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): era_banner.visible = false)
