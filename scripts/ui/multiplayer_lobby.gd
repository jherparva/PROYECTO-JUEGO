## MultiplayerLobby — Menú de Conexión y Reglas de Partida Estilo Empire Earth (Godot 4.3).
##
## Estructura de dos columnas: 8 slots híbridos (tipo, bando, color) y opciones globales de partida.
## Sincronización RPC fiable de ajustes en tiempo real e inyección masiva en GameSettings al iniciar.

class_name MultiplayerLobby
extends Control

# ─── Constantes y Colores Clásicos RTS ──────────────────────────────────────
const CLR_PANEL_BG  := Color(0.118, 0.063, 0.031, 0.90) # Caoba oscuro #1E1008
const CLR_BORDER    := Color(0.831, 0.686, 0.216, 1.0)  # Dorado #D4AF37
const CLR_GOLD      := Color(1.0, 0.88, 0.28, 1.0)     # Amarillo brillante
const CLR_TEXT_DIM  := Color(0.9, 0.85, 0.70, 1.0)

const PALETA_COLORES: Array[Dictionary] = [
	{"nombre": "Rojo",     "color": Color(0.90, 0.15, 0.15, 1.0)},
	{"nombre": "Azul",     "color": Color(0.15, 0.45, 0.95, 1.0)},
	{"nombre": "Amarillo", "color": Color(0.95, 0.85, 0.15, 1.0)},
	{"nombre": "Verde",    "color": Color(0.15, 0.85, 0.25, 1.0)},
	{"nombre": "Cian",     "color": Color(0.15, 0.85, 0.85, 1.0)},
	{"nombre": "Púrpura",  "color": Color(0.65, 0.20, 0.85, 1.0)},
	{"nombre": "Naranja",  "color": Color(0.95, 0.50, 0.15, 1.0)},
	{"nombre": "Gris",     "color": Color(0.60, 0.60, 0.60, 1.0)}
]

const ERAS_LIST: Array[String] = [
	"0. Prehistórica", "1. Piedra", "2. Bronce", "3. Hierro", "4. Medieval",
	"5. Renacimiento", "6. Industrial", "7. Atómica", "8. Digital", "9. Nano-Futurista"
]

const GAME_TYPES: Array[String] = ["Mapa Aleatorio", "Escenario Personalizado"]
const MAP_SIZES: Array[String] = ["Pequeño (200m)", "Mediano (400m)", "Grande (600m)", "Gigante (800m)"]
const BIOMES_LIST: Array[String] = ["Continental", "Islas (Dock3D)", "Planicie Desértica"]
const RESOURCES_PRESETS: Array[String] = ["Escasos", "Estándar", "Abundantes", "Torneo - Bajo (Deathmatch)"]
const POP_LIMITS: Array[int] = [50, 100, 150, 200, 250, 300, 400, 500]

# ─── Referencias a Nodos ──────────────────────────────────────────────────────
@onready var input_ip: LineEdit        = _get_line_edit(["%InputIP", "CenterPanel/Margin/VBox/HBoxConn/InputIP"])
@onready var input_port: LineEdit      = _get_line_edit(["%InputPort", "CenterPanel/Margin/VBox/HBoxConn/InputPort"])
@onready var btn_host: Button          = _get_btn(["%BtnHost", "%BtnCreateHost", "CenterPanel/Margin/VBox/HBoxConn/BtnHost"])
@onready var btn_join: Button          = _get_btn(["%BtnJoin", "CenterPanel/Margin/VBox/HBoxConn/BtnJoin"])
@onready var btn_start: Button         = _get_btn(["%BtnStart", "%BtnStartMatch", "CenterPanel/Margin/VBox/HBoxActions/BtnStart"])
@onready var btn_load_save: Button     = _get_btn(["%BtnLoadSave", "CenterPanel/Margin/VBox/HBoxActions/BtnLoadSave"])
@onready var btn_back: Button          = _get_btn(["%BtnBack", "CenterPanel/Margin/VBox/HBoxActions/BtnBack"])
@onready var lbl_status: Label         = _get_lbl(["%LblStatus", "%LblNetStatus", "CenterPanel/Margin/VBox/LblStatus"])
@onready var slots_container: VBoxContainer = get_node_or_null("%SlotsContainer") as VBoxContainer
@onready var rules_vbox: VBoxContainer      = get_node_or_null("%RulesVBox") as VBoxContainer
@onready var lobby_bg: TextureRect         = get_node_or_null("%LobbyBackground") as TextureRect
@onready var dark_overlay: ColorRect       = get_node_or_null("%DarkOverlay") as ColorRect

var mm: Node = null
var _is_loaded_save_game: bool = false

# Controles Derecha (Opciones Globales)
var _opt_game_type: OptionButton = null
var _opt_map_size: OptionButton  = null
var _opt_biome: OptionButton     = null
var _opt_resources: OptionButton = null
var _opt_start_era: OptionButton = null
var _opt_max_era: OptionButton   = null
var _opt_pop_limit: OptionButton = null
var _opt_game_speed: OptionButton = null

var _chk_show_map: CheckBox      = null
var _chk_custom_civ: CheckBox    = null
var _chk_lock_teams: CheckBox    = null
var _chk_cheats: CheckBox        = null

# Datos locales de slots para colores y equipos asignados (8 ranuras)
var _slot_colors: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7] # Índice de color por slot
var _slot_teams: Array[int]  = [1, 2, 1, 2, 1, 2, 1, 2] # Equipo numerico 1..4 por slot

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("multiplayer_lobby")
	_resolve_mm()

	if is_instance_valid(input_ip): input_ip.text = "127.0.0.1"
	if is_instance_valid(input_port): input_port.text = "4242"

	_setup_background()
	_build_right_rules_panel()
	_connect_buttons()
	_apply_styles_to_buttons()
	_connect_multiplayer_signals()
	_update_slots_ui()
	_update_interactivity_state()

	print("MultiplayerLobby Empire Earth Redesign: Inicializado.")

func _get_btn(candidates: Array) -> Button:
	for p in candidates:
		var n := get_node_or_null(str(p)) as Button
		if is_instance_valid(n): return n
	return null

func _get_line_edit(candidates: Array) -> LineEdit:
	for p in candidates:
		var n := get_node_or_null(str(p)) as LineEdit
		if is_instance_valid(n): return n
	return null

func _get_lbl(candidates: Array) -> Label:
	for p in candidates:
		var n := get_node_or_null(str(p)) as Label
		if is_instance_valid(n): return n
	return null

func _resolve_mm() -> Node:
	if is_instance_valid(mm): return mm
	var node: Node = get_node_or_null("/root/MultiplayerManager")
	if not is_instance_valid(node) and get_tree():
		if get_tree().current_scene:
			node = get_tree().current_scene.get_node_or_null("MultiplayerManager")
		if not is_instance_valid(node):
			node = get_tree().root.get_node_or_null("MultiplayerManager")
	if not is_instance_valid(node):
		print("MultiplayerLobby: Instanciando MultiplayerManager dinámicamente...")
		var scr := load("res://scripts/core/multiplayer_manager.gd") as GDScript
		if is_instance_valid(scr):
			node = scr.new()
			node.name = "MultiplayerManager"
			get_tree().root.add_child(node)
	if is_instance_valid(node):
		mm = node
		if mm.has_signal("lobby_slots_updated") and not mm.lobby_slots_updated.is_connected(_update_slots_ui):
			mm.lobby_slots_updated.connect(_update_slots_ui)
	return mm

# ─── Visuales y Fondo ─────────────────────────────────────────────────────────

func _setup_background() -> void:
	if is_instance_valid(dark_overlay):
		dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dark_overlay.color = Color(0.04, 0.02, 0.01, 0.75)
	if not is_instance_valid(lobby_bg): return
	lobby_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lobby_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	lobby_bg.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	lobby_bg.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	lobby_bg.modulate      = Color(0.25, 0.25, 0.25, 1.0)
	var tex: Texture2D = null
	for path in ["res://assets/main_menu_bg.png", "res://assets/main_menu_bg.jpg"]:
		if FileAccess.file_exists(path):
			var bytes := FileAccess.get_file_as_bytes(path)
			if bytes.size() > 0:
				var img := Image.new()
				if img.load_jpg_from_buffer(bytes) == OK or img.load_png_from_buffer(bytes) == OK:
					if not img.is_empty():
						tex = ImageTexture.create_from_image(img)
						break
	if tex == null:
		for path in ["res://assets/main_menu_bg.jpg", "res://assets/main_menu_bg.png"]:
			if ResourceLoader.exists(path):
				tex = load(path) as Texture2D
				break
	if is_instance_valid(tex):
		lobby_bg.texture = tex

# ─── Estilos de Botones y Paneles ─────────────────────────────────────────────

func _apply_styles_to_buttons() -> void:
	# Estilo píldora para botón Iniciar Partida
	if is_instance_valid(btn_start):
		var s_start := StyleBoxFlat.new()
		s_start.bg_color = Color(0.24, 0.15, 0.03, 0.98)
		s_start.border_color = Color(1.0, 0.85, 0.30, 1.0)
		s_start.border_width_left = 3
		s_start.border_width_top = 3
		s_start.border_width_right = 3
		s_start.border_width_bottom = 3
		s_start.corner_radius_top_left = 22
		s_start.corner_radius_top_right = 22
		s_start.corner_radius_bottom_left = 22
		s_start.corner_radius_bottom_right = 22
		s_start.shadow_color = Color(0.9, 0.7, 0.2, 0.5)
		s_start.shadow_size = 10
		btn_start.add_theme_stylebox_override("normal", s_start)
		btn_start.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35, 1.0))
		btn_start.add_theme_font_size_override("font_size", 18)

	# Estilo para Volver y Cargar
	var s_pill := StyleBoxFlat.new()
	s_pill.bg_color = Color(0.18, 0.11, 0.04, 0.95)
	s_pill.border_color = Color(0.70, 0.55, 0.22, 1.0)
	s_pill.border_width_left = 2
	s_pill.border_width_top = 2
	s_pill.border_width_right = 2
	s_pill.border_width_bottom = 2
	s_pill.corner_radius_top_left = 18
	s_pill.corner_radius_top_right = 18
	s_pill.corner_radius_bottom_left = 18
	s_pill.corner_radius_bottom_right = 18

	if is_instance_valid(btn_back):
		btn_back.add_theme_stylebox_override("normal", s_pill)
		btn_back.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	if is_instance_valid(btn_load_save):
		btn_load_save.add_theme_stylebox_override("normal", s_pill)
		btn_load_save.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))

	# Estilo para Botones de Conexión (Host y Join)
	var s_conn := StyleBoxFlat.new()
	s_conn.bg_color = Color(0.20, 0.13, 0.06, 0.95)
	s_conn.border_color = Color(0.75, 0.60, 0.22, 1.0)
	s_conn.border_width_left = 1
	s_conn.border_width_top = 1
	s_conn.border_width_right = 1
	s_conn.border_width_bottom = 1
	s_conn.corner_radius_top_left = 8
	s_conn.corner_radius_top_right = 8
	s_conn.corner_radius_bottom_left = 8
	s_conn.corner_radius_bottom_right = 8

	if is_instance_valid(btn_host):
		btn_host.add_theme_stylebox_override("normal", s_conn)
		btn_host.add_theme_color_override("font_color", CLR_GOLD)
	if is_instance_valid(btn_join):
		btn_join.add_theme_stylebox_override("normal", s_conn)
		btn_join.add_theme_color_override("font_color", CLR_GOLD)

# ─── Construcción de Columna Derecha (Opciones Globales y Previsualización) ───

func _build_right_rules_panel() -> void:
	if not is_instance_valid(rules_vbox): return

	for child in rules_vbox.get_children():
		child.queue_free()

	# ─── 1. Previsualización de Mapa Isométrico (Estilo multijugador.jpg) ─────
	var vbox_map_preview := VBoxContainer.new()
	vbox_map_preview.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_map_preview.add_theme_constant_override("separation", 4)

	var lbl_map_title := _create_label("VISUALIZACIÓN DE MAPA (Previsualización de Edad)")
	lbl_map_title.add_theme_color_override("font_color", CLR_GOLD)
	lbl_map_title.add_theme_font_size_override("font_size", 13)
	lbl_map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_map_preview.add_child(lbl_map_title)

	var iso_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/ui/iso_map_preview.png"):
		iso_tex = load("res://assets/ui/iso_map_preview.png") as Texture2D

	if is_instance_valid(iso_tex):
		var tex_rect := TextureRect.new()
		tex_rect.texture = iso_tex
		tex_rect.custom_minimum_size = Vector2(280, 100)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vbox_map_preview.add_child(tex_rect)

	rules_vbox.add_child(vbox_map_preview)

	var sep_map := HSeparator.new()
	rules_vbox.add_child(sep_map)

	# ─── 2. Cuadrícula de Selectores de Partida ──────────────────────────────
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 7)

	# 1. Tipo de Partida
	grid.add_child(_create_label("Tipo de Partida:"))
	_opt_game_type = _create_option_button(GAME_TYPES, 0)
	grid.add_child(_opt_game_type)

	# 2. Tamaño del Mapa
	grid.add_child(_create_label("Tamaño del Mapa:"))
	_opt_map_size = _create_option_button(MAP_SIZES, 1) # Mediano por defecto
	grid.add_child(_opt_map_size)

	# 3. Bioma / Terreno
	grid.add_child(_create_label("Tipo de Terreno:"))
	_opt_biome = _create_option_button(BIOMES_LIST, 0) # Continental
	grid.add_child(_opt_biome)

	# 4. Recursos Iniciales
	grid.add_child(_create_label("Recursos Iniciales:"))
	_opt_resources = _create_option_button(RESOURCES_PRESETS, 1) # Estándar
	grid.add_child(_opt_resources)

	# 5. Edad Inicial
	grid.add_child(_create_label("Edad Inicial:"))
	_opt_start_era = _create_option_button(ERAS_LIST, 0)
	grid.add_child(_opt_start_era)

	# 6. Edad Límite
	var max_eras_opts: Array[String] = ["Sin Límite"]
	max_eras_opts.append_array(ERAS_LIST)
	grid.add_child(_create_label("Edad Límite:"))
	_opt_max_era = _create_option_button(max_eras_opts, 0) # Sin Límite
	grid.add_child(_opt_max_era)

	# 7. Límite de Unidades
	var pop_strs: Array[String] = []
	for p in POP_LIMITS:
		pop_strs.append("%d Unidades" % p)
	grid.add_child(_create_label("Límite de Unidades:"))
	_opt_pop_limit = _create_option_button(pop_strs, 3) # 200 Unidades por defecto
	grid.add_child(_opt_pop_limit)

	# 8. Velocidad de Partida
	var speed_opts: Array[String] = [
		"Muy Lento (0.5x)", "Lento (0.75x)", "Normal / Torneo (1.0x)", "Rápido (1.4x)", "Muy Rápido (2.0x)"
	]
	grid.add_child(_create_label("Velocidad de Partida:"))
	_opt_game_speed = _create_option_button(speed_opts, 2)
	grid.add_child(_opt_game_speed)

	rules_vbox.add_child(grid)

	# Separador
	var sep := HSeparator.new()
	rules_vbox.add_child(sep)

	# ─── 3. Checkboxes de Reglas Especiales ──────────────────────────────────
	var lbl_rules := _create_label("Reglas Especiales:")
	lbl_rules.add_theme_color_override("font_color", CLR_GOLD)
	rules_vbox.add_child(lbl_rules)

	_chk_show_map = _create_checkbox("Mostrar mapa (Quitar niebla inicial)", false)
	rules_vbox.add_child(_chk_show_map)

	# Fila interactiva con botón de cresta dorada para Árbol de Ventajas
	var hbox_civ_rule := HBoxContainer.new()
	hbox_civ_rule.add_theme_constant_override("separation", 8)

	_chk_custom_civ = _create_checkbox("Personalizar civilización (Árbol de ventajas)", true)
	hbox_civ_rule.add_child(_chk_custom_civ)

	var btn_crest := Button.new()
	var crest_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/ui/crest_icon.png"):
		crest_tex = load("res://assets/ui/crest_icon.png") as Texture2D

	if is_instance_valid(crest_tex):
		btn_crest.icon = crest_tex
	else:
		btn_crest.text = "🏛️"

	btn_crest.custom_minimum_size = Vector2(28, 28)
	btn_crest.tooltip_text = "Abrir Configuración Avanzada de Civilización / Árbol de Ventajas"
	btn_crest.pressed.connect(_open_civ_tree_modal)
	_chk_custom_civ.toggled.connect(func(pressed: bool):
		if pressed:
			_open_civ_tree_modal()
	)
	hbox_civ_rule.add_child(btn_crest)
	rules_vbox.add_child(hbox_civ_rule)

	_chk_lock_teams = _create_checkbox("Bloquear equipos", true)
	_chk_cheats = _create_checkbox("Códigos de trucos", false)

	rules_vbox.add_child(_chk_lock_teams)
	rules_vbox.add_child(_chk_cheats)

	# Conectar cambio de opciones del Host para sync RPC
	_connect_right_panel_signals()

func _create_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", CLR_TEXT_DIM)
	return l

func _create_option_button(items: Array, default_idx: int) -> OptionButton:
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(240, 32)
	ob.add_theme_color_override("font_color", CLR_GOLD)
	for item in items:
		ob.add_item(str(item))
	ob.selected = default_idx
	return ob

func _create_checkbox(text: String, default_val: bool) -> CheckBox:
	var cb := CheckBox.new()
	cb.text = text
	cb.button_pressed = default_val
	cb.add_theme_color_override("font_color", CLR_TEXT_DIM)
	return cb

func _connect_right_panel_signals() -> void:
	var opts: Array = [_opt_game_type, _opt_map_size, _opt_biome, _opt_resources, _opt_start_era, _opt_max_era, _opt_pop_limit, _opt_game_speed]
	for i in range(opts.size()):
		var ob: OptionButton = opts[i]
		if is_instance_valid(ob):
			var opt_idx := i
			ob.item_selected.connect(func(val_idx: int):
				_play_sfx()
				_on_host_setting_changed("option_%d" % opt_idx, val_idx)
			)

	var chks: Array = [_chk_show_map, _chk_custom_civ, _chk_lock_teams, _chk_cheats]
	for i in range(chks.size()):
		var cb: CheckBox = chks[i]
		if is_instance_valid(cb):
			var chk_idx := i
			cb.toggled.connect(func(pressed: bool):
				_play_sfx()
				_on_host_setting_changed("check_%d" % chk_idx, pressed)
			)

# ─── Modal Árbol de Ventajas de Civilización ──────────────────────────────────

func _open_civ_tree_modal() -> void:
	_play_sfx()
	var existing = get_node_or_null("CivUpgradePanelModal")
	if is_instance_valid(existing):
		existing.visible = true
		return
	var cup := CivUpgradePanel.new()
	cup.name = "CivUpgradePanelModal"
	add_child(cup)
	cup.visible = true

# ─── Construcción de Columna Izquierda (8 Slots Híbridos con Retratos) ────────

func _update_slots_ui() -> void:
	var mgr: Node = _resolve_mm()
	if not is_instance_valid(mgr) or not is_instance_valid(slots_container):
		return

	for child in slots_container.get_children():
		child.queue_free()

	var slots: Array = mgr.lobby_slots
	var host_authority: bool = (not multiplayer.has_multiplayer_peer() or multiplayer.is_server() or mgr.is_host)

	for i in range(slots.size()):
		var slot_info: Dictionary = slots[i]

		# Contenedor de fila con estilo alternado
		var row_panel := PanelContainer.new()
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.16, 0.10, 0.05, 0.6) if (i % 2 == 0) else Color(0.12, 0.08, 0.04, 0.6)
		row_style.corner_radius_top_left = 6
		row_style.corner_radius_top_right = 6
		row_style.corner_radius_bottom_left = 6
		row_style.corner_radius_bottom_right = 6
		row_panel.add_theme_stylebox_override("panel", row_style)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		hbox.custom_minimum_size = Vector2(0, 36)

		# 1. Etiqueta de Índice
		var lbl_idx := Label.new()
		lbl_idx.text = " %d." % (i + 1)
		lbl_idx.custom_minimum_size = Vector2(22, 0)
		lbl_idx.add_theme_color_override("font_color", CLR_GOLD)
		lbl_idx.add_theme_font_size_override("font_size", 13)
		hbox.add_child(lbl_idx)

		# 2. Retrato del Jugador / Bot
		var tex_av := TextureRect.new()
		var av_path: String = "res://assets/ui/icons/avatar_slot_%d.png" % (i + 1)
		if ResourceLoader.exists(av_path):
			tex_av.texture = load(av_path) as Texture2D
		tex_av.custom_minimum_size = Vector2(30, 30)
		tex_av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hbox.add_child(tex_av)

		# 3. Pin táctico con color del slot
		var pin_lbl := Label.new()
		pin_lbl.text = "📍"
		var active_col_idx: int = _slot_colors[i] if i < _slot_colors.size() else (i % PALETA_COLORES.size())
		pin_lbl.modulate = PALETA_COLORES[active_col_idx]["color"]
		hbox.add_child(pin_lbl)

		# 4. Dropdown Tipo de Ranura: [Humano], [Bot IA (Normal)], [Bot IA (Difícil)], [Cerrado]
		var opt_type := OptionButton.new()
		opt_type.add_item("👤 Humano")
		opt_type.add_item("🤖 Bot IA (Normal)")
		opt_type.add_item("🤖 Bot IA (Difícil)")
		opt_type.add_item("🔒 Cerrado")
		opt_type.custom_minimum_size = Vector2(145, 30)

		var slot_type_val: int = int(slot_info.get("type", 0))
		match slot_type_val:
			1: opt_type.selected = 0 # HUMAN
			2:
				var diff: String = str(slot_info.get("ai_difficulty", "normal"))
				opt_type.selected = 2 if diff == "dificil" else 1
			3: opt_type.selected = 3 # CLOSED
			_: opt_type.selected = 0 # Default OPEN/HUMAN

		opt_type.disabled = not host_authority or (i == 0) # Slot 0 es Host
		var slot_idx := i
		opt_type.item_selected.connect(func(idx: int):
			_play_sfx()
			_on_slot_type_changed(slot_idx, idx)
		)
		hbox.add_child(opt_type)

		# 5. Dropdown Equipo: "-", "1", "2", "3", "4"
		var opt_team := OptionButton.new()
		opt_team.add_item("Sin Equipo (-)")
		opt_team.add_item("Equipo 1")
		opt_team.add_item("Equipo 2")
		opt_team.add_item("Equipo 3")
		opt_team.add_item("Equipo 4")
		opt_team.custom_minimum_size = Vector2(105, 30)
		opt_team.selected = _slot_teams[i] if i < _slot_teams.size() else 1
		opt_team.disabled = not host_authority
		opt_team.item_selected.connect(func(idx: int):
			_play_sfx()
			_on_slot_team_changed(slot_idx, idx)
		)
		hbox.add_child(opt_team)

		# 6. Dropdown Color + Rect de Muestra
		var opt_color := OptionButton.new()
		for c_dict in PALETA_COLORES:
			opt_color.add_item(c_dict["nombre"])
		opt_color.custom_minimum_size = Vector2(90, 30)
		opt_color.selected = _slot_colors[i] if i < _slot_colors.size() else (i % PALETA_COLORES.size())
		opt_color.disabled = not host_authority and (multiplayer.get_unique_id() != slot_info.get("peer_id", 0))

		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = Vector2(22, 22)
		var active_col: Color = PALETA_COLORES[opt_color.selected]["color"]
		color_rect.color = active_col
		color_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		opt_color.item_selected.connect(func(c_idx: int):
			_play_sfx()
			_on_slot_color_changed(slot_idx, c_idx, color_rect, opt_color, pin_lbl)
		)
		hbox.add_child(opt_color)
		hbox.add_child(color_rect)

		# 7. Nombre del Slot / Estado
		var lbl_name := Label.new()
		lbl_name.text = str(slot_info.get("name", "Jugador %d" % (i + 1)))
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_name.add_theme_color_override("font_color", CLR_TEXT_DIM)
		lbl_name.add_theme_font_size_override("font_size", 13)
		hbox.add_child(lbl_name)

		row_panel.add_child(hbox)
		slots_container.add_child(row_panel)

# ─── Validación de Colores y Cambio de Ranuras ───────────────────────────────

func _on_slot_color_changed(slot_idx: int, chosen_color_idx: int, rect_node: ColorRect, opt_node: OptionButton, pin_node: Label = null) -> void:
	# Comprobar si el color está ocupado en otro slot activo
	for s_i in range(_slot_colors.size()):
		if s_i != slot_idx and _slot_colors[s_i] == chosen_color_idx:
			_set_status("⚠️ El color '%s' ya está ocupado por la ranura %d." % [
				PALETA_COLORES[chosen_color_idx]["nombre"], s_i + 1
			], Color(1.0, 0.6, 0.2))
			opt_node.selected = _slot_colors[slot_idx]
			return

	_slot_colors[slot_idx] = chosen_color_idx
	var chosen_col: Color = PALETA_COLORES[chosen_color_idx]["color"]
	if is_instance_valid(rect_node):
		rect_node.color = chosen_col
	if is_instance_valid(pin_node):
		pin_node.modulate = chosen_col

	if multiplayer.has_multiplayer_peer():
		rpc("rpc_sincronizar_ajuste_lobby", "slot_color_%d" % slot_idx, chosen_color_idx)

func _on_slot_team_changed(slot_idx: int, chosen_team_idx: int) -> void:
	_slot_teams[slot_idx] = chosen_team_idx
	var mgr: Node = _resolve_mm()
	if is_instance_valid(mgr) and "lobby_slots" in mgr:
		var slots: Array = mgr.lobby_slots
		if slot_idx < slots.size():
			slots[slot_idx]["bando"] = chosen_team_idx

	if multiplayer.has_multiplayer_peer():
		rpc("rpc_sincronizar_ajuste_lobby", "slot_team_%d" % slot_idx, chosen_team_idx)

func _on_slot_type_changed(slot_idx: int, type_choice_idx: int) -> void:
	var mgr: Node = _resolve_mm()
	if not is_instance_valid(mgr) or not mgr.is_host: return

	var slots: Array = mgr.lobby_slots
	if slot_idx >= slots.size(): return

	match type_choice_idx:
		0: # HUMANO / OPEN
			var p_id: int = int(slots[slot_idx].get("peer_id", 0))
			if p_id > 0:
				slots[slot_idx]["type"] = 1 # SlotType.HUMAN
				slots[slot_idx]["status"] = "HUMANO"
				slots[slot_idx]["name"] = "Jugador_%d" % p_id
			else:
				slots[slot_idx]["type"] = 0 # SlotType.OPEN
				slots[slot_idx]["status"] = "OPEN"
				slots[slot_idx]["name"] = "Ranura Abierta (%d)" % (slot_idx + 1)
		1: # BOT IA (Normal)
			slots[slot_idx]["type"] = 2 # SlotType.BOT
			slots[slot_idx]["status"] = "BOT_IA"
			slots[slot_idx]["name"] = "Bot IA (Normal)"
			slots[slot_idx]["ai_difficulty"] = "normal"
		2: # BOT IA (Difícil)
			slots[slot_idx]["type"] = 2 # SlotType.BOT
			slots[slot_idx]["status"] = "BOT_IA"
			slots[slot_idx]["name"] = "Bot IA (Difícil)"
			slots[slot_idx]["ai_difficulty"] = "dificil"
		3: # CERRADO
			slots[slot_idx]["type"] = 3 # SlotType.CLOSED
			slots[slot_idx]["status"] = "CERRADO"
			slots[slot_idx]["name"] = "🔒 Cerrado"
			slots[slot_idx]["peer_id"] = 0

	if mgr.has_method("rpc") and multiplayer.has_multiplayer_peer():
		mgr.rpc("rpc_sincronizar_slots", slots)

	if mgr.has_signal("lobby_slots_updated"):
		mgr.lobby_slots_updated.emit()

# ─── Sincronización RPC Fiable ────────────────────────────────────────────────

func _on_host_setting_changed(param: String, val: Variant) -> void:
	if not (not multiplayer.has_multiplayer_peer() or multiplayer.is_server()):
		return
	if multiplayer.has_multiplayer_peer():
		rpc("rpc_sincronizar_ajuste_lobby", param, val)

@rpc("any_peer", "call_local", "reliable")
func rpc_sincronizar_ajuste_lobby(parametro: String, valor: Variant) -> void:
	print("Lobby RPC Sync: %s = %s" % [parametro, str(valor)])

	if parametro.begins_with("slot_color_"):
		var idx := int(parametro.replace("slot_color_", ""))
		if idx >= 0 and idx < _slot_colors.size():
			_slot_colors[idx] = int(valor)
			_update_slots_ui()
		return

	if parametro.begins_with("slot_team_"):
		var idx := int(parametro.replace("slot_team_", ""))
		if idx >= 0 and idx < _slot_teams.size():
			_slot_teams[idx] = int(valor)
			_update_slots_ui()
		return

	if parametro.begins_with("option_"):
		var opt_idx := int(parametro.replace("option_", ""))
		var opts: Array = [_opt_game_type, _opt_map_size, _opt_biome, _opt_resources, _opt_start_era, _opt_max_era, _opt_pop_limit]
		if opt_idx >= 0 and opt_idx < opts.size():
			var ob: OptionButton = opts[opt_idx]
			if is_instance_valid(ob):
				ob.selected = int(valor)
		return

	if parametro.begins_with("check_"):
		var chk_idx := int(parametro.replace("check_", ""))
		var chks: Array = [_chk_show_map, _chk_custom_civ, _chk_lock_teams, _chk_cheats]
		if chk_idx >= 0 and chk_idx < chks.size():
			var cb: CheckBox = chks[chk_idx]
			if is_instance_valid(cb):
				cb.button_pressed = bool(valor)
		return

# Habilitar/Deshabilitar según autoridad de Host
func _update_interactivity_state() -> void:
	var host_authority: bool = (not multiplayer.has_multiplayer_peer() or multiplayer.is_server())
	var opts: Array = [_opt_game_type, _opt_map_size, _opt_biome, _opt_resources, _opt_start_era, _opt_max_era, _opt_pop_limit]
	for ob in opts:
		if is_instance_valid(ob):
			ob.disabled = not host_authority

	var chks: Array = [_chk_show_map, _chk_custom_civ, _chk_lock_teams, _chk_cheats]
	for cb in chks:
		if is_instance_valid(cb):
			cb.disabled = not host_authority

# ─── Audio y Conexiones de Botones ────────────────────────────────────────────

func _play_sfx() -> void:
	var sm := get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
		sm.call("jugar_sfx_interfaz", "buy_click")

func _connect_buttons() -> void:
	for b: Button in [btn_host, btn_join, btn_start, btn_load_save, btn_back]:
		if is_instance_valid(b): b.mouse_entered.connect(func(): _play_sfx())
	if is_instance_valid(btn_host):      btn_host.pressed.connect(_on_host_pressed)
	if is_instance_valid(btn_join):      btn_join.pressed.connect(_on_join_pressed)
	if is_instance_valid(btn_start):
		btn_start.pressed.connect(_on_start_pressed)
		btn_start.disabled = true
	if is_instance_valid(btn_load_save):
		btn_load_save.pressed.connect(_on_load_save_pressed)
		btn_load_save.disabled = true
	if is_instance_valid(btn_back):      btn_back.pressed.connect(_on_back_pressed)

func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_conectado):
		multiplayer.peer_connected.connect(_on_peer_conectado)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_desconectado):
		multiplayer.peer_disconnected.connect(_on_peer_desconectado)
	if not multiplayer.connected_to_server.is_connected(_on_conectado_al_servidor):
		multiplayer.connected_to_server.connect(_on_conectado_al_servidor)
	if not multiplayer.connection_failed.is_connected(_on_conexion_fallida):
		multiplayer.connection_failed.connect(_on_conexion_fallida)
	if not multiplayer.server_disconnected.is_connected(_on_servidor_desconectado):
		multiplayer.server_disconnected.connect(_on_servidor_desconectado)

# ─── Botones Acción ───────────────────────────────────────────────────────────

func _on_host_pressed() -> void:
	_play_sfx()
	var mgr: Node = _resolve_mm()
	if not is_instance_valid(mgr):
		_set_status("❌ [ERROR]: No se pudo instanciar MultiplayerManager.", Color(1.0, 0.3, 0.3))
		return
	var port := int(input_port.text) if is_instance_valid(input_port) else 4242
	var err: int = int(mgr.crear_servidor(port))
	if err == OK:
		_set_status("🟢 [SERVIDOR]: Escuchando conexiones locales en el Puerto %d de forma segura..." % port, Color(0.2, 0.9, 0.3))
		if is_instance_valid(btn_start): btn_start.disabled = false
		if is_instance_valid(btn_load_save): btn_load_save.disabled = false
		_update_interactivity_state()
		_update_slots_ui()
	else:
		_set_status("❌ [ERROR]: No se pudo levantar el servidor en el puerto %d (Err: %d)" % [port, err], Color(1.0, 0.3, 0.3))

func _on_join_pressed() -> void:
	_play_sfx()
	var mgr: Node = _resolve_mm()
	if not is_instance_valid(mgr):
		_set_status("❌ [ERROR]: No se pudo instanciar MultiplayerManager.", Color(1.0, 0.3, 0.3))
		return
	var ip   := input_ip.text if is_instance_valid(input_ip) else "127.0.0.1"
	var port := int(input_port.text) if is_instance_valid(input_port) else 4242
	_set_status("🟡 [CONEXIÓN]: Intentando enlazar por IP directa hacia %s:%d..." % [ip, port], Color(1.0, 0.85, 0.2))
	var err: int = int(mgr.unirse_a_servidor(ip, port))
	if err != OK:
		_set_status("❌ [ERROR]: Error al iniciar cliente ENet para %s:%d (Err: %d)" % [ip, port, err], Color(1.0, 0.3, 0.3))

func _on_load_save_pressed() -> void:
	_play_sfx()
	var mgr: Node = _resolve_mm()
	if is_instance_valid(mgr) and mgr.is_host:
		if mgr.cargar_partida_guardada_en_lobby("quicksave.json"):
			_is_loaded_save_game = true
			_set_status("📂 Partida Guardada vinculada al lobby. Presiona INICIAR PARTIDA.", Color(0.3, 0.85, 1.0))
		else:
			_set_status("⚠️ No se encontró 'user://saves/quicksave.json' válido.", Color(1.0, 0.6, 0.2))

func _on_start_pressed() -> void:
	_play_sfx()
	var mgr: Node = _resolve_mm()
	if not is_instance_valid(mgr) or not mgr.is_host: return

	# Inyección Masiva en GameSettings
	_inject_massive_settings_to_game()

	if _is_loaded_save_game:
		_set_status("🚀 Reanudando partida guardada en red...", Color(0.2, 0.9, 0.4))
		mgr.continuar_partida_guardada_multijugador("quicksave.json")
	else:
		_set_status("🚀 Cargando mapa procedural 3D e inicializando IAs...", Color(0.2, 0.9, 0.4))
		mgr.iniciar_partida_hibrida()

func _on_back_pressed() -> void:
	_play_sfx()
	var mgr: Node = _resolve_mm()
	if is_instance_valid(mgr): mgr.cerrar_conexion()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu_vintage.tscn")

# ─── Inyección Masiva en GameSettings ─────────────────────────────────────────

func _inject_massive_settings_to_game() -> void:
	var gs: Node = get_node_or_null("/root/GameSettings")
	if not is_instance_valid(gs):
		var scr := load("res://scripts/core/game_settings.gd") as GDScript
		if is_instance_valid(scr):
			gs = scr.new()
			gs.name = "GameSettings"
			get_tree().root.add_child(gs)
	if not is_instance_valid(gs): return

	var res_keys: Array[String] = ["escaso", "normal", "abundante", "deathmatch"]
	var start_era: int = _opt_start_era.selected if is_instance_valid(_opt_start_era) else 0
	var max_era_idx: int = _opt_max_era.selected if is_instance_valid(_opt_max_era) else 0
	var max_era_val: int = 9 if max_era_idx == 0 else (max_era_idx - 1)
	var res_idx: int = _opt_resources.selected if is_instance_valid(_opt_resources) else 1
	var pop_limit: int = POP_LIMITS[_opt_pop_limit.selected] if is_instance_valid(_opt_pop_limit) else 200
	var biome_idx: int = _opt_biome.selected if is_instance_valid(_opt_biome) else 0
	var map_size_idx: int = _opt_map_size.selected if is_instance_valid(_opt_map_size) else 1

	# ─── Semilla aleatoria única por partida ───────────────────────────────────
	var new_seed: int = randi()

	gs.set("starting_era",         start_era)
	gs.set("max_era",              max_era_val)
	gs.set("max_population_limit", pop_limit)
	gs.set("starting_resources",   res_keys[clampi(res_idx, 0, res_keys.size() - 1)])
	gs.set("map_type",             "aleatorio" if (_opt_game_type and _opt_game_type.selected == 0) else "custom")
	gs.set("map_size_preset",      map_size_idx)  # 0=Pequeño 1=Mediano 2=Grande 3=Gigante
	gs.set("map_biome",            biome_idx)      # 0=Continental 1=Islas 2=Planicie
	gs.set("map_seed",             new_seed)       # Semilla única

	gs.set("show_map",           _chk_show_map.button_pressed   if is_instance_valid(_chk_show_map)   else false)
	gs.set("fog_of_war_enabled", not _chk_show_map.button_pressed if is_instance_valid(_chk_show_map) else true)
	gs.set("custom_civ",         _chk_custom_civ.button_pressed if is_instance_valid(_chk_custom_civ) else true)
	gs.set("lock_teams",         _chk_lock_teams.button_pressed if is_instance_valid(_chk_lock_teams) else true)
	gs.set("cheat_codes",        _chk_cheats.button_pressed    if is_instance_valid(_chk_cheats)     else false)

	var speed_factors: Array[float] = [0.5, 0.75, 1.0, 1.4, 2.0]
	var spd_idx: int = _opt_game_speed.selected if is_instance_valid(_opt_game_speed) else 2
	var speed_val: float = speed_factors[clampi(spd_idx, 0, speed_factors.size() - 1)]
	gs.set("game_speed_modifier", speed_val)
	gs.set("game_speed",          speed_val)
	Engine.time_scale = speed_val

	# Asignación de colores y equipos por slot
	var slot_color_values: Array[Color] = []
	for c_idx in _slot_colors:
		slot_color_values.append(PALETA_COLORES[c_idx]["color"])

	gs.set("slot_colors", slot_color_values)
	gs.set("slot_teams",  _slot_teams)

	# Sincronizar ResourceManager
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/GlobalResourceManager")
	if is_instance_valid(rm):
		if "max_population" in rm:
			rm.set("max_population", pop_limit)
		if "max_era" in rm:
			rm.set("max_era", max_era_val)
		if rm.has_method("_aplicar_nueva_era"):
			rm.call("_aplicar_nueva_era", start_era)
		var amounts: Dictionary = gs.call("get_starting_resource_amounts") if gs.has_method("get_starting_resource_amounts") else {}
		for res in amounts:
			if res in rm:
				rm.set(res, amounts[res])

	print("MultiplayerLobby: ✅ Inyección Masiva completada → Era: %d | Mapa: %d | Bioma: %d | Seed: %d | Pob: %d" % [
		start_era, map_size_idx, biome_idx, new_seed, pop_limit
	])

# ─── Callbacks de Red ─────────────────────────────────────────────────────────

func _on_peer_conectado(id: int) -> void:
	_set_status("👤 ¡Nuevo jugador en la sala! (Peer ID: %d)" % id, Color(0.2, 0.9, 0.4))
	_update_interactivity_state()
	_update_slots_ui()

func _on_peer_desconectado(id: int) -> void:
	_set_status("👤 Jugador desconectado (Peer ID: %d)." % id, Color(0.9, 0.6, 0.2))
	_update_slots_ui()

func _on_conectado_al_servidor() -> void:
	_set_status("🟢 [CLIENTE]: ¡Conexión exitosa con el Servidor Host!", Color(0.2, 0.9, 0.4))
	_update_interactivity_state()
	_update_slots_ui()

func _on_conexion_fallida() -> void:
	_set_status("❌ [ERROR]: Error crítico de red. Tiempo de espera agotado.", Color(1.0, 0.3, 0.3))

func _on_servidor_desconectado() -> void:
	_set_status("🔴 [DESCONEXIÓN]: El Servidor Host ha cerrado la sesión.", Color(1.0, 0.3, 0.3))

func _set_status(msg: String, text_color: Color = CLR_TEXT_DIM) -> void:
	if is_instance_valid(lbl_status):
		lbl_status.text = msg
		lbl_status.add_theme_color_override("font_color", text_color)
