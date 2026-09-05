## Projectile3D — Entidad Física de Proyectil 3D (GDScript 2.0 / Godot 4).
##
## Controla la balística 3D de proyectiles a distancia (Piedras, Flechas, Balas, Plasma).
## Se desplaza hacia la coordenada/nodo enemigo, aplica daño al impactar y se autolimpia.

class_name Projectile3D
extends Area3D

const CombatDamageCalculator = preload("res://scripts/core/combat_damage_calculator.gd")


signal impacted(target: Node3D, pos: Vector3)

# ─── Configuración de Balística ───────────────────────────────────────────────
@export var speed: float = 22.0 # Velocidad en m/s
@export var damage: float = 20.0
@export var projectile_type: String = "arrow" # "stone", "arrow", "bullet", "plasma"
@export var bando: int = 0

var target_node: Node3D = null
var target_position: Vector3 = Vector3.ZERO
var source_unit: Node3D = null

var _life_timer: float = 3.0 # Límite de vida (3s) para evitar fugas de memoria
var _is_impacted: bool = false
var _falange_scan_timer: float = 0.0
const FALANGE_SCAN_INTERVAL: float = 0.5

# ─── Nodos Visuales ────────────────────────────────────────────────────────────
var _mesh_instance: MeshInstance3D = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("projectiles_3d")

	# Configurar colisión 3D esférica
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.4
	col.shape = sphere
	add_child(col)

	# Crear o configurar la malla visual según el tipo de proyectil
	_setup_visual_mesh()

	# Conectar detección de cuerpos si entra en colisión directa
	body_entered.connect(_on_body_entered)

func _setup_visual_mesh() -> void:
	_mesh_instance = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if not is_instance_valid(_mesh_instance):
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "MeshInstance3D"
		add_child(_mesh_instance)

	match projectile_type:
		"stone":
			var sphere_mesh := SphereMesh.new()
			sphere_mesh.radius = 0.2
			sphere_mesh.height = 0.4
			_mesh_instance.mesh = sphere_mesh
		"arrow":
			var cylinder_mesh := CylinderMesh.new()
			cylinder_mesh.top_radius = 0.05
			cylinder_mesh.bottom_radius = 0.05
			cylinder_mesh.height = 0.8
			_mesh_instance.mesh = cylinder_mesh
			_mesh_instance.rotation_degrees.x = 90.0
		"bullet":
			var bullet_mesh := SphereMesh.new()
			bullet_mesh.radius = 0.1
			bullet_mesh.height = 0.2
			_mesh_instance.mesh = bullet_mesh
		"plasma":
			var plasma_mesh := SphereMesh.new()
			plasma_mesh.radius = 0.3
			plasma_mesh.height = 0.6
			_mesh_instance.mesh = plasma_mesh

func _physics_process(delta: float) -> void:
	if _is_impacted:
		return

	# Límite de seguridad contra fugas de memoria
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return

	# BUFFER DE FALANGE PASIVA: Escaneo pasivo cada 0.5s en vuelo
	_falange_scan_timer += delta
	if _falange_scan_timer >= FALANGE_SCAN_INTERVAL:
		_falange_scan_timer = 0.0
		_escanear_buffer_falange()

	# Actualizar posición del objetivo si la unidad sigue viva
	if is_instance_valid(target_node):
		if target_node.has_method("is_dead") and target_node.call("is_dead"):
			target_node = null
		else:
			target_position = target_node.global_position + Vector3(0.0, 1.2, 0.0)

	if target_position == Vector3.ZERO:
		queue_free()
		return

	# Moverse hacia las coordenadas del objetivo
	var dir := (target_position - global_position).normalized()
	var step := dir * speed * delta
	global_position += step

	if dir != Vector3.ZERO:
		look_at(global_position + dir, Vector3.UP)

	# Chequear impacto por distancia
	if global_position.distance_to(target_position) <= 0.8:
		_execute_impact(target_node)

func _escanear_buffer_falange() -> void:
	if not is_instance_valid(target_node):
		return

	# Escanear si el objetivo o tropas cercanas están en formación falange
	var tactics_class = load("res://scripts/core/military_war_tactics_3d.gd")
	if is_instance_valid(tactics_class) and tactics_class.has_method("es_victima_en_falange"):
		if bool(tactics_class.call("es_victima_en_falange", target_node)):
			target_node.set_meta("phalanx_active", true)
			target_node.set_meta("phalanx_armor_bonus", 0.30)

# ─── Lógica de Impacto y Daño ──────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if _is_impacted or body == source_unit:
		return

	# Prevenir fuego amigo
	var is_enemy := false
	if bando == 0 and (body.is_in_group("enemy_units") or body.is_in_group("enemy_buildings")):
		is_enemy = true
	elif bando == 1 and (body.is_in_group("player_units") or body.is_in_group("player_buildings")):
		is_enemy = true

	if is_enemy and body is Node3D:
		_execute_impact(body as Node3D)

func _execute_impact(hit_target: Node3D) -> void:
	if _is_impacted:
		return
	_is_impacted = true

	var final_damage := damage
	if is_instance_valid(hit_target):
		final_damage = CombatDamageCalculator.calcular_dano(damage, projectile_type, source_unit, hit_target)

	# Modificador especial Lanzador_Piedras (dbweapontohit.dat): x1.5 vs infantería cuerpo a cuerpo (MELEE_SHOCK)
	if is_instance_valid(source_unit) and "unit_id" in source_unit and str(source_unit.get("unit_id")).to_lower() == "lanzador_piedras":
		var is_infantry: bool = hit_target.is_in_group("infantry_3d") or CombatDamageCalculator._resolver_armor_type(hit_target) == CombatDamageCalculator.ArmorType.INFANTRY
		var target_wt: int = CombatDamageCalculator.WeaponType.NONE
		if "weapon_type" in hit_target:
			target_wt = CombatDamageCalculator._resolver_weapon_type(str(hit_target.get("weapon_type")))
		if is_infantry and target_wt == CombatDamageCalculator.WeaponType.MELEE_SHOCK:
			final_damage = damage * 1.5
			print("Projectile3D: ¡Bono de hostigador x1.5 de Lanzador de Piedras contra infantería MELEE_SHOCK (%s)!" % hit_target.name)

	# Aplicar reducción por Formación en Falange y Escudos (+30% resistencia balística)
	var tactics_class = load("res://scripts/core/military_war_tactics_3d.gd")
	if is_instance_valid(tactics_class) and tactics_class.has_method("aplicar_reduccion_danio_falange"):
		final_damage = float(tactics_class.call("aplicar_reduccion_danio_falange", hit_target, final_damage))

	if is_instance_valid(hit_target) and hit_target.has_method("recibir_daño"):
		hit_target.call("recibir_daño", final_damage, source_unit)

	# Generar efecto de partículas/impacto si HitVFX3D existe
	var hit_vfx_class = load("res://scripts/world/hit_vfx_3d.gd")
	if is_instance_valid(hit_vfx_class) and hit_vfx_class.has_method("create_hit_vfx"):
		var cur_scene: Node = get_tree().current_scene if (get_tree() and get_tree().current_scene) else null
		if is_instance_valid(cur_scene):
			hit_vfx_class.call("create_hit_vfx", global_position, cur_scene)

	impacted.emit(hit_target, global_position)
	queue_free()
