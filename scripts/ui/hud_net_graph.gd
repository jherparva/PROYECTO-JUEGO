## HUDNetGraph — Indicador de Telemetría de Red y Rendimiento en Pantalla (GDScript 2.0 / Godot 4).
##
## Muestra el Ping (Latencia ms) y el Ancho de Banda consumido (KB/s) en tiempo real en una esquina del HUD.

class_name HUDNetGraph
extends Control

@onready var label_stats: Label = get_node_or_null("%LabelStats") as Label

var ncm: NetworkCompressionManager = null

func _ready() -> void:
	add_to_group("hud_net_graph")
	process_mode = PROCESS_MODE_ALWAYS

	ncm = NetworkCompressionManager.instance
	if not is_instance_valid(ncm):
		ncm = get_node_or_null("/root/NetworkCompressionManager") as NetworkCompressionManager

	if is_instance_valid(ncm):
		ncm.net_stats_updated.connect(_on_net_stats_updated)

	_setup_default_label()

func _setup_default_label() -> void:
	if not is_instance_valid(label_stats):
		label_stats = Label.new()
		label_stats.name = "LabelStats"
		add_child(label_stats)

	label_stats.add_theme_font_size_override("font_size", 12)
	label_stats.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6)) # Verde cibernético
	label_stats.text = "📶 Ping: 0 ms | 📊 Net: 0.0 KB/s"

func _on_net_stats_updated(ping_ms: int, kbps: float) -> void:
	if is_instance_valid(label_stats):
		label_stats.text = "📶 Ping: %d ms | 📊 Net: %.1f KB/s" % [ping_ms, kbps]
