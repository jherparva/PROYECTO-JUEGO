## MoveOrderIndicator3D — Indicador de Respuesta Visual en Suelo al Dar Órdenes (GDScript 2.0 / Godot 4).
##
## Instancía un anillo/marcador verde temporal en el suelo al dar clic derecho,
## realiza un escalado animado (Tween) y se autodestruye en 0.5s.

class_name MoveOrderIndicator3D
extends Node3D

const LIFETIME: float = 0.5

var _mesh_instance: MeshInstance3D = null

static func create_at(pos: Vector3, parent: Node = null) -> MoveOrderIndicator3D:
	if not is_instance_valid(parent) and Engine.has_singleton("SceneTree"):
		parent = (Engine.get_singleton("SceneTree") as SceneTree).current_scene

	if not is_instance_valid(parent):
		return null

	var indicator := MoveOrderIndicator3D.new()
	parent.add_child(indicator)
	indicator.global_position = pos + Vector3(0.0, 0.05, 0.0) # Leve elevación para z-fighting
	return indicator

func _ready() -> void:
	# Crear malla de anillo plano verde
	_mesh_instance = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.4
	torus.outer_radius = 0.6

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.1, 1.0, 0.3, 0.95)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.4)
	mat.emission_energy_multiplier = 3.0

	_mesh_instance.mesh = torus
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

	# Animación de escala con Tween
	scale = Vector3(0.3, 0.3, 0.3)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector3(1.2, 1.2, 1.2), LIFETIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, LIFETIME)

	# Eliminar tras medio segundo
	if is_inside_tree() and get_tree():
		get_tree().create_timer(LIFETIME).timeout.connect(queue_free)
