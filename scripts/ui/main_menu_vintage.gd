## MainMenuVintage — Menú Principal Estilo Empire Earth (GDScript 2.0 / Godot 4.3).
##
## Controla el flujo de navegación del menú principal con estética vintage trans-era:
## - Single Player → Sub-panel modal flotante de Configuración Real (Match Setup)
## - Multiplayer   → Transición limpia a res://scenes/ui/multiplayer_lobby.tscn
## - Game Tools    → Modal de Herramientas de Escenario y Modding
## - Game Settings → Modal de Opciones de Audio (SoundManager) y Parámetros de Simulación
## - Exit Game     → Cierre seguro multiplataforma (PC / Móvil RAM clean)

class_name MainMenuVintage
extends Control

# ─── Referencias a Botones (%UniqueNames y $VBoxMenu Fallbacks) ─────────────
@onready var btn_single_player: Button  = _get_btn(["%SinglePlayer", "%BtnSinglePlayer", "VBoxMenu/BtnSinglePlayer"])
@onready var btn_multiplayer: Button    = _get_btn(["%Multiplayer", "%BtnMultiplayer", "VBoxMenu/BtnMultiplayer"])
@onready var btn_game_tools: Button     = _get_btn(["%GameTools", "%BtnGameTools", "VBoxMenu/BtnGameTools"])
@onready var btn_game_settings: Button  = _get_btn(["%GameSettings", "%BtnGameSettings", "VBoxMenu/BtnGameSettings"])
@onready var btn_exit: Button           = _get_btn(["%ExitGame", "%BtnExit", "VBoxMenu/BtnExit"])

@onready var lbl_title: Label           = get_node_or_null("LblTitle") as Label
@onready var lbl_version: Label         = get_node_or_null("LblVersion") as Label

# ─── Estética Retro Unificada (Caoba + Dorado) ───────────────────────────────
const CLR_PANEL_BG    := Color(0.118, 0.063, 0.031, 0.90)  # #1E1008 caoba oscuro
const CLR_BORDER      := Color(0.831, 0.686, 0.216, 1.0)   # #D4AF37 dorado
const CLR_BORDER_GOLD := Color(0.831, 0.686, 0.216, 1.0)   # #D4AF37 dorado
const CLR_TEXT_GOLD   := Color(1.0,   0.878, 0.278, 1.0)   # Amarillo brillante
const CLR_TEXT_DIM    := Color(0.9,   0.85,  0.70,  1.0)   # Texto secundario

# ─── Estado ──────────────────────────────────────────────────────────────────
var _tween: Tween = null
var _is_mobile: bool = false
var _particle_nodes: Array[Node] = []
var _bg_container: Control = null

# Nombres de las 10 Eras del Juego
const ERAS_LIST: Array[String] = [
	"0. Prehistórica",
	"1. Piedra",
	"2. Bronce",
	"3. Hierro",
	"4. Medieval",
	"5. Renacimiento",
	"6. Industrial",
	"7. Atómica",
	"8. Digital",
	"9. Nano-Futurista"
]

const RESOURCES_PRESETS: Array[String] = [
	"Escasos",
	"Estándar",
	"Abundantes",
	"Imperio Extremo"
]

const AI_DIFFICULTIES: Array[String] = [
	"Fácil",
	"Normal",
	"Difícil",
	"Experto"
]

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("main_menu")
	_is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

	_build_procedural_background()
	_connect_signals()
	_animate_entrance()
	_start_floating_particles()

	print("MainMenuVintage: Menú Principal iniciado. Plataforma: %s" % ("Móvil" if _is_mobile else "PC"))

func _get_btn(candidates: Array) -> Button:
	for path in candidates:
		var node := get_node_or_null(str(path)) as Button
		if is_instance_valid(node):
			return node
	return null

## Fábrica de StyleBoxFlat con tema retro caoba+dorado compartido por todos los modales.
func _make_retro_style(radius: int = 18, bg_alpha: float = 0.96) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(CLR_PANEL_BG.r, CLR_PANEL_BG.g, CLR_PANEL_BG.b, bg_alpha)
	s.border_color = CLR_BORDER
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.80)
	s.shadow_size  = 14
	return s

# ─── Configuración del Fondo Compatible PC-Móvil ───────────────────────────────

func _build_procedural_background() -> void:
	var bg_node := get_node_or_null("BgRect") as TextureRect
	if not is_instance_valid(bg_node):
		bg_node = get_node_or_null("%BgRect") as TextureRect

	var overlay_node := get_node_or_null("Overlay") as Control
	if is_instance_valid(overlay_node):
		overlay_node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tex: Texture2D = null

	# 1. Carga universal desde buffer de bytes (Soporta JPG y PNG independientemente de la extensión)
	for img_path in ["res://assets/main_menu_bg.png", "res://assets/main_menu_bg.jpg"]:
		if FileAccess.file_exists(img_path):
			var bytes := FileAccess.get_file_as_bytes(img_path)
			if bytes.size() > 0:
				var img := Image.new()
				var err := img.load_jpg_from_buffer(bytes)
				if err != OK:
					err = img.load_png_from_buffer(bytes)
				if err != OK:
					err = img.load_webp_from_buffer(bytes)
				if err == OK and not img.is_empty():
					tex = ImageTexture.create_from_image(img)
					print("MainMenuVintage: Imagen de fondo cargada exitosamente desde '%s' (%dx%d px)." % [img_path, img.get_width(), img.get_height()])
					break

	# 2. Fallback de respaldo mediante ResourceLoader
	if tex == null:
		if ResourceLoader.exists("res://assets/main_menu_bg.png"):
			tex = load("res://assets/main_menu_bg.png") as Texture2D
		elif ResourceLoader.exists("res://assets/main_menu_bg.jpg"):
			tex = load("res://assets/main_menu_bg.jpg") as Texture2D

	# 3. Aplicar la textura cargada al nodo de fondo BgRect con STRETCH_KEEP_ASPECT_COVERED
	if is_instance_valid(tex) and is_instance_valid(bg_node):
		bg_node.texture = tex
		bg_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_node.visible = true
		return

	# ── Fallback procedural si no hay textura ──
	_bg_container = Control.new()
	_bg_container.name = "ProcBgContainer"
	_bg_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_container)
	move_child(_bg_container, 0)

	var grad_bg := ColorRect.new()
	grad_bg.name = "ProcGradBg"
	grad_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad_bg.color = Color(0.04, 0.02, 0.01, 1.0)
	grad_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_container.add_child(grad_bg)

	_add_gradient_layer(Color(0.02, 0.05, 0.15, 0.85), Color(0.0, 0.0, 0.0, 0.0), true)
	_add_radial_glow(Color(0.55, 0.35, 0.05, 0.22), Vector2(0.5, 0.72))
	_add_radial_glow(Color(0.10, 0.20, 0.45, 0.18), Vector2(0.12, 0.60))
	_add_radial_glow(Color(0.50, 0.10, 0.05, 0.15), Vector2(0.88, 0.60))
	_add_horizon_band(Color(0.35, 0.22, 0.04, 0.40), 0.68, 0.12)
	_add_gradient_layer(Color(0.0, 0.0, 0.0, 0.72), Color(0.0, 0.0, 0.0, 0.0), false)

func _add_gradient_layer(color_solid: Color, color_clear: Color, from_top: bool) -> void:
	if not is_instance_valid(_bg_container):
		return
	var script_override := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.add_point(0.0, color_solid if from_top else color_clear)
	grad.add_point(1.0, color_clear if from_top else color_solid)
	script_override.gradient = grad
	script_override.fill_from = Vector2(0.5, 0.0 if from_top else 1.0)
	script_override.fill_to = Vector2(0.5, 1.0 if from_top else 0.0)

	var tex_rect := TextureRect.new()
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.texture = script_override
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_container.add_child(tex_rect)

func _add_radial_glow(color: Color, center_anchor: Vector2) -> void:
	if not is_instance_valid(_bg_container):
		return
	var tex_rect := TextureRect.new()
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.add_point(0.0, color)
	g.add_point(1.0, Color(color.r, color.g, color.b, 0.0))
	grad.gradient = g
	grad.fill_from = center_anchor
	grad.fill_to = Vector2(center_anchor.x + 0.5, center_anchor.y + 0.5)
	grad.fill = GradientTexture2D.FILL_RADIAL
	tex_rect.texture = grad
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_container.add_child(tex_rect)

func _add_horizon_band(color: Color, y_center: float, thickness: float) -> void:
	if not is_instance_valid(_bg_container):
		return
	var cr := ColorRect.new()
	cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	cr.anchor_top = y_center - thickness * 0.5
	cr.anchor_bottom = y_center + thickness * 0.5
	cr.color = color
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_container.add_child(cr)

# ─── Partículas Flotantes (Ascuas de Batalla) ───────────────────────────────────

func _start_floating_particles() -> void:
	var target_parent: Node = _bg_container if is_instance_valid(_bg_container) else self

	for i in range(24):
		var p := ColorRect.new()
		var p_size := randf_range(2.0, 5.0)
		p.custom_minimum_size = Vector2(p_size, p_size)
		p.size = Vector2(p_size, p_size)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.color = Color(
			randf_range(0.85, 1.0),
			randf_range(0.50, 0.85),
			randf_range(0.10, 0.30),
			randf_range(0.40, 0.90)
		)
		p.position = Vector2(randf_range(20, 1880), randf_range(200, 1000))
		target_parent.add_child(p)
		_particle_nodes.append(p)

		var duration := randf_range(4.0, 9.0)
		var start_y := p.position.y
		var tw := p.create_tween().set_loops()
		tw.tween_property(p, "position:y", start_y - randf_range(200, 550), duration) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(p, "modulate:a", 0.0, duration * 0.85) \
			.set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			p.position = Vector2(randf_range(20, 1880), randf_range(850, 1050))
			p.modulate.a = randf_range(0.4, 0.9)
		)

# ─── Conexión de Señales y Audio Feedback ─────────────────────────────────────

func _play_sfx(sfx_id: String) -> void:
	var sm: Node = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("jugar_sfx_interfaz"):
		sm.call("jugar_sfx_interfaz", sfx_id)

func _connect_signals() -> void:
	var button_list: Array[Button] = [
		btn_single_player,
		btn_multiplayer,
		btn_game_tools,
		btn_game_settings,
		btn_exit
	]

	for btn in button_list:
		if is_instance_valid(btn):
			btn.mouse_entered.connect(func(): _play_sfx("buy_click"))

	if is_instance_valid(btn_single_player):
		btn_single_player.pressed.connect(_on_single_player_pressed)
	if is_instance_valid(btn_multiplayer):
		btn_multiplayer.pressed.connect(_on_multiplayer_pressed)
	if is_instance_valid(btn_game_tools):
		btn_game_tools.pressed.connect(_on_game_tools_pressed)
	if is_instance_valid(btn_game_settings):
		btn_game_settings.pressed.connect(_on_game_settings_pressed)
	if is_instance_valid(btn_exit):
		btn_exit.pressed.connect(_on_exit_pressed)

# ─── Animación de Entrada ──────────────────────────────────────────────────────

func _animate_entrance() -> void:
	var vbox := get_node_or_null("VBoxMenu") as Control
	if is_instance_valid(vbox):
		vbox.modulate.a = 0.0
		vbox.position.y += 50.0
		_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_tween.tween_property(vbox, "modulate:a", 1.0, 1.0)
		_tween.parallel().tween_property(vbox, "position:y", vbox.position.y - 50.0, 1.0)

	if is_instance_valid(lbl_title):
		var orig_y := lbl_title.position.y
		lbl_title.position.y -= 80.0
		lbl_title.modulate.a = 0.0
		var tw2 := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw2.tween_property(lbl_title, "position:y", orig_y, 1.2)
		tw2.parallel().tween_property(lbl_title, "modulate:a", 1.0, 0.7)

	var sub := get_node_or_null("LblSubtitle") as Control
	if is_instance_valid(sub):
		sub.modulate.a = 0.0
		var tw3 := create_tween()
		tw3.tween_interval(0.6)
		tw3.tween_property(sub, "modulate:a", 1.0, 0.8)

	var line := get_node_or_null("LineSeparator") as Control
	if is_instance_valid(line):
		line.modulate.a = 0.0
		var tw4 := create_tween()
		tw4.tween_interval(0.8)
		tw4.tween_property(line, "modulate:a", 1.0, 0.6)

# ─── Pipeline de Lógica de Botones (Button Logic Pipeline) ────────────────────

## %SinglePlayer (Modo Un Jugador / Escaramuza)
## Despliega en pantalla el Sub-Panel Contenedor Flotante de Configuración Real
func _on_single_player_pressed() -> void:
	_play_sfx("buy_click")
	_show_skirmish_setup_modal()

## %Multiplayer (Modo Multijugador)
## Cambia la escena de forma estricta hacia res://scenes/ui/multiplayer_lobby.tscn
func _on_multiplayer_pressed() -> void:
	_play_sfx("buy_click")
	_fade_and_change_scene("res://scenes/ui/multiplayer_lobby.tscn")

## %GameTools (Herramientas de Juego / Escenario)
func _on_game_tools_pressed() -> void:
	_play_sfx("buy_click")
	_show_modal_panel(
		"🛠️ GAME TOOLS & EDICIÓN DE MAPAS",
		"Herramientas de Escenario y Modding — Próximamente:\n\n" +
		"• Editor 3D Procedural de Terrenos y Vistas Tácticas.\n" +
		"• Creador de Campañas Históricas y Diseñador de Burlas (Taunts).\n" +
		"• Gestor de Scripts de Misión e Inteligencia Artificial Custom."
	)

## %GameSettings (Opciones de Juego / Audio SoundManager)
func _on_game_settings_pressed() -> void:
	_play_sfx("buy_click")
	_show_settings_modal()

## %ExitGame (Salir del Juego / Gestión RAM Móvil)
func _on_exit_pressed() -> void:
	_play_sfx("buy_click")
	if _is_mobile:
		print("MainMenuVintage: Dispositivo móvil detectado. Limpiando memoria y enviando a segundo plano...")
		if OS.has_method("move_window_to_background"):
			OS.call("move_window_to_background")
		else:
			get_tree().quit()
	else:
		var tw := create_tween().set_ease(Tween.EASE_IN)
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		await tw.finished
		get_tree().quit()

# ─── Panel Modal Real de Configuración Pre-Partida (%OptStartingEra, %OptResources, %PopLimitSlider, %BtnStartMatch) ───

func _show_skirmish_setup_modal() -> void:
	# Ocultar controles del menú principal mientras el modal de partida esté activo
	var vbox_main_menu := get_node_or_null("VBoxMenu") as Control
	if is_instance_valid(vbox_main_menu):
		vbox_main_menu.visible = false
	var main_title_node := get_node_or_null("LblTitle") as Control
	if is_instance_valid(main_title_node):
		main_title_node.visible = false
	var main_sub_node := get_node_or_null("LblSubtitle") as Control
	if is_instance_valid(main_sub_node):
		main_sub_node.visible = false
	var main_line_node := get_node_or_null("LineSeparator") as Control
	if is_instance_valid(main_line_node):
		main_line_node.visible = false
	var main_ver_node := get_node_or_null("LblVersion") as Control
	if is_instance_valid(main_ver_node):
		main_ver_node.visible = false

	# Contenedor raíz modal de pantalla completa
	var modal_bg := Control.new()
	modal_bg.name = "SkirmishModalOverlay"
	add_child(modal_bg)
	modal_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_bg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	modal_bg.grow_vertical = Control.GROW_DIRECTION_BOTH
	modal_bg.mouse_filter = Control.MOUSE_FILTER_STOP

	# Fondo opcional panorámico cubriendo todo el viewport
	var bg_tex: Texture2D = load("res://assets/main_menu_bg.jpg") as Texture2D
	if is_instance_valid(bg_tex):
		var bg_rect := TextureRect.new()
		bg_rect.texture = bg_tex
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_rect.modulate = Color(0.28, 0.28, 0.28, 1.0)
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		modal_bg.add_child(bg_rect)
		bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dark_overlay := ColorRect.new()
	dark_overlay.color = Color(0.02, 0.01, 0.0, 0.70)
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_bg.add_child(dark_overlay)
	dark_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# CenterContainer para centrar perfectamente en cualquier monitor
	var center_container := CenterContainer.new()
	center_container.name = "CenterWrapper"
	modal_bg.add_child(center_container)
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_container.grow_vertical = Control.GROW_DIRECTION_BOTH

	var root_vbox := VBoxContainer.new()
	root_vbox.custom_minimum_size = Vector2(1240, 680)
	root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_theme_constant_override("separation", 10)
	center_container.add_child(root_vbox)

	# ─── ENCABEZADO SUPERIOR CON ESPADAS: EMPIRE TACTICS ────────────────────────
	var hbox_top_banner := HBoxContainer.new()
	hbox_top_banner.alignment = BoxContainer.ALIGNMENT_CENTER

	var banner_tex: Texture2D = load("res://assets/ui/title_banner.png") as Texture2D
	if is_instance_valid(banner_tex):
		var banner_rect := TextureRect.new()
		banner_rect.texture = banner_tex
		banner_rect.custom_minimum_size = Vector2(610, 75)
		banner_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hbox_top_banner.add_child(banner_rect)
	else:
		var lbl_title_top := Label.new()
		lbl_title_top.text = "⚔️  EMPIRE TACTICS  ⚔️\n— From Stone to Stars: Command Through the Ages —"
		lbl_title_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_title_top.add_theme_font_size_override("font_size", 22)
		lbl_title_top.add_theme_color_override("font_color", CLR_TEXT_GOLD)
		hbox_top_banner.add_child(lbl_title_top)

	root_vbox.add_child(hbox_top_banner)

	# ─── CONTENEDOR CENTRAL: DOS PANELES LADO A LADO ─────────────────────────────
	var hbox_panels := HBoxContainer.new()
	hbox_panels.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_panels.add_theme_constant_override("separation", 16)
	root_vbox.add_child(hbox_panels)

	# Estilos de pergamino vintage compartidos
	var parchment_panel_style := StyleBoxFlat.new()
	parchment_panel_style.bg_color = Color(0.92, 0.86, 0.74, 0.96) # Pergamino cálido
	parchment_panel_style.border_color = Color(0.48, 0.36, 0.16, 1.0) # Marco bronce antiguo
	parchment_panel_style.border_width_left = 3
	parchment_panel_style.border_width_top = 3
	parchment_panel_style.border_width_right = 3
	parchment_panel_style.border_width_bottom = 3
	parchment_panel_style.corner_radius_top_left = 10
	parchment_panel_style.corner_radius_top_right = 10
	parchment_panel_style.corner_radius_bottom_left = 10
	parchment_panel_style.corner_radius_bottom_right = 10
	parchment_panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.75)
	parchment_panel_style.shadow_size = 14

	var header_bar_style := StyleBoxFlat.new()
	header_bar_style.bg_color = Color(0.20, 0.14, 0.07, 1.0) # Bronce oscuro repujado
	header_bar_style.border_color = Color(0.75, 0.60, 0.22, 1.0)
	header_bar_style.border_width_bottom = 2
	header_bar_style.corner_radius_top_left = 8
	header_bar_style.corner_radius_top_right = 8

	# ══════════════════════════════════════════════════════════════════════════════
	# PANEL 1 (IZQUIERDA): GESTIÓN DE RANURAS (JUGADORES & BOTS)
	# ══════════════════════════════════════════════════════════════════════════════
	var panel_slots := PanelContainer.new()
	panel_slots.custom_minimum_size = Vector2(590, 500)
	panel_slots.add_theme_stylebox_override("panel", parchment_panel_style)

	var vbox_slots_outer := VBoxContainer.new()
	panel_slots.add_child(vbox_slots_outer)

	# Cabecera Panel Ranuras
	var header_slots := PanelContainer.new()
	header_slots.custom_minimum_size = Vector2(0, 36)
	header_slots.add_theme_stylebox_override("panel", header_bar_style)
	var hbox_head_slots := HBoxContainer.new()
	hbox_head_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	var lbl_head_slots := Label.new()
	lbl_head_slots.text = "🏛️ GESTIÓN DE RANURAS (JUGADORES & BOTS)"
	lbl_head_slots.add_theme_font_size_override("font_size", 15)
	lbl_head_slots.add_theme_color_override("font_color", CLR_TEXT_GOLD)
	hbox_head_slots.add_child(lbl_head_slots)
	header_slots.add_child(hbox_head_slots)
	vbox_slots_outer.add_child(header_slots)

	# Filas de las 8 ranuras
	var slots_vbox := VBoxContainer.new()
	slots_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slots_vbox.add_theme_constant_override("separation", 4)

	# Paleta de colores para ranuras
	var slot_colors := [
		Color(0.9, 0.15, 0.15), Color(0.2, 0.45, 0.95), Color(0.95, 0.85, 0.2), Color(0.2, 0.8, 0.2),
		Color(0.2, 0.85, 0.85), Color(0.65, 0.2, 0.85), Color(0.95, 0.55, 0.1), Color(0.65, 0.65, 0.65)
	]
	var slot_color_names := ["Rojo", "Azul", "Amarillo", "Verde", "Cian", "Púrpura", "Naranja", "Gris"]
	var slot_row_controls: Array[Dictionary] = []

	for i in range(8):
		var row_panel := PanelContainer.new()
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.94, 0.88, 0.78, 1.0) if (i % 2 == 0) else Color(0.88, 0.82, 0.70, 1.0)
		row_style.corner_radius_top_left = 6
		row_style.corner_radius_top_right = 6
		row_style.corner_radius_bottom_left = 6
		row_style.corner_radius_bottom_right = 6
		row_panel.add_theme_stylebox_override("panel", row_style)

		var hbox_row := HBoxContainer.new()
		hbox_row.add_theme_constant_override("separation", 6)
		hbox_row.custom_minimum_size = Vector2(0, 36)

		# 1. Número de ranura
		var lbl_num := Label.new()
		lbl_num.text = " %d." % (i + 1)
		lbl_num.custom_minimum_size = Vector2(22, 0)
		lbl_num.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
		lbl_num.add_theme_font_size_override("font_size", 13)
		hbox_row.add_child(lbl_num)

		# 2. Avatar de retrato del jugador/bot
		var tex_av := TextureRect.new()
		var av_res: Texture2D = load("res://assets/ui/icons/avatar_slot_%d.png" % (i + 1)) as Texture2D
		if is_instance_valid(av_res):
			tex_av.texture = av_res
		tex_av.custom_minimum_size = Vector2(30, 30)
		tex_av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hbox_row.add_child(tex_av)

		# 3. Pin coloreado
		var pin_lbl := Label.new()
		pin_lbl.text = "📍"
		pin_lbl.modulate = slot_colors[i]
		hbox_row.add_child(pin_lbl)

		# 4. Dropdown de Tipo (Humano / BOT Normal / BOT Difícil / Cerrado)
		var opt_slot_type := OptionButton.new()
		opt_slot_type.add_item("Humano")
		opt_slot_type.add_item("BOT (Normal)")
		opt_slot_type.add_item("BOT (Difícil)")
		opt_slot_type.add_item("Cerrado")
		opt_slot_type.custom_minimum_size = Vector2(105, 30)
		opt_slot_type.selected = 0 if (i == 0) else (1 if i < 4 else 3)
		hbox_row.add_child(opt_slot_type)

		# 5. Dropdown de Equipo
		var opt_slot_team := OptionButton.new()
		opt_slot_team.add_item("Team 1")
		opt_slot_team.add_item("Equipo 2")
		opt_slot_team.add_item("Equipo 3")
		opt_slot_team.add_item("Equipo 4")
		opt_slot_team.custom_minimum_size = Vector2(88, 30)
		opt_slot_team.selected = 0 if (i % 2 == 0) else 1
		hbox_row.add_child(opt_slot_team)

		# 6. Dropdown de Color
		var opt_slot_col := OptionButton.new()
		for c_name in slot_color_names:
			opt_slot_col.add_item(c_name)
		opt_slot_col.custom_minimum_size = Vector2(82, 30)
		opt_slot_col.selected = i
		hbox_row.add_child(opt_slot_col)

		# 7. Rectángulo de Muestra de Color
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(22, 22)
		swatch.color = slot_colors[i]
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox_row.add_child(swatch)

		opt_slot_col.item_selected.connect(func(c_idx: int):
			swatch.color = slot_colors[c_idx]
			pin_lbl.modulate = slot_colors[c_idx]
		)

		# 8. Estado de la Ranura (Host / BOT / Libre / Cerrado)
		var lbl_status := Label.new()
		lbl_status.custom_minimum_size = Vector2(50, 0)
		lbl_status.add_theme_font_size_override("font_size", 13)
		if i == 0:
			lbl_status.text = "Host"
			lbl_status.add_theme_color_override("font_color", Color(0.2, 0.45, 0.15))
		elif i < 4:
			lbl_status.text = "BOT"
			lbl_status.add_theme_color_override("font_color", Color(0.6, 0.4, 0.15))
		else:
			lbl_status.text = "Cerrado"
			lbl_status.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3))

		opt_slot_type.item_selected.connect(func(type_idx: int):
			match type_idx:
				0:
					lbl_status.text = "Host" if i == 0 else "Humano"
					lbl_status.add_theme_color_override("font_color", Color(0.2, 0.45, 0.15))
				1:
					lbl_status.text = "BOT"
					lbl_status.add_theme_color_override("font_color", Color(0.6, 0.4, 0.15))
				2:
					lbl_status.text = "BOT+"
					lbl_status.add_theme_color_override("font_color", Color(0.7, 0.2, 0.15))
				3:
					lbl_status.text = "Cerrado"
					lbl_status.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3))
		)

		hbox_row.add_child(lbl_status)
		row_panel.add_child(hbox_row)
		slots_vbox.add_child(row_panel)

		slot_row_controls.append({
			"type": opt_slot_type,
			"team": opt_slot_team,
			"color": opt_slot_col,
			"status": lbl_status
		})

	vbox_slots_outer.add_child(slots_vbox)
	hbox_panels.add_child(panel_slots)

	# ══════════════════════════════════════════════════════════════════════════════
	# PANEL 2 (DERECHA): OPCIONES GLOBALES DE PARTIDA
	# ══════════════════════════════════════════════════════════════════════════════
	var panel_rules := PanelContainer.new()
	panel_rules.custom_minimum_size = Vector2(630, 500)
	panel_rules.add_theme_stylebox_override("panel", parchment_panel_style)

	var vbox_rules_outer := VBoxContainer.new()
	panel_rules.add_child(vbox_rules_outer)

	# Cabecera Panel Opciones
	var header_rules := PanelContainer.new()
	header_rules.custom_minimum_size = Vector2(0, 36)
	header_rules.add_theme_stylebox_override("panel", header_bar_style)
	var hbox_head_rules := HBoxContainer.new()
	hbox_head_rules.alignment = BoxContainer.ALIGNMENT_CENTER
	var lbl_head_rules := Label.new()
	lbl_head_rules.text = "⚙️ OPCIONES GLOBALES DE PARTIDA"
	lbl_head_rules.add_theme_font_size_override("font_size", 15)
	lbl_head_rules.add_theme_color_override("font_color", CLR_TEXT_GOLD)
	hbox_head_rules.add_child(lbl_head_rules)
	header_rules.add_child(hbox_head_rules)
	vbox_rules_outer.add_child(header_rules)

	# Cuerpo derecho dividido en [Selectores] y [Mapa + Tabletas]
	var hbox_rules_body := HBoxContainer.new()
	hbox_rules_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_rules_body.add_theme_constant_override("separation", 14)
	vbox_rules_outer.add_child(hbox_rules_body)

	# Subcolumna 1: Selectores de Partida
	var vbox_options_col := VBoxContainer.new()
	vbox_options_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_options_col.add_theme_constant_override("separation", 6)

	var grid_opts := GridContainer.new()
	grid_opts.columns = 2
	grid_opts.add_theme_constant_override("h_separation", 8)
	grid_opts.add_theme_constant_override("v_separation", 6)

	var opt_game_type := func_create_opt_row("Tipo de Partida:", ["Mapa Aleatorio", "Campaña", "Personalizado"], 0, grid_opts)
	var opt_map_size := func_create_opt_row("Tamaño del Mapa:", ["Pequeño (150m)", "Mediano (300m)", "Grande (600m)", "Gigante (1200m)"], 1, grid_opts)
	var opt_terrain := func_create_opt_row("Tipo de Terreno:", ["Continental", "Islas (Dock3D)", "Planicie"], 0, grid_opts)
	var opt_biome := func_create_opt_row("Bioma / Clima:", ["Continental", "Bosque Templado", "Desierto", "Ártico"], 0, grid_opts)
	var opt_resources := func_create_opt_row("Recursos Iniciales:", ["Escaso", "Estándar", "Abundante", "Imperio Extremo"], 1, grid_opts)
	var opt_starting_era := func_create_opt_row("Edad Inicial:", ERAS_LIST, 0, grid_opts)
	var opt_max_era := func_create_opt_row("Edad Límite:", ["Sin Límite"] + ERAS_LIST, 0, grid_opts)
	var opt_units_limit := func_create_opt_row("Límite de Unidades:", ["50 Unidades", "100 Unidades", "200 Unidades", "300 Unidades", "500 Unidades"], 2, grid_opts)

	vbox_options_col.add_child(grid_opts)

	# Separador sutil
	var sep_rules := HSeparator.new()
	vbox_options_col.add_child(sep_rules)

	var lbl_special := Label.new()
	lbl_special.text = "Reglas Especiales:"
	lbl_special.add_theme_font_size_override("font_size", 13)
	lbl_special.add_theme_color_override("font_color", Color(0.35, 0.25, 0.1))
	vbox_options_col.add_child(lbl_special)

	var chk_reveal_map := CheckBox.new()
	chk_reveal_map.text = "Mostrar mapa (Quitar niebla inicial)"
	chk_reveal_map.add_theme_font_size_override("font_size", 12)
	chk_reveal_map.add_theme_color_override("font_color", Color(0.2, 0.15, 0.08))
	vbox_options_col.add_child(chk_reveal_map)

	var hbox_civ_tree := HBoxContainer.new()
	hbox_civ_tree.add_theme_constant_override("separation", 8)
	var chk_civ_tree := CheckBox.new()
	chk_civ_tree.text = "Personalizar civilización (Árbol de ventajas)"
	chk_civ_tree.button_pressed = true
	chk_civ_tree.add_theme_font_size_override("font_size", 12)
	chk_civ_tree.add_theme_color_override("font_color", Color(0.2, 0.15, 0.08))
	hbox_civ_tree.add_child(chk_civ_tree)

	# Botón interactivo de Balanza / Árbol Tecnológico (scale_tree_btn.png)
	var btn_scale_tree := Button.new()
	var scale_tex: Texture2D = load("res://assets/ui/icons/scale_tree_btn.png") as Texture2D
	if is_instance_valid(scale_tex):
		btn_scale_tree.icon = scale_tex
	else:
		btn_scale_tree.text = "⚖️"
	btn_scale_tree.custom_minimum_size = Vector2(28, 28)
	btn_scale_tree.tooltip_text = "Abrir Configuración Avanzada de Civilización / Árbol de Ventajas"
	btn_scale_tree.pressed.connect(_open_civ_tree_modal)
	chk_civ_tree.toggled.connect(func(pressed: bool):
		if pressed: _open_civ_tree_modal()
	)
	hbox_civ_tree.add_child(btn_scale_tree)
	vbox_options_col.add_child(hbox_civ_tree)

	var chk_lock_teams := CheckBox.new()
	chk_lock_teams.text = "Bloquear equipos"
	chk_lock_teams.button_pressed = true
	chk_lock_teams.add_theme_font_size_override("font_size", 12)
	chk_lock_teams.add_theme_color_override("font_color", Color(0.2, 0.15, 0.08))
	vbox_options_col.add_child(chk_lock_teams)

	hbox_rules_body.add_child(vbox_options_col)

	# Subcolumna 2: Mapa Circular y Cuadrícula de Tabletas de Piedra
	var vbox_map_col := VBoxContainer.new()
	vbox_map_col.custom_minimum_size = Vector2(150, 0)
	vbox_map_col.add_theme_constant_override("separation", 10)
	vbox_map_col.alignment = BoxContainer.ALIGNMENT_CENTER

	# Ilustración circular del mapa terráqueo vintage
	var map_circle_tex: Texture2D = load("res://assets/ui/map_circle_preview.png") as Texture2D
	if is_instance_valid(map_circle_tex):
		var tex_map_circle := TextureRect.new()
		tex_map_circle.texture = map_circle_tex
		tex_map_circle.custom_minimum_size = Vector2(130, 130)
		tex_map_circle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_map_circle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vbox_map_col.add_child(tex_map_circle)

	# Cuadrícula 2x3 de tabletas de piedra con iconos tácticos
	var grid_tablets := GridContainer.new()
	grid_tablets.columns = 2
	grid_tablets.add_theme_constant_override("h_separation", 6)
	grid_tablets.add_theme_constant_override("v_separation", 6)

	_add_tablet_btn("tablet_era.png", "Era", grid_tablets, func(): opt_starting_era.grab_focus())
	_add_tablet_btn("tablet_recursos.png", "Recursos", grid_tablets, func(): opt_resources.grab_focus())
	_add_tablet_btn("tablet_poblacion.png", "Población", grid_tablets, func(): opt_units_limit.grab_focus())
	_add_tablet_btn("tablet_ia_group.png", "IA", grid_tablets, func(): pass)
	_add_tablet_btn("tablet_ia_bot.png", "IA Bot", grid_tablets, func(): pass)
	_add_tablet_btn("tablet_etc.png", "etc.", grid_tablets, func(): _open_civ_tree_modal())

	vbox_map_col.add_child(grid_tablets)
	hbox_rules_body.add_child(vbox_map_col)

	hbox_panels.add_child(panel_rules)

	# ══════════════════════════════════════════════════════════════════════════════
	# BARRA INFERIOR DE NAVEGACIÓN: [VOLVER] [CARGAR GUARDADO] [INICIAR PARTIDA]
	# ══════════════════════════════════════════════════════════════════════════════
	var hbox_bottom_bar := HBoxContainer.new()
	hbox_bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_bottom_bar.add_theme_constant_override("separation", 24)
	hbox_bottom_bar.custom_minimum_size = Vector2(0, 56)

	var btn_pill_style := StyleBoxFlat.new()
	btn_pill_style.bg_color = Color(0.18, 0.11, 0.04, 0.95)
	btn_pill_style.border_color = CLR_BORDER_GOLD
	btn_pill_style.border_width_left = 2
	btn_pill_style.border_width_top = 2
	btn_pill_style.border_width_right = 2
	btn_pill_style.border_width_bottom = 2
	btn_pill_style.corner_radius_top_left = 20
	btn_pill_style.corner_radius_top_right = 20
	btn_pill_style.corner_radius_bottom_left = 20
	btn_pill_style.corner_radius_bottom_right = 20

	var btn_cancel := Button.new()
	btn_cancel.text = "VOLVER"
	btn_cancel.custom_minimum_size = Vector2(160, 48)
	btn_cancel.add_theme_font_size_override("font_size", 16)
	btn_cancel.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	btn_cancel.add_theme_stylebox_override("normal", btn_pill_style)
	btn_cancel.pressed.connect(func():
		_play_sfx("buy_click")
		if is_instance_valid(vbox_main_menu): vbox_main_menu.visible = true
		if is_instance_valid(main_title_node): main_title_node.visible = true
		if is_instance_valid(main_sub_node): main_sub_node.visible = true
		if is_instance_valid(main_line_node): main_line_node.visible = true
		if is_instance_valid(main_ver_node): main_ver_node.visible = true
		modal_bg.queue_free()
	)
	hbox_bottom_bar.add_child(btn_cancel)

	var btn_load := Button.new()
	btn_load.text = "CARGAR GUARDADO"
	btn_load.custom_minimum_size = Vector2(210, 48)
	btn_load.add_theme_font_size_override("font_size", 16)
	btn_load.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	btn_load.add_theme_stylebox_override("normal", btn_pill_style)
	btn_load.pressed.connect(func():
		_play_sfx("buy_click")
		_on_load_saved_game_pressed()
	)
	hbox_bottom_bar.add_child(btn_load)

	# Botón central monumental: INICIAR PARTIDA
	var btn_start_match := Button.new()
	btn_start_match.name = "BtnStartMatch"
	btn_start_match.text = "⚔️   INICIAR PARTIDA   🚀"
	btn_start_match.custom_minimum_size = Vector2(360, 52)
	btn_start_match.add_theme_font_size_override("font_size", 20)
	btn_start_match.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35, 1.0))

	var start_style := StyleBoxFlat.new()
	start_style.bg_color = Color(0.24, 0.15, 0.03, 0.98)
	start_style.border_color = Color(1.0, 0.85, 0.30, 1.0)
	start_style.border_width_left = 3
	start_style.border_width_top = 3
	start_style.border_width_right = 3
	start_style.border_width_bottom = 3
	start_style.corner_radius_top_left = 26
	start_style.corner_radius_top_right = 26
	start_style.corner_radius_bottom_left = 26
	start_style.corner_radius_bottom_right = 26
	start_style.shadow_color = Color(0.9, 0.7, 0.2, 0.6)
	start_style.shadow_size = 12
	btn_start_match.add_theme_stylebox_override("normal", start_style)

	btn_start_match.pressed.connect(func():
		_play_sfx("buy_click")
		# Inyectar slots y configuración elegida con todos los filtros
		_start_skirmish_with_two_panel_settings(
			opt_game_type.selected,
			opt_starting_era.selected,
			opt_max_era.selected,
			opt_resources.selected,
			opt_units_limit.selected,
			opt_map_size.selected,
			opt_terrain.selected,
			opt_biome.selected,
			chk_reveal_map.button_pressed,
			chk_civ_tree.button_pressed,
			chk_lock_teams.button_pressed,
			slot_row_controls
		)
	)
	hbox_bottom_bar.add_child(btn_start_match)

	root_vbox.add_child(hbox_bottom_bar)

# ─── Helpers de Creación del Menú Vintage ──────────────────────────────────────

func func_create_opt_row(title: String, items: Array, default_idx: int, container: GridContainer) -> OptionButton:
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.25, 0.18, 0.10))
	container.add_child(lbl)

	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(210, 30)
	for item in items:
		ob.add_item(str(item))
	ob.selected = default_idx
	ob.add_theme_color_override("font_color", CLR_TEXT_GOLD)

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.22, 0.15, 0.08, 0.95)
	s.border_color = Color(0.65, 0.50, 0.20, 1.0)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	ob.add_theme_stylebox_override("normal", s)

	container.add_child(ob)
	return ob

func _add_tablet_btn(icon_filename: String, title: String, container: GridContainer, on_click: Callable) -> void:
	var btn := Button.new()
	var path: String = "res://assets/ui/icons/" + icon_filename
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		btn.icon = tex
	# No asignamos texto para no duplicar el grabado de la tableta de piedra
	btn.text = ""
	btn.tooltip_text = title
	btn.custom_minimum_size = Vector2(65, 48)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.20, 0.14, 0.07, 0.9)
	s.border_color = Color(0.6, 0.45, 0.18, 1.0)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", s)

	btn.pressed.connect(func():
		_play_sfx("buy_click")
		on_click.call()
	)
	container.add_child(btn)

func _open_civ_tree_modal() -> void:
	_play_sfx("buy_click")
	var existing = get_node_or_null("CivUpgradePanelModal")
	if is_instance_valid(existing):
		existing.visible = true
		return
	var cup := CivUpgradePanel.new()
	cup.name = "CivUpgradePanelModal"
	add_child(cup)
	cup.visible = true

func _on_load_saved_game_pressed() -> void:
	var sm: Node = get_node_or_null("/root/SaveManager")
	if is_instance_valid(sm) and sm.has_method("cargar_partida"):
		sm.call("cargar_partida", "quicksave.json")
		_fade_and_change_scene("res://scenes/main_3d.tscn")
	else:
		print("MainMenuVintage: No se encontró SaveManager para cargar partida.")

## Inicia la partida offline leyendo con total rigor las ranuras y filtros configurados
func _start_skirmish_with_two_panel_settings(
	game_type_idx: int,
	era_index: int,
	max_era_idx: int,
	res_index: int,
	pop_limit_idx: int,
	map_size_idx: int,
	terrain_idx: int,
	biome_idx: int,
	reveal_map: bool,
	custom_civ: bool,
	lock_teams: bool,
	slot_controls: Array[Dictionary]
) -> void:
	var pop_limits_arr := [50, 100, 200, 300, 500]
	var pop_limit: int = pop_limits_arr[clampi(pop_limit_idx, 0, pop_limits_arr.size() - 1)]
	var max_era_val: int = 9 if max_era_idx == 0 else (max_era_idx - 1)
	var res_preset_keys: Array[String] = ["escaso", "normal", "abundante", "deathmatch"]
	var selected_res_key: String = res_preset_keys[clampi(res_index, 0, res_preset_keys.size() - 1)]
	var new_seed: int = randi()

	# 1. Configurar GameSettings
	var gs: Node = get_node_or_null("/root/GameSettings")
	if not is_instance_valid(gs):
		gs = GameSettings.new()
		gs.name = "GameSettings"
		get_tree().root.add_child(gs)

	gs.set("starting_era",         era_index)
	gs.set("max_era",              max_era_val)
	gs.set("max_population_limit", pop_limit)
	gs.set("starting_resources",   selected_res_key)
	gs.set("map_type",             "aleatorio" if game_type_idx == 0 else "custom")
	gs.set("map_size_preset",      map_size_idx)  # 0=Pequeño, 1=Mediano, 2=Grande, 3=Gigante
	gs.set("map_biome",            biome_idx)     # 0=Continental, 1=Islas, 2=Planicie
	gs.set("map_terrain_type",     terrain_idx)
	gs.set("map_seed",             new_seed)
	gs.set("show_map",             reveal_map)
	gs.set("fog_of_war_enabled",   not reveal_map)
	gs.set("custom_civ",           custom_civ)
	# Contabilizar jugadores y bots activos para definir player_count real (1 = 0 enemigos / práctica)
	var active_humans := 0
	var active_bots := 0
	for ctrl in slot_controls:
		var type_idx: int = ctrl["type"].selected
		if type_idx == 0:
			active_humans += 1
		elif type_idx == 1 or type_idx == 2:
			active_bots += 1

	var total_active_players: int = max(1, active_humans + active_bots)
	gs.set("player_count", total_active_players)

	# Paleta de colores para asignar a GameSettings
	var slot_colors := [
		Color(0.9, 0.15, 0.15), Color(0.2, 0.45, 0.95), Color(0.95, 0.85, 0.2), Color(0.2, 0.8, 0.2),
		Color(0.2, 0.85, 0.85), Color(0.65, 0.2, 0.85), Color(0.95, 0.55, 0.1), Color(0.65, 0.65, 0.65)
	]
	var slot_color_values: Array[Color] = []
	var slot_teams_values: Array[int] = []
	for ctrl in slot_controls:
		var c_idx: int = ctrl["color"].selected
		var t_idx: int = ctrl["team"].selected
		slot_color_values.append(slot_colors[c_idx] if c_idx < slot_colors.size() else Color.WHITE)
		slot_teams_values.append(t_idx + 1)
	gs.set("slot_colors", slot_color_values)
	gs.set("slot_teams",  slot_teams_values)

	# 2. Configurar recursos
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/GlobalResourceManager")
	if is_instance_valid(rm):
		if "max_population" in rm:
			rm.set("max_population", pop_limit)
		if "max_era" in rm:
			rm.set("max_era", max_era_val)
		if rm.has_method("_aplicar_nueva_era"):
			rm.call("_aplicar_nueva_era", era_index)
		var amounts: Dictionary = gs.call("get_starting_resource_amounts") if gs.has_method("get_starting_resource_amounts") else {}
		for res in amounts:
			if res in rm:
				rm.set(res, amounts[res])

	# 3. Configurar MultiplayerManager con los 8 slots configurados
	var mm: Node = get_node_or_null("/root/MultiplayerManager")
	if is_instance_valid(mm):
		if mm.has_method("crear_servidor"):
			mm.call("crear_servidor")

		if "lobby_slots" in mm and mm.get("lobby_slots") is Array:
			var slots: Array = mm.get("lobby_slots")
			var host_team: int = slot_controls[0]["team"].selected if slot_controls.size() > 0 else 0
			for i in range(min(slots.size(), slot_controls.size())):
				var ctrl: Dictionary = slot_controls[i]
				var type_idx: int = ctrl["type"].selected
				var team_idx: int = ctrl["team"].selected
				var color_idx: int = ctrl["color"].selected

				# El equipo del Host siempre corresponde a Bando.PLAYER (0). Equipos contrarios a Bando.ENEMY (1).
				slots[i]["bando"] = 0 if (team_idx == host_team) else 1
				slots[i]["team"] = team_idx + 1
				slots[i]["color"] = color_idx
				match type_idx:
					0: # Humano
						slots[i]["type"] = 1 # SlotType.HUMAN
						slots[i]["status"] = "HUMANO"
						slots[i]["peer_id"] = 1 if i == 0 else 0
						slots[i]["name"] = "Jugador 1 (Host)" if i == 0 else "Humano_%d" % (i + 1)
					1: # BOT Normal
						slots[i]["type"] = 2 # SlotType.BOT
						slots[i]["status"] = "BOT_IA"
						slots[i]["name"] = "Bot IA (%d)" % (i + 1)
						slots[i]["ai_difficulty"] = "normal"
					2: # BOT Difícil
						slots[i]["type"] = 2 # SlotType.BOT
						slots[i]["status"] = "BOT_IA"
						slots[i]["name"] = "Bot IA Difícil (%d)" % (i + 1)
						slots[i]["ai_difficulty"] = "dificil"
					3: # Cerrado
						slots[i]["type"] = 3 # SlotType.CLOSED
						slots[i]["status"] = "CERRADO"
						slots[i]["name"] = "Slot %d (Cerrado)" % (i + 1)
						slots[i]["peer_id"] = 0

		if mm.has_method("iniciar_partida_hibrida"):
			mm.call("iniciar_partida_hibrida")
			return

	_fade_and_change_scene("res://scenes/main_3d.tscn")

## Inyección en runtime a GameSettings, GlobalResourceManager y MultiplayerManager
func _start_skirmish_with_custom_settings(
	era_index: int,
	res_index: int,
	pop_limit: int,
	ai_diff_index: int,
	map_size_idx: int = 1,
	biome_idx: int = 0
) -> void:
	# 1. Obtener o instanciar GameSettings
	var gs: Node = get_node_or_null("/root/GameSettings")
	if not is_instance_valid(gs):
		gs = GameSettings.new()
		gs.name = "GameSettings"
		get_tree().root.add_child(gs)

	# 2. Inyectar Era Inicial, Tamaño de Mapa, Bioma y Semilla Aleatoria Única
	gs.set("starting_era",     era_index)
	gs.set("max_population_limit", pop_limit)
	gs.set("map_size_preset",  map_size_idx)
	gs.set("map_biome",        biome_idx)
	# Semilla única por partida — garantiza mapas completamente distintos
	var new_seed: int = randi()
	gs.set("map_seed", new_seed)

	# Mapeo de recursos seleccionados
	var res_preset_keys: Array[String] = ["escaso", "normal", "abundante", "deathmatch"]
	var selected_res_key: String = res_preset_keys[clampi(res_index, 0, res_preset_keys.size() - 1)]
	gs.set("starting_resources", selected_res_key)

	# Mapeo de dificultad de IA
	var ai_diff_keys: Array[String] = ["facil", "normal", "dificil", "experto"]
	var selected_ai_key: String = ai_diff_keys[clampi(ai_diff_index, 0, ai_diff_keys.size() - 1)]
	gs.set("ai_difficulty", selected_ai_key)

	print("MainMenuVintage: Inyectando datos de partida → Era: %d | Pob Máx: %d | Recursos: %s | IA: %s | Mapa: %d | Bioma: %d | Seed: %d" % [
		era_index, pop_limit, selected_res_key, selected_ai_key, map_size_idx, biome_idx, new_seed
	])

	# 3. Inyectar recursos iniciales en GlobalResourceManager / ResourceManager
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/GlobalResourceManager")

	if is_instance_valid(rm):
		if "max_population" in rm:
			rm.set("max_population", pop_limit)

		var res_amounts: Dictionary = {"food": 250, "wood": 250, "stone": 150, "gold": 150, "iron": 0}
		if gs.has_method("get_starting_resource_amounts"):
			res_amounts = gs.call("get_starting_resource_amounts")

		for k in res_amounts:
			if k in rm:
				rm.set(k, res_amounts[k])

		if rm.has_method("_aplicar_nueva_era"):
			rm.call("_aplicar_nueva_era", era_index)

	# 4. Iniciar Listen Server de 1 Peer en MultiplayerManager con Bots IA Skirmish
	var mm: Node = get_node_or_null("/root/MultiplayerManager")
	if is_instance_valid(mm):
		if mm.has_method("crear_servidor"):
			mm.call("crear_servidor")

		if "lobby_slots" in mm and mm.get("lobby_slots") is Array:
			var slots: Array = mm.get("lobby_slots")
			slots[0]["type"] = 1 # SlotType.HUMAN
			slots[0]["status"] = "HUMANO"
			slots[0]["peer_id"] = 1
			slots[0]["name"] = "Jugador 1 (Host)"
			slots[0]["bando"] = 0

			var num_participantes: int = 2
			match map_size_idx:
				0: num_participantes = 2 # Pequeño (2 Jugadores: 1 Host + 1 Bot)
				1: num_participantes = 4 # Mediano (4 Jugadores: 1 Host + 3 Bots)
				2: num_participantes = 6 # Grande (6 Jugadores: 1 Host + 5 Bots)
				3: num_participantes = 8 # Gigante (8 Jugadores: 1 Host + 7 Bots)

			for i in range(1, slots.size()):
				if i < num_participantes:
					slots[i]["type"] = 2 # SlotType.BOT (IA Skirmish)
					slots[i]["status"] = "BOT_IA"
					slots[i]["name"] = "Bot IA (%d)" % (i + 1)
					slots[i]["bando"] = 1
					slots[i]["ai_difficulty"] = selected_ai_key
				else:
					slots[i]["type"] = 3 # SlotType.CLOSED
					slots[i]["status"] = "CERRADO"
					slots[i]["name"] = "Slot %d (Cerrado)" % (i + 1)
					slots[i]["peer_id"] = 0

		if mm.has_method("iniciar_partida_hibrida"):
			mm.call("iniciar_partida_hibrida")
			return

	_fade_and_change_scene("res://scenes/main_3d.tscn")

# ─── Helpers de Transición e Interfaz Modal ───────────────────────────────────

func _fade_and_change_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		# Fallback de seguridad: Si se solicita res://scenes/ui/multiplayer_lobby.tscn e instanciación directa
		if scene_path == "res://scenes/ui/multiplayer_lobby.tscn":
			var lobby_script: Script = load("res://scripts/ui/multiplayer_lobby.gd")
			if is_instance_valid(lobby_script):
				var lobby: Node = lobby_script.new()
				get_tree().root.add_child(lobby)
				get_tree().current_scene = lobby
				self.queue_free()
				return

		_show_modal_panel("⚠️ ERROR DE NAVEGACIÓN", "Escena no encontrada en disco:\n%s" % scene_path)
		return

	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate:a", 0.0, 0.45)
	await tw.finished
	get_tree().change_scene_to_file(scene_path)

func _show_modal_panel(title_text: String, body_text: String) -> void:
	var modal_bg := ColorRect.new()
	modal_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_bg.color = Color(0.0, 0.0, 0.0, 0.75)
	modal_bg.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_retro_style(18, 0.95))

	panel.custom_minimum_size = Vector2(620, 320)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -160
	panel.offset_bottom = 160

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)

	var lbl_h := Label.new()
	lbl_h.text = title_text
	lbl_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_h.add_theme_font_size_override("font_size", 22)
	lbl_h.add_theme_color_override("font_color", CLR_TEXT_GOLD)

	var lbl_b := Label.new()
	lbl_b.text = body_text
	lbl_b.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_b.add_theme_font_size_override("font_size", 16)
	lbl_b.add_theme_color_override("font_color", CLR_TEXT_DIM)
	lbl_b.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var btn_close := Button.new()
	btn_close.text = "ACEPTAR"
	btn_close.custom_minimum_size = Vector2(180, 44)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_close.add_theme_font_size_override("font_size", 18)
	btn_close.add_theme_color_override("font_color", CLR_TEXT_GOLD)

	vbox.add_child(lbl_h)
	vbox.add_child(lbl_b)
	vbox.add_child(btn_close)
	panel.add_child(vbox)
	modal_bg.add_child(panel)

	add_child(modal_bg)

	btn_close.pressed.connect(func():
		_play_sfx("buy_click")
		modal_bg.queue_free()
	)

func _show_settings_modal() -> void:
	var modal_bg := ColorRect.new()
	modal_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_bg.color = Color(0.0, 0.0, 0.0, 0.75)
	modal_bg.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_retro_style(18, 0.95))

	panel.custom_minimum_size = Vector2(650, 360)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -325
	panel.offset_right = 325
	panel.offset_top = -180
	panel.offset_bottom = 180

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)

	var lbl_h := Label.new()
	lbl_h.text = "⚙  OPCIONES DE CONFIGURACIÓN DE AUDIO & JUEGO"
	lbl_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_h.add_theme_font_size_override("font_size", 20)
	lbl_h.add_theme_color_override("font_color", CLR_TEXT_GOLD)

	# Slider de Volumen Master / SoundManager
	var hbox_vol := HBoxContainer.new()
	var lbl_vol := Label.new()
	lbl_vol.text = "🔊 Volumen Master (SoundManager):"
	lbl_vol.add_theme_font_size_override("font_size", 16)
	lbl_vol.custom_minimum_size = Vector2(300, 0)

	var slider_vol := HSlider.new()
	slider_vol.min_value = 0.0
	slider_vol.max_value = 1.0
	slider_vol.step = 0.05
	slider_vol.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	slider_vol.custom_minimum_size = Vector2(240, 32)
	slider_vol.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hbox_vol.add_child(lbl_vol)
	hbox_vol.add_child(slider_vol)

	slider_vol.value_changed.connect(func(val: float):
		AudioServer.set_bus_volume_db(0, linear_to_db(val))
		_play_sfx("buy_click")
	)

	var lbl_info := Label.new()
	lbl_info.text = "• Gráficos: Sombras Dinámicas 3D y Niebla de Guerra activas.\n" + \
		"• Red: Sincronización Cuantizada ENet a 20 Hz.\n" + \
		"• Sonido: Pool Autónomo de 16 Canales UI / Posicional 3D."
	lbl_info.add_theme_font_size_override("font_size", 15)
	lbl_info.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, 1.0))

	var btn_close := Button.new()
	btn_close.text = "GUARDAR Y CERRAR"
	btn_close.custom_minimum_size = Vector2(220, 46)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_close.add_theme_font_size_override("font_size", 18)
	btn_close.add_theme_color_override("font_color", Color(1.0, 0.88, 0.28, 1.0))

	vbox.add_child(lbl_h)
	vbox.add_child(hbox_vol)
	vbox.add_child(lbl_info)
	vbox.add_child(btn_close)
	panel.add_child(vbox)
	modal_bg.add_child(panel)

	add_child(modal_bg)

	btn_close.pressed.connect(func():
		_play_sfx("buy_click")
		modal_bg.queue_free()
	)
