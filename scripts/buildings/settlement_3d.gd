## Settlement3D — Asentamiento Tribal / Campamento de Depósito de Recursos (GDScript 2.0 / Godot 4).
##
## Edificio económico de recolección avanzada. Permite a los aldeanos depositar
## madera, comida, piedra y oro sin necesidad de caminar hasta el Capitolio principal.

class_name Settlement3D
extends BuildingBase3D

signal resources_deposited(resource_type: String, amount: int)

func _init() -> void:
	building_name = "Asentamiento Tribal"
	salud_maxima = 350.0
	salud_actual = 350.0
	progreso_construccion = 0.0
	is_under_construction = true
	esta_construido = false

func _ready() -> void:
	super._ready()
	add_to_group("town_centers")
	add_to_group("settlements")
	add_to_group("drop_off_buildings")
	
	if bando == Bando.PLAYER:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")

## API de Depósito de Recursos compatible con el Capitolio
func deposit_resources(resource_type: String, amount: int, depositor: Node = null) -> void:
	if is_dead or is_under_construction:
		return
		
	if bando == Bando.PLAYER:
		var rm: Node = get_node_or_null("/root/ResourceManager")
		if is_instance_valid(rm) and rm.has_method("add_resources"):
			rm.add_resources(resource_type, amount)
	else:
		var enemy_ais := get_tree().get_nodes_in_group("enemy_ai")
		for ai in enemy_ais:
			if is_instance_valid(ai) and ai.has_method("agregar_recursos_ia"):
				ai.agregar_recursos_ia(resource_type, amount)

	resources_deposited.emit(resource_type, amount)

	# Feedback flotante sobre el asentamiento
	_mostrar_feedback_deposito(resource_type, amount)

func _mostrar_feedback_deposito(res_type: String, amount: int) -> void:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 26
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.modulate = Color(0.2, 1.0, 0.5) # Verde esmeralda
	label.position = Vector3(0.0, 2.5, 0.0)
	label.text = "+%d %s" % [amount, res_type.capitalize()]
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", 4.0, 1.4)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.4)
	tween.tween_callback(label.queue_free)
