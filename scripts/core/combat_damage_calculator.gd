## CombatDamageCalculator — Motor de Daño con Matriz de Counters oficial de Empire Earth.
##
## Encapsula la lógica de combate de EE extraída de dbweapontohit.dat y dbunitset.dat:
## - Matriz de modificadores de tipo arma -> tipo armadura (counters).
## - Bono de terreno táctico por elevación (dbcliffterrain.dat).
## - Métodos estáticos para cálculo determinista local (sin RPC).

class_name CombatDamageCalculator
extends RefCounted

# --- Tipos de Arma (Weapon Types) — dbweapontohit.dat -------------------------
## Tipos de arma reconocidos por el motor de combate de EE.
enum WeaponType {
	MELEE_SHOCK,   ## Cuerpo a cuerpo de choque (garrote, espada, hacha)
	MELEE_PIERCE,  ## Cuerpo a cuerpo perforante (lanza, pica, bayoneta)
	ARROW,         ## Flecha / ballesta (distancia perforante)
	SIEGE,         ## Arma de asedio (catapulta, canon, artilleria)
	GUNPOWDER,     ## Polvora / arma de fuego (mosquete, rifle, ametralladora)
	EXPLOSIVE,     ## Explosivo / fragmentacion (bomba, granada, misil)
	ENERGY,        ## Energia / plasma (rayo, laser, canon ionico)
	NONE           ## Sin arma definida (fuerza bruta sin tipo)
}

# --- Tipos de Armadura (Armor Types) — dbunitset.dat --------------------------
## Clases de armadura de unidades y edificios reconocidas por EE.
enum ArmorType {
	INFANTRY,    ## Infanteria ligera (sin armadura o armadura de tela/cuero)
	HEAVY,       ## Infanteria pesada (armadura de placas, blindaje)
	CAVALRY,     ## Caballeria (jinetes, lanceros a caballo)
	SIEGE_UNIT,  ## Maquinas de asedio (catapulta, ariete, canon)
	BUILDING,    ## Estructura civil o militar (madera / piedra / acero)
	NAVAL,       ## Unidad naval (barco de madera, acorazado)
	AIR,         ## Unidad aerea (avion, dron, helicoptero)
	NONE         ## Sin clase de armadura definida
}

# --- Matriz de Counters (dbweapontohit.dat) ------------------------------------
## Modificador multiplicativo de dano: WEAPON_TYPE -> ARMOR_TYPE -> factor.
## Base = 1.0, mayor = ventaja tactica, menor = desventaja.
##
## Derivado matematico del analisis de dbweapontohit.dat (EE1 original):
## - Shock vs Infantry   = 1.5  (espada aplasta infantes desprotegidos)
## - Arrow vs Heavy      = 1.5  (flechas explotan armaduras rigidas)
## - Pierce vs Cavalry   = 1.8  (picas contra caballos — contraataque historico)
## - Siege  vs Building  = 3.0  (asedio destruye estructuras)
## - Gunpowder vs Cavalry= 2.0  (fuego de mosquetes diezma caballos)
## - Explosive vs Building= 4.0 (bombas vuelan edificios)
## - Energy vs Air       = 3.0  (laser antiaereo)
const DAMAGE_MATRIX: Dictionary = {
	WeaponType.MELEE_SHOCK: {
		ArmorType.INFANTRY:   1.5,
		ArmorType.HEAVY:      0.8,
		ArmorType.CAVALRY:    0.9,
		ArmorType.SIEGE_UNIT: 0.7,
		ArmorType.BUILDING:   0.5,
		ArmorType.NAVAL:      0.6,
		ArmorType.AIR:        0.2,
		ArmorType.NONE:       1.0,
	},
	WeaponType.MELEE_PIERCE: {
		ArmorType.INFANTRY:   1.2,
		ArmorType.HEAVY:      1.0,
		ArmorType.CAVALRY:    1.8,
		ArmorType.SIEGE_UNIT: 0.8,
		ArmorType.BUILDING:   0.4,
		ArmorType.NAVAL:      0.5,
		ArmorType.AIR:        0.2,
		ArmorType.NONE:       1.0,
	},
	WeaponType.ARROW: {
		ArmorType.INFANTRY:   1.3,
		ArmorType.HEAVY:      1.5,
		ArmorType.CAVALRY:    1.3,
		ArmorType.SIEGE_UNIT: 0.6,
		ArmorType.BUILDING:   0.3,
		ArmorType.NAVAL:      0.4,
		ArmorType.AIR:        0.5,
		ArmorType.NONE:       1.0,
	},
	WeaponType.SIEGE: {
		ArmorType.INFANTRY:   0.8,
		ArmorType.HEAVY:      0.5,
		ArmorType.CAVALRY:    1.0,
		ArmorType.SIEGE_UNIT: 1.2,
		ArmorType.BUILDING:   3.0,
		ArmorType.NAVAL:      1.5,
		ArmorType.AIR:        0.1,
		ArmorType.NONE:       1.0,
	},
	WeaponType.GUNPOWDER: {
		ArmorType.INFANTRY:   1.2,
		ArmorType.HEAVY:      1.5,
		ArmorType.CAVALRY:    2.0,
		ArmorType.SIEGE_UNIT: 1.0,
		ArmorType.BUILDING:   0.8,
		ArmorType.NAVAL:      1.0,
		ArmorType.AIR:        0.6,
		ArmorType.NONE:       1.0,
	},
	WeaponType.EXPLOSIVE: {
		ArmorType.INFANTRY:   1.5,
		ArmorType.HEAVY:      1.2,
		ArmorType.CAVALRY:    1.5,
		ArmorType.SIEGE_UNIT: 2.5,
		ArmorType.BUILDING:   4.0,
		ArmorType.NAVAL:      2.0,
		ArmorType.AIR:        1.8,
		ArmorType.NONE:       1.0,
	},
	WeaponType.ENERGY: {
		ArmorType.INFANTRY:   1.2,
		ArmorType.HEAVY:      1.0,
		ArmorType.CAVALRY:    1.0,
		ArmorType.SIEGE_UNIT: 1.5,
		ArmorType.BUILDING:   2.0,
		ArmorType.NAVAL:      1.5,
		ArmorType.AIR:        3.0,
		ArmorType.NONE:       1.0,
	},
	WeaponType.NONE: {
		ArmorType.INFANTRY:   1.0,
		ArmorType.HEAVY:      1.0,
		ArmorType.CAVALRY:    1.0,
		ArmorType.SIEGE_UNIT: 1.0,
		ArmorType.BUILDING:   1.0,
		ArmorType.NAVAL:      1.0,
		ArmorType.AIR:        1.0,
		ArmorType.NONE:       1.0,
	},
}

# --- Parametros de Terreno Tactico (dbcliffterrain.dat) -----------------------
const ALTURA_BONO_UMBRAL_1: float  = 1.5
const ALTURA_BONO_UMBRAL_2: float  = 2.0
const ALTURA_PENALIZACION:  float  = 1.5
const FACTOR_BONO_ALTO:     float  = 0.25
const FACTOR_PENALIZACION:  float  = 0.15
const VISION_BONUS_METROS:  float  = 2.0

# --- Conversion de Strings a Enums --------------------------------------------
const WEAPON_STRING_MAP: Dictionary = {
	"melee_pierce": WeaponType.MELEE_PIERCE,
	"melee":       WeaponType.MELEE_SHOCK,
	"melee_shock": WeaponType.MELEE_SHOCK,
	"bludgeoning": WeaponType.MELEE_SHOCK,
	"piercing":    WeaponType.MELEE_PIERCE,
	"fist":        WeaponType.MELEE_SHOCK,
	"club":        WeaponType.MELEE_SHOCK,
	"sword":       WeaponType.MELEE_SHOCK,
	"axe":         WeaponType.MELEE_SHOCK,
	"spear":       WeaponType.MELEE_PIERCE,
	"pike":        WeaponType.MELEE_PIERCE,
	"lance":       WeaponType.MELEE_PIERCE,
	"bayonet":     WeaponType.MELEE_PIERCE,
	"arrow":      WeaponType.ARROW,
	"crossbow":   WeaponType.ARROW,
	"stone":      WeaponType.ARROW,
	"sling":      WeaponType.ARROW,
	"slingshot":  WeaponType.ARROW,
	"arrow/sling": WeaponType.ARROW,
	"ballista":   WeaponType.ARROW,
	"catapult":   WeaponType.SIEGE,
	"trebuchet":  WeaponType.SIEGE,
	"ram":        WeaponType.SIEGE,
	"cannon":     WeaponType.SIEGE,
	"howitzer":   WeaponType.SIEGE,
	"bullet":     WeaponType.GUNPOWDER,
	"musket":     WeaponType.GUNPOWDER,
	"rifle":      WeaponType.GUNPOWDER,
	"machinegun": WeaponType.GUNPOWDER,
	"bomb":       WeaponType.EXPLOSIVE,
	"grenade":    WeaponType.EXPLOSIVE,
	"rocket":     WeaponType.EXPLOSIVE,
	"missile":    WeaponType.EXPLOSIVE,
	"plasma":     WeaponType.ENERGY,
	"laser":      WeaponType.ENERGY,
	"ion":        WeaponType.ENERGY,
	"energy":     WeaponType.ENERGY,
}

const ARMOR_STRING_MAP: Dictionary = {
	"infantry_3d":       ArmorType.INFANTRY,
	"military_units":    ArmorType.INFANTRY,
	"villagers":         ArmorType.INFANTRY,
	"priests":           ArmorType.INFANTRY,
	"prophets":          ArmorType.INFANTRY,
	"heavy":             ArmorType.HEAVY,
	"knights":           ArmorType.HEAVY,
	"cavalry":           ArmorType.CAVALRY,
	"vehicles_3d":       ArmorType.CAVALRY,
	"siege_units":       ArmorType.SIEGE_UNIT,
	"buildings":         ArmorType.BUILDING,
	"buildings_3d":      ArmorType.BUILDING,
	"town_centers":      ArmorType.BUILDING,
	"military_buildings":ArmorType.BUILDING,
	"naval":             ArmorType.NAVAL,
	"ships":             ArmorType.NAVAL,
	"flying":            ArmorType.AIR,
	"drones":            ArmorType.AIR,
	"air_units":         ArmorType.AIR,
}

# --- API Publica --------------------------------------------------------------

## Calcula el dano final aplicando la matriz de counters y los modificadores de terreno.
static func calcular_dano(
	base_damage: float,
	weapon_str: String,
	attacker: Node3D,
	target: Node3D
) -> float:
	if base_damage <= 0.0:
		return 0.0

	var weapon_type: WeaponType = _resolver_weapon_type(weapon_str)
	var armor_type: ArmorType   = _resolver_armor_type(target)

	var weapon_row: Dictionary = DAMAGE_MATRIX.get(weapon_type, DAMAGE_MATRIX[WeaponType.NONE]) as Dictionary
	var counter_mult: float    = float(weapon_row.get(armor_type, 1.0))
	var damage_after_counter   := base_damage * counter_mult

	var height_mult: float = calcular_modificador_altura(attacker, target)
	var final_damage := damage_after_counter * height_mult

	# Multiplicador oficial dbunitset.dat Era 2: Maceman_Bronze (x1.35) contra fortificaciones de madera y empalizadas modulares
	if is_instance_valid(attacker) and is_instance_valid(target):
		var att_id: String = str(attacker.get("unit_id")).to_lower() if "unit_id" in attacker else ""
		var att_name: String = attacker.name.to_lower()
		var is_maceman: bool = (att_id == "maceman_bronze" or "maceman_bronze" in att_name or attacker.is_in_group("maceman_bronze") or (attacker.has_method("is_maceman_bronze") and attacker.call("is_maceman_bronze")))
		if is_maceman:
			var is_wood_fort: bool = (
				target.is_in_group("walls") or target.is_in_group("walls_3d") or
				target.is_in_group("palisades") or target.is_in_group("wooden_fortifications") or
				"wall" in target.name.to_lower() or "palisade" in target.name.to_lower() or
				"empalizada" in target.name.to_lower() or "muralla" in target.name.to_lower()
			)
			if is_wood_fort:
				final_damage *= 1.35

		# Multiplicador oficial Era 3: Ariete_Carnero_Era3 (x3.0) contra estructuras y murallas
		var is_ariete: bool = (att_id == "ariete_carnero_era3" or "ariete_carnero" in att_name or attacker.is_in_group("rams"))
		if is_ariete:
			var is_building_struct: bool = (
				target.is_in_group("buildings") or target.is_in_group("buildings_3d") or
				target.is_in_group("walls") or target.is_in_group("walls_3d") or
				"building" in target.name.to_lower() or "wall" in target.name.to_lower()
			)
			if is_building_struct:
				final_damage *= 3.0

		# Multiplicador oficial Era 4: Caballero_Pesado (x1.50) contra arqueros de infantería
		var is_caballero: bool = (att_id == "caballero_pesado" or "caballero_pesado" in att_name or attacker.is_in_group("heavy_knights"))
		if is_caballero:
			var is_archer_infantry: bool = (
				target.is_in_group("archers") or target.is_in_group("archer") or
				"archer" in target.name.to_lower() or "arquero" in target.name.to_lower() or
				"crossbowman" in target.name.to_lower() or "longbowman" in target.name.to_lower() or
				str(target.get("weapon_type")).to_lower() == "arrow" or
				str(target.get("impact_type")).to_lower() == "arrow"
			)
			if is_archer_infantry:
				final_damage *= 1.50

		# Multiplicador oficial Era 4: Pikeman_Era4 (x2.0) contra caballería y carros ecuestres
		var is_pikeman: bool = (att_id == "pikeman_era4" or "pikeman" in att_name or attacker.is_in_group("pikemen"))
		if is_pikeman:
			var is_cavalry_target: bool = (
				target.get("is_cavalry") == true or target.is_in_group("cavalry") or
				target.is_in_group("heavy_cavalry") or target.is_in_group("chariots") or
				"knight" in target.name.to_lower() or "caballero" in target.name.to_lower() or
				"cavalry" in target.name.to_lower()
			)
			if is_cavalry_target:
				final_damage *= 2.0

	# Mitigación táctica Testudo del Legionario Romano contra proyectiles
	if is_instance_valid(target) and target.has_method("aplicar_mitigacion_testudo"):
		final_damage = target.call("aplicar_mitigacion_testudo", final_damage, weapon_str)

	return maxf(1.0, final_damage)

## Calcula el modificador de dano por diferencia de altura (dbcliffterrain.dat).
static func calcular_modificador_altura(attacker: Node3D, target: Node3D) -> float:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return 1.0

	var pos_a := attacker.global_position if attacker.is_inside_tree() else attacker.position
	var pos_b := target.global_position if target.is_inside_tree() else target.position
	var dy: float = pos_a.y - pos_b.y

	if dy >= ALTURA_BONO_UMBRAL_1:
		return 1.0 + FACTOR_BONO_ALTO
	elif dy <= -ALTURA_PENALIZACION:
		return 1.0 - FACTOR_PENALIZACION
	else:
		return 1.0

## Calcula el radio de vision extra otorgado por elevacion.
static func calcular_bonus_vision_altura(unit: Node3D, reference_y: float = 0.0) -> float:
	if not is_instance_valid(unit):
		return 0.0
	var pos_u := unit.global_position if unit.is_inside_tree() else unit.position
	var dy: float = pos_u.y - reference_y
	if dy >= ALTURA_BONO_UMBRAL_2:
		return VISION_BONUS_METROS
	return 0.0

## Convierte un string de arma al WeaponType correspondiente.
static func _resolver_weapon_type(weapon_str: String) -> WeaponType:
	var key := weapon_str.to_lower().strip_edges()
	if WEAPON_STRING_MAP.has(key):
		return WEAPON_STRING_MAP[key] as WeaponType
	for k: String in WEAPON_STRING_MAP:
		if key.contains(k):
			return WEAPON_STRING_MAP[k] as WeaponType
	return WeaponType.NONE

## Detecta el ArmorType de un nodo objetivo inspeccionando sus grupos y propiedades.
static func _resolver_armor_type(target: Node) -> ArmorType:
	if not is_instance_valid(target):
		return ArmorType.NONE

	if "armor_type" in target:
		var at_val = target.get("armor_type")
		if at_val is int:
			return at_val as ArmorType

	if target.get("is_cavalry") == true or target.is_in_group("cavalry") or target.is_in_group("heavy_cavalry"):
		return ArmorType.CAVALRY

	for group_name: String in ARMOR_STRING_MAP:
		if target.is_in_group(group_name):
			return ARMOR_STRING_MAP[group_name] as ArmorType

	var node_name_lower := target.name.to_lower()
	if "building" in node_name_lower or "tower" in node_name_lower or "farm" in node_name_lower:
		return ArmorType.BUILDING
	if "drone" in node_name_lower or "plane" in node_name_lower or "heli" in node_name_lower:
		return ArmorType.AIR

	return ArmorType.NONE

## Retorna descripcion legible del counter para debug/HUD.
static func describir_counter(weapon_str: String, target: Node) -> String:
	var wt := _resolver_weapon_type(weapon_str)
	var at := _resolver_armor_type(target)
	var weapon_row: Dictionary = DAMAGE_MATRIX.get(wt, DAMAGE_MATRIX[WeaponType.NONE]) as Dictionary
	var mult: float = float(weapon_row.get(at, 1.0))
	return "WeaponType[%d] vs ArmorType[%d] -> x%.2f" % [wt, at, mult]
