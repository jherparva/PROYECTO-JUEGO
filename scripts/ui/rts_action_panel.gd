## RTSActionPanel — Consola de Mando Inferior estilo Empire Earth / Age of Empires (Godot 4).
##
## Presenta una interfaz pulida con estética de piedra y bronce ornamental:
## - Retrato estilizado de la entidad seleccionada.
## - Barra de salud de alto contraste con valor numérico en tiempo real.
## - Estado operativo detallado (Carga de recursos, producción, rol).
## - Cuadrícula táctica de botones con relieve 3D, bordes dorados y hover interactivo.

class_name RTSActionPanel
extends PanelContainer

# ─── Nodos de UI ───────────────────────────────────────────────────────────────
var portrait_label: Label
var label_title: Label
var label_subtitle: Label
var hp_bar: ProgressBar
var actions_container: GridContainer
var production_queue_container: HBoxContainer

var _current_selection: Array = []
var _building_placer: BuildingPlacer = null
var current_era_theme: String = "madera_rustica"
var current_era_style: StyleBoxFlat = null
var current_player_era: int = 0

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	if not is_instance_valid(label_subtitle):
		_setup_panel_style()
		_create_ui_hierarchy()

func _enter_tree() -> void:
	if not is_instance_valid(label_subtitle):
		_setup_panel_style()
		_create_ui_hierarchy()

func _ready() -> void:
	if not is_instance_valid(label_subtitle):
		_setup_panel_style()
		_create_ui_hierarchy()
	visible = false

	# Conectar al gestor global de selección
	var sm: Node = get_node_or_null("/root/SelectionManager")
	if is_instance_valid(sm) and sm.has_signal("selection_changed"):
		sm.selection_changed.connect(_on_selection_changed)

	# Conectar a la evolución de era para mutación estética del panel
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/GlobalResourceManager")
	if is_instance_valid(rm):
		if rm.has_signal("era_evolucionada") and not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)
		if "era_actual" in rm:
			_aplicar_estilo_era(int(rm.era_actual))

	call_deferred("_find_building_placer")

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

	# Filtro por Player ID: Solo el HUD del jugador local mutará visualmente
	if player_id != local_id:
		return

	_aplicar_estilo_era(era_val)
	if visible and not _current_selection.is_empty():
		_on_selection_changed(_current_selection)

func _get_local_player_era() -> int:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/GlobalResourceManager")
	if not is_instance_valid(rm) and is_inside_tree() and get_tree() and get_tree().root:
		rm = get_tree().root.get_node_or_null("ResourceManager")
		if not is_instance_valid(rm):
			rm = get_tree().root.get_node_or_null("GlobalResourceManager")
	if is_instance_valid(rm) and "era_actual" in rm:
		return int(rm.era_actual)
	return current_player_era

func actualizar_progreso_era(tc: Node, porcentaje: int, progreso_frac: float) -> void:
	if not visible or _current_selection.is_empty() or _current_selection[0] != tc:
		return
	label_subtitle.text = "Evolucionando... (" + str(porcentaje) + "%)"
	hp_bar.max_value = 1.0
	hp_bar.value = progreso_frac

func _find_building_placer() -> void:
	if get_tree() and get_tree().current_scene:
		_building_placer = get_tree().current_scene.find_child("BuildingPlacer", true, false) as BuildingPlacer

# ─── Estilos y Jerarquía UI ────────────────────────────────────────────────────

func _setup_panel_style() -> void:
	_aplicar_estilo_era(0)

func _aplicar_estilo_era(era_val: int) -> void:
	current_player_era = era_val
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_width_top = 3
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0

	if era_val < 2:
		# Era 0..1: Fondo de madera rústica
		style.bg_color = Color(0.18, 0.12, 0.07, 0.95)
		style.border_color = Color(0.55, 0.38, 0.20, 1.0)
		current_era_theme = "madera_rustica"
	elif era_val < 6:
		# Era 2..5: Piedra labrada / Bronce
		style.bg_color = Color(0.09, 0.10, 0.12, 0.96)
		style.border_color = Color(0.72, 0.58, 0.28, 0.95)
		current_era_theme = "piedra_labrada"
	elif era_val < 8:
		# Era 6..7: Placas de hierro victoriano remachado
		style.bg_color = Color(0.11, 0.13, 0.16, 0.98)
		style.border_color = Color(0.60, 0.65, 0.72, 1.0)
		style.border_width_top = 4
		current_era_theme = "hierro_victoriano"
	else:
		# Era 8..9: Cromo y neón digital cian
		style.bg_color = Color(0.04, 0.07, 0.14, 0.98)
		style.border_color = Color(0.0, 0.88, 1.0, 1.0)
		style.shadow_color = Color(0.0, 0.88, 1.0, 0.4)
		style.shadow_size = 10
		current_era_theme = "cromo_neon_digital"

	current_era_style = style
	add_theme_stylebox_override("panel", style)

func _create_ui_hierarchy() -> void:
	var main_hbox := HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	main_hbox.add_theme_constant_override("separation", 20)
	add_child(main_hbox)

	# ── Retrato Ornamental ─────────────────────────────────────────────────────
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(72.0, 72.0)
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.05, 0.07, 0.09, 1.0)
	p_style.border_color = Color(0.65, 0.52, 0.25, 0.9)
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(6)
	portrait_frame.add_theme_stylebox_override("panel", p_style)
	main_hbox.add_child(portrait_frame)

	portrait_label = Label.new()
	portrait_label.text = "🏛️"
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_label.add_theme_font_size_override("font_size", 34)
	portrait_frame.add_child(portrait_label)

	# ── Sección Izquierda: Estadísticas e Identidad ────────────────────────────
	var info_vbox := VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(230.0, 0.0)
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	info_vbox.add_theme_constant_override("separation", 4)
	main_hbox.add_child(info_vbox)

	label_title = Label.new()
	label_title.text = "Unidad Seleccionada"
	label_title.add_theme_font_size_override("font_size", 16)
	label_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	info_vbox.add_child(label_title)

	# Barra de Vida con estilo nítido
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(220.0, 18.0)
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.show_percentage = false

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.14, 0.18, 1.0)
	bar_bg.border_color = Color(0.25, 0.3, 0.38, 0.8)
	bar_bg.set_border_width_all(1)
	bar_bg.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.18, 0.82, 0.35, 1.0)
	bar_fill.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", bar_fill)
	info_vbox.add_child(hp_bar)

	label_subtitle = Label.new()
	label_subtitle.text = "Listo para trabajar"
	label_subtitle.add_theme_font_size_override("font_size", 12)
	label_subtitle.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95))
	info_vbox.add_child(label_subtitle)

	# Separador vertical ornamentado
	var v_sep := VSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.55, 0.45, 0.25, 0.6)
	sep_style.vertical = true
	sep_style.thickness = 2
	v_sep.add_theme_stylebox_override("separator", sep_style)
	main_hbox.add_child(v_sep)

	# ── Sección Derecha: Cuadrícula de Acciones Tácticas y Cola de Producción ──
	var right_vbox = VBoxContainer.new()
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_child(right_vbox)

	actions_container = GridContainer.new()
	actions_container.columns = 3
	actions_container.add_theme_constant_override("h_separation", 6)
	actions_container.add_theme_constant_override("v_separation", 6)
	right_vbox.add_child(actions_container)

	production_queue_container = HBoxContainer.new()
	production_queue_container.custom_minimum_size.y = 20
	production_queue_container.add_theme_constant_override("separation", 4)
	right_vbox.add_child(production_queue_container)

# ─── Respuesta a Cambio de Selección ──────────────────────────────────────────

func _on_selection_changed(selected: Array) -> void:
	_current_selection = selected
	_clear_actions()

	if selected.is_empty():
		visible = false
		return

	visible = true

	# Detectar si hay 2 o más guerreros seleccionados
	var military_units: Array[Node] = []
	for u in selected:
		if is_instance_valid(u) and (u is Soldier3D or u.is_in_group("military_units") or u.is_in_group("soldiers")):
			military_units.append(u)

	if military_units.size() >= 2:
		_update_military_squad_info(military_units)
		_build_formation_actions(military_units)
		return

	var primary: Node = selected[0] as Node
	if not is_instance_valid(primary):
		visible = false
		return

	# Actualizar stats básicos y retrato
	_update_info_section(primary)

	# Construir botones según el tipo de entidad
	if primary is Villager3D:
		_build_villager_actions(primary as Villager3D)
	elif primary is TownCenter3D:
		_build_town_center_actions(primary as TownCenter3D)
	elif primary is Farm3D:
		_build_farm_actions(primary as Farm3D)
	elif primary is Temple3D:
		_build_temple_actions(primary as Temple3D)
	elif primary is Tower3D:
		_build_tower_actions(primary as Tower3D)
	elif primary is Barracks3D:
		_build_barracks_actions(primary as Barracks3D)
	elif primary is ArcheryRange3D:
		_build_archery_range_actions(primary as ArcheryRange3D)
	elif primary is Stable3D:
		_build_stable_actions(primary as Stable3D)
	elif primary is Prophet3D:
		_build_prophet_actions(primary as Prophet3D)
	elif primary is Soldier3D:
		_build_soldier_actions(primary as Soldier3D)
	elif primary is ResourceNode3D or primary.is_in_group("resources") or primary.is_in_group("resources_3d"):
		_build_resource_actions(primary)
	elif primary is BuildingBase3D:
		_build_generic_building_actions(primary as BuildingBase3D)

func _process(_delta: float) -> void:
	if not visible or _current_selection.is_empty():
		return

	var military_units: Array[Node] = []
	for u in _current_selection:
		if is_instance_valid(u) and (u is Soldier3D or u.is_in_group("military_units") or u.is_in_group("soldiers")):
			military_units.append(u)

	if military_units.size() >= 2:
		_update_military_squad_info(military_units)
		return

	var primary: Node = _current_selection[0] as Node
	if not is_instance_valid(primary):
		visible = false
		return
	_update_info_section(primary)

func _update_military_squad_info(squad: Array[Node]) -> void:
	portrait_label.text = "⚔️"
	label_title.text = "Escuadrón (%d Guerreros)" % squad.size()
	var form_name := "Línea"
	var rts_input: Node = get_tree().current_scene.get_node_or_null("RTSInputController")
	if is_instance_valid(rts_input) and "current_formation" in rts_input:
		match int(rts_input.current_formation):
			0: form_name = "🛡️ Línea"
			1: form_name = "⚔️ Cuña"
			2: form_name = "🔲 Bloque"
			3: form_name = "⭕ Dispersa"
	label_subtitle.text = "Formación: %s | Listos para marchar" % form_name
	hp_bar.max_value = float(squad.size())
	hp_bar.value = float(squad.size())

func _update_info_section(primary: Node) -> void:
	# ── CASO RECURSO ─────────────────────────────────────────────────────────
	if primary is ResourceNode3D or primary.is_in_group("resources") or primary.is_in_group("resources_3d"):
		var res_type: String = "wood"
		if primary.has_method("get_resource_type"):
			res_type = primary.get_resource_type()
		elif "resource_type" in primary:
			res_type = str(primary.get("resource_type"))

		var cur_amt: int = int(primary.get("current_amount")) if "current_amount" in primary else 0
		var max_amt: int = int(primary.get("max_amount")) if "max_amount" in primary else 300

		hp_bar.max_value = float(max_amt)
		hp_bar.value = float(cur_amt)

		match res_type.to_lower():
			"gold":
				portrait_label.text = "🪙"
				label_title.text = "Mina de Oro"
				label_subtitle.text = "✨ %d / %d Oro restante" % [cur_amt, max_amt]
			"stone":
				portrait_label.text = "🪨"
				label_title.text = "Cantera de Piedra"
				label_subtitle.text = "⛏️ %d / %d Piedra restante" % [cur_amt, max_amt]
			"wood":
				portrait_label.text = "🌲"
				label_title.text = "Árbol de Madera"
				label_subtitle.text = "🪵 %d / %d Madera restante" % [cur_amt, max_amt]
			"iron":
				portrait_label.text = "⚙️"
				label_title.text = "Yacimiento de Hierro"
				label_subtitle.text = "🔩 %d / %d Hierro restante" % [cur_amt, max_amt]
			"food":
				portrait_label.text = "🍓"
				label_title.text = "Fuente de Alimento"
				label_subtitle.text = "🍖 %d / %d Comida restante" % [cur_amt, max_amt]
			_:
				portrait_label.text = "💎"
				label_title.text = "Nodo de Recurso"
				label_subtitle.text = "%d / %d Unidades restantes" % [cur_amt, max_amt]
		return

	# ── SALUD BASE PARA UNIDADES Y EDIFICIOS ─────────────────────────────────
	if "salud_maxima" in primary and "salud_actual" in primary:
		var max_h: float = float(primary.salud_maxima)
		var cur_h: float = float(primary.salud_actual)
		hp_bar.max_value = max_h
		hp_bar.value = cur_h

	if primary is Villager3D:
		var vil: Villager3D = primary as Villager3D
		portrait_label.text = "🧔"
		label_title.text = "Aldeano Prehistórico"
		var is_building := false
		if is_instance_valid(vil.state_machine) and is_instance_valid(vil.state_machine.current_state):
			var cur_st: Node = vil.state_machine.current_state as Node
			if is_instance_valid(cur_st):
				var cur_st_name: String = str(cur_st.name)
				if cur_st_name == "Building" or cur_st_name == "StateBuilding3D":
					var target_bld: Node = cur_st.get("_target_building") if "_target_building" in cur_st else null
					if is_instance_valid(target_bld):
						var prog: float = float(target_bld.get("progreso_construccion")) if "progreso_construccion" in target_bld else 0.0
						var bld_name: String = str(target_bld.get("building_name")) if "building_name" in target_bld else "Estructura"
						label_title.text = "🔨 Construyendo " + bld_name
						label_subtitle.text = "🧱 Progreso de Obra: %d%%" % int(prog)
						hp_bar.max_value = 100.0
						hp_bar.value = prog
						is_building = true
		if not is_building:
			if vil.carried_amount > 0:
				label_subtitle.text = "🎒 Carga: %d/%d (%s)" % [vil.carried_amount, vil.MAX_CARGA, vil.carried_resource_type.capitalize()]
			else:
				label_subtitle.text = "⛏️ Listo para trabajar"
	elif primary is BuildingBase3D and (primary as BuildingBase3D).is_under_construction:
		var bld := primary as BuildingBase3D
		portrait_label.text = "🔨"
		label_title.text = bld.building_name + " (En Construcción)"
		label_subtitle.text = "🧱 Progreso de Obra: %d%%" % int(bld.progreso_construccion)
		hp_bar.max_value = 100.0
		hp_bar.value = bld.progreso_construccion
	elif primary is Soldier3D or primary.is_in_group("military_units") or primary.is_in_group("archers_3d"):
		portrait_label.text = "🏹" if primary.is_in_group("archers_3d") else "⚔️"
		var unit_n: String = str(primary.get("unit_name")) if "unit_name" in primary else "Guerrero Militar"
		label_title.text = unit_n
		var high_ground_str := ""
		if primary is Node3D and TerrainModifierManager.tiene_ventaja_altura(primary as Node3D):
			high_ground_str = " | ⛰️ Ventaja de Altura (+25% Daño)"
		label_subtitle.text = "🛡️ En Guardia / Patrullando" + high_ground_str
	elif primary is TownCenter3D:
		var tc := primary as TownCenter3D
		portrait_label.text = "🏛️"
		var cur_era: int = _get_local_player_era()
		if cur_era >= 3:
			label_title.text = "Foro Romano / Mármol"
		elif cur_era == 2:
			label_title.text = "Acrópolis / Bronce"
		elif cur_era == 1:
			label_title.text = "Centro Urbano de Piedra"
		else:
			label_title.text = "Centro Urbano"

		var esta_ev: bool = ("evolucionando" in tc and tc.evolucionando) or ("esta_evolucionando" in tc and tc.esta_evolucionando)
		var tiene_progreso_era: bool = false
		var porcentaje: int = 0
		var prog_frac: float = 0.0

		if esta_ev and tc.has_method("get_era_progress_percentage"):
			porcentaje = tc.get_era_progress_percentage()
			prog_frac = tc.get_era_progress_fraction()
			tiene_progreso_era = true
		elif esta_ev and is_instance_valid(tc._era_timer) and tc._era_timer.wait_time > 0.0:
			var tl: float = tc.mock_time_left if ("mock_time_left" in tc and tc.mock_time_left >= 0.0) else tc._era_timer.time_left
			porcentaje = int((1.0 - (tl / tc._era_timer.wait_time)) * 100)
			prog_frac = clampf(1.0 - (tl / tc._era_timer.wait_time), 0.0, 1.0)
			tiene_progreso_era = true

		if tiene_progreso_era:
			label_subtitle.text = "Evolucionando... (" + str(porcentaje) + "%)"
			hp_bar.max_value = 1.0
			hp_bar.value = prog_frac
		elif tc.has_method("get_queue_count") and tc.get_queue_count() > 0:
			var prog: float = tc.get_training_progress()
			label_subtitle.text = "⚡ Entrenando Aldeano: %d%% (%d en cola)" % [int(prog * 100.0), tc.get_queue_count()]
			hp_bar.max_value = 1.0
			hp_bar.value = prog
		else:
			if cur_era >= 3:
				label_subtitle.text = "🏛️ Sede del Foro Romano & Administración Clásica"
			elif cur_era > 0:
				label_subtitle.text = "🏛️ Cuartel General & Centro de Producción"
			else:
				label_subtitle.text = "🔥 Fuego Tribal & Cuartel General"
	elif primary is Farm3D:
		var f := primary as Farm3D
		portrait_label.text = "🌾"
		label_title.text = f.building_name
		label_subtitle.text = "🌾 Comida: %d / %d %s" % [f.current_food_amount, f.max_food_amount, "(⚠️ Agotada)" if f.is_depleted() else ""]
	elif primary is Temple3D:
		var tmp := primary as Temple3D
		portrait_label.text = "✨"
		label_title.text = tmp.building_name
		label_subtitle.text = "✨ Fe Acumulada: %d / %d (+%.1f/s)" % [int(tmp.current_faith_points), int(tmp.max_faith_points), tmp.faith_regen_rate]
	elif primary is Tower3D:
		var tw := primary as Tower3D
		portrait_label.text = "🗼"
		label_title.text = tw.building_name
		label_subtitle.text = "🛡️ Daño: %d | Rango: %.1fm | Guarnición: %d/%d" % [int(tw.base_damage), tw.attack_range, tw.garrisoned_units.size(), tw.max_garrison_capacity]
	elif primary is Barracks3D:
		var bar := primary as Barracks3D
		var bname: String = str(bar.get("building_name")) if "building_name" in bar else ""
		if bar.is_in_group("archery_ranges") or "Tiro" in bname or "Arquero" in bname:
			portrait_label.text = "🏹"
		elif bar.is_in_group("stables") or "Establo" in bname or "Caballeriz" in bname:
			portrait_label.text = "🐴"
		elif bar.is_in_group("siege_workshops") or "Asedio" in bname or "Taller" in bname:
			portrait_label.text = "⚙️"
		else:
			portrait_label.text = "⚔️"
		label_title.text = bar.building_name
		if bar.has_method("get_queue_count") and bar.get_queue_count() > 0:
			var prog: float = bar.get_training_progress()
			label_subtitle.text = "⚡ Entrenando Tropa: %d%% (%d en cola)" % [int(prog * 100.0), bar.get_queue_count()]
			hp_bar.max_value = 1.0
			hp_bar.value = prog
		else:
			label_subtitle.text = "⚔️ Producción Militar (Listo)"
	elif primary is Prophet3D:
		portrait_label.text = "🧙"
		label_title.text = primary.unit_name
		label_subtitle.text = "✨ Místico Espiritual | Conversión & Cataclismos"
	elif primary is Hut3D:
		portrait_label.text = "🛖"
		label_title.text = "Choza Prehistórica"
		label_subtitle.text = "🏠 +5 Límite de Población"
	elif primary.is_in_group("settlements") or primary.name.begins_with("Settlement"):
		portrait_label.text = "⛺"
		label_title.text = "Asentamiento Tribal"
		label_subtitle.text = "📦 Campamento de Depósito Cercano"
	else:
		portrait_label.text = "📦"
		label_title.text = primary.name
		label_subtitle.text = ""

# ─── Generación de Botones de Acción con Relieve ──────────────────────────────

func _clear_actions() -> void:
	for child in actions_container.get_children():
		child.queue_free()

func _add_action_button(text: String, tooltip: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(120.0, 56.0)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Estilo normal (piedra con relieve)
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.14, 0.18, 0.24, 0.95)
	style_normal.border_color = Color(0.60, 0.48, 0.24, 0.85)
	style_normal.set_border_width_all(2)
	style_normal.border_width_top = 3
	style_normal.set_corner_radius_all(6)
	style_normal.shadow_color = Color(0, 0, 0, 0.5)
	style_normal.shadow_size = 4
	style_normal.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", style_normal)

	# Estilo Hover (resaltado dorado brillante)
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.22, 0.30, 0.42, 1.0)
	style_hover.border_color = Color(1.0, 0.85, 0.35, 1.0)
	style_hover.set_border_width_all(2)
	style_hover.border_width_top = 3
	style_hover.set_corner_radius_all(6)
	style_hover.shadow_color = Color(0.8, 0.6, 0.1, 0.4)
	style_hover.shadow_size = 6
	btn.add_theme_stylebox_override("hover", style_hover)

	# Estilo Presionado
	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.10, 0.13, 0.18, 1.0)
	style_pressed.border_color = Color(0.85, 0.70, 0.25, 1.0)
	style_pressed.set_border_width_all(2)
	style_pressed.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	btn.pressed.connect(callback)
	actions_container.add_child(btn)
	return btn

# ─── Menús por Entidad ────────────────────────────────────────────────────────

func _build_villager_actions(villager: Villager3D) -> void:
	var cur_era: int = 0
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and "era_actual" in rm:
		cur_era = int(rm.era_actual)

	# ─── Planos de Construcción Restringidos por Era (Tech Tree Locking) ───
	# Vivienda: Choza en Eras Primitivas (0-2) o Residencia Urbana en Eras Avanzadas (3+)
	if cur_era <= 2:
		_add_action_button(
			"🛖 Choza\n(40 🪵)",
			"Construir Choza Prehistórica (+5 población). Requiere 40 de madera.",
			func() -> void: _start_building_placement("res://scenes/buildings/hut_3d.tscn", {"wood": 40})
		)
	else:
		_add_action_button(
			"🏠 Residencia\n(60 🪵 20 🪨)",
			"Construir Residencia Urbana (+10 población). Requiere 60 de madera y 20 de piedra.",
			func() -> void: _start_building_placement("res://scenes/buildings/hut_3d.tscn", {"wood": 60, "stone": 20})
		)

	# Depósito de Recursos: Asentamiento Tribal (0-2) o Depósito Central (3+)
	if cur_era <= 2:
		_add_action_button(
			"⛺ Asentamiento\n(50 🪵)",
			"Construir Asentamiento Tribal para recolectar recursos. Requiere 50 de madera.",
			func() -> void: _start_building_placement("res://scenes/buildings/settlement_3d.tscn", {"wood": 50})
		)
	else:
		_add_action_button(
			"🏛️ Depósito\n(80 🪵 40 🪨)",
			"Construir Depósito de Suministros Avanzado para descarga de recursos. Requiere 80 de madera y 40 de piedra.",
			func() -> void: _start_building_placement("res://scenes/buildings/settlement_3d.tscn", {"wood": 80, "stone": 40})
		)

	# Producción Militar: Cuartel (Infantería y tropas a pie)
	_add_action_button(
		"⚔️ Cuartel\n(75 🪵 25 🪨)",
		"Construir Cuartel Militar para entrenar infantería y soldados a pie. Requiere 75 de madera y 25 de piedra.",
		func() -> void: _start_building_placement("res://scenes/buildings/barracks_3d.tscn", {"wood": 75, "stone": 25})
	)

	# Edificios disponibles a partir de la Edad de Piedra (Era 1+)
	if cur_era >= 1:
		# Campo de Tiro - Arqueros / Fonderos / Fusileros
		_add_action_button(
			"🏹 Campo de Tiro\n(70 🪵 20 🪨)",
			"Construir Campo de Tiro para entrenar honderos, arqueros y fusileros. Requiere 70 de madera y 20 de piedra.",
			func() -> void: _start_building_placement("res://scenes/buildings/archery_range_3d.tscn", {"wood": 70, "stone": 20})
		)

		# Granja Agrícola (Producción Sostenible de Alimento)
		_add_action_button(
			"🌾 Granja\n(60 🪵)",
			"Construir Granja Agrícola para suministro continuo de alimento. Requiere 60 de madera.",
			func() -> void: _start_building_placement("res://scenes/buildings/farm_3d.tscn", {"wood": 60})
		)

		# Torre Defensiva (Vigilancia y proyectiles automáticos)
		_add_action_button(
			"🗼 Torre Guardia\n(80 🪵 40 🪨)",
			"Construir Torre Defensiva con guarnición y proyectiles automáticos. Requiere 80 de madera y 40 de piedra.",
			func() -> void: _start_building_placement("res://scenes/buildings/tower_3d.tscn", {"wood": 80, "stone": 40})
		)

		# Templo Sagrado (Profetas, Sacerdotes y Generación de Fe)
		_add_action_button(
			"✨ Templo\n(100 🪨 50 🪵)",
			"Construir Templo para entrenar Profetas y acumular Fe divina. Requiere 100 de piedra y 50 de madera.",
			func() -> void: _start_building_placement("res://scenes/buildings/temple_3d.tscn", {"stone": 100, "wood": 50})
		)

		# Corral / Establo Temprano (Era 1: Corral para investigación de velocidad de monturas)
		if cur_era == 1:
			_add_action_button(
				"🐴 Corral\n(80 🪵 20 🪨)",
				"Construir Corral Temprano para investigación de monturas e IA Skirmish. Requiere 80 de madera y 20 de piedra.",
				func() -> void: _start_building_placement("res://scenes/buildings/stable_3d.tscn", {"wood": 80, "stone": 20})
			)

	# Edificios disponibles a partir de la Edad del Cobre (Era 2+)
	if cur_era >= 2:
		# Establo - Caballería y Tropas Montadas
		_add_action_button(
			"🐴 Establo\n(90 🪵 30 🪨)",
			"Construir Establo Real para entrenar jinetes, caballería y vehículos blindados. Requiere 90 de madera y 30 de piedra.",
			func() -> void: _start_building_placement("res://scenes/buildings/stable_3d.tscn", {"wood": 90, "stone": 30})
		)

		# Taller de Asedio - Catapultas, Arietes y Artillería
		_add_action_button(
			"⚙️ Taller Asedio\n(120 🪵 50 🪨)",
			"Construir Taller de Asedio para fabricar arietes, catapultas y artillería pesada. Requiere 120 de madera y 50 de piedra.",
			func() -> void: _start_building_placement("res://scenes/buildings/siege_workshop_3d.tscn", {"wood": 120, "stone": 50})
		)

	# Botón 4: Depositar y regresar al trabajo
	if is_instance_valid(villager) and villager.carried_amount > 0:
		_add_action_button(
			"📦 Depositar",
			"Lleva los recursos cargados al asentamiento o capitolio más cercano y regresa automáticamente.",
			func() -> void:
				var tc: Node3D = null
				var state_g = villager.state_machine.get_node_or_null("Gathering")
				if is_instance_valid(state_g) and state_g.has_method("_find_nearest_town_center"):
					tc = state_g._find_nearest_town_center()
				if is_instance_valid(tc) and villager.has_method("command_deposit"):
					villager.command_deposit(tc)
		)

	# Botón 5: Detener acción
	_add_action_button(
		"🛑 Detener",
		"Cancela la tarea actual del aldeano y lo coloca en reposo.",
		func() -> void:
			if is_instance_valid(villager) and villager.state_machine:
				villager.state_machine.change_state(&"Idle")
				villager.set_status_text("")
	)

func _build_soldier_actions(soldier: Soldier3D) -> void:
	_add_action_button(
		"🛑 Detener",
		"Cancela la tarea o movimiento del guerrero.",
		func() -> void:
			if is_instance_valid(soldier) and soldier.has_method("command_stop"):
				soldier.command_stop()
	)

func _build_formation_actions(squad: Array[Node]) -> void:
	var rts_input: Node = get_tree().current_scene.get_node_or_null("RTSInputController")

	# Formación 1: Línea
	_add_action_button(
		"🛡️ Línea",
		"Formación táctica en Línea frontal defensiva.",
		func() -> void:
			if is_instance_valid(rts_input) and rts_input.has_method("set_formation"):
				rts_input.set_formation("line")
				_update_military_squad_info(squad)
	)

	# Formación 2: Cuña
	_add_action_button(
		"⚔️ Cuña",
		"Formación táctica en Cuña (V) punta de lanza ofensiva.",
		func() -> void:
			if is_instance_valid(rts_input) and rts_input.has_method("set_formation"):
				rts_input.set_formation("wedge")
				_update_military_squad_info(squad)
	)

	# Formación 3: Bloque
	_add_action_button(
		"🔲 Bloque",
		"Formación táctica en Bloque compacto y cuadrado.",
		func() -> void:
			if is_instance_valid(rts_input) and rts_input.has_method("set_formation"):
				rts_input.set_formation("box")
				_update_military_squad_info(squad)
	)

	# Formación 4: Dispersa
	_add_action_button(
		"⭕ Dispersa",
		"Formación táctica Dispersa para evasión y avance amplio.",
		func() -> void:
			if is_instance_valid(rts_input) and rts_input.has_method("set_formation"):
				rts_input.set_formation("scattered")
				_update_military_squad_info(squad)
	)

	# Botón 5: Detener todo el escuadrón
	_add_action_button(
		"🛑 Detener",
		"Cancela la orden actual de todos los guerreros del escuadrón.",
		func() -> void:
			for u in squad:
				if is_instance_valid(u) and u.has_method("command_stop"):
					u.command_stop()
	)

func _build_town_center_actions(town_center: TownCenter3D) -> void:
	var cur_era: int = _get_local_player_era()
	var vil_label: String = "👤 Aldeano Clásico\n(50 🍖)" if cur_era >= 3 else "👤 Aldeano\n(50 🍖)"
	var vil_tooltip: String = "Entrenar un nuevo Aldeano Clásico (Costo: 50 de Comida)." if cur_era >= 3 else "Entrenar un nuevo Aldeano (Costo: 50 de Comida)."

	_add_action_button(
		vil_label,
		vil_tooltip,
		func() -> void:
			if is_instance_valid(town_center):
				town_center.train_villager()
	)

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/GlobalResourceManager")
	if not is_instance_valid(rm) and is_inside_tree() and get_tree() and get_tree().root:
		rm = get_tree().root.get_node_or_null("ResourceManager")
		if not is_instance_valid(rm):
			rm = get_tree().root.get_node_or_null("GlobalResourceManager")

	var era_val: int = int(rm.era_actual) if (is_instance_valid(rm) and "era_actual" in rm) else cur_era
	if era_val < 9:
		var costo: Dictionary = rm.consulta_coste_era() if (is_instance_valid(rm) and rm.has_method("consulta_coste_era")) else {"food": 500, "stone": 200}
		var texto_costo := ""
		for rk in costo:
			texto_costo += " %d %s" % [int(costo[rk]), rk.capitalize()]

		var nombre_siguiente_era: String = "Siguiente Era"
		if era_val == 0:
			nombre_siguiente_era = "Edad de Piedra"
		elif era_val == 1:
			nombre_siguiente_era = "Edad de Cobre"
		elif era_val == 2:
			nombre_siguiente_era = "Edad de Hierro"
		elif era_val == 3:
			nombre_siguiente_era = "Edad Media"
		elif is_instance_valid(rm) and "NOMBRE_ERA" in rm and rm.NOMBRE_ERA is Dictionary:
			nombre_siguiente_era = rm.NOMBRE_ERA.get(era_val + 1, "Siguiente Era")

		var label_btn := "🏛️ Avanzar a %s\n(%s)" % [nombre_siguiente_era, texto_costo.strip_edges()]
		var esta_ev: bool = ("evolucionando" in town_center and town_center.evolucionando) or ("esta_evolucionando" in town_center and town_center.esta_evolucionando)
		if esta_ev:
			var pct: int = 0
			if town_center.has_method("get_era_progress_percentage"):
				pct = town_center.get_era_progress_percentage()
			elif is_instance_valid(town_center._era_timer) and not town_center._era_timer.is_stopped() and town_center._era_timer.wait_time > 0:
				pct = int((1.0 - (town_center._era_timer.time_left / town_center._era_timer.wait_time)) * 100)
			label_btn = "⏳ Evolucionando... (" + str(pct) + "%)"

		_add_action_button(
			label_btn,
			"Evolucionar a la siguiente Era histórica.",
			func() -> void:
				if is_instance_valid(town_center):
					if ("evolucionando" in town_center and town_center.evolucionando) or town_center.esta_evolucionando:
						town_center.cancelar_evolucion_era()
					else:
						town_center.iniciar_evolucion_era()
		)

func _build_barracks_actions(barracks: Barracks3D) -> void:
	if not is_instance_valid(barracks):
		return

	var cur_era: int = 0
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and "era_actual" in rm:
		cur_era = int(rm.era_actual)

	# Determinar el tipo de edificio por nombre/grupo para filtrar el catálogo
	var btype: String = "barracks"
	var bname: String = str(barracks.get("building_name")) if "building_name" in barracks else ""
	if barracks.is_in_group("archery_ranges") or "Campo de Tiro" in bname or "Tiro" in bname:
		btype = "archery_range"
	elif barracks.is_in_group("stables") or "Establo" in bname or "Caballeriz" in bname:
		btype = "stable"
	elif barracks.is_in_group("siege_workshops") or "Asedio" in bname or "Taller" in bname:
		btype = "siege_workshop"

	# Mostrar ÚNICAMENTE las unidades disponibles para la Era y tipo de edificio actual
	var disponibles: Array[Dictionary] = Barracks3D.get_unidades_disponibles_era(cur_era, btype)
	var seen_unit_btns: Dictionary = {}
	for u_info in disponibles:
		var unit_id: String = str(u_info.get("id", ""))
		if seen_unit_btns.has(unit_id):
			continue
		seen_unit_btns[unit_id] = true
		var era_min: int = int(u_info.get("era_min", 0))
		var u_name: String = str(u_info.get("name", unit_id))
		var cost: Dictionary = u_info.get("cost", {})
		var cost_str := ""
		for rk in cost:
			var icon: String = "🍖" if rk == "food" else ("🪵" if rk == "wood" else ("🪨" if rk == "stone" else ("⚙️" if rk == "iron" else "🪙")))
			cost_str += "%d%s " % [int(cost[rk]), icon]

		var type_icon: String = "⚔️"
		var utype: String = str(u_info.get("type", "melee"))
		if utype == "ranged": type_icon = "🏹"
		elif utype == "cavalry": type_icon = "🐴"
		elif utype == "siege": type_icon = "💣"

		var btn_label := "%s %s\n(%s)" % [type_icon, u_name, cost_str.strip_edges()]
		var tooltip := "Entrenar %s (Época %d)" % [u_name, era_min]

		var captured_id: String = unit_id
		_add_action_button(
			btn_label,
			tooltip,
			func() -> void:
				if is_instance_valid(barracks):
					if barracks.has_method("entrenar_unidad"):
						barracks.entrenar_unidad(captured_id)
					elif barracks.has_method("train_soldier"):
						barracks.train_soldier()
		)

func _build_archery_range_actions(archery: ArcheryRange3D) -> void:
	if not is_instance_valid(archery):
		return
	var cur_era: int = 0
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and "era_actual" in rm:
		cur_era = int(rm.era_actual)

	if cur_era >= 1:
		_add_action_button(
			"🪨 Lanzador Piedras\n(30 🍖 20 🪵)",
			"Entrenar Lanzador de Piedras (Hostigador con bono x1.5 vs infantería).",
			func() -> void:
				if is_instance_valid(archery):
					archery.entrenar_lanzador_piedras()
		)
		_add_action_button(
			"🏹 Arquero Piedra\n(40 🍖 30 🪵)",
			"Entrenar Arquero de Piedra (Unidad balística regular de 14.0m de alcance).",
			func() -> void:
				if is_instance_valid(archery):
					archery.entrenar_arquero_piedra()
		)

func _build_stable_actions(stable: Stable3D) -> void:
	if not is_instance_valid(stable):
		return
	var cur_era: int = 0
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and "era_actual" in rm:
		cur_era = int(rm.era_actual)

	if cur_era == 1:
		var btn_label := "🐴 Investigar Monturas\n(60 🍖 40 🪵)"
		if stable.velocidad_monturas_investigada:
			btn_label = "✅ Monturas Investigadas"
		_add_action_button(
			btn_label,
			"Investigación pasiva de velocidad de monturas para caballería e IA Skirmish (+15%).",
			func() -> void:
				if is_instance_valid(stable):
					stable.investigar_velocidad_monturas()
		)

func _build_resource_actions(res_node: Node) -> void:
	_add_action_button(
		"⛏️ Recolectar",
		"Envía a un aldeano del jugador a extraer recursos de este depósito.",
		func() -> void:
			if not is_instance_valid(res_node):
				return

			var rts_input: Node = get_tree().current_scene.get_node_or_null("RTSInputController")
			if is_instance_valid(rts_input) and rts_input.has_method("_can_gather_resource"):
				var check: Dictionary = rts_input._can_gather_resource(res_node as Node3D)
				if not check.get("allowed", true):
					var notif: Node = get_tree().get_first_node_in_group("rts_notification_manager")
					if is_instance_valid(notif) and notif.has_method("add_notification"):
						notif.add_notification(check.get("reason", "Recurso no accesible"))
					return

			# 1. Intentar con aldeanos seleccionados actualmente
			var sm: Node = get_node_or_null("/root/SelectionManager")
			var ordered := false
			if is_instance_valid(sm) and "selected_units" in sm:
				for u in sm.selected_units:
					if is_instance_valid(u) and u is Villager3D and u.has_method("command_gather"):
						u.command_gather(res_node)
						ordered = true
			# 2. Si no hay seleccionados, buscar el aldeano más cercano
			if not ordered:
				var villagers := get_tree().get_nodes_in_group("player_units")
				var best_v: Node = null
				var min_d := INF
				for v in villagers:
					if is_instance_valid(v) and v is Villager3D and (res_node is Node3D):
						var d: float = (v as Node3D).global_position.distance_to((res_node as Node3D).global_position)
						if d < min_d:
							min_d = d
							best_v = v
				if is_instance_valid(best_v) and best_v.has_method("command_gather"):
					best_v.command_gather(res_node)
	)

func _build_farm_actions(farm: Farm3D) -> void:
	if not is_instance_valid(farm):
		return

	# Botón 1: Asignar aldeano cercano a trabajar la tierra
	_add_action_button(
		"🌾 Trabajar Granja",
		"Envía a un aldeano a cultivar y extraer alimento de esta parcela.",
		func() -> void:
			if not is_instance_valid(farm):
				return
			var villagers := get_tree().get_nodes_in_group("player_units")
			var best_v: Node = null
			var min_d := INF
			for v in villagers:
				if is_instance_valid(v) and v is Villager3D:
					var d: float = (v as Node3D).global_position.distance_to(farm.global_position)
					if d < min_d:
						min_d = d
						best_v = v
			if is_instance_valid(best_v) and best_v.has_method("command_gather"):
				best_v.command_gather(farm)
	)

	# Botón 2: Resembrar la granja si está agotada o desgastada
	_add_action_button(
		"🌱 Resembrar\n(50 🪵)",
		"Restaura las reservas de alimento de la granja (+2000 🍖) a cambio de 50 de madera.",
		func() -> void:
			if is_instance_valid(farm):
				farm.resembrar()
	)

func _build_temple_actions(temple: Temple3D) -> void:
	if not is_instance_valid(temple):
		return

	# Botón 1: Entrenar Profeta
	var cost: Dictionary = temple.prophet_cost
	var cost_str := ""
	for rk in cost:
		var icon: String = "🍖" if rk == "food" else ("🪵" if rk == "wood" else ("🪨" if rk == "stone" else ("⚙️" if rk == "iron" else "🪙")))
		cost_str += "%d%s " % [int(cost[rk]), icon]

	_add_action_button(
		"🧙 Profeta\n(%s)" % cost_str.strip_edges(),
		"Entrena un Profeta Sagrado para conversión de tropas y milagros espirituales.",
		func() -> void:
			if is_instance_valid(temple):
				temple.entrenar_profeta()
	)

	# Botón 2: Bendición Sagrada (Cura en área a unidades aliadas)
	_add_action_button(
		"✨ Bendición\n(50 Fe)",
		"Canaliza 50 de Fe para restaurar la salud de todas las unidades aliadas cercanas.",
		func() -> void:
			if is_instance_valid(temple) and temple.gastar_fe(50.0):
				for u in temple.get_tree().get_nodes_in_group("player_units"):
					if is_instance_valid(u) and (u as Node3D).global_position.distance_to(temple.global_position) <= 25.0:
						if u.has_method("heal"):
							u.heal(40.0)
						elif "salud_actual" in u and "salud_maxima" in u:
							u.salud_actual = minf(float(u.salud_maxima), float(u.salud_actual) + 40.0)
				print("Temple3D: ¡Bendición Sagrada activada! Tropas sanadas.")
	)

func _build_tower_actions(tower: Tower3D) -> void:
	if not is_instance_valid(tower):
		return

	# Botón 1: Desalojar guarnición si tiene unidades adentro
	if tower.garrisoned_units.size() > 0:
		_add_action_button(
			"🚪 Desalojar (%d)" % tower.garrisoned_units.size(),
			"Expulsa a todas las unidades guarecidas en el interior de la torre defensiva.",
			func() -> void:
				if is_instance_valid(tower):
					while tower.garrisoned_units.size() > 0:
						var u: Node3D = tower.garrisoned_units.pop_back()
						if is_instance_valid(u):
							u.visible = true
							u.global_position = tower.global_position + Vector3(3.0, 0.0, 3.0)
		)

func _build_prophet_actions(prophet: Prophet3D) -> void:
	if not is_instance_valid(prophet):
		return

	# Botón 1: Detener
	_add_action_button(
		"🛑 Detener",
		"Cancela cualquier rezo o desplazamiento en curso.",
		func() -> void:
			if is_instance_valid(prophet) and prophet.has_method("command_stop"):
				prophet.command_stop()
	)

	# Botón 2: Invocar Terremoto (cataclismo a edificios)
	_add_action_button(
		"🌪️ Terremoto\n(100 Fe)",
		"Desata un cataclismo sísmico que arrasa fortificaciones y estructuras enemigas.",
		func() -> void:
			if is_instance_valid(prophet):
				prophet.invocar_terremoto(prophet.global_position + prophet.transform.basis.z * -12.0)
	)

	# Botón 3: Invocar Plaga (DoT a unidades orgánicas)
	_add_action_button(
		"☠️ Plaga\n(90 Fe)",
		"Propaga una epidemia letal que diezma regimientos de infantería enemiga.",
		func() -> void:
			if is_instance_valid(prophet):
				prophet.invocar_plaga(prophet.global_position + prophet.transform.basis.z * -12.0)
	)

func _build_generic_building_actions(_building: BuildingBase3D) -> void:
	pass

# ─── Helper de Colocación de Edificios ─────────────────────────────────────────

func _start_building_placement(scene_path: String, cost: Dictionary) -> void:
	if not is_instance_valid(_building_placer):
		_find_building_placer()
	if not is_instance_valid(_building_placer):
		push_error("RTSActionPanel: BuildingPlacer no disponible.")
		return

	var pscene: PackedScene = null
	if ResourceLoader.exists(scene_path):
		pscene = load(scene_path) as PackedScene

	# Fallback inteligente si la escena .tscn no existe en disco
	if not is_instance_valid(pscene):
		var script_path := scene_path.replace("scenes/buildings/", "scripts/buildings/").replace(".tscn", ".gd")
		var base_node: BuildingBase3D = null
		if ResourceLoader.exists(script_path):
			var b_script := load(script_path) as Script
			if is_instance_valid(b_script):
				base_node = b_script.new() as BuildingBase3D

		if not is_instance_valid(base_node):
			base_node = BuildingBase3D.new()

		if "barracks" in scene_path:
			base_node.building_name = "Cuartel"
		elif "hut" in scene_path:
			base_node.building_name = "Choza"
		elif "settlement" in scene_path:
			base_node.building_name = "Asentamiento"

		pscene = PackedScene.new()
		pscene.pack(base_node)

	if is_instance_valid(pscene):
		_building_placer.iniciar_colocacion(pscene, cost)
