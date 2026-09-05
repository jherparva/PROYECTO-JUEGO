## HUD — Interfaz de usuario de recursos y población.
##
## Se construye completamente por código (no necesita escena .tscn externa).
## Conecta automáticamente a las señales de ResourceManager.
##
## Uso: añade este script a un nodo CanvasLayer en main.tscn, o
##      instancia la escena hud.tscn desde main.tscn.
##
## Diseño visual: barra oscura y semitransparente en la parte superior,
## iconos de texto + valores numéricos para cada recurso y la población.

class_name HUD
extends CanvasLayer

# ─── Constantes de Diseño ──────────────────────────────────────────────────────
const BAR_HEIGHT    := 44
const ICON_FONT_SZ  := 20
const VALUE_FONT_SZ := 16
const ITEM_MIN_W    := 90
const BG_COLOR      := Color(0.06, 0.06, 0.08, 0.88)
const ICON_COLOR    := Color(0.9, 0.85, 0.6, 1.0)
const VALUE_COLOR   := Color(1.0, 1.0, 1.0, 1.0)
const POP_OK_COLOR  := Color(0.4, 1.0, 0.5, 1.0)
const POP_FULL_COLOR:= Color(1.0, 0.35, 0.35, 1.0)

# Emojis / símbolos por recurso
const ICONS: Dictionary = {
	"wood":  "🪵",
	"food":  "🌾",
	"gold":  "💰",
	"iron":  "⚙️",
	"stone": "🪨",
}

# ─── Nodos Generados ───────────────────────────────────────────────────────────
var _value_labels: Dictionary = {}   # { resource_name: Label }
var _pop_label: Label = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	layer = 5
	_build_ui()
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		if rm.has_signal("resources_changed"):
			rm.resources_changed.connect(_on_resources_changed)
		elif rm.has_signal("recursos_actualizados"):
			rm.recursos_actualizados.connect(_on_resources_changed)
		if rm.has_signal("population_changed"):
			rm.population_changed.connect(_on_population_changed)

# ─── Construcción de UI ────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Fondo semitransparente
	var bg := ColorRect.new()
	bg.name           = "Background"
	bg.color          = BG_COLOR
	bg.anchor_right   = 1.0
	bg.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	add_child(bg)

	# Contenedor principal horizontal
	var hbox := HBoxContainer.new()
	hbox.name                 = "ResourceBar"
	hbox.anchor_right         = 1.0
	hbox.custom_minimum_size  = Vector2(0, BAR_HEIGHT)
	hbox.alignment            = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)

	# Separador izquierdo
	var left_spacer := Control.new()
	left_spacer.custom_minimum_size = Vector2(16, 0)
	hbox.add_child(left_spacer)

	# Un ítem por cada recurso
	for res_name in ["wood", "food", "gold", "iron", "stone"]:
		_add_resource_item(hbox, res_name)
		_add_separator(hbox)

	# Población (extremo derecho)
	_add_population_item(hbox)

	# Separador derecho
	var right_spacer := Control.new()
	right_spacer.custom_minimum_size = Vector2(16, 0)
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_spacer)

func _add_resource_item(parent: HBoxContainer, res_name: String) -> void:
	var container := HBoxContainer.new()
	container.name = res_name.capitalize() + "Box"
	container.custom_minimum_size = Vector2(ITEM_MIN_W, 0)
	container.add_theme_constant_override("separation", 4)

	# Icono
	var icon_lbl := Label.new()
	icon_lbl.text = ICONS.get(res_name, "?")
	icon_lbl.add_theme_font_size_override("font_size", ICON_FONT_SZ)
	icon_lbl.add_theme_color_override("font_color", ICON_COLOR)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(icon_lbl)

	# Valor
	var val_lbl := Label.new()
	val_lbl.name = res_name + "_value"
	val_lbl.text = "0"
	val_lbl.add_theme_font_size_override("font_size", VALUE_FONT_SZ)
	val_lbl.add_theme_color_override("font_color", VALUE_COLOR)
	val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_lbl.custom_minimum_size = Vector2(50, 0)
	container.add_child(val_lbl)

	_value_labels[res_name] = val_lbl
	parent.add_child(container)

func _add_population_item(parent: HBoxContainer) -> void:
	var container := HBoxContainer.new()
	container.name = "PopBox"
	container.add_theme_constant_override("separation", 4)

	var icon_lbl := Label.new()
	icon_lbl.text = "👥"
	icon_lbl.add_theme_font_size_override("font_size", ICON_FONT_SZ)
	icon_lbl.add_theme_color_override("font_color", ICON_COLOR)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(icon_lbl)

	_pop_label = Label.new()
	_pop_label.name = "pop_value"
	_pop_label.text = "0 / 10"
	_pop_label.add_theme_font_size_override("font_size", VALUE_FONT_SZ)
	_pop_label.add_theme_color_override("font_color", POP_OK_COLOR)
	_pop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(_pop_label)

	parent.add_child(container)

func _add_separator(parent: HBoxContainer) -> void:
	var sep := VSeparator.new()
	sep.add_theme_color_override("color", Color(1, 1, 1, 0.15))
	parent.add_child(sep)

# ─── Señales de ResourceManager ────────────────────────────────────────────────

func _on_resources_changed(current_resources: Dictionary) -> void:
	for res_name in _value_labels:
		var lbl: Label = _value_labels[res_name]
		lbl.text = str(current_resources.get(res_name, 0))

func _on_population_changed(current_pop: int, max_pop: int) -> void:
	if not is_instance_valid(_pop_label):
		return
	_pop_label.text = "%d / %d" % [current_pop, max_pop]
	# Cambiar color al rojo cuando la población está al límite
	var color := POP_FULL_COLOR if current_pop >= max_pop else POP_OK_COLOR
	_pop_label.add_theme_color_override("font_color", color)
