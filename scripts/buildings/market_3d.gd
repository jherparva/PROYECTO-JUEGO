## Market3D — Mercado y Puesto Comercial 3D (GDScript 2.0 / Godot 4).
##
## Edificio económico para trueque de recursos con una tasa de conversión de 2 a 1.

class_name Market3D
extends "res://scripts/buildings/building_base_3d.gd"

signal trade_executed(sell_type: String, buy_type: String, amount_sold: int, amount_bought: int)

func _init() -> void:
	building_name = "Mercado y Puesto Comercial"
	salud_maxima = 800.0
	salud_actual = 800.0
	radio_vision = 30.0

func _ready() -> void:
	super._ready()
	add_to_group("markets")
	add_to_group("markets_3d")

## Intercambia recursos en ResourceManager a tasa 2:1 (vendes N, recibes N/2)
func intercambiar_recursos(tipo_venta: String, tipo_compra: String, cantidad: int) -> bool:
	if is_dead or is_under_construction or cantidad <= 0:
		return false

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		return false

	var cost_dict := { tipo_venta: cantidad }
	var success: bool = false
	if rm.has_method("gastar_recursos"):
		success = rm.call("gastar_recursos", cost_dict)
	elif rm.has_method("spend_resources"):
		success = rm.call("spend_resources", cost_dict)

	if success:
		var amount_received := cantidad / 2
		if rm.has_method("agregar_recurso"):
			rm.call("agregar_recurso", tipo_compra, amount_received)
		elif "resources" in rm and rm.resources is Dictionary:
			var cur: int = int(rm.resources.get(tipo_compra, 0))
			rm.resources[tipo_compra] = cur + amount_received

		var sm = get_node_or_null("/root/SoundManager")
		if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
			sm.jugar_sfx_interfaz("minimap_alert")

		print("Market3D: Trueque exitoso — Vendido %d de %s ➔ Recibido %d de %s" % [
			cantidad, tipo_venta, amount_received, tipo_compra
		])
		trade_executed.emit(tipo_venta, tipo_compra, cantidad, amount_received)
		return true

	print("Market3D: Fondos insuficientes para vender %d de %s." % [cantidad, tipo_venta])
	return false
