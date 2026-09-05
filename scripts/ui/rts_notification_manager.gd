## RTSNotificationManager — Sistema de Alertas y Notificaciones Dinámicas del HUD RTS.
##                          (GDScript 2.0 / Godot 4 — Triple-A Production Grade)
##
## Arquitectura desacoplada basada en señales. Se conecta a:
##   • ResourceManager.era_evolucionada  → Banner central de avance tecnológico
##   • RTSEnemyAI.ataque_lanzado         → Alerta crítica roja de ataque enemigo
##   • API pública show_notification()   → Cualquier sistema del juego puede enviar mensajes
##
## Cada notificación es un nodo Control instanciado dinámicamente que:
##   1. Entra con animación de slide + fade-in (0.35s)
##   2. Permanece visible durante su duración configurada
##   3. Sale con fade-out suave (0.6s) usando Tween de Godot 4
##   4. Se destruye al completar la animación de salida (queue_free)
##
## Soporta hasta MAX_NOTIFICACIONES_VISIBLES simultáneas; las más antiguas se expulsan
## si la cola se satura para evitar la acumulación infinita en pantalla.

class_name RTSNotificationManager
extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# TIPOS Y CONSTANTES
# ──────────────────────────────────────────────────────────────────────────────

## Tipos de notificación con estilos visuales diferenciados.
enum TipoNotificacion {
	INFO      = 0,  ## Información general — azul/gris
	EXITO     = 1,  ## Acción completada — verde
	ADVERTENCIA = 2, ## Aviso no crítico — naranja
	CRITICA   = 3,  ## Alerta de combate — rojo pulsante
	ERA       = 4,  ## Avance de era — dorado/amber especial
}

## Máximo de notificaciones visibles simultáneamente antes de expulsar las más antiguas.
const MAX_NOTIFICACIONES_VISIBLES: int = 5

## Duración por defecto según tipo (segundos).
const DURACION_POR_TIPO: Dictionary = {
	TipoNotificacion.INFO:        3.5,
	TipoNotificacion.EXITO:       3.5,
	TipoNotificacion.ADVERTENCIA: 4.0,
	TipoNotificacion.CRITICA:     6.0,
	TipoNotificacion.ERA:         6.0,
}

## Colores de fondo por tipo.
const COLOR_FONDO: Dictionary = {
	TipoNotificacion.INFO:        Color(0.08, 0.12, 0.22, 0.92),
	TipoNotificacion.EXITO:       Color(0.04, 0.22, 0.08, 0.92),
	TipoNotificacion.ADVERTENCIA: Color(0.28, 0.14, 0.02, 0.94),
	TipoNotificacion.CRITICA:     Color(0.30, 0.02, 0.02, 0.95),
	TipoNotificacion.ERA:         Color(0.18, 0.12, 0.02, 0.97),
}

## Colores de borde/acento por tipo.
const COLOR_ACENTO: Dictionary = {
	TipoNotificacion.INFO:        Color(0.35, 0.60, 1.00, 1.0),
	TipoNotificacion.EXITO:       Color(0.25, 0.90, 0.40, 1.0),
	TipoNotificacion.ADVERTENCIA: Color(1.00, 0.60, 0.10, 1.0),
	TipoNotificacion.CRITICA:     Color(1.00, 0.15, 0.15, 1.0),
	TipoNotificacion.ERA:         Color(1.00, 0.80, 0.10, 1.0),
}

## Iconos Unicode por tipo.
const ICONO_TIPO: Dictionary = {
	TipoNotificacion.INFO:        "ℹ",
	TipoNotificacion.EXITO:       "✔",
	TipoNotificacion.ADVERTENCIA: "⚠",
	TipoNotificacion.CRITICA:     "⚔",
	TipoNotificacion.ERA:         "⚜",
}

## Tamaños de fuente por tipo.
const FONT_SIZE_TITULO: Dictionary = {
	TipoNotificacion.INFO:        16,
	TipoNotificacion.EXITO:       16,
	TipoNotificacion.ADVERTENCIA: 17,
	TipoNotificacion.CRITICA:     20,
	TipoNotificacion.ERA:         26,
}

# ──────────────────────────────────────────────────────────────────────────────
# EXPORTS
# ──────────────────────────────────────────────────────────────────────────────

@export_group("Animación")
## Duración de la animación de entrada (slide + fade-in) en segundos.
@export var duracion_entrada:  float = 0.35
## Duración de la animación de salida (fade-out) en segundos.
@export var duracion_salida:   float = 0.60
## Margen horizontal de los mensajes de alerta respecto al borde de la ventana.
@export var margen_lateral:    float = 20.0
## Margen vertical desde la parte superior de la pantalla para las alertas apiladas.
@export var margen_superior:   float = 60.0
## Espacio vertical entre notificaciones apiladas.
@export var espaciado_pila:    float = 6.0

@export_group("Pulsación Crítica")
## Si true, las alertas CRITICA parpadean con un efecto de pulse de color.
@export var habilitar_pulso_critico: bool = true
## Velocidad de pulsación para alertas de tipo CRITICA.
@export var velocidad_pulso:   float = 2.5

# ──────────────────────────────────────────────────────────────────────────────
# ESTADO INTERNO
# ──────────────────────────────────────────────────────────────────────────────

## Lista de nodos Control activos actualmente visibles en pantalla.
var _notificaciones_activas: Array[Control] = []

## Nodo raíz donde se parenteran todas las notificaciones instanciadas.
var _contenedor: Control = null

## Referencia al viewport para calcular tamaños responsivos.
var _viewport_size: Vector2 = Vector2(1920.0, 1080.0)

# ──────────────────────────────────────────────────────────────────────────────
# CICLO DE VIDA
# ──────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	layer = 20  # Por encima del HUD (5), Minimapa (6) y Selection UI (10)
	name = "RTSNotificationManager"

	# Crear el contenedor transparente de tamaño completo
	_contenedor = Control.new()
	_contenedor.name = "NotificationsRoot"
	_contenedor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_contenedor)

	_viewport_size = get_viewport().get_visible_rect().size

	# Conectar señales globales de forma desacoplada
	call_deferred("_conectar_senales_globales")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_viewport_size = get_viewport().get_visible_rect().size

# ──────────────────────────────────────────────────────────────────────────────
# CONEXIÓN DE SEÑALES GLOBALES (desacoplado — no requiere referencias directas)
# ──────────────────────────────────────────────────────────────────────────────

func _conectar_senales_globales() -> void:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

	# ── RTSEnemyAI → Ataque lanzado (buscar en grupo enemy_ai) ───────────────
	_conectar_ia_enemiga()

func _conectar_ia_enemiga() -> void:
	var ai_nodes := get_tree().get_nodes_in_group("enemy_ai")
	for ai_node in ai_nodes:
		if is_instance_valid(ai_node) and ai_node.has_signal("ataque_lanzado"):
			if not (ai_node as RTSEnemyAI).ataque_lanzado.is_connected(_on_ataque_enemigo_lanzado):
				(ai_node as RTSEnemyAI).ataque_lanzado.connect(_on_ataque_enemigo_lanzado)

# ──────────────────────────────────────────────────────────────────────────────
# HANDLERS DE SEÑALES
# ──────────────────────────────────────────────────────────────────────────────

## Handler: ResourceManager.era_evolucionada
func _on_era_evolucionada(player_id_or_era: Variant = 0, nueva_era: Variant = null, _extra: Variant = null) -> void:
	var local_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	var player_id: int = 1
	var era_val: int = 0
	if nueva_era != null and nueva_era is int:
		player_id = int(player_id_or_era)
		era_val = int(nueva_era)
	elif player_id_or_era is int:
		era_val = int(player_id_or_era)
	elif player_id_or_era is String:
		show_era_banner(player_id_or_era)
		return

	var rm_ref: Node = get_node_or_null("/root/ResourceManager")
	var era_nom: String = rm_ref.NOMBRE_ERA.get(era_val, "Era %d" % era_val) if (is_instance_valid(rm_ref) and "NOMBRE_ERA" in rm_ref) else ("Era %d" % era_val)

	if player_id == local_id:
		show_era_banner(era_nom)

## Handler: RTSEnemyAI.ataque_lanzado
func _on_ataque_enemigo_lanzado(guerreros: int, _posicion: Vector3) -> void:
	show_attack_alert(guerreros)

# ──────────────────────────────────────────────────────────────────────────────
# API PÚBLICA — NOTIFICACIONES ESPECIALIZADAS
# ──────────────────────────────────────────────────────────────────────────────

## Muestra el banner central dorado de avance de era.
## Llamado automáticamente por la señal era_evolucionada.
func show_era_banner(nombre_era: String) -> void:
	# El banner de era ocupa el centro de la pantalla y es único
	_descartar_notificaciones_tipo(TipoNotificacion.ERA)

	var titulo: String  = "⚜  ¡AVANCE TECNOLÓGICO!  ⚜"
	var mensaje: String = "Has entrado en la  %s" % nombre_era.to_upper()
	_crear_notificacion_era(titulo, mensaje)

## Muestra la alerta crítica roja de ataque enemigo.
## Llamado automáticamente por la señal ataque_lanzado de RTSEnemyAI.
func show_attack_alert(num_guerreros: int) -> void:
	var mensaje: String = "⚔  ¡ALERTA: %d Fuerzas enemigas marchan\nhacia tu Centro de Ciudad!" % num_guerreros
	show_notification(mensaje, TipoNotificacion.CRITICA)

## Muestra una notificación genérica con tipo y duración personalizable.
##
## @param texto     Texto a mostrar (soporta \n para saltos de línea).
## @param tipo      TipoNotificacion — controla estilo visual.
## @param duracion  Segundos de visibilidad. 0 = usar duración por defecto del tipo.
func show_notification(texto: String, tipo: TipoNotificacion = TipoNotificacion.INFO, duracion: float = 0.0) -> void:
	var dur: float = duracion if duracion > 0.0 else float(DURACION_POR_TIPO.get(int(tipo), 4.0))
	_crear_notificacion_estandar(texto, tipo, dur)

func info(texto: String, duracion: float = 0.0)        -> void: show_notification(texto, TipoNotificacion.INFO, duracion)
func exito(texto: String, duracion: float = 0.0)       -> void: show_notification(texto, TipoNotificacion.EXITO, duracion)
func advertencia(texto: String, duracion: float = 0.0) -> void: show_notification(texto, TipoNotificacion.ADVERTENCIA, duracion)
func critica(texto: String, duracion: float = 0.0)     -> void: show_notification(texto, TipoNotificacion.CRITICA, duracion)

func add_notification(texto: String, tipo: int = -1, duracion: float = 0.0) -> void:
	var notif_tipo := TipoNotificacion.INFO
	if tipo >= 0:
		notif_tipo = tipo as TipoNotificacion
	elif texto.contains("⚠️") or texto.contains("⚔") or texto.to_lower().contains("población"):
		notif_tipo = TipoNotificacion.CRITICA
	show_notification(texto, notif_tipo, duracion)


# ──────────────────────────────────────────────────────────────────────────────
# CONSTRUCCIÓN DE NOTIFICACIÓN — BANNER DE ERA (estilo especial centrado)
# ──────────────────────────────────────────────────────────────────────────────

func _crear_notificacion_era(titulo: String, subtitulo: String) -> void:
	var dur: float = float(DURACION_POR_TIPO.get(int(TipoNotificacion.ERA), 6.0))

	# ── Contenedor raíz de la notificación ────────────────────────────────────
	var panel: Control = Control.new()
	panel.name = "EraNotification"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Dimensiones del banner de era (ancho fijo, centrado)
	var ancho:  float = minf(860.0, _viewport_size.x - 40.0)
	var alto:   float = 110.0
	var pos_x:  float = (_viewport_size.x - ancho) * 0.5
	var pos_y:  float = 80.0
	panel.set_position(Vector2(pos_x, pos_y - 120.0))  # Empieza fuera de pantalla (arriba)
	panel.set_size(Vector2(ancho, alto))

	# ── Fondo con bordes redondeados simulados vía capas ──────────────────────
	var bg_outer: ColorRect = _crear_rect(Color(1.00, 0.80, 0.10, 0.90), Vector2.ZERO, Vector2(ancho, alto))
	var bg_inner: ColorRect = _crear_rect(Color(0.12, 0.08, 0.01, 0.97), Vector2(3, 3), Vector2(ancho - 6, alto - 6))

	panel.add_child(bg_outer)
	panel.add_child(bg_inner)

	# ── Texto título ──────────────────────────────────────────────────────────
	var lbl_titulo: Label = _crear_label(
		titulo,
		24,
		Color(1.00, 0.85, 0.20, 1.0),
		true
	)
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.set_position(Vector2(0.0, 10.0))
	lbl_titulo.set_size(Vector2(ancho, 38.0))
	panel.add_child(lbl_titulo)

	# ── Texto subtítulo ───────────────────────────────────────────────────────
	var lbl_sub: Label = _crear_label(
		subtitulo,
		18,
		Color(1.00, 0.96, 0.75, 1.0),
		false
	)
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.set_position(Vector2(0.0, 54.0))
	lbl_sub.set_size(Vector2(ancho, 42.0))
	panel.add_child(lbl_sub)

	# ── Línea decorativa inferior ──────────────────────────────────────────────
	var linea: ColorRect = _crear_rect(Color(1.00, 0.80, 0.10, 0.6), Vector2(40.0, alto - 8.0), Vector2(ancho - 80.0, 3.0))
	panel.add_child(linea)

	_contenedor.add_child(panel)
	_notificaciones_activas.append(panel)
	_limpiar_cola_saturada()

	# ── Animación de entrada: slide-down + fade-in ────────────────────────────
	var tween_in: Tween = create_tween().set_parallel(true)
	tween_in.tween_property(panel, "position:y", pos_y, duracion_entrada).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_in.tween_property(panel, "modulate:a", 1.0, duracion_entrada).from(0.0)

	# ── Efecto sutil de pulso dorado en el borde ──────────────────────────────
	var tween_pulse: Tween = create_tween().set_loops(3)
	tween_pulse.tween_property(bg_outer, "color:a", 0.60, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween_pulse.tween_property(bg_outer, "color:a", 0.92, 0.5).set_ease(Tween.EASE_IN_OUT)

	# ── Programar fade-out y destrucción ──────────────────────────────────────
	_programar_salida(panel, dur)

# ──────────────────────────────────────────────────────────────────────────────
# CONSTRUCCIÓN DE NOTIFICACIÓN — ESTÁNDAR (apilada en esquina derecha)
# ──────────────────────────────────────────────────────────────────────────────

func _crear_notificacion_estandar(texto: String, tipo: TipoNotificacion, duracion: float) -> void:
	var color_fondo:  Color = COLOR_FONDO.get(int(tipo),  Color(0.1, 0.1, 0.1, 0.9)) as Color
	var color_acento: Color = COLOR_ACENTO.get(int(tipo), Color(0.5, 0.5, 0.5, 1.0)) as Color
	var icono:        String = ICONO_TIPO.get(int(tipo), "•") as String
	var font_sz:      int    = FONT_SIZE_TITULO.get(int(tipo), 16) as int

	# Calcular el alto según número de líneas del texto
	var lineas: int = texto.count("\n") + 1
	var ancho:  float = 520.0 if tipo == TipoNotificacion.CRITICA else 440.0
	var alto:   float = 28.0 + lineas * (font_sz + 8.0)

	# ── Posición inicial: fuera del borde derecho de la pantalla ──────────────
	var pos_y_final: float = _calcular_pos_y_siguiente()
	var pos_x_final: float = _viewport_size.x - ancho - margen_lateral
	var pos_x_inicio: float = _viewport_size.x + 20.0  # Empieza a la derecha fuera

	# ── Nodo raíz ─────────────────────────────────────────────────────────────
	var panel: Control = Control.new()
	panel.name = "Notification_%s" % TipoNotificacion.keys()[int(tipo)]
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_position(Vector2(pos_x_inicio, pos_y_final))
	panel.set_size(Vector2(ancho, alto))

	# ── Borde acento (2px izquierda) ──────────────────────────────────────────
	var borde: ColorRect = _crear_rect(color_acento, Vector2.ZERO, Vector2(4.0, alto))
	panel.add_child(borde)

	# ── Fondo principal ───────────────────────────────────────────────────────
	var fondo: ColorRect = _crear_rect(color_fondo, Vector2(4.0, 0.0), Vector2(ancho - 4.0, alto))
	panel.add_child(fondo)

	# ── Icono ─────────────────────────────────────────────────────────────────
	var lbl_icono: Label = _crear_label(icono, font_sz + 4, color_acento, true)
	lbl_icono.set_position(Vector2(12.0, (alto - float(font_sz + 4)) * 0.5))
	lbl_icono.set_size(Vector2(32.0, float(font_sz + 8)))
	panel.add_child(lbl_icono)

	# ── Texto del mensaje ─────────────────────────────────────────────────────
	var lbl_texto: Label = _crear_label(texto, font_sz, Color(0.95, 0.95, 0.95, 1.0), false)
	lbl_texto.set_position(Vector2(48.0, 10.0))
	lbl_texto.set_size(Vector2(ancho - 58.0, alto - 12.0))
	lbl_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(lbl_texto)

	_contenedor.add_child(panel)
	_notificaciones_activas.append(panel)
	_limpiar_cola_saturada()

	# ── Animación de entrada: slide desde la derecha ──────────────────────────
	var tween_in: Tween = create_tween().set_parallel(true)
	tween_in.tween_property(panel, "position:x", pos_x_final, duracion_entrada).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween_in.tween_property(panel, "modulate:a", 1.0, duracion_entrada).from(0.0)

	# ── Efecto pulsante en alertas críticas ───────────────────────────────────
	if tipo == TipoNotificacion.CRITICA and habilitar_pulso_critico:
		_aplicar_pulso_critico(fondo, borde, color_acento, color_fondo, duracion)

	# ── Programar fade-out ────────────────────────────────────────────────────
	_programar_salida(panel, duracion)

# ──────────────────────────────────────────────────────────────────────────────
# ANIMACIÓN DE SALIDA Y GESTIÓN DE COLA
# ──────────────────────────────────────────────────────────────────────────────

## Programa el fade-out de una notificación tras `duracion` segundos.
func _programar_salida(panel: Control, duracion: float) -> void:
	# Timer de espera antes del fade-out
	var timer: SceneTreeTimer = get_tree().create_timer(duracion)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(panel):
			return
		# Fade-out suave con tween
		var tween_out: Tween = create_tween().set_parallel(true)
		tween_out.tween_property(panel, "modulate:a", 0.0, duracion_salida).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween_out.tween_property(panel, "scale", Vector2(0.95, 0.95), duracion_salida).set_ease(Tween.EASE_IN)
		# Destruir al completar
		tween_out.chain().tween_callback(func() -> void:
			if is_instance_valid(panel):
				_notificaciones_activas.erase(panel)
				panel.queue_free()
				_reordenar_pila()
		)
	)

## Efecto de pulsación roja continua para notificaciones críticas.
func _aplicar_pulso_critico(fondo: ColorRect, borde: ColorRect, col_acento: Color, col_fondo: Color, duracion: float) -> void:
	var iteraciones: int = int(duracion / (1.0 / velocidad_pulso)) + 1
	var tween_pulse: Tween = create_tween().set_loops(iteraciones)
	tween_pulse.tween_property(fondo, "color", Color(col_fondo.r + 0.12, col_fondo.g, col_fondo.b, col_fondo.a), 0.4 / velocidad_pulso).set_ease(Tween.EASE_IN_OUT)
	tween_pulse.tween_property(fondo, "color", col_fondo, 0.4 / velocidad_pulso).set_ease(Tween.EASE_IN_OUT)

	var tween_borde: Tween = create_tween().set_loops(iteraciones)
	tween_borde.tween_property(borde, "color:a", 0.45, 0.35 / velocidad_pulso).set_ease(Tween.EASE_IN_OUT)
	tween_borde.tween_property(borde, "color:a", 1.0,  0.35 / velocidad_pulso).set_ease(Tween.EASE_IN_OUT)

## Reposiciona verticalmente todas las notificaciones activas tras eliminar una.
func _reordenar_pila() -> void:
	var pos_y: float = margen_superior
	for notif in _notificaciones_activas:
		if not is_instance_valid(notif):
			continue
		# Sólo reordenar las notificaciones de pila (no los banners ERA centrados)
		if notif.name.begins_with("Notification_"):
			var tween_move: Tween = create_tween()
			tween_move.tween_property(notif, "position:y", pos_y, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			pos_y += notif.size.y + espaciado_pila

## Expulsa las notificaciones más antiguas si la cola supera el máximo.
func _limpiar_cola_saturada() -> void:
	while _notificaciones_activas.size() > MAX_NOTIFICACIONES_VISIBLES:
		var mas_antigua: Control = _notificaciones_activas[0]
		_notificaciones_activas.remove_at(0)
		if is_instance_valid(mas_antigua):
			var tween_expulsar: Tween = create_tween()
			tween_expulsar.tween_property(mas_antigua, "modulate:a", 0.0, 0.2)
			tween_expulsar.tween_callback(func() -> void:
				if is_instance_valid(mas_antigua):
					mas_antigua.queue_free()
			)

## Elimina todas las notificaciones activas de un tipo específico.
func _descartar_notificaciones_tipo(tipo: TipoNotificacion) -> void:
	var tipo_str: String = TipoNotificacion.keys()[int(tipo)]
	for notif in _notificaciones_activas.duplicate():
		if not is_instance_valid(notif):
			continue
		if notif.name.contains(tipo_str) or (tipo == TipoNotificacion.ERA and notif.name == "EraNotification"):
			_notificaciones_activas.erase(notif)
			var tw: Tween = create_tween()
			tw.tween_property(notif, "modulate:a", 0.0, 0.2)
			tw.tween_callback(notif.queue_free)

# ──────────────────────────────────────────────────────────────────────────────
# HELPERS DE POSICIONAMIENTO
# ──────────────────────────────────────────────────────────────────────────────

## Calcula la posición Y donde debe aparecer la siguiente notificación de pila.
func _calcular_pos_y_siguiente() -> float:
	var pos_y: float = margen_superior
	for notif in _notificaciones_activas:
		if is_instance_valid(notif) and notif.name.begins_with("Notification_"):
			pos_y += notif.size.y + espaciado_pila
	return pos_y

# ──────────────────────────────────────────────────────────────────────────────
# HELPERS DE CONSTRUCCIÓN DE NODOS
# ──────────────────────────────────────────────────────────────────────────────

## Crea un ColorRect con posición y tamaño ya configurados.
func _crear_rect(color: Color, pos: Vector2, size: Vector2) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.color = color
	rect.position = pos
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

## Crea un Label con tamaño de fuente y color configurados.
func _crear_label(texto: String, font_size: int, color: Color, negrita: bool) -> Label:
	var lbl: Label = Label.new()
	lbl.text = texto
	lbl.modulate = color
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Configurar tamaño y peso de fuente mediante Theme overrides
	lbl.add_theme_font_size_override("font_size", font_size)

	if negrita:
		# Forzar apariencia de negrita mediante outline como hack de production
		lbl.add_theme_constant_override("outline_size", 1)
		lbl.add_theme_color_override("font_outline_color", color.darkened(0.4))

	return lbl

# ──────────────────────────────────────────────────────────────────────────────
# API DE DEPURACIÓN Y CONTROL
# ──────────────────────────────────────────────────────────────────────────────

## Elimina todas las notificaciones activas inmediatamente (útil en pausa/game-over).
func limpiar_todas() -> void:
	for notif in _notificaciones_activas.duplicate():
		if is_instance_valid(notif):
			notif.queue_free()
	_notificaciones_activas.clear()

## Retorna el número de notificaciones actualmente visibles.
func get_count_activas() -> int:
	return _notificaciones_activas.size()

## Reintenta conectar señales si la IA enemiga fue instanciada después del _ready().
func reconectar_ia_enemiga() -> void:
	_conectar_ia_enemiga()
