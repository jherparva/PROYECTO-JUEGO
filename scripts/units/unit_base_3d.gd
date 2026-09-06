## UnitBase3D — Clase base para todas las unidades 3D del juego (GDScript 2.0 / Godot 4).

class_name UnitBase3D
extends CharacterBody3D

# ─── Bando / Facción ───────────────────────────────────────────────────────────
enum Bando { PLAYER, ENEMY }

# ─── Señales ───────────────────────────────────────────────────────────────────
signal died(dead_unit: CharacterBody3D)
signal hp_changed(current: float, maximum: float)
signal selected_changed(is_selected: bool)

# ─── Stats Exportables ─────────────────────────────────────────────────────────
@export_group("Identidad")
@export var unit_name: String = "Unit3D"
@export var era: int = 0
@export var era_entrenada: int = 0
@export var es_militar: bool = false
@export var bando: Bando = Bando.PLAYER
@export var owner_peer_id: int = 1

@export_group("Visión y Niebla de Guerra")
## Radio del campo de visión en unidades 3D para el Fog of War.
@export var radio_vision: float = 26.0

@export_group("Atributos de Combate")
@export var salud_maxima: float = 100.0
@export var daño: float = 10.0
@export var rango_ataque: float = 2.5
@export var velocidad_ataque: float = 1.2

const GameSettingsClass = preload("res://scripts/core/game_settings.gd")
var _speed: float = 4.5
@export var speed: float:
	get:
		return _speed * GameSettingsClass.get_game_speed_mod()
	set(v):
		_speed = v
@export var rotation_speed: float = 12.0

# ─── Estado en Tiempo de Ejecución ────────────────────────────────────────────
var salud_actual: float = 100.0
var is_dead: bool = false
var is_selected: bool = false
var is_slowed: bool = false

# Property Aliases
var max_hp: int:
	get: return int(salud_maxima)
	set(v): salud_maxima = float(v)

var hp: int:
	get: return int(salud_actual)
	set(v): salud_actual = float(v)

var attack_damage: int:
	get: return int(daño)
	set(v): daño = float(v)

var attack_range: float:
	get: return rango_ataque
	set(v): rango_ataque = v

var attack_cooldown: float:
	get: return velocidad_ataque
	set(v): velocidad_ataque = v

# ─── Referencias a Nodos Hijos ────────────────────────────────────────────────
var state_machine: Node:
	get:
		if not is_instance_valid(_state_machine):
			_state_machine = get_node_or_null("StateMachine3D")
		if not is_instance_valid(_state_machine) and has_method("_ensure_state_machine"):
			call("_ensure_state_machine")
		return _state_machine
	set(v):
		_state_machine = v
var _state_machine: Node = null

@onready var nav_agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D") as NavigationAgent3D
@onready var selection_indicator: Node3D = get_node_or_null("SelectionIndicator") as Node3D

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	salud_actual = salud_maxima
	add_to_group("units")
	add_to_group("units_3d")
	
	if bando == Bando.PLAYER:
		add_to_group("player_units")
	else:
		add_to_group("enemy_units")

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_method("change_current_population") and bando == Bando.PLAYER:
		if not get_meta("pop_counted", false):
			rm.change_current_population(1)
			set_meta("pop_counted", true)


	# Registrar la era de nacimiento de la unidad
	if era_entrenada == 0 and is_instance_valid(rm) and "era_actual" in rm:
		era_entrenada = int(rm.era_actual)

	# Determinar si es unidad militar de combate
	if not es_militar:
		if is_in_group("military_units") or is_in_group("soldiers") or is_in_group("archers_3d") or is_in_group("cavalry_3d"):
			es_militar = true

	# Conectar señal global de evolución de era
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)
		
	# Sincronizar autoridad de red con el propietario si aplica
	if owner_peer_id == 1 and multiplayer != null and multiplayer.has_multiplayer_peer() and get_multiplayer_authority() != 1:
		owner_peer_id = get_multiplayer_authority()

	input_ray_pickable = true
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	_setup_stats()
	call_deferred("_ensure_unit_primitive_mesh")
	call_deferred("_ensure_unit_label3d")

## Replicación Asíncrona Individual por Jugador (Asynchronous Mesh Swap)
func _on_era_evolucionada(player_id: int = 0, nueva_era: int = 0) -> void:
	if is_dead:
		return

	if self.owner_peer_id != player_id:
		return

	# ── REGLA TÁCTICA EMPIRE EARTH: Preservación Militar ──────────────────────────
	# Las unidades militares ya desplegadas físicamente en el mapa conservan
	# su malla, velocidad de ataque y balística original (no mutan automáticamente).
	if es_militar:
		print("UnitBase3D '%s': Unidad militar (Era %d) preservada intacta en combate." % [name, era_entrenada])
		return

	var era_val: int = nueva_era
	_actualizar_modelo_visual_era(era_val)

func _actualizar_modelo_visual_era(_era_val: int) -> void:
	# Sobrescrito por unidades civiles (Villager3D)
	pass

func _setup_stats() -> void:
	pass

## Genera una malla cápsula y un anillo de selección procedural si la unidad no tiene MeshInstance3D hijo.
func _ensure_unit_primitive_mesh() -> void:
	var has_mesh: bool = false
	for child in get_children():
		if child is MeshInstance3D:
			has_mesh = true
			break
	if not has_mesh:
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "UnitPrimitive"
		var cap := CapsuleMesh.new()
		cap.radius = 0.38
		cap.height = 1.6
		mesh_inst.mesh = cap
		mesh_inst.position = Vector3(0.0, 0.8, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.55, 1.0) if bando == Bando.PLAYER else Color(0.9, 0.2, 0.2)
		mesh_inst.material_override = mat
		add_child(mesh_inst)

	# Anillo de selección
	if not is_instance_valid(selection_indicator):
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.45
		ring_mesh.outer_radius = 0.65
		var ring_inst := MeshInstance3D.new()
		ring_inst.name = "SelectionIndicator"
		ring_inst.mesh = ring_mesh
		ring_inst.position = Vector3(0.0, 0.08, 0.0)
		var ring_mat := StandardMaterial3D.new()
		ring_mat.albedo_color = Color(0.2, 1.0, 0.4)
		ring_mat.emission_enabled = true
		ring_mat.emission = Color(0.2, 1.0, 0.4)
		ring_mat.emission_energy_multiplier = 1.2
		ring_inst.material_override = ring_mat
		ring_inst.visible = false
		add_child(ring_inst)

	# Colisionador cápsula si falta
	var has_col: bool = false
	for child in get_children():
		if child is CollisionShape3D:
			has_col = true
			break
	if not has_col:
		var col := CollisionShape3D.new()
		var cap_shape := CapsuleShape3D.new()
		cap_shape.radius = 0.4
		cap_shape.height = 1.6
		col.shape = cap_shape
		col.position = Vector3(0.0, 0.8, 0.0)
		add_child(col)

## Etiqueta 3D flotante con el nombre de la unidad y estado de vida en tiempo real.
func _ensure_unit_label3d() -> void:
	var lbl: Label3D = get_node_or_null("UnitLabel3D") as Label3D
	if not is_instance_valid(lbl):
		lbl = get_node_or_null("UnitNameLabel3D") as Label3D
	if not is_instance_valid(lbl):
		lbl = get_node_or_null("StatusLabel") as Label3D
	if not is_instance_valid(lbl):
		lbl = Label3D.new()
		lbl.name = "UnitLabel3D"
		lbl.font_size = 18
		lbl.modulate = Color(1.0, 1.0, 1.0, 0.85)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0.0, 2.1, 0.0)
		lbl.pixel_size = 0.008
		lbl.no_depth_test = true
		add_child(lbl)
	else:
		lbl.name = "UnitLabel3D"
	actualizar_label_vida()

func actualizar_label_vida() -> void:
	var lbl: Label3D = get_node_or_null("UnitLabel3D") as Label3D
	if not is_instance_valid(lbl):
		lbl = get_node_or_null("UnitNameLabel3D") as Label3D
	if not is_instance_valid(lbl):
		lbl = get_node_or_null("StatusLabel") as Label3D
	if is_instance_valid(lbl):
		lbl.text = "%s (%d/%d)" % [unit_name, int(salud_actual), int(salud_maxima)]

# ─── Sistema de Daño y Muerte ──────────────────────────────────────────────────

func recibir_daño(cantidad: float, atacante: Node = null) -> void:
	if is_dead or cantidad <= 0.0:
		return

	salud_actual = maxf(0.0, salud_actual - cantidad)
	hp_changed.emit(salud_actual, salud_maxima)
	actualizar_label_vida()

	# Actualizar o instanciar la barra de salud 3D flotante
	var hbar := get_node_or_null("HealthBar3D")
	if not is_instance_valid(hbar):
		var hbar_class = load("res://scripts/ui/health_bar_3d.gd")
		if is_instance_valid(hbar_class) and hbar_class.has_method("create_for"):
			hbar = hbar_class.call("create_for", self, 2.2)
	if is_instance_valid(hbar) and hbar.has_method("actualizar_salud"):
		hbar.call("actualizar_salud", salud_actual, salud_maxima)

	# ── Alerta de Ataque para Unidades del Jugador ────────────────────────
	if bando == Bando.PLAYER:
		var snd: Node = get_node_or_null("/root/SoundManager")
		if is_instance_valid(snd):
			if snd.get("instance") != null and snd.instance.has_method("play_attack_alert"):
				snd.instance.play_attack_alert()
			elif snd.has_method("play_attack_alert"):
				snd.play_attack_alert()
		var minimap := get_tree().get_first_node_in_group("minimap") if get_tree() else null
		if is_instance_valid(minimap) and minimap.has_method("ping_attack_location"):
			minimap.call("ping_attack_location", global_position)

	if salud_actual <= 0.0:
		morir()
		return

	# Autodefensa reactiva: si el atacante es válido, contratacar
	if is_instance_valid(atacante) and atacante != self:
		_responder_a_ataque(atacante)

func take_damage(amount: int, source: Node = null) -> void:
	recibir_daño(float(amount), source)

func _responder_a_ataque(atacante: Node) -> void:
	if not state_machine or not is_instance_valid(atacante):
		return

	# PACIFIC WORKERS: Los aldeanos son pacíficos y no contraatacan ni alertan a otros trabajadores
	if self.is_in_group("villagers") or self.name.begins_with("Villager"):
		if has_method("guarecer_en"):
			var tcs := get_tree().get_nodes_in_group("town_centers") if get_tree() else []
			for tc in tcs:
				if is_instance_valid(tc) and tc is Node3D:
					if global_position.distance_to((tc as Node3D).global_position) <= 45.0:
						call("guarecer_en", tc)
						return
		if state_machine.has_method("change_state"):
			set_status_text("⚠️ ¡Defensa personal!", 2.0)
			state_machine.change_state(&"Attacking", {"target": atacante})
		return

	var is_currently_attacking := false
	var current_target: Node3D = null

	if "current_state" in state_machine and state_machine.current_state and state_machine.current_state.state_name == &"Attacking":
		is_currently_attacking = true
		if "_target" in state_machine.current_state:
			current_target = state_machine.current_state._target as Node3D

	# REGLA RTS TÁCTICA:
	# 1. Si no está atacando -> responder inmediatamente.
	# 2. Si está atacando un EDIFICIO y lo ataca un SOLDADO/FAUNA enemigo -> abandonar edificio y defenderse.
	var should_switch_target := false

	if not is_currently_attacking:
		should_switch_target = true
	elif is_instance_valid(current_target):
		var target_is_building: bool = (current_target is BuildingBase3D or current_target.is_in_group("buildings") or current_target.is_in_group("buildings_3d"))
		var attacker_is_unit: bool = (atacante is CharacterBody3D or atacante.is_in_group("units") or atacante.is_in_group("fauna") or atacante.is_in_group("player_units") or atacante.is_in_group("enemy_units"))
		if target_is_building and attacker_is_unit:
			should_switch_target = true

	if should_switch_target:
		if has_method("set_status_text"):
			call("set_status_text", "⚔️ ¡Defendiéndose!", 2.5)

		if state_machine.has_method("change_state"):
			state_machine.change_state(&"Attacking", {"target": atacante})

		# Alertar a soldados aliados cercanos en radio de 10m (excluye aldeanos)
		_alertar_aliados_cercanos(atacante, 10.0)

func _alertar_aliados_cercanos(atacante: Node, radio: float) -> void:
	var grupo := "player_units" if bando == Bando.PLAYER else "enemy_units"
	for aliado in get_tree().get_nodes_in_group(grupo):
		if not is_instance_valid(aliado) or aliado == self or not (aliado is Node3D):
			continue
		# Excluir aldeanos de la alerta para mantenerlos en su labor pacífica
		if aliado.is_in_group("villagers") or aliado.name.begins_with("Villager"):
			continue
		var dist := global_position.distance_to((aliado as Node3D).global_position)
		if dist <= radio:
			if "state_machine" in aliado and aliado.state_machine:
				var sm: Node = aliado.state_machine as Node
				if sm and "current_state" in sm and sm.current_state and sm.current_state.state_name == &"Idle":
					if aliado.has_method("set_status_text"):
						aliado.call("set_status_text", "🛡️ ¡Auxiliando!", 2.0)
					if sm.has_method("change_state"):
						sm.change_state(&"Attacking", {"target": atacante})

var is_stunned: bool = false
var is_stun_immune: bool = false

func aplicar_stun(duracion: float = 1.5) -> bool:
	if is_dead or is_stunned or is_stun_immune:
		return false
	aplicar_aturdimiento(duracion)
	return true

@rpc("any_peer", "call_local", "reliable")
func aplicar_aturdimiento(duracion: float = 1.5) -> void:
	if is_dead or is_stunned or is_stun_immune:
		return
	is_stunned = true
	var orig_mode := process_mode
	process_mode = PROCESS_MODE_DISABLED
	if is_instance_valid(state_machine):
		state_machine.process_mode = PROCESS_MODE_DISABLED

	var snd: Node = get_node_or_null("/root/SoundManager")
	if is_instance_valid(snd):
		if snd.get("instance") != null and snd.instance.has_method("jugar_sfx_interfaz"):
			snd.instance.jugar_sfx_interfaz("minimap_alert")
		elif snd.has_method("jugar_sfx_interfaz"):
			snd.jugar_sfx_interfaz("minimap_alert")

	var tree := get_tree() if is_inside_tree() and get_tree() else Engine.get_main_loop() as SceneTree
	if is_instance_valid(tree):
		await tree.create_timer(duracion).timeout
		is_stunned = false
		process_mode = orig_mode
		if is_instance_valid(state_machine):
			state_machine.process_mode = PROCESS_MODE_INHERIT

var is_suppressed: bool = false

@rpc("any_peer", "call_local", "reliable")
func aplicar_supresion(duracion: float = 2.0) -> void:
	if is_dead or is_suppressed:
		return
	is_suppressed = true
	var orig_speed = _speed
	_speed = _speed * 0.70 # Ralentización del -30%
	var tree := get_tree() if is_inside_tree() and get_tree() else Engine.get_main_loop() as SceneTree
	if is_instance_valid(tree):
		await tree.create_timer(duracion).timeout
		is_suppressed = false
		_speed = orig_speed

var is_on_fire: bool = false
var damage_modifier: float = 1.0

@rpc("any_peer", "call_local", "reliable")
func aplicar_quemadura(duracion: float = 3.0, dps: float = 5.0) -> void:
	if is_dead or is_on_fire:
		return
	is_on_fire = true
	var elapsed := 0.0
	while elapsed < duracion and not is_dead:
		if is_inside_tree() and get_tree():
			await get_tree().create_timer(1.0).timeout
		else:
			break
		elapsed += 1.0
		recibir_daño(dps)

	is_on_fire = false

var is_cloaked: bool = false
var is_hacked: bool = false

@rpc("any_peer", "call_local", "reliable")
func aplicar_hackeo_red(duracion: float = 4.0) -> void:
	if is_dead or is_hacked:
		return
	is_hacked = true
	var orig_bando: int = int(bando)
	# Invertir bando temporalmente (0 -> 1 o 1 -> 0)
	bando = (Bando.ENEMY if orig_bando == Bando.PLAYER else Bando.PLAYER) as Bando

	var snd: Node = get_node_or_null("/root/SoundManager")
	if is_instance_valid(snd):
		if snd.get("instance") != null and snd.instance.has_method("jugar_sfx_interfaz"):
			snd.instance.jugar_sfx_interfaz("minimap_alert")
		elif snd.has_method("jugar_sfx_interfaz"):
			snd.jugar_sfx_interfaz("minimap_alert")

	print("Unidad/Edificio '%s': ¡Cortafuegos comprometido! Bando invertido por %.1fs" % [name, duracion])

	if is_inside_tree() and get_tree():
		await get_tree().create_timer(duracion).timeout

	bando = orig_bando as Bando
	is_hacked = false
	print("Unidad/Edificio '%s': Cortafuegos reiniciado. Bando restaurado." % name)

func set_status_text(_text: String, _duration: float = 0.0) -> void:
	pass



func morir() -> void:
	if is_dead:
		return
	is_dead = true

	set_physics_process(false)
	velocity = Vector3.ZERO
	if has_node("CollisionShape3D"):
		var col = get_node("CollisionShape3D")
		if col is CollisionShape3D:
			col.set_deferred("disabled", true)

	var sm: Node = _get_selection_manager()
	if is_instance_valid(sm) and "selected_units" in sm and sm.selected_units.has(self):
		sm.selected_units.erase(self)
		if sm.has_signal("selection_changed"):
			sm.selection_changed.emit(sm.selected_units)

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_method("change_current_population") and bando == Bando.PLAYER:
		rm.change_current_population(-1)

	died.emit(self)
	remove_from_group("units")
	remove_from_group("units_3d")
	remove_from_group("player_units")
	remove_from_group("enemy_units")
	
	queue_free()

func die() -> void:
	morir()

func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	salud_actual = minf(salud_actual + float(amount), salud_maxima)
	hp_changed.emit(salud_actual, salud_maxima)
	actualizar_label_vida()
	var hbar := get_node_or_null("HealthBar3D")
	if is_instance_valid(hbar) and hbar.has_method("actualizar_salud"):
		hbar.call("actualizar_salud", salud_actual, salud_maxima)

func _get_selection_manager() -> Node:
	return get_node_or_null("/root/SelectionManager")

# ─── Interacción y Clic Militar RTS ───────────────────────────────────────────

func _on_input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if bando == Bando.PLAYER:
				var sm: Node = _get_selection_manager()
				if is_instance_valid(sm):
					if Input.is_key_pressed(KEY_SHIFT):
						sm.add_units_to_selection([self])
					else:
						sm.select_units([self])
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if bando == Bando.ENEMY:
				_order_selected_units_to_attack_self()

func _order_selected_units_to_attack_self() -> void:
	var sm: Node = _get_selection_manager()
	if not is_instance_valid(sm) or not ("selected_units" in sm):
		return
		
	for unit_node in sm.selected_units:
		if is_instance_valid(unit_node) and unit_node != self:
			if unit_node.has_method("command_attack"):
				unit_node.command_attack(self)

# ─── Sistema de Attachment & Props ──────────────────────────────────────────────

func get_right_hand_attachment() -> Node3D:
	return find_child("RightHandAttachment", true, false) as Node3D

func get_back_attachment() -> Node3D:
	return find_child("BackAttachment", true, false) as Node3D

func set_attachment_prop(attachment: Node3D, prop_name: String) -> void:
	if not is_instance_valid(attachment):
		return
		
	for child in attachment.get_children():
		if child is Node3D:
			if prop_name.is_empty():
				child.visible = false
			else:
				child.visible = (child.name.to_lower() == prop_name.to_lower() or child.name.to_lower().contains(prop_name.to_lower()))

func set_hand_prop(prop_name: String) -> void:
	var hand := get_right_hand_attachment()
	if hand:
		set_attachment_prop(hand, prop_name)

func set_back_prop(prop_name: String) -> void:
	var back := get_back_attachment()
	if back:
		set_attachment_prop(back, prop_name)

# ─── Orientación 3D ────────────────────────────────────────────────────────────

func rotate_towards_direction(direction: Vector3, delta: float) -> void:
	var flat_dir := Vector3(direction.x, 0.0, direction.z)
	if flat_dir.length_squared() < 0.001:
		return
	flat_dir = flat_dir.normalized()
	
	var target_y_rad := atan2(flat_dir.x, flat_dir.z)
	rotation.y = lerp_angle(rotation.y, target_y_rad, rotation_speed * delta)

# ─── Selección RTS ─────────────────────────────────────────────────────────────

func select() -> void:
	is_selected = true
	selected_changed.emit(true)
	var ring: Node3D = selection_indicator
	if not is_instance_valid(ring):
		ring = get_node_or_null("SelectionIndicator") as Node3D
	if is_instance_valid(ring):
		ring.visible = true

func deselect() -> void:
	is_selected = false
	selected_changed.emit(false)
	var ring: Node3D = selection_indicator
	if not is_instance_valid(ring):
		ring = get_node_or_null("SelectionIndicator") as Node3D
	if is_instance_valid(ring):
		ring.visible = false

# ─── Comandos ──────────────────────────────────────────────────────────────────

var desired_facing_direction: Vector3 = Vector3.ZERO

func command_move(target_pos: Vector3) -> void:
	desired_facing_direction = Vector3.ZERO
	set_meta("new_move_command", target_pos)
	if state_machine and is_instance_valid(state_machine.current_state):
		if state_machine.current_state.state_name == &"Attacking":
			state_machine.current_state.set("_manual_move_override", true)
			state_machine.current_state.set("_target", null)
	if state_machine:
		state_machine.change_state(&"Move", {"target_position": target_pos})

func command_move_to(target_pos: Vector3) -> void:
	command_move(target_pos)

func command_move_with_facing(target_pos: Vector3, facing_dir: Vector3) -> void:
	desired_facing_direction = Vector3(facing_dir.x, 0.0, facing_dir.z).normalized()
	set_meta("new_move_command", target_pos)
	if state_machine and is_instance_valid(state_machine.current_state):
		if state_machine.current_state.state_name == &"Attacking":
			state_machine.current_state.set("_manual_move_override", true)
			state_machine.current_state.set("_target", null)
	if state_machine:
		state_machine.change_state(&"Move", {
			"target_position": target_pos,
			"facing_direction": desired_facing_direction
		})

func command_attack(target: Node) -> void:
	if not is_instance_valid(target) or target == self:
		return
	if is_dead:
		return

	# Bloqueo de fuego amigo
	if "bando" in target and int(target.bando) == int(bando):
		return
	if bando == Bando.PLAYER and (target.is_in_group("player_units") or target.is_in_group("player_buildings") or target.is_in_group("allies")):
		return
	if bando == Bando.ENEMY and (target.is_in_group("enemy_units") or target.is_in_group("enemy_buildings")):
		return

	if state_machine:
		state_machine.change_state(&"Attacking", {"target": target})

func command_stop() -> void:
	if state_machine:
		state_machine.change_state(&"Idle")

func play_animation(anim_name: String) -> void:
	# ── Prioridad 1: Delegar al UnitAnimationController3D si está adjunto ─────
	var anim_ctrl: UnitAnimationController3D = get_node_or_null("UnitAnimationController3D") as UnitAnimationController3D
	if is_instance_valid(anim_ctrl):
		match anim_name:
			"attack":
				# Disparo OneShot sincronizado por RPC (incluye la sync de red)
				var w_type: String = str(get("weapon_type")) if get("weapon_type") != null else "melee"
				anim_ctrl.reproducir_ataque_visual(w_type)
			_:
				# Walk / Idle / Gather / Repair → controlados por el blend automático.
				# Para animaciones directas se usa play_direct.
				anim_ctrl.play_direct(anim_name)
		return

	# ── Prioridad 2: Fallback directo a AnimationPlayer ───────────────────────
	var anim_player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if is_instance_valid(anim_player) and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		return

	# ── Prioridad 3: Fallback a AnimationTree (set directo de parámetro blend) ──
	var anim_tree := get_node_or_null("AnimationTree") as AnimationTree
	if is_instance_valid(anim_tree):
		match anim_name:
			"walk", "run":
				if anim_tree.has_parameter("parameters/move_blend/blend_position"):
					anim_tree.set("parameters/move_blend/blend_position", speed)
			"idle":
				if anim_tree.has_parameter("parameters/move_blend/blend_position"):
					anim_tree.set("parameters/move_blend/blend_position", 0.0)
			"attack":
				if anim_tree.has_parameter("parameters/attack_oneshot/request"):
					anim_tree.set("parameters/attack_oneshot/request",
							AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


