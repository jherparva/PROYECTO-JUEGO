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
	"sword":       WeaponType.MELEE_SHOCK,
	"slashing":    WeaponType.MELEE_SHOCK,
	"club":        WeaponType.MELEE_SHOCK,
	"mace":        WeaponType.MELEE_SHOCK,
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
	"gun":        WeaponType.GUNPOWDER,
	"gunpowder":  WeaponType.GUNPOWDER,
	"gunpotwer":  WeaponType.GUNPOWDER,
	"gatling":    WeaponType.GUNPOWDER,
	"musket":     WeaponType.GUNPOWDER,
	"rifle":      WeaponType.GUNPOWDER,
	"sniper":     WeaponType.GUNPOWDER,
	"machinegun": WeaponType.GUNPOWDER,
	"bomb":       WeaponType.EXPLOSIVE,
	"grenade":    WeaponType.EXPLOSIVE,
	"rocket":     WeaponType.EXPLOSIVE,
	"missile":    WeaponType.EXPLOSIVE,
	"nuclear":    WeaponType.EXPLOSIVE,
	"icbm":       WeaponType.EXPLOSIVE,
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

		# Multiplicador oficial Era 5: Halberdier_Era5 (x1.65) contra caballería blindada
		var is_halberdier: bool = (att_id == "halberdier_era5" or "halberdier" in att_name or attacker.is_in_group("halberdiers"))
		if is_halberdier:
			var is_cavalry_target_h: bool = (
				target.get("is_cavalry") == true or target.is_in_group("cavalry") or
				target.is_in_group("heavy_cavalry") or target.is_in_group("chariots") or
				"knight" in target.name.to_lower() or "caballero" in target.name.to_lower()
			)
			if is_cavalry_target_h:
				final_damage *= 1.65

		# Multiplicador oficial Era 5: Conquistador_Era5 (x1.30) contra infantería ligera de choque
		var is_conquistador: bool = (att_id == "conquistador_era5" or "conquistador" in att_name or attacker.is_in_group("conquistadors"))
		if is_conquistador:
			var is_shock_infantry: bool = (
				target.is_in_group("infantry_3d") or target.is_in_group("military_units") or
				str(target.get("impact_type")).to_lower() == "melee_shock" or
				str(target.get("weapon_type")).to_lower() == "melee_shock" or
				"soldier" in target.name.to_lower() or "infantry" in target.name.to_lower()
			)
			if is_shock_infantry:
				final_damage *= 1.30

		# Multiplicador oficial Era 5: Canon_Culebrina_Era5 (x3.0) contra edificios y murallas
		var is_culebrina: bool = (att_id == "canon_culebrina_era5" or "culebrina" in att_name or attacker.is_in_group("cannons"))
		if is_culebrina:
			var is_building_target: bool = (
				target.is_in_group("buildings") or target.is_in_group("buildings_3d") or
				target.is_in_group("walls") or target.is_in_group("walls_3d") or
				"building" in target.name.to_lower() or "wall" in target.name.to_lower()
			)
			if is_building_target:
				final_damage *= 3.0

		# Penetración oficial Era 5: Mosquetero (reduce mitigaciones de armadura pesada en -25%)
		var is_mosquetero: bool = (att_id == "mosquetero_era5" or att_id == "mosquetero" or "mosquetero" in att_name or attacker.get("is_armor_piercing_gun") == true)
		if is_mosquetero and armor_type == ArmorType.HEAVY:
			final_damage *= 1.25

		# Multiplicador oficial Era 6: Hussar_Era6 (x1.40) contra unidades de rango de infantería desprotegidas
		var is_hussar: bool = (att_id == "hussar_era6" or "hussar" in att_name or attacker.is_in_group("hussars"))
		if is_hussar:
			var is_ranged_infantry: bool = (
				target.is_in_group("ranged_infantry") or target.is_in_group("archers") or
				target.is_in_group("fusileros") or "fusilero" in target.name.to_lower() or
				"mosquetero" in target.name.to_lower() or "crossbow" in target.name.to_lower() or
				"longbow" in target.name.to_lower() or "archer" in target.name.to_lower() or
				str(target.get("weapon_type")).to_lower() in ["gun", "arrow"]
			)
			if is_ranged_infantry:
				final_damage *= 1.40

		# Multiplicador oficial Era 6: SteamTank_Era6 (x2.5) contra estructuras y murallas
		var is_steamtank: bool = (att_id == "steamtank_era6" or "steamtank" in att_name or attacker.is_in_group("steamtanks"))
		if is_steamtank:
			var is_building_target_st: bool = (
				target.is_in_group("buildings") or target.is_in_group("buildings_3d") or
				target.is_in_group("walls") or target.is_in_group("walls_3d") or
				"building" in target.name.to_lower() or "wall" in target.name.to_lower()
			)
			if is_building_target_st:
				final_damage *= 2.5

		# Multiplicador oficial Era 8: GISoldier_Era8 (x1.25) contra infantería ligera de eras anteriores
		var is_gi: bool = (att_id == "gi_soldier_era8" or "gi_soldier" in att_name or attacker.is_in_group("gi_soldiers"))
		if is_gi:
			var is_past_infantry: bool = (
				(target.is_in_group("infantry_3d") or target.is_in_group("military_units")) and
				not target.is_in_group("gi_soldiers") and not "gi_soldier" in target.name.to_lower()
			)
			if is_past_infantry:
				final_damage *= 1.25

		# Multiplicador oficial Era 8: Sniper_Era8 (x3.0) contra civiles y sacerdotes
		var is_sniper: bool = (att_id == "sniper_era8" or "sniper" in att_name or attacker.is_in_group("snipers"))
		if is_sniper:
			var is_civil_or_priest: bool = (
				target.is_in_group("villagers") or target.is_in_group("priests") or
				target.is_in_group("prophets") or "villager" in target.name.to_lower() or
				"priest" in target.name.to_lower() or "aldeano" in target.name.to_lower() or
				"sacerdote" in target.name.to_lower()
			)
			if is_civil_or_priest:
				final_damage *= 3.0

		# Multiplicador oficial Era 8: Tanque_Sherman_T34 (x1.50) contra camiones e infantería mecanizada
		var is_sherman: bool = (att_id == "tanque_sherman_t34" or "sherman" in att_name or "t34" in att_name or attacker.is_in_group("shermans"))
		if is_sherman:
			var is_truck_or_mechanized: bool = (
				target.is_in_group("transports") or target.is_in_group("transports_3d") or
				target.is_in_group("camiones") or "camion" in target.name.to_lower() or
				"truck" in target.name.to_lower()
			)
			if is_truck_or_mechanized:
				final_damage *= 1.50

	# Mitigación táctica Testudo del Legionario Romano contra proyectiles
	if is_instance_valid(target) and target.has_method("aplicar_mitigacion_testudo"):
		final_damage = target.call("aplicar_mitigacion_testudo", final_damage, weapon_str)

	# Mitigación innata del Carro Blindado de DaVinci (-20% de daño físico recibido)
	if is_instance_valid(target) and target.has_method("aplicar_mitigacion_blindaje"):
		final_damage = target.call("aplicar_mitigacion_blindaje", final_damage)

	# Mitigación de Trinchera del Doughboy de Era 7 (-20% de daño balístico en reposo/Idle)
	if is_instance_valid(target) and target.has_method("aplicar_mitigacion_trinchera"):
		final_damage = target.call("aplicar_mitigacion_trinchera", final_damage, weapon_str)

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

	if target.get("is_cavalry") == true or target.get("is_vehicle") == true or target.is_in_group("cavalry") or target.is_in_group("heavy_cavalry"):
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
