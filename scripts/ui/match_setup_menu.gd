## MatchSetupMenu — Menú de Configuración Pre-Partida RTS (GDScript 2.0 / Godot 4).
##
## Captura las preferencias de Jugadores (0 enemigos en 1J), Aldeanos, Recursos,
## Velocidad, Dificultad y Niebla, inyectándolas en GameSettings y la partida activa.

class_name MatchSetupMenu
extends Control

signal settings_applied()

# ─── Referencias a Nodos de la Interfaz (%UniqueNames en match_setup_menu.tscn) ─
@onready var opt_players: OptionButton = get_node_or_null("%OptPlayers") as OptionButton
@onready var opt_villagers: OptionButton = get_node_or_null("%OptVillagers") as OptionButton
@onready var opt_resources: OptionButton = get_node_or_null("%OptResources") as OptionButton
@onready var opt_speed: OptionButton = (get_node_or_null("%OptGameSpeed") if get_node_or_null("%OptGameSpeed") else get_node_or_null("%OptSpeed")) as OptionButton
@onready var opt_game_speed: OptionButton = (get_node_or_null("%OptGameSpeed") if get_node_or_null("%OptGameSpeed") else get_node_or_null("%OptSpeed")) as OptionButton
@onready var opt_difficulty: OptionButton = get_node_or_null("%OptDifficulty") as OptionButton
@onready var opt_fow: OptionButton = get_node_or_null("%OptFOW") as OptionButton

@onready var btn_apply: Button = get_node_or_null("%BtnApply") as Button
@onready var btn_defaults: Button = get_node_or_null("%BtnDefaults") as Button
@onready var btn_close: Button = get_node_or_null("%BtnClose") as Button

var _game_settings: Node = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("match_setup_menu")

	# Buscar Singleton global o instanciar local
	_game_settings = get_node_or_null("/root/GameSettings")
	if not is_instance_valid(_game_settings):
		var gs_class: GDScript = load("res://scripts/core/game_settings.gd") as GDScript
		_game_settings = gs_class.new()
		_game_settings.name = "GameSettings"
		add_child(_game_settings)

	_setup_option_buttons()
	_connect_signals()
	reset_to_default_ui()

func open_menu() -> void:
	visible = true

func _setup_option_buttons() -> void:
	# 1. Cantidad de Jugadores (1 Jugador = 0 Enemigos / Modo Práctica)
	if is_instance_valid(opt_players):
		opt_players.clear()
		opt_players.add_item("1 Jugador (Práctica / Sin Enemigos)", 0)
		opt_players.add_item("2 Jugadores (1 Enemigo)", 1)
		opt_players.add_item("3 Jugadores (2 Enemigos)", 2)
		opt_players.add_item("4 Jugadores (3 Enemigos)", 3)
		opt_players.select(1) # Por defecto 2 jugadores

	# 2. Aldeanos Iniciales
	if is_instance_valid(opt_villagers):
		opt_villagers.clear()
		opt_villagers.add_item("3 Aldeanos", 0)
		opt_villagers.add_item("5 Aldeanos (Estándar)", 1)
		opt_villagers.add_item("8 Aldeanos (Rápido)", 2)
		opt_villagers.select(1)

	# 3. Recursos Iniciales
	if is_instance_valid(opt_resources):
		opt_resources.clear()
		opt_resources.add_item("Estándar (500 c/u)", 0)
		opt_resources.add_item("Escasos (100 c/u)", 1)
		opt_resources.add_item("Abundantes (2000 c/u)", 2)
		opt_resources.add_item("Imperio Extremo (50000 c/u)", 3)
		opt_resources.select(0)

	# 4. Velocidad de Partida
	var spd_btn := opt_game_speed if is_instance_valid(opt_game_speed) else opt_speed
	if is_instance_valid(spd_btn):
		spd_btn.clear()
		spd_btn.add_item("Muy Lento (Very Slow)", 0)
		spd_btn.add_item("Lento (Slow)", 1)
		spd_btn.add_item("Normal / Torneo (Standard)", 2)
		spd_btn.add_item("Rápido (Fast)", 3)
		spd_btn.add_item("Muy Rápido (Very Fast)", 4)
		spd_btn.select(2)

	# 5. Dificultad de la IA
	if is_instance_valid(opt_difficulty):
		opt_difficulty.clear()
		opt_difficulty.add_item("Normal (Equilibrada)", 0)
		opt_difficulty.add_item("Fácil (Pacífica / Lenta)", 1)
		opt_difficulty.add_item("Difícil (Muy Agresiva)", 2)
		opt_difficulty.add_item("Experto (Invasiones Continuas)", 3)
		opt_difficulty.select(0)

	# 6. Niebla de Guerra
	if is_instance_valid(opt_fow):
		opt_fow.clear()
		opt_fow.add_item("Niebla Activada (Exploración Normal)", 0)
		opt_fow.add_item("Mapa Descubierto (Sin Niebla)", 1)
		opt_fow.select(0)

func _connect_signals() -> void:
	if is_instance_valid(btn_defaults):
		btn_defaults.pressed.connect(reset_to_default_ui)
	if is_instance_valid(btn_apply):
		btn_apply.pressed.connect(_on_apply_button_pressed)
	if is_instance_valid(btn_close):
		btn_close.pressed.connect(_on_close_pressed)

func reset_to_default_ui() -> void:
	if is_instance_valid(opt_players): opt_players.select(1)
	if is_instance_valid(opt_villagers): opt_villagers.select(1)
	if is_instance_valid(opt_resources): opt_resources.select(0)
	var spd_btn := opt_game_speed if is_instance_valid(opt_game_speed) else opt_speed
	if is_instance_valid(spd_btn): spd_btn.select(2)
	if is_instance_valid(opt_difficulty): opt_difficulty.select(0)
	if is_instance_valid(opt_fow): opt_fow.select(0)

func _on_close_pressed() -> void:
	visible = false

# ─── Inyección en GameSettings e Inicio/Aplicación de Partida ─────────────────

func _on_apply_button_pressed() -> void:
	if not is_instance_valid(_game_settings):
		var gs_class: GDScript = load("res://scripts/core/game_settings.gd") as GDScript
		_game_settings = gs_class.new()
		add_child(_game_settings)

	# 1. Cantidad de Jugadores (0 = 1 jugador, práctica sin enemigos)
	if is_instance_valid(opt_players):
		_game_settings.player_count = opt_players.selected + 1

	# 2. Aldeanos Iniciales
	if is_instance_valid(opt_villagers):
		match opt_villagers.selected:
			0: _game_settings.starting_villagers = 3
			1: _game_settings.starting_villagers = 5
			2: _game_settings.starting_villagers = 8

	# 3. Recursos Iniciales
	if is_instance_valid(opt_resources):
		match opt_resources.selected:
			0: _game_settings.starting_resources = "normal"
			1: _game_settings.starting_resources = "escaso"
			2: _game_settings.starting_resources = "abundante"
			3: _game_settings.starting_resources = "deathmatch"

	# 4. Velocidad
	var spd_btn_apply := opt_game_speed if is_instance_valid(opt_game_speed) else opt_speed
	if is_instance_valid(spd_btn_apply):
		match spd_btn_apply.selected:
			0:
				_game_settings.game_speed_modifier = 0.5
				_game_settings.game_speed = 0.5
			1:
				_game_settings.game_speed_modifier = 0.75
				_game_settings.game_speed = 0.75
			2:
				_game_settings.game_speed_modifier = 1.0
				_game_settings.game_speed = 1.0
			3:
				_game_settings.game_speed_modifier = 1.4
				_game_settings.game_speed = 1.4
			4:
				_game_settings.game_speed_modifier = 2.0
				_game_settings.game_speed = 2.0
			_:
				_game_settings.game_speed_modifier = 1.0
				_game_settings.game_speed = 1.0

	# 5. Dificultad de la IA
	if is_instance_valid(opt_difficulty):
		match opt_difficulty.selected:
			0: _game_settings.ai_difficulty = "normal"
			1: _game_settings.ai_difficulty = "facil"
			2: _game_settings.ai_difficulty = "dificil"
			3: _game_settings.ai_difficulty = "experto"

	# 6. Niebla de Guerra
	if is_instance_valid(opt_fow):
		_game_settings.fog_of_war_enabled = (opt_fow.selected == 0)

	# Inyectar configuración en runtime en la escena activa
	_game_settings.apply_to_game(get_tree())
	settings_applied.emit()

	print("MatchSetupMenu: Ajustes aplicados -> Jugadores: %d | Recursos: %s | IA: %s | FOW: %s" % [
		_game_settings.player_count,
		_game_settings.starting_resources,
		_game_settings.ai_difficulty,
		str(_game_settings.fog_of_war_enabled)
	])

	visible = false
