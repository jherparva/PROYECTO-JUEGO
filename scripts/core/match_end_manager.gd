## MatchEndManager — Administrador de Fin de Partida RTS (GDScript 2.0 / Godot 4).
##
## Escanea y escucha la destrucción de los Centros Urbanos (TownCenter3D) del jugador y la IA.
## Al cumplirse la condición de Victoria o Derrota:
##   1. Congela el tiempo del juego (get_tree().paused = true).
##   2. Revela por completo la Niebla de Guerra en el FogOfWarManager.
##   3. Despliega la pantalla modal de resultados con estadísticas completas.

class_name MatchEndManager
extends Node

signal victory_triggered
signal defeat_triggered
signal match_ended(is_victory: bool, stats: Dictionary)

# ─── Estado Interno ────────────────────────────────────────────────────────────
var _is_match_over: bool = false
var match_duration_seconds: float = 0.0

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("match_end_manager")
	process_mode = PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if _is_match_over:
		return

	if not get_tree().paused:
		match_duration_seconds += delta

	# Comprobar la existencia de Centros Urbanos del jugador e IA
	_check_victory_defeat_conditions()

# ─── Verificación de Triggers de Victoria y Derrota ───────────────────────────

func _check_victory_defeat_conditions() -> void:
	if _is_match_over or not get_tree() or not get_tree().current_scene:
		return

	var player_tc_alive: bool = false
	var enemy_tc_alive: bool = false

	# Escanear centros urbanos activos
	for tc in get_tree().get_nodes_in_group("town_centers"):
		if not is_instance_valid(tc) or not (tc is Node3D):
			continue

		var is_dead_node: bool = false
		if tc.has_method("is_dead") and tc.call("is_dead"):
			is_dead_node = true
		elif "is_dead" in tc and tc.get("is_dead"):
			is_dead_node = true

		if not is_dead_node:
			if "bando" in tc:
				var bando_val: int = int(tc.get("bando"))
				if bando_val == 0: # Bando.PLAYER
					player_tc_alive = true
				elif bando_val == 1: # Bando.ENEMY
					enemy_tc_alive = true
			else:
				player_tc_alive = true

	# Trigger de Derrota: Si el jugador perdió su Capitolio principal
	if not player_tc_alive and enemy_tc_alive:
		_trigger_match_end(false)

	# Trigger de Victoria: Si la IA perdió todos sus Capitolios y el jugador conserva el suyo
	elif player_tc_alive and not enemy_tc_alive:
		_trigger_match_end(true)

# ─── API Pública para Triggers Especiales (Maravilla, etc.) ──────────────────

func forzar_fin_partida(is_player_win: bool, _motivo: String = "Victoria por Maravilla") -> void:
	_trigger_match_end(is_player_win)

# ─── Ejecución de Transición de Fin de Partida ─────────────────────────────────

func _trigger_match_end(is_victory: bool) -> void:
	if _is_match_over:
		return

	_is_match_over = true
	get_tree().paused = true

	# 1. Revelar por completo la Niebla de Guerra para admirar el mapa final
	_reveal_full_fog_of_war()

	# 2. Compilar estadísticas finales de la partida
	var stats := _compile_match_stats(is_victory)

	if is_victory:
		print("MatchEndManager: ¡VICTORIA! Todos los centros urbanos enemigos han sido destruidos.")
		victory_triggered.emit()
	else:
		print("MatchEndManager: ¡DERROTA! El centro urbano del jugador ha sido destruido.")
		defeat_triggered.emit()

	match_ended.emit(is_victory, stats)

	# 3. Desplegar la pantalla modal de resultados
	_show_match_end_screen(is_victory, stats)

func _reveal_full_fog_of_war() -> void:
	var fow := get_tree().get_first_node_in_group("fog_of_war_manager") if get_tree() else null
	if is_instance_valid(fow) and "_grid_data" in fow:
		var grid: PackedByteArray = fow._grid_data
		grid.fill(255) # STATE_VISIBLE = 255 (Revelación Total)
		if fow.has_method("update_fog"):
			fow.call("update_fog")

func _compile_match_stats(is_victory: bool) -> Dictionary:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	var era_val: int = 0
	var resources_dict: Dictionary = {}

	if is_instance_valid(rm):
		if "era_actual" in rm:
			era_val = int(rm.era_actual)
		if "resources" in rm:
			resources_dict = (rm.resources as Dictionary).duplicate()

	return {
		"is_victory": is_victory,
		"duration": match_duration_seconds,
		"era_final": era_val,
		"resources_final": resources_dict,
		"player_units_count": get_tree().get_nodes_in_group("player_units").size() if get_tree() else 0,
		"enemy_units_count": get_tree().get_nodes_in_group("enemy_units").size() if get_tree() else 0
	}

func _show_match_end_screen(is_victory: bool, stats: Dictionary) -> void:
	var end_screen := get_tree().get_first_node_in_group("match_end_screen")
	if is_instance_valid(end_screen) and end_screen.has_method("mostrar_resultados"):
		end_screen.call("mostrar_resultados", is_victory, stats)
	else:
		var pscene := load("res://scenes/ui/match_end_screen.tscn") as PackedScene
		if is_instance_valid(pscene):
			var inst: Control = pscene.instantiate() as Control
			get_tree().current_scene.add_child(inst)
			if inst.has_method("mostrar_resultados"):
				inst.call("mostrar_resultados", is_victory, stats)
