## MatchEndScreen — Pantalla Modal de Resultados de Fin de Partida (GDScript 2.0 / Godot 4).
##
## Despliega el resumen de Victoria o Derrota con estadísticas detalladas:
## - Tiempo total transcurrido.
## - Era final alcanzada.
## - Recursos y unidades supervivientes.
## - Botones de navegación ("Volver al Menú" / "Salir del Juego").

class_name MatchEndScreen
extends Control

signal restart_pressed
signal quit_pressed

@onready var lbl_title: Label = get_node_or_null("%LblTitle") as Label
@onready var lbl_subtitle: Label = get_node_or_null("%LblSubtitle") as Label
@onready var lbl_stats: Label = get_node_or_null("%LblStats") as Label

@onready var btn_restart: Button = get_node_or_null("%BtnRestart") as Button
@onready var btn_quit: Button = get_node_or_null("%BtnQuit") as Button

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	add_to_group("match_end_screen")
	visible = false

	_connect_buttons()

func _connect_buttons() -> void:
	if is_instance_valid(btn_restart):
		btn_restart.pressed.connect(_on_restart_pressed)
	if is_instance_valid(btn_quit):
		btn_quit.pressed.connect(_on_quit_pressed)

## Despliega la ventana modal de resultados e inyecta las estadísticas finales.
func mostrar_resultados(is_victory: bool, stats: Dictionary) -> void:
	visible = true

	# 1. Título y Estilizado
	if is_instance_valid(lbl_title):
		if is_victory:
			lbl_title.text = "¡VICTORIA ABSOLUTA!"
			lbl_title.modulate = Color(1.0, 0.85, 0.2) # Dorado brillante
		else:
			lbl_title.text = "¡DERROTA DEVASTADORA!"
			lbl_title.modulate = Color(0.9, 0.2, 0.2) # Rojo ceniza

	if is_instance_valid(lbl_subtitle):
		if is_victory:
			lbl_subtitle.text = "Has destruido la base enemiga y conquistado el mapa."
		else:
			lbl_subtitle.text = "Tu Centro Urbano ha sido destruido por las oleadas enemigas."

	# 2. Formatear Estadísticas Finales
	var duration_sec := float(stats.get("duration", 0.0))
	var minutes := int(duration_sec / 60.0)
	var seconds := int(duration_sec) % 60
	var time_str := "%02d:%02d" % [minutes, seconds]

	var era_val := int(stats.get("era_final", 0))
	var era_names: Array[String] = ["Prehistoria", "Piedra", "Bronce", "Hierro", "Medieval", "Renacimiento", "Industrial", "Atómica", "Digital", "Nano-Futurista"]
	var era_str: String = era_names[era_val] if (era_val >= 0 and era_val < era_names.size()) else "Desconocida"

	var resources: Dictionary = stats.get("resources_final", {})
	var wood := int(resources.get("wood", 0))
	var food := int(resources.get("food", 0))
	var stone := int(resources.get("stone", 0))
	var gold := int(resources.get("gold", 0))

	var player_units := int(stats.get("player_units_count", 0))
	var enemy_units := int(stats.get("enemy_units_count", 0))

	if is_instance_valid(lbl_stats):
		lbl_stats.text = """📊 RESUMEN DE LA BATALLA

⏱️ Tiempo Transcurrido: %s
📜 Era Final Alcanzada: Era %d (%s)
👥 Unidades Sobrevivientes: %d (Enemigas: %d)

📦 Recursos Restantes:
   - 🪵 Madera: %d
   - 🌾 Comida: %d
   - 🪨 Piedra: %d
   - 🪙 Oro: %d
""" % [time_str, era_val, era_str, player_units, enemy_units, wood, food, stone, gold]

	# Sonido de fanfarria de fin de partida
	var sm = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("play_attack_alert"):
		sm.play_attack_alert()

# ─── Botones de Acción ─────────────────────────────────────────────────────────

func _on_restart_pressed() -> void:
	get_tree().paused = false
	restart_pressed.emit()
	_ejecutar_limpieza_autoloads()
	var err := get_tree().change_scene_to_file("res://scenes/ui/match_setup_menu.tscn")
	if err != OK:
		print("MatchEndScreen: Regresando al menú pre-partida.")

func _on_quit_pressed() -> void:
	quit_pressed.emit()
	_ejecutar_limpieza_autoloads()
	print("MatchEndScreen: Cerrando aplicación de forma segura...")
	get_tree().quit()

# ─── Limpieza de Autoloads (State Reset Loop) ──────────────────────────────────

## Restablece el estado de todos los Autoloads antes de regresar al menú.
## Garantiza que una nueva escaramuza nunca herede datos de la batalla anterior.
func _ejecutar_limpieza_autoloads() -> void:
	var autoloads: Array[StringName] = [
		&"ResourceManager",
		&"GlobalResourceManager",
		&"GameSettings",
		&"CivPointsManager",
		&"MultiplayerManager",
	]
	for al_name: StringName in autoloads:
		var al_node: Node = get_node_or_null("/root/" + str(al_name))
		if is_instance_valid(al_node) and al_node.has_method("reiniciar_banco_partida"):
			al_node.call("reiniciar_banco_partida")

	var cpm: Node = get_node_or_null("/root/CivPointsManager")
	if is_instance_valid(cpm) and cpm.has_method("reiniciar_banco_partida"):
		cpm.call("reiniciar_banco_partida")

	print("MatchEndScreen: ✅ Limpieza de Autoloads completada. Estado de partida restablecido.")
