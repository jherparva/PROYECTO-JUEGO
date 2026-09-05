## Gladiador_Retiarius — Gladiador Lanzador de Redes (Edad del Cobre / Era 2).
##
## Infantería táctica de choque que cuenta con la habilidad especial OneShot por RPC
## para lanzar el proyectil 'Red_Tridente_Retiarius', ralentizando a las unidades enemigas
## en un -50% ('is_slowed' = true) estrictamente por 3.5 segundos en la FSM.
class_name Gladiador_Retiarius
extends "res://scripts/units/soldier_3d.gd"

signal red_lanzada(target: Node)

func _init() -> void:
	unit_id = "retiarius_gladiador"
	unit_name = "Gladiador Retiarius"
	attack_type = "melee"
	weapon_type = "net_trident"
	_salud_base = 145.0
	salud_maxima = 145.0
	salud_actual = 145.0
	_daño_base = 19.0
	daño = 19.0
	rango_ataque = 4.5
	velocidad_ataque = 1.0
	speed = 5.4
	era_entrenada = 2

func _ready() -> void:
	super._ready()
	add_to_group("gladiadores")
	add_to_group("infantry_3d")

## Ataque especial OneShot para lanzar la red ralentizadora
func lanzar_red(target: Node) -> void:
	if not is_instance_valid(target):
		return
	_ejecutar_lanzar_red(target)
	if is_inside_tree() and multiplayer != null and multiplayer.has_multiplayer_peer():
		rpc("rpc_lanzar_red_retiarius", target.get_path())

@rpc("call_remote", "reliable")
func rpc_lanzar_red_retiarius(target_path: NodePath) -> void:
	var target: Node = null
	if not str(target_path).is_empty():
		if is_inside_tree():
			target = get_node_or_null(target_path)
		if not is_instance_valid(target) and Engine.get_main_loop() is SceneTree:
			target = (Engine.get_main_loop() as SceneTree).root.get_node_or_null(target_path)
	_ejecutar_lanzar_red(target)

func _ejecutar_lanzar_red(target: Node) -> void:
	# Instanciar o simular el proyectil visual de área 'Red_Tridente_Retiarius'
	var red_proj := Node3D.new()
	red_proj.name = "Red_Tridente_Retiarius"
	add_child(red_proj)

	if is_instance_valid(target):
		aplicar_debuff_red(target)
		red_lanzada.emit(target)

func aplicar_debuff_red(target: Node) -> void:
	if not is_instance_valid(target):
		return

	target.set("is_slowed", true)
	if "speed" in target:
		var orig_speed: float = float(target.get("speed"))
		if not target.has_meta("_original_speed_before_net"):
			target.set_meta("_original_speed_before_net", orig_speed)
			target.set("speed", orig_speed * 0.5)

	# Restauración tras 3.5 segundos oficiales
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if is_instance_valid(tree):
		var timer := tree.create_timer(3.5)
		if is_instance_valid(timer):
			timer.timeout.connect(func():
				restaurar_velocidad(target)
			)

func restaurar_velocidad(target: Node) -> void:
	if is_instance_valid(target):
		target.set("is_slowed", false)
		if target.has_meta("_original_speed_before_net"):
			target.set("speed", float(target.get_meta("_original_speed_before_net")))
			target.remove_meta("_original_speed_before_net")
