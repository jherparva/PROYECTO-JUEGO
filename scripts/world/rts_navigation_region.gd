## RTSNavigationRegion — Horneado y Gestión Automática de NavigationMesh 3D en Runtime.
class_name RTSNavigationRegion
extends NavigationRegion3D

func _ready() -> void:
	call_deferred("_bake_at_start")

func _bake_at_start() -> void:
	# Esperar a que el spawner de recursos y edificios estén en la escena
	await get_tree().physics_frame
	await get_tree().physics_frame
	if navigation_mesh:
		bake_navigation_mesh(false)
