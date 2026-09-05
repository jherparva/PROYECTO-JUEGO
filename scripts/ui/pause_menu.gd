## PauseMenu — Controlador del Menú de Pausa Modal RTS (GDScript 2.0 / Godot 4).
##
## Muestra el menú modal al presionar ESC, congela la simulación del juego (get_tree().paused),
## y permite guardar/cargar la partida mediante SaveManager o regresar al menú principal.

class_name PauseMenu
extends Control

signal menu_closed
signal menu_opened

const SaveManagerClass = preload("res://scripts/core/save_manager.gd")
const GameSettingsClass = preload("res://scripts/core/game_settings.gd")
const CivPointsManagerClass = preload("res://scripts/core/civ_points_manager.gd")

var title_label: Label = null

var _btn_resume: Button = null
var btn_resume: Button:
	get:
		if not is_instance_valid(_btn_resume):
			_ensure_buttons()
		return _btn_resume
	set(v):
		_btn_resume = v

var _btn_save: Button = null
var btn_save: Button:
	get:
		if not is_instance_valid(_btn_save):
			_ensure_buttons()
		return _btn_save
	set(v):
		_btn_save = v

var _btn_load: Button = null
var btn_load: Button:
	get:
		if not is_instance_valid(_btn_load):
			_ensure_buttons()
		return _btn_load
	set(v):
		_btn_load = v

var _btn_surrender: Button = null
var btn_surrender: Button:
	get:
		if not is_instance_valid(_btn_surrender):
			_ensure_buttons()
		return _btn_surrender
	set(v):
		_btn_surrender = v

var btn_quit_match: Button:
	get:
		return btn_surrender
	set(v):
		btn_surrender = v

var btn_main_menu: Button:
	get:
		return btn_surrender
	set(v):
		btn_surrender = v

var target_tree: SceneTree = null

func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	visible = false

func _enter_tree() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")
	visible = false
	_ensure_buttons()
	_connect_buttons()

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")

	visible = false
	_ensure_buttons()
	_connect_buttons()

func _get_active_tree() -> SceneTree:
	if is_instance_valid(target_tree):
		return target_tree
	var t: SceneTree = get_tree()
	if is_instance_valid(t):
		return t
	var ml = Engine.get_main_loop()
	if ml is SceneTree:
		return ml
	return null

func _ensure_buttons() -> void:
	title_label = find_child("TitleLabel", true, false) as Label
	if is_instance_valid(title_label):
		title_label.text = "AJUSTES DE LA PARTIDA EN CURSO"

	# 1. Buscar primero los botones reales creados en la escena .tscn
	var real_resume := find_child("BtnResume", true, false) as Button
	var real_save := find_child("BtnSave", true, false) as Button
	var real_load := find_child("BtnLoad", true, false) as Button
	var real_surrender := find_child("BtnSurrender", true, false) as Button

	# 2. Si no existen en la jerarquía (ej. tests unitarios instanciando PauseMenuClass.new()), crearlos
	if not is_instance_valid(real_resume):
		real_resume = _find_or_create_btn("BtnResume", "▶️ Reanudar Juego")
	else:
		real_resume.text = "▶️ Reanudar Juego"

	if not is_instance_valid(real_save):
		real_save = _find_or_create_btn("BtnSave", "💾 Guardar Partida (F5)")
	else:
		real_save.text = "💾 Guardar Partida (F5)"

	if not is_instance_valid(real_load):
		real_load = _find_or_create_btn("BtnLoad", "📂 Cargar Partida (F9)")
	else:
		real_load.text = "📂 Cargar Partida (F9)"

	if not is_instance_valid(real_surrender):
		real_surrender = _find_or_create_btn("BtnSurrender", "🏳️ Rendirse / Terminar Partida")
	else:
		real_surrender.text = "🏳️ Rendirse / Terminar Partida"

	_btn_resume = real_resume
	_btn_save = real_save
	_btn_load = real_load
	_btn_surrender = real_surrender

func _find_or_create_btn(btn_name: String, default_text: String) -> Button:
	var b := find_child(btn_name, true, false) as Button
	if not is_instance_valid(b):
		b = Button.new()
		b.name = btn_name
		b.text = default_text
		var container := find_child("ButtonsContainer", true, false)
		if is_instance_valid(container):
			container.add_child(b)
		else:
			add_child(b)
	return b

func _connect_buttons() -> void:
	if is_instance_valid(btn_resume) and not btn_resume.pressed.is_connected(reanudar_juego):
		btn_resume.pressed.connect(reanudar_juego)
	if is_instance_valid(btn_save) and not btn_save.pressed.is_connected(_on_save_pressed):
		btn_save.pressed.connect(_on_save_pressed)
	if is_instance_valid(btn_load) and not btn_load.pressed.is_connected(_on_load_pressed):
		btn_load.pressed.connect(_on_load_pressed)
	if is_instance_valid(btn_surrender) and not btn_surrender.pressed.is_connected(_on_main_menu_pressed):
		btn_surrender.pressed.connect(_on_main_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_F3)):
		var t := _get_active_tree()
		if is_instance_valid(t):
			t.paused = !t.paused
			if t.paused:
				abrir_pausa()
			else:
				reanudar_juego()
		else:
			toggle_pause()

func toggle_pause() -> void:
	if visible:
		reanudar_juego()
	else:
		abrir_pausa()

func abrir_pausa() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_ensure_buttons()
	_connect_buttons()
	visible = true
	var t := _get_active_tree()
	if is_instance_valid(t):
		t.paused = true
	menu_opened.emit()

func reanudar_juego() -> void:
	visible = false
	var t := _get_active_tree()
	if is_instance_valid(t):
		t.paused = false
	menu_closed.emit()

func _on_save_pressed() -> void:
	var sm: Node = get_node_or_null("/root/SaveManager")
	if not is_instance_valid(sm) and is_inside_tree() and get_tree() and get_tree().root:
		sm = get_tree().root.get_node_or_null("SaveManager")
	if not is_instance_valid(sm):
		sm = SaveManagerClass.instance

	if is_instance_valid(sm) and sm.has_method("guardar_partida"):
		sm.call("guardar_partida", "quicksave.json")

func _on_load_pressed() -> void:
	var sm: Node = get_node_or_null("/root/SaveManager")
	if not is_instance_valid(sm) and is_inside_tree() and get_tree() and get_tree().root:
		sm = get_tree().root.get_node_or_null("SaveManager")
	if not is_instance_valid(sm):
		sm = SaveManagerClass.instance

	if is_instance_valid(sm) and sm.has_method("cargar_partida"):
		if sm.call("cargar_partida", "quicksave.json"):
			reanudar_juego()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	_ejecutar_limpieza_autoloads()
	var err := get_tree().change_scene_to_file("res://scenes/ui/main_menu_vintage.tscn")
	if err != OK:
		print("PauseMenu: Regresando al menú principal.")

# ─── Limpieza de Autoloads (State Reset Loop) ──────────────────────────────────

## Restablece el estado de todos los Autoloads antes de regresar al menú.
## Garantiza que una nueva escaramuza nunca herede datos de la batalla anterior.
func _ejecutar_limpieza_autoloads() -> void:
	var autoload_names: Array[String] = [
		"ResourceManager",
		"GlobalResourceManager",
		"GameSettings",
		"CivPointsManager",
		"MultiplayerManager",
	]
	var root_node: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		root_node = get_tree().root

	for al_name in autoload_names:
		var al_node: Node = null
		if is_instance_valid(root_node):
			al_node = root_node.get_node_or_null(al_name)
		if not is_instance_valid(al_node):
			al_node = get_node_or_null("/root/" + al_name)
		if is_instance_valid(al_node) and al_node.has_method("reiniciar_banco_partida"):
			al_node.call("reiniciar_banco_partida")

	# Fallbacks directos para singletons estáticos
	if is_instance_valid(GameSettingsClass.instance) and GameSettingsClass.instance.has_method("reiniciar_banco_partida"):
		GameSettingsClass.instance.reiniciar_banco_partida()
	if is_instance_valid(CivPointsManagerClass.instance) and CivPointsManagerClass.instance.has_method("reiniciar_banco_partida"):
		CivPointsManagerClass.instance.reiniciar_banco_partida()

	print("PauseMenu: ✅ Limpieza de Autoloads completada. Estado de partida restablecido.")
