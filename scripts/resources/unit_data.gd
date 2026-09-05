## UnitData — Recurso de datos para definir unidades.
##
## Crea instancias .tres para cada tipo de unidad por era.
## Patrón: Data-Driven Design (Strategy por era vía Resources).
##
## El campo `cost` usa claves de STRING para coincidir con el
## ResourceManager del proyecto (resources["wood"], ["food"], etc.)
## Ejemplo: { "wood": 50, "food": 30 }

class_name UnitData
extends Resource

# ─── Identificación ────────────────────────────────────────────────────────────
@export var unit_name: String = ""
@export var description: String = ""
@export_file("*.tscn") var scene_path: String = ""

# ─── Costo de Producción ───────────────────────────────────────────────────────
## Claves: "wood" | "food" | "gold" | "iron" | "stone"
## Ejemplo: { "wood": 50, "food": 30 }
@export var cost: Dictionary = {
	"wood": 50,
	"food": 30,
}

## Tiempo en segundos para producir esta unidad.
@export var production_time: float = 10.0

## Era mínima requerida (0 = Edad de Piedra, 1 = Bronce, 2 = Hierro, …)
@export var era_requirement: int = 0

# ─── Stats Base ────────────────────────────────────────────────────────────────
@export var base_hp: int = 100
@export var base_speed: float = 100.0
@export var base_attack_damage: int = 5
@export var base_attack_range: float = 40.0
@export var base_attack_cooldown: float = 1.0

# ─── Combate a Distancia ───────────────────────────────────────────────────────
@export var projectile_scene: PackedScene = null
@export var aoe_radius: float = 0.0

# ─── UI ────────────────────────────────────────────────────────────────────────
@export var icon: Texture2D = null
