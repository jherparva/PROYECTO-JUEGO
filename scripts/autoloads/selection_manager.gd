# res://scripts/autoloads/selection_manager.gd
extends Node

# Señal que escucha la UI o las propias unidades para saber si están seleccionadas
signal selection_changed(current_selection: Array)

# Lista de unidades seleccionadas actualmente
var selected_units: Array = []

# Diccionario para almacenar los grupos de control (del 0 al 9)
var control_groups: Dictionary = {}

func _ready() -> void:
	for i in range(10):
		control_groups[i] = []

# Reemplaza la selección actual por una nueva lista de unidades
func select_units(new_selection: Array) -> void:
	deselect_all()
	for unit in new_selection:
		if is_instance_valid(unit):
			if unit.has_method("select"):
				unit.select()
			selected_units.append(unit)
			unit.add_to_group("unidades_seleccionadas")
	selection_changed.emit(selected_units)

# Añade unidades a la selección actual
func add_units_to_selection(units_to_add: Array) -> void:
	for unit in units_to_add:
		if is_instance_valid(unit) and not selected_units.has(unit):
			if unit.has_method("select"):
				unit.select()
			selected_units.append(unit)
			unit.add_to_group("unidades_seleccionadas")
	selection_changed.emit(selected_units)

# Limpia la selección actual y quita el estado visual en las unidades
func deselect_all() -> void:
	for unit in selected_units:
		if is_instance_valid(unit):
			if unit.has_method("deselect"):
				unit.deselect()
			if unit.is_in_group("unidades_seleccionadas"):
				unit.remove_from_group("unidades_seleccionadas")
	selected_units.clear()
	selection_changed.emit(selected_units)

# Asigna la selección actual a un grupo de control (Ctrl + Número)
func assign_control_group(group_number: int) -> void:
	if not control_groups.has(group_number): return
	
	control_groups[group_number].clear()
	for unit in selected_units:
		if is_instance_valid(unit):
			control_groups[group_number].append(unit)

# Recupera y selecciona las unidades guardadas en un grupo
func recall_control_group(group_number: int) -> void:
	if not control_groups.has(group_number): return
	
	var valid_units: Array = []
	for unit in control_groups[group_number]:
		if is_instance_valid(unit):
			valid_units.append(unit)
			
	control_groups[group_number] = valid_units
	select_units(valid_units)
