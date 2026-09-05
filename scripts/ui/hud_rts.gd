## HUDRTS — Controlador de Interfaz de Usuario de Recursos RTS (GDScript 2.0 / Godot 4).
##
## Conecta automáticamente con el Autoload global ResourceManager y actualiza en tiempo real
## los contadores de pantalla: LabelMadera, LabelComida, LabelPiedra, LabelHierro y LabelOro.

class_name HUDRTS
extends CanvasLayer

# ─── Referencias a Nodos Label ────────────────────────────────────────────────
@onready var label_madera: Label = find_child("LabelMadera", true, false) as Label
@onready var label_comida: Label = find_child("LabelComida", true, false) as Label
@onready var label_piedra: Label = find_child("LabelPiedra", true, false) as Label
@onready var label_hierro: Label = find_child("LabelHierro", true, false) as Label
@onready var label_oro: Label    = find_child("LabelOro", true, false) as Label

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Conectarse a la señal del Autoload global ResourceManager
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		if rm.has_signal("recursos_actualizados"):
			rm.recursos_actualizados.connect(_on_recursos_actualizados)
		elif rm.has_signal("resources_changed"):
			rm.resources_changed.connect(_on_recursos_actualizados)
		if rm.has_signal("era_evolucionada"):
			rm.era_evolucionada.connect(_on_era_evolucionada)

		# Forzar actualización inicial de la interfaz y estilo de era
		if "resources" in rm and rm.resources is Dictionary:
			_on_recursos_actualizados(rm.resources)
		if "era_actual" in rm:
			_aplicar_estilo_tema_hud(int(rm.era_actual))

	# Conectar botón de menú superior (despliega menú modal de pausa y rendición)
	var btn_config: Button = get_node_or_null("%BtnMatchSettings") as Button
	if not is_instance_valid(btn_config):
		btn_config = find_child("BtnMatchSettings", true, false) as Button
	if not is_instance_valid(btn_config):
		btn_config = get_node_or_null("%BtnConfig") as Button
	if not is_instance_valid(btn_config):
		btn_config = find_child("BtnConfig", true, false) as Button
	if is_instance_valid(btn_config):
		btn_config.text = "Menú"
		btn_config.pressed.connect(_on_config_pressed)

func _on_era_evolucionada(player_id_or_era: Variant = 0, nueva_era: Variant = null, _extra: Variant = null) -> void:
	var local_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	var era_val: int = 0
	var player_id: int = 1

	if nueva_era != null and nueva_era is int:
		player_id = int(player_id_or_era)
		era_val = int(nueva_era)
	elif player_id_or_era is int:
		era_val = int(player_id_or_era)
	else:
		var rm: Node = get_node_or_null("/root/ResourceManager")
		if is_instance_valid(rm) and "era_actual" in rm:
			era_val = int(rm.era_actual)

	var rm_ref: Node = get_node_or_null("/root/ResourceManager")
	var era_nom: String = rm_ref.NOMBRE_ERA.get(era_val, "Era %d" % era_val) if (is_instance_valid(rm_ref) and "NOMBRE_ERA" in rm_ref) else ("Era %d" % era_val)

	var notif: Node = get_tree().get_first_node_in_group("rts_notification_manager") if get_tree() else null
	if is_instance_valid(notif) and notif.has_method("agregar_notificacion"):
		if player_id == local_id:
			notif.call("agregar_notificacion", "🏛️ ¡HEMOS EVOLUCIONADO A LA " + era_nom.to_upper() + "!", 1, Vector3.ZERO)
		else:
			notif.call("agregar_notificacion", "⚠️ Rival (Jugador %d) ha evolucionado a %s" % [player_id, era_nom], 0, Vector3.ZERO)

	if player_id == local_id:
		var sm = get_node_or_null("/root/SoundManager")
		if is_instance_valid(sm) and sm.has_method("play_era_sound"):
			sm.play_era_sound()
		_aplicar_estilo_tema_hud(era_val)

func _aplicar_estilo_tema_hud(era_val: int) -> void:
	var top_panel := find_child("TopPanel", true, false) as Panel
	var bottom_panel := find_child("BottomPanel", true, false) as Panel

	var theme_style := StyleBoxFlat.new()
	theme_style.corner_radius_top_left = 6
	theme_style.corner_radius_top_right = 6
	theme_style.corner_radius_bottom_left = 6
	theme_style.corner_radius_bottom_right = 6
	theme_style.border_width_left = 2
	theme_style.border_width_top = 2
	theme_style.border_width_right = 2
	theme_style.border_width_bottom = 2

	match era_val:
		0, 1, 2: # Bloque Primitivo: Pergamino y Piedra Rústica
			theme_style.bg_color = Color("#4A3525E6") # Marrón cálido rústico
			theme_style.border_color = Color("#8B6D51")
			print("HUDRTS: Aplicado Tema 'Pergamino y Piedra Rústica' (Eras 0-2).")

		3, 4, 5: # Bloque Histórico: Madera Tallada y Filos de Oro
			theme_style.bg_color = Color("#2C1A0EE6") # Caoba oscuro noble
			theme_style.border_color = Color("#D4AF37") # Borde dorado
			print("HUDRTS: Aplicado Tema 'Madera Tallada y Filos de Oro' (Eras 3-5).")

		6, 7: # Bloque Industrial: Acero Remachado Militar
			theme_style.bg_color = Color("#2B3036F0") # Gris acero remachado
			theme_style.border_color = Color("#5A6572")
			print("HUDRTS: Aplicado Tema 'Acero Remachado Militar' (Eras 6-7).")

		8, 9: # Bloque Futurista: Holográfico Translúcido Azul Neón
			theme_style.bg_color = Color("#0E1B2ED9") # Translúcido cian ciberpunk
			theme_style.border_color = Color("#00F0FF") # Neón azul brillante
			print("HUDRTS: Aplicado Tema 'Holográfico Translúcido Azul Neón' (Eras 8-9).")

	if is_instance_valid(top_panel):
		top_panel.add_theme_stylebox_override("panel", theme_style)
	if is_instance_valid(bottom_panel):
		bottom_panel.add_theme_stylebox_override("panel", theme_style)

func _on_config_pressed() -> void:
	var pause_menu: Node = get_tree().get_first_node_in_group("pause_menu") if get_tree() else null
	if not is_instance_valid(pause_menu) and get_tree() and get_tree().current_scene:
		pause_menu = get_tree().current_scene.find_child("PauseMenu", true, false)
	if not is_instance_valid(pause_menu) and get_tree() and get_tree().root:
		pause_menu = get_tree().root.find_child("PauseMenu", true, false)

	if not is_instance_valid(pause_menu):
		var pm_scene := load("res://scenes/ui/pause_menu.tscn") as PackedScene
		if is_instance_valid(pm_scene):
			pause_menu = pm_scene.instantiate()
		else:
			var pm_class := load("res://scripts/ui/pause_menu.gd") as GDScript
			if is_instance_valid(pm_class):
				pause_menu = pm_class.new()
		if is_instance_valid(pause_menu):
			var parent: Node = get_tree().current_scene if (get_tree() and get_tree().current_scene) else self
			parent.add_child(pause_menu)

	if is_instance_valid(pause_menu):
		if pause_menu.has_method("abrir_pausa"):
			pause_menu.abrir_pausa()
		elif pause_menu.has_method("toggle_pause"):
			pause_menu.toggle_pause()
		else:
			pause_menu.visible = true

# ─── Actualización en Tiempo Real ──────────────────────────────────────────────

func _on_recursos_actualizados(recursos: Dictionary) -> void:
	if is_instance_valid(label_madera):
		label_madera.text = "🪵 " + str(recursos.get("wood", 0))

	if is_instance_valid(label_comida):
		label_comida.text = "🍖 " + str(recursos.get("food", 0))

	if is_instance_valid(label_piedra):
		label_piedra.text = "🪨 " + str(recursos.get("stone", 0))

	if is_instance_valid(label_hierro):
		label_hierro.text = "⚙️ " + str(recursos.get("iron", 0))

	if is_instance_valid(label_oro):
		label_oro.text = "🪙 " + str(recursos.get("gold", 0))
