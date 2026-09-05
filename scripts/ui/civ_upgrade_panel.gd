## CivUpgradePanel — Configuración Avanzada de Civilización / Árbol de Ventajas (GDScript 2.0 / Godot 4.3).
##
## Implementa la interfaz visual idéntica a 'crear civilizaciones.jpg':
## - Columna izquierda: Selección y lista de civilizaciones / tecnologías.
## - Columna central: 'Árbol de Ventajas' interactivo con ramas por Era y nodos comprables.
## - Columna derecha: Ficha de civilización (Romanos), Puntos disponibles y desglose de bonificaciones.
## - Botón inferior: 'CONFIRMAR VENTAJAS Y VOLVER'.

class_name CivUpgradePanel
extends Control

signal closed()

# ─── Colores y Estilos del Tema Vintage ────────────────────────────────────────
const CLR_BG_DARK    := Color(0.10, 0.07, 0.04, 0.96)
const CLR_BORDER_GOLD:= Color(0.85, 0.70, 0.25, 1.0)
const CLR_TEXT_GOLD  := Color(1.00, 0.88, 0.32, 1.0)
const CLR_TEXT_DIM   := Color(0.88, 0.82, 0.72, 1.0)
const CLR_NODE_BG    := Color(0.18, 0.12, 0.06, 0.90)
const CLR_NODE_BORDER:= Color(0.65, 0.50, 0.20, 1.0)

var cpm: Node = null
var _lbl_points_val: Label = null
var _lbl_eco_bonus: Label = null
var _lbl_def_bonus: Label = null
var _lbl_mil_bonus: Label = null
var _tree_node_buttons: Dictionary = {}

# Definición de Tecnologías del Árbol de Ventajas (id, nombre, era, icono, rama, coste)
const TECH_TREE_DATA: Array[Dictionary] = [
	{
		"id": "economy_speed",
		"name": "Herramientas de Pedernal",
		"era": "Prehistoria",
		"icon": "🪓",
		"desc": "+10% Velocidad de Recolección",
		"category": "eco"
	},
	{
		"id": "infantry_ranged",
		"name": "Arco Primitivo y Caza",
		"era": "Prehistoria",
		"icon": "🏹",
		"desc": "+15% Alcance de Proyectiles",
		"category": "mil"
	},
	{
		"id": "infantry_melee",
		"name": "Infantería Romana",
		"era": "Edad de Piedra",
		"icon": "🛡️",
		"desc": "+10% Daño de Combate Cuerpo a Cuerpo",
		"category": "mil"
	},
	{
		"id": "defense_walls",
		"name": "Murallas y Cantería",
		"era": "Edad de Bronce",
		"icon": "🏰",
		"desc": "+20% Puntos de Salud en Edificios",
		"category": "def"
	},
	{
		"id": "cavalry_speed",
		"name": "Caballeros Pesados",
		"era": "Edad de Hierro",
		"icon": "🐎",
		"desc": "+15% Velocidad de Caballería",
		"category": "mil"
	},
	{
		"id": "siege_power",
		"name": "Motor de Vapor y Asedio",
		"era": "Edad Imperial",
		"icon": "⚙️",
		"desc": "+20% Daño en Máquinas y Artillería",
		"category": "mil"
	},
	{
		"id": "cyber_robotic",
		"name": "Armadura de Energía",
		"era": "Edad del Futuro",
		"icon": "🤖",
		"desc": "+10% HP y Blindaje Robótico",
		"category": "def"
	}
]

func _ready() -> void:
	add_to_group("civ_upgrade_panel")
	process_mode = PROCESS_MODE_ALWAYS
	anchors_preset = Control.PRESET_FULL_RECT
	visible = false

	cpm = get_node_or_null("/root/CivPointsManager")
	if is_instance_valid(cpm):
		if cpm.has_signal("civ_points_changed"):
			cpm.civ_points_changed.connect(_on_civ_points_changed)
		if cpm.has_signal("upgrade_purchased"):
			cpm.upgrade_purchased.connect(_on_upgrade_purchased)

	_build_tree_interface()
	_update_ui_state()

func toggle_panel() -> void:
	visible = not visible
	if visible:
		_update_ui_state()

# ─── Construcción de la Interfaz Visual Idéntica a crear civilizaciones.jpg ───

func _build_tree_interface() -> void:
	for ch in get_children():
		ch.queue_free()

	# 1. Fondo semitransparente oscuro modal
	var modal_bg := ColorRect.new()
	modal_bg.name = "ModalDimmer"
	modal_bg.anchors_preset = Control.PRESET_FULL_RECT
	modal_bg.color = Color(0.0, 0.0, 0.0, 0.75)
	add_child(modal_bg)

	# 2. Marco principal estilo vitral / caoba dorada
	var main_frame := PanelContainer.new()
	main_frame.name = "MainCivFrame"
	main_frame.custom_minimum_size = Vector2(980, 680)
	main_frame.anchors_preset = Control.PRESET_CENTER

	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = CLR_BG_DARK
	frame_style.border_color = CLR_BORDER_GOLD
	frame_style.border_width_left = 3
	frame_style.border_width_top = 3
	frame_style.border_width_right = 3
	frame_style.border_width_bottom = 3
	frame_style.corner_radius_top_left = 18
	frame_style.corner_radius_top_right = 18
	frame_style.corner_radius_bottom_left = 18
	frame_style.corner_radius_bottom_right = 18
	frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.9)
	frame_style.shadow_size = 20
	main_frame.add_theme_stylebox_override("panel", frame_style)
	modal_bg.add_child(main_frame)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	main_frame.add_child(root_vbox)

	# ─── ENCABEZADO: CONFIGURACIÓN AVANZADA DE CIVILIZACIÓN ───────────────────
	var header_bar := PanelContainer.new()
	var head_style := StyleBoxFlat.new()
	head_style.bg_color = Color(0.18, 0.12, 0.05, 0.95)
	head_style.border_color = CLR_BORDER_GOLD
	head_style.border_width_bottom = 2
	head_style.corner_radius_top_left = 16
	head_style.corner_radius_top_right = 16
	header_bar.add_theme_stylebox_override("panel", head_style)
	header_bar.custom_minimum_size = Vector2(0, 48)

	var hbox_head := HBoxContainer.new()
	hbox_head.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_head.add_theme_constant_override("separation", 16)

	var lbl_head := Label.new()
	lbl_head.text = "⚙️  CONFIGURACIÓN AVANZADA DE CIVILIZACIÓN  🚀"
	lbl_head.add_theme_font_size_override("font_size", 20)
	lbl_head.add_theme_color_override("font_color", CLR_TEXT_GOLD)
	hbox_head.add_child(lbl_head)

	header_bar.add_child(hbox_head)
	root_vbox.add_child(header_bar)

	# ─── CUERPO EN 3 COLUMNAS: [Lista Civs] | [Árbol de Ventajas] | [Ficha Civ] ───
	var hbox_body := HBoxContainer.new()
	hbox_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_body.add_theme_constant_override("separation", 12)
	root_vbox.add_child(hbox_body)

	# ── COLUMNA 1: LISTA LATERAL DE TECNOLOGÍAS Y CIVILIZACIONES (Izquierda) ──
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(230, 0)
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var vbox_left := VBoxContainer.new()
	vbox_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_left.add_theme_constant_override("separation", 8)

	var btn_romanos := _create_side_tech_btn("🏛️ Romanos", "Civilización Elegida", true)
	vbox_left.add_child(btn_romanos)

	for tdata in TECH_TREE_DATA:
		var btn_side := _create_side_tech_btn("%s %s" % [tdata["icon"], tdata["name"]], tdata["era"], false)
		var tech_id: String = tdata["id"]
		btn_side.pressed.connect(func(): _buy(tech_id))
		vbox_left.add_child(btn_side)

	left_scroll.add_child(vbox_left)
	hbox_body.add_child(left_scroll)

	# ── COLUMNA 2: ÁRBOL DE VENTAJAS ILUSTRADO (Centro) ──────────────────────
	var center_panel := PanelContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var center_style := StyleBoxFlat.new()
	center_style.bg_color = Color(0.08, 0.05, 0.02, 0.85)
	center_style.border_color = Color(0.5, 0.4, 0.2, 0.8)
	center_style.border_width_left = 1
	center_style.border_width_right = 1
	center_style.border_width_top = 1
	center_style.border_width_bottom = 1
	center_style.corner_radius_top_left = 10
	center_style.corner_radius_top_right = 10
	center_style.corner_radius_bottom_left = 10
	center_style.corner_radius_bottom_right = 10
	center_panel.add_theme_stylebox_override("panel", center_style)

	var tree_container := Control.new()
	tree_container.anchors_preset = Control.PRESET_FULL_RECT
	tree_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var tree_bg := TextureRect.new()
	tree_bg.anchors_preset = Control.PRESET_FULL_RECT
	var tree_tex: Texture2D = load("res://assets/ui/civ_tree_bg.png") as Texture2D
	if is_instance_valid(tree_tex):
		tree_bg.texture = tree_tex
	tree_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tree_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tree_bg.modulate = Color(1.0, 1.0, 1.0, 0.85)
	tree_container.add_child(tree_bg)

	var scroll_tree := ScrollContainer.new()
	scroll_tree.anchors_preset = Control.PRESET_FULL_RECT
	scroll_tree.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var vbox_nodes := VBoxContainer.new()
	vbox_nodes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_nodes.add_theme_constant_override("separation", 14)
	vbox_nodes.alignment = BoxContainer.ALIGNMENT_CENTER

	for tdata in TECH_TREE_DATA:
		var node_box := _create_interactive_tech_node(tdata)
		vbox_nodes.add_child(node_box)

	scroll_tree.add_child(vbox_nodes)
	tree_container.add_child(scroll_tree)
	center_panel.add_child(tree_container)
	hbox_body.add_child(center_panel)

	# ── COLUMNA 3: FICHA DE CIVILIZACIÓN Y BONIFICACIONES (Derecha) ───────────
	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(230, 0)
	var right_style := StyleBoxFlat.new()
	right_style.bg_color = Color(0.14, 0.09, 0.04, 0.92)
	right_style.border_color = CLR_BORDER_GOLD
	right_style.border_width_left = 1
	right_style.border_width_right = 1
	right_style.border_width_top = 1
	right_style.border_width_bottom = 1
	right_style.corner_radius_top_left = 10
	right_style.corner_radius_top_right = 10
	right_style.corner_radius_bottom_left = 10
	right_style.corner_radius_bottom_right = 10
	right_panel.add_theme_stylebox_override("panel", right_style)

	var vbox_right := VBoxContainer.new()
	vbox_right.add_theme_constant_override("separation", 10)

	var tex_badge := TextureRect.new()
	var badge_res: Texture2D = load("res://assets/ui/civ_badge_romanos.png") as Texture2D
	if is_instance_valid(badge_res):
		tex_badge.texture = badge_res
	tex_badge.custom_minimum_size = Vector2(80, 80)
	tex_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vbox_right.add_child(tex_badge)

	var lbl_civ_title := Label.new()
	lbl_civ_title.text = "🏛️ ROMANOS"
	lbl_civ_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_civ_title.add_theme_font_size_override("font_size", 18)
	lbl_civ_title.add_theme_color_override("font_color", CLR_TEXT_GOLD)
	vbox_right.add_child(lbl_civ_title)

	_lbl_points_val = Label.new()
	_lbl_points_val.text = "Puntos Disponibles: 5"
	_lbl_points_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_points_val.add_theme_font_size_override("font_size", 14)
	_lbl_points_val.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	vbox_right.add_child(_lbl_points_val)

	var sep_r := ColorRect.new()
	sep_r.custom_minimum_size = Vector2(0, 2)
	sep_r.color = CLR_BORDER_GOLD
	vbox_right.add_child(sep_r)

	var lbl_bonuses_title := Label.new()
	lbl_bonuses_title.text = "Bonificaciones Activas:"
	lbl_bonuses_title.add_theme_font_size_override("font_size", 14)
	lbl_bonuses_title.add_theme_color_override("font_color", CLR_TEXT_GOLD)
	vbox_right.add_child(lbl_bonuses_title)

	_lbl_eco_bonus = Label.new()
	_lbl_eco_bonus.text = "⭐ Economía: +0%"
	_lbl_eco_bonus.add_theme_font_size_override("font_size", 13)
	_lbl_eco_bonus.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	vbox_right.add_child(_lbl_eco_bonus)

	_lbl_def_bonus = Label.new()
	_lbl_def_bonus.text = "🛡️ Defensa: +0%"
	_lbl_def_bonus.add_theme_font_size_override("font_size", 13)
	_lbl_def_bonus.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	vbox_right.add_child(_lbl_def_bonus)

	_lbl_mil_bonus = Label.new()
	_lbl_mil_bonus.text = "⚔️ Militar: +0%"
	_lbl_mil_bonus.add_theme_font_size_override("font_size", 13)
	_lbl_mil_bonus.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox_right.add_child(_lbl_mil_bonus)

	var lbl_lore := Label.new()
	lbl_lore.text = "\nLegiones disciplinadas con bonificación a la construcción y tácticas de falange pesada."
	lbl_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_lore.add_theme_font_size_override("font_size", 12)
	lbl_lore.add_theme_color_override("font_color", CLR_TEXT_DIM)
	vbox_right.add_child(lbl_lore)

	right_panel.add_child(vbox_right)
	hbox_body.add_child(right_panel)

	# ─── BOTÓN INFERIOR: CONFIRMAR VENTAJAS Y VOLVER ──────────────────────────
	var hbox_bottom := HBoxContainer.new()
	hbox_bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_bottom.custom_minimum_size = Vector2(0, 52)

	var btn_confirm := Button.new()
	btn_confirm.name = "BtnLockCivSettings"
	btn_confirm.unique_name_in_owner = true
	btn_confirm.text = "🔒 CONFIRMAR VENTAJAS Y BLOQUEAR"
	btn_confirm.custom_minimum_size = Vector2(360, 46)
	btn_confirm.add_theme_font_size_override("font_size", 16)
	btn_confirm.add_theme_color_override("font_color", CLR_TEXT_GOLD)

	var style_btn := StyleBoxFlat.new()
	style_btn.bg_color = Color(0.22, 0.14, 0.05, 0.95)
	style_btn.border_color = CLR_BORDER_GOLD
	style_btn.border_width_left = 2
	style_btn.border_width_top = 2
	style_btn.border_width_right = 2
	style_btn.border_width_bottom = 2
	style_btn.corner_radius_top_left = 20
	style_btn.corner_radius_top_right = 20
	style_btn.corner_radius_bottom_left = 20
	style_btn.corner_radius_bottom_right = 20
	btn_confirm.add_theme_stylebox_override("normal", style_btn)

	btn_confirm.pressed.connect(func():
		if is_instance_valid(cpm) and cpm.has_method("lock_civ_settings"):
			cpm.lock_civ_settings(0)
		# Inhabilitar botones del panel
		btn_confirm.disabled = true
		for b in _tree_node_buttons.values():
			if is_instance_valid(b):
				b.disabled = true
		visible = false
		closed.emit()
	)
	hbox_bottom.add_child(btn_confirm)
	root_vbox.add_child(hbox_bottom)

# ─── Helpers de Creación de Nodos Visuales ────────────────────────────────────

func _create_side_tech_btn(title: String, subtitle: String, is_selected: bool) -> Button:
	var btn := Button.new()
	btn.text = "%s\n(%s)" % [title, subtitle]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 12)

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.25, 0.16, 0.05, 0.9) if is_selected else Color(0.14, 0.09, 0.04, 0.8)
	s.border_color = CLR_BORDER_GOLD if is_selected else Color(0.5, 0.4, 0.2, 0.6)
	s.border_width_left = 2 if is_selected else 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_color_override("font_color", CLR_TEXT_GOLD if is_selected else CLR_TEXT_DIM)
	return btn

func _create_interactive_tech_node(tdata: Dictionary) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)

	var lbl_era := Label.new()
	lbl_era.text = "[%s]" % tdata["era"]
	lbl_era.custom_minimum_size = Vector2(110, 0)
	lbl_era.add_theme_font_size_override("font_size", 12)
	lbl_era.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	hbox.add_child(lbl_era)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(300, 42)
	btn.text = "%s %s  —  [Nivel 0/3]" % [tdata["icon"], tdata["name"]]
	btn.add_theme_font_size_override("font_size", 13)

	var s := StyleBoxFlat.new()
	s.bg_color = CLR_NODE_BG
	s.border_color = CLR_NODE_BORDER
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_color_override("font_color", CLR_TEXT_GOLD)

	var tech_id: String = tdata["id"]
	btn.pressed.connect(func(): _buy(tech_id))
	_tree_node_buttons[tech_id] = btn

	hbox.add_child(btn)
	return hbox

# ─── Lógica de Compras y Sincronización ────────────────────────────────────────

func _buy(upgrade_id: String) -> void:
	if not is_instance_valid(cpm):
		cpm = get_node_or_null("/root/CivPointsManager")
	if is_instance_valid(cpm):
		cpm.comprar_mejora_local(upgrade_id)
		_update_ui_state()

func _on_civ_points_changed(_pts: int) -> void:
	_update_ui_state()

func _on_upgrade_purchased(_id: String, _lvl: int) -> void:
	_update_ui_state()

func _update_ui_state() -> void:
	if not is_instance_valid(cpm):
		cpm = get_node_or_null("/root/CivPointsManager")
	if not is_instance_valid(cpm):
		return

	var pts: int = int(cpm.get("puntos_civ")) if ("puntos_civ" in cpm) else 0
	if is_instance_valid(_lbl_points_val):
		_lbl_points_val.text = "Puntos Disponibles: %d" % pts

	# Actualizar nodos del árbol
	for tdata in TECH_TREE_DATA:
		var tech_id: String = tdata["id"]
		if _tree_node_buttons.has(tech_id):
			var btn: Button = _tree_node_buttons[tech_id]
			if is_instance_valid(btn):
				var lvl: int = int(cpm.get_upgrade_level(tech_id)) if cpm.has_method("get_upgrade_level") else 0
				btn.text = "%s %s  —  [Nivel %d/3]" % [tdata["icon"], tdata["name"], lvl]
				btn.disabled = (pts < 1 or lvl >= 3)
				if lvl > 0:
					btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
				else:
					btn.add_theme_color_override("font_color", CLR_TEXT_GOLD)

	# Actualizar desgloses de bonificaciones
	var m_lvl: int = int(cpm.get_upgrade_level("infantry_melee")) if cpm.has_method("get_upgrade_level") else 0
	var r_lvl: int = int(cpm.get_upgrade_level("infantry_ranged")) if cpm.has_method("get_upgrade_level") else 0
	var e_lvl: int = int(cpm.get_upgrade_level("economy_speed")) if cpm.has_method("get_upgrade_level") else 0
	var d_lvl: int = int(cpm.get_upgrade_level("defense_walls")) if cpm.has_method("get_upgrade_level") else 0

	if is_instance_valid(_lbl_eco_bonus):
		_lbl_eco_bonus.text = "⭐ Economía: +%d%% (+10%%/lvl)" % (e_lvl * 10)
	if is_instance_valid(_lbl_def_bonus):
		_lbl_def_bonus.text = "🛡️ Defensa: +%d%% (+20%%/lvl)" % (d_lvl * 20)
	if is_instance_valid(_lbl_mil_bonus):
		_lbl_mil_bonus.text = "⚔️ Militar: +%d%% (+15%%/lvl)" % (m_lvl * 10 + r_lvl * 15)
