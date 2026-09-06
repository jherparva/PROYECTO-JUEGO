## HUDController — Controlador de Interfaz de Usuario y Morphing Estético por Era (Godot 4.3).
##
## Gestiona la evolución estética en caliente del HUD y menús al evolucionar de era:
## - Conecta a GlobalResourceManager.era_evolucionada(player_id, nueva_era).
## - Filtro estricto por local player_id: if player_id != multiplayer.get_unique_id(): return.
## - Conmuta dinámicamente StyleBox y texturas de fondo según los bloques de era de Empire Earth:
##   * Era 0..2: Madera rústica / Piedra labrada
##   * Era 3..5: Piedra fortificada / Bronce medieval
##   * Era 6..7: Placas de hierro victoriano remachado
##   * Era 8..9: Cromo y neón digital cian

class_name HUDController
extends Control

signal era_style_updated(nueva_era: int, theme_name: String)

var current_era: int = 0
var current_theme_name: String = "madera_rustica"
var current_stylebox: StyleBoxFlat = null

# Contenedores registrados para recibir morphing en caliente
var registered_containers: Array[Control] = []

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	add_to_group("hud_controller")
	_build_hud_structure()
	_connect_resource_manager()
	aplicar_estilo_era(current_era)

func _connect_resource_manager() -> void:
	var ml = Engine.get_main_loop()
	var rm: Node = null
	if ml and "root" in ml and ml.root:
		rm = ml.root.get_node_or_null("ResourceManager")
		if not is_instance_valid(rm):
			rm = ml.root.get_node_or_null("GlobalResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/GlobalResourceManager")

	if is_instance_valid(rm):
		if rm.has_signal("era_evolucionada") and not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)
		if "era_actual" in rm:
			current_era = int(rm.era_actual)
			aplicar_estilo_era(current_era)

func _on_era_evolucionada(player_id_or_era: Variant = 0, nueva_era: Variant = null, _extra: Variant = null) -> void:
	var local_id: int = 1
	var mp = get_multiplayer() if has_method("get_multiplayer") else null
	if not is_instance_valid(mp) and "multiplayer" in self:
		mp = multiplayer
	if is_instance_valid(mp) and mp.has_multiplayer_peer():
		local_id = mp.get_unique_id()
	var player_id: int = 1
	var era_val: int = 0

	if nueva_era != null and nueva_era is int:
		player_id = int(player_id_or_era)
		era_val = int(nueva_era)
	elif player_id_or_era is int:
		era_val = int(player_id_or_era)
		player_id = local_id

	# FILTRO ESTRICTO: Solo el HUD del jugador local que avanzó mutará visualmente
	if player_id != local_id:
		return

	aplicar_estilo_era(era_val)

func registrar_contenedor(cont: Control) -> void:
	if is_instance_valid(cont) and not registered_containers.has(cont):
		registered_containers.append(cont)
		if current_stylebox:
			cont.add_theme_stylebox_override("panel", current_stylebox)

func aplicar_estilo_era(era_val: int) -> void:
	current_era = era_val
	current_stylebox = crear_stylebox_para_era(era_val)

	if era_val < 4:
		current_theme_name = "madera_rustica" if era_val < 2 else "piedra_labrada"
	elif era_val == 4:
		current_theme_name = "bronce_medieval"
	elif era_val < 8:
		current_theme_name = "hierro_victoriano"
	else:
		current_theme_name = "cromo_neon_digital"

	# Aplicar el StyleBox en los contenedores registrados y en este nodo si tiene override
	add_theme_stylebox_override("panel", current_stylebox)
	for c in registered_containers:
		if is_instance_valid(c):
			c.add_theme_stylebox_override("panel", current_stylebox)
			if c.has_method("_aplicar_estilo_era"):
				c.call("_aplicar_estilo_era", era_val)

	era_style_updated.emit(current_era, current_theme_name)
	print("HUDController: 🎨 UI Era Morphing aplicado a Era %d (%s) para Player Local." % [current_era, current_theme_name])

static func get_tc_title_for_era(era_idx: int) -> String:
	if era_idx >= 3:
		return "Foro Romano / Mármol"
	elif era_idx == 2:
		return "Acrópolis / Bronce"
	elif era_idx == 1:
		return "Centro Urbano de Piedra"
	return "Centro Urbano"

static func get_tc_subtitle_for_era(era_idx: int) -> String:
	if era_idx >= 3:
		return "🏛️ Sede del Foro Romano & Administración Clásica"
	elif era_idx > 0:
		return "🏛️ Cuartel General & Centro de Producción"
	return "🔥 Fuego Tribal & Cuartel General"

static func crear_stylebox_para_era(era_val: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(8)
	s.content_margin_left = 12.0
	s.content_margin_right = 12.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0

	if era_val < 2:
		# Era 0..1: Madera rústica
		s.bg_color = Color(0.18, 0.12, 0.07, 0.95)
		s.border_color = Color(0.55, 0.38, 0.20, 1.0)
		s.set_border_width_all(2)
	elif era_val < 6:
		# Era 2..5: Piedra labrada / Bronce
		s.bg_color = Color(0.12, 0.11, 0.10, 0.96)
		s.border_color = Color(0.75, 0.60, 0.28, 1.0)
		s.set_border_width_all(2)
	elif era_val < 8:
		# Era 6..7: Placas de hierro victoriano remachado
		s.bg_color = Color(0.11, 0.13, 0.15, 0.98)
		s.border_color = Color(0.60, 0.65, 0.72, 1.0)
		s.set_border_width_all(3)
	else:
		# Era 8..9: Cromo y neón digital cian
		s.bg_color = Color(0.04, 0.07, 0.12, 0.98)
		s.border_color = Color(0.0, 0.88, 1.0, 1.0) # Neón cian brillante
		s.set_border_width_all(2)
		s.shadow_color = Color(0.0, 0.88, 1.0, 0.4)
		s.shadow_size = 8

	return s

# ─── ESTRUCTURA TRIPARTITA DEL HUD (Empire Earth) ──────────────────────────────
var hud_bottom_bar: HBoxContainer = null
var panel_left_stats: PanelContainer = null
var panel_center_grid: PanelContainer = null
var panel_right_minimap: PanelContainer = null

var lbl_unit_name: Label = null
var lbl_unit_hp: Label = null
var lbl_unit_stats: Label = null

func _build_hud_structure() -> void:
	# Asegurar que estamos en un CanvasLayer superior
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	layer.add_child(margin)

	hud_bottom_bar = HBoxContainer.new()
	hud_bottom_bar.custom_minimum_size.y = 160
	hud_bottom_bar.add_theme_constant_override("separation", 2)
	margin.add_child(hud_bottom_bar)

	# Panel Izquierdo: Stats/Selección (20%)
	panel_left_stats = PanelContainer.new()
	panel_left_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_left_stats.size_flags_stretch_ratio = 0.25
	hud_bottom_bar.add_child(panel_left_stats)
	registrar_contenedor(panel_left_stats)

	var vbox_left = VBoxContainer.new()
	panel_left_stats.add_child(vbox_left)
	lbl_unit_name = Label.new()
	lbl_unit_name.add_theme_font_size_override("font_size", 16)
	vbox_left.add_child(lbl_unit_name)
	lbl_unit_hp = Label.new()
	lbl_unit_hp.add_theme_color_override("font_color", Color.GREEN)
	vbox_left.add_child(lbl_unit_hp)
	lbl_unit_stats = Label.new()
	lbl_unit_stats.add_theme_font_size_override("font_size", 12)
	vbox_left.add_child(lbl_unit_stats)

	# Panel Central: Consola de Comandos / Grid de Producción (55%)
	panel_center_grid = PanelContainer.new()
	panel_center_grid.name = "CenterGridContainer"
	panel_center_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_center_grid.size_flags_stretch_ratio = 0.55
	hud_bottom_bar.add_child(panel_center_grid)
	registrar_contenedor(panel_center_grid)

	var action_panel = load("res://scripts/ui/rts_action_panel.gd").new()
	action_panel.name = "RTSActionPanel"
	panel_center_grid.add_child(action_panel)

	# Panel Derecho: Minimapa (20%)
	panel_right_minimap = PanelContainer.new()
	panel_right_minimap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_right_minimap.size_flags_stretch_ratio = 0.20
	hud_bottom_bar.add_child(panel_right_minimap)
	registrar_contenedor(panel_right_minimap)

	# Conectar al gestor de selección
	_connect_selection_manager()

func _connect_selection_manager() -> void:
	var sm: Node = get_node_or_null("/root/SelectionManager")
	if is_instance_valid(sm) and sm.has_signal("selection_changed"):
		if not sm.selection_changed.is_connected(_on_selection_changed):
			sm.selection_changed.connect(_on_selection_changed)

func _on_selection_changed(selected_units: Array) -> void:
	if selected_units.is_empty():
		panel_left_stats.visible = false
	else:
		panel_left_stats.visible = true
		var target = selected_units[0]
		if is_instance_valid(target):
			var u_name = target.get("unit_name") if "unit_name" in target else target.name
			var hp = target.get("salud_actual") if "salud_actual" in target else 0
			var max_hp = target.get("salud_maxima") if "salud_maxima" in target else 0
			var dmg = target.get("daño") if "daño" in target else 0

			lbl_unit_name.text = str(u_name)
			lbl_unit_hp.text = "%d/%d HP" % [int(hp), int(max_hp)]
			lbl_unit_stats.text = "Daño: %d\nArmadura: Base" % int(dmg)
