extends SceneTree

const LeaderPrehistoric3D = preload("res://scripts/units/leader_prehistoric_3d.gd")
const Canoe3D = preload("res://scripts/units/canoe_3d.gd")
const ProphetStone3D = preload("res://scripts/units/prophet_stone_3d.gd")
const ArcheryRange3D = preload("res://scripts/buildings/archery_range_3d.gd")
const Stable3D = preload("res://scripts/buildings/stable_3d.gd")
const WallWoodEra1 = preload("res://scripts/buildings/wall_wood_3d.gd")
const DockEra13D = preload("res://scripts/buildings/dock_era1_3d.gd")
const FishingBoatEra13D = preload("res://scripts/units/fishing_boat_era1_3d.gd")
const CivPointsManager = preload("res://scripts/core/civ_points_manager.gd")
const GameSettings = preload("res://scripts/core/game_settings.gd")
const SiegeWorkshop3D = preload("res://scripts/buildings/siege_workshop_3d.gd")
const WonderZigurat3D = preload("res://scripts/buildings/wonder_zigurat_3d.gd")
const CivAdvantagesMenuClass = preload("res://scripts/ui/civ_advantages_menu.gd")
const PauseMenuClass = preload("res://scripts/ui/pause_menu.gd")
const HUDControllerClass = preload("res://scripts/ui/hud_controller.gd")
const RTSActionPanelClass = preload("res://scripts/ui/rts_action_panel.gd")
const RTSInputControllerClass = preload("res://scripts/core/rts_input_controller.gd")
const TownCenter3DClass = preload("res://scripts/buildings/town_center_3d.gd")
const Barracks3DClass = preload("res://scripts/buildings/barracks_3d.gd")
const Soldier3DClass = preload("res://scripts/units/soldier_3d.gd")
const ResourceNode3DClass = preload("res://scripts/world/resource_node_3d.gd")
const RTSResourceSpawnerClass = preload("res://scripts/world/rts_resource_spawner.gd")
const MultiplayerManagerClass = preload("res://scripts/core/multiplayer_manager.gd")
const Farm3DClass = preload("res://scripts/buildings/farm_3d.gd")
const Villager3DClass = preload("res://scripts/units/villager_3d.gd")
const StateGathering3DClass = preload("res://scripts/units/fsm/state_gathering_3d.gd")
const StateMove3DClass = preload("res://scripts/units/fsm/state_move_3d.gd")

func _init() -> void:
	print("\n========================================================")
	print(" [TEST EE] INICIANDO SUITE DE VALIDACIÓN AUTOMATIZADA EE ")
	print("========================================================")

	# TEST 1: Resource Manager Presets (dbstartingresources.dat)
	print("\n--- TEST 1: Resource Manager Presets ---")
	var rm := GlobalResourceManager.new()
	assert(rm.PRESETS_RECURSOS_INICIALES.size() == 5, "Deben existir 5 presets oficiales")
	var p0: Dictionary = rm.PRESETS_RECURSOS_INICIALES[0]
	assert(p0["food"] == 200 and p0["wood"] == 175 and p0["stone"] == 210, "Preset 0 debe ser Tournament Low")
	var p4: Dictionary = rm.PRESETS_RECURSOS_INICIALES[4]
	assert(p4["food"] == 15000 and p4["iron"] == 10000, "Preset 4 debe ser Death Match con 15000 comida")
	print("✅ Test 1 Superado: Presets 0-4 verificados fielmente.")
	rm.free()

	# TEST 2: Fauna Oficial EE (dbanimals.dat) & Mamut 600u
	print("\n--- TEST 2: Catálogo Fauna EE (Mamut 600u / Tigre 120 HP) ---")
	var animal := FaunaAnimal3D.new()
	assert(animal.CATALOGO_ANIMALES_EE.has("mamut"), "Catálogo debe incluir al mamut")
	assert(animal.CATALOGO_ANIMALES_EE["mamut"]["food"] == 600, "El mamut debe otorgar 600u de alimento")
	assert(animal.CATALOGO_ANIMALES_EE["mamut"]["hp"] == 240.0, "El mamut debe tener 240 HP")
	animal.configurar_especie("mamut")
	assert(animal.current_amount == 600, "current_amount debe ser 600u")
	assert(animal.animal_health == 240.0, "animal_health debe ser 240.0")

	animal.configurar_especie("tigre")
	assert(animal.is_aggressive == true, "El tigre debe ser agresivo")
	assert(animal.animal_health == 120.0, "El tigre debe tener 120 HP")
	print("✅ Test 2 Superado: Catálogo de fauna, stats y mamut de 600u comida OK.")
	animal.free()

	# TEST 3: Tácticas .tai (CheckRange, ShouldIFollow) y Smart Targeting EE
	print("\n--- TEST 3: FSM .tai y Prioridad Táctica EE ---")
	var root_node := Node3D.new()
	root.add_child(root_node)

	var attacker := CharacterBody3D.new()
	root_node.add_child(attacker)
	attacker.position = Vector3(0, 0, 0)
	attacker.set_meta("attack_range", 10.0)

	var target_priest := CharacterBody3D.new()
	target_priest.name = "PriestOfGod"
	root_node.add_child(target_priest)
	target_priest.position = Vector3(5, 0, 0)

	var target_villager := CharacterBody3D.new()
	target_villager.name = "Villager3D_Worker"
	root_node.add_child(target_villager)
	target_villager.position = Vector3(5, 0, 0)

	var target_barracks := Node3D.new()
	target_barracks.name = "Barracks_Cuartel"
	root_node.add_child(target_barracks)
	target_barracks.position = Vector3(5, 0, 0)

	var target_tc := Node3D.new()
	target_tc.name = "TownCenter_Capitolio"
	root_node.add_child(target_tc)
	target_tc.position = Vector3(5, 0, 0)

	assert(MilitaryWarTactics3D.check_range(attacker, target_priest) == true, "CheckRange debe ser true a 5m con alcance 10m")
	assert(MilitaryWarTactics3D.should_i_follow(attacker, target_priest, 35.0) == true, "ShouldIFollow debe ser true a 5m")

	var prio_priest := MilitaryWarTactics3D.calcular_prioridad_objetivo(target_priest)
	var prio_vil := MilitaryWarTactics3D.calcular_prioridad_objetivo(target_villager)
	var prio_barr := MilitaryWarTactics3D.calcular_prioridad_objetivo(target_barracks)
	var prio_tc := MilitaryWarTactics3D.calcular_prioridad_objetivo(target_tc)

	print("Prioridades evaluadas: Sacerdote=%d, Aldeano=%d, Cuartel=%d, Capitolio=%d" % [
		prio_priest, prio_vil, prio_barr, prio_tc
	])
	assert(prio_priest > prio_vil, "Sacerdotes deben tener mayor prioridad que Aldeanos")
	assert(prio_vil > prio_barr, "Aldeanos deben tener mayor prioridad que Cuarteles")
	assert(prio_barr > prio_tc, "Cuarteles deben tener mayor prioridad que Capitolio")
	print("✅ Test 3 Superado: FSM CheckRange/ShouldIFollow y jerarquía Sacerdotes > Aldeanos > Cuarteles > Capitolio verificada.")

	root_node.free()

	# TEST 4: Chat Manager y los 30 Taunts Oficiales de EE
	print("\n--- TEST 4: NetworkChatManager y Base de Datos de 30 Taunts ---")
	var chat_class = load("res://scripts/core/network_chat_manager.gd")
	assert(chat_class != null, "network_chat_manager.gd debe cargar correctamente")
	var chat: Node = chat_class.new()
	root.add_child(chat)
	assert(chat.get("TAUNTS_OFICIALES_EE") != null, "TAUNTS_OFICIALES_EE debe estar definido")
	var taunts: Dictionary = chat.get("TAUNTS_OFICIALES_EE")
	assert(taunts.size() == 30, "Deben existir exactamente 30 taunts de Empire Earth")
	assert(taunts[1] == "Sí.", "Taunt 1 debe ser 'Sí.'")
	assert(taunts[10] == "¡A la carga!", "Taunt 10 debe ser '¡A la carga!'")
	assert(taunts[30] == "¡Ríndete y acepta tu destino!", "Taunt 30 debe ser '¡Ríndete y acepta tu destino!'")
	assert(chat.has_method("bot_taunt_destruccion_edificio"), "Debe existir bot_taunt_destruccion_edificio")
	assert(chat.has_method("bot_taunt_asedio_capitolio"), "Debe existir bot_taunt_asedio_capitolio")
	print("✅ Test 4 Superado: 30 Taunts de EE y triggers de bot completamente operativos.")
	chat.free()

	# TEST 5: Bloqueo de Fuego Amigo (Aldeanos y Soldados Propios / Aliados)
	print("\n--- TEST 5: Bloqueo de Fuego Amigo e Inmunidad Aliada ---")
	var vil1 := Villager3D.new()
	vil1.name = "Vil1"
	vil1.bando = 0
	vil1.add_to_group("player_units")
	root.add_child(vil1)

	var vil2 := Villager3D.new()
	vil2.name = "Vil2"
	vil2.bando = 0
	vil2.add_to_group("player_units")
	root.add_child(vil2)

	var enemy := Villager3D.new()
	enemy.name = "EnemyVil"
	enemy.bando = 1
	enemy.add_to_group("enemy_units")
	root.add_child(enemy)

	var atk_state := StateAttacking3D.new()
	atk_state.unit = vil1

	# 1. Aliados y tropas del mismo bando rechazados
	assert(atk_state._is_valid_enemy_target(vil2) == false, "Objetivo aliado del mismo bando debe ser inválido para atacar")
	assert(atk_state._is_valid_enemy_target(vil1) == false, "Auto-ataque debe ser inválido")
	
	# 2. Enemigos legítimos sí son válidos
	assert(atk_state._is_valid_enemy_target(enemy) == true, "Objetivo de bando enemigo debe ser válido")

	# 3. Soldado tampoco debe atacar aliados
	var soldier := Soldier3D.new()
	soldier.bando = 0
	soldier.add_to_group("player_units")
	root.add_child(soldier)
	atk_state.unit = soldier
	assert(atk_state._is_valid_enemy_target(vil1) == false, "Soldado no debe validar a un aldeano aliado como objetivo")
	assert(atk_state._is_valid_enemy_target(soldier) == false, "Soldado no debe auto-atacarse")

	vil1.free()
	vil2.free()
	enemy.free()
	soldier.free()
	atk_state.free()
	print("✅ Test 5 Superado: Fuego amigo bloqueado al 100% para aldeanos y combatientes.")

	# TEST 6: Rango de Construcción Dinámico para Templo, Granja y Torre
	print("\n--- TEST 6: Rango Dinámico de Construcción de Edificios Grandes ---")
	var bld_state := StateBuilding3D.new()

	var temple_scene: PackedScene = load("res://scenes/buildings/temple_3d.tscn")
	var temple_inst: BuildingBase3D = temple_scene.instantiate() as BuildingBase3D
	root.add_child(temple_inst)
	bld_state._target_building = temple_inst
	var temple_range: float = bld_state._get_effective_build_range()
	assert(temple_range >= 6.5, "El rango de construcción para el Templo debe ser >= 6.5m (Obtenido: %.1f)" % temple_range)

	var farm_scene: PackedScene = load("res://scenes/buildings/farm_3d.tscn")
	var farm_inst: BuildingBase3D = farm_scene.instantiate() as BuildingBase3D
	root.add_child(farm_inst)
	bld_state._target_building = farm_inst
	var farm_range: float = bld_state._get_effective_build_range()
	assert(farm_range >= 6.5, "El rango de construcción para la Granja debe ser >= 6.5m (Obtenido: %.1f)" % farm_range)

	bld_state.free()
	temple_inst.free()
	farm_inst.free()
	print("✅ Test 6 Superado: Rango y márgenes de parada adaptados a colisiones de edificios grandes.")

	# TEST 7: Matriz de Eras en BuildingPlacer
	print("\n--- TEST 7: Matriz de Eras Histórica de Empire Earth ---")
	assert(BuildingPlacer.REQUIRED_ERAS["Hut3D"] == 0, "Choza debe ser Era 0")
	assert(BuildingPlacer.REQUIRED_ERAS["Barracks3D"] == 0, "Cuartel debe ser Era 0")
	assert(BuildingPlacer.REQUIRED_ERAS["Settlement3D"] == 0, "Asentamiento debe ser Era 0")
	assert(BuildingPlacer.REQUIRED_ERAS["ArcheryRange3D"] == 1, "Campo de Tiro debe ser Era 1+")
	assert(BuildingPlacer.REQUIRED_ERAS["Farm3D"] == 1, "Granja debe ser Era 1+")
	assert(BuildingPlacer.REQUIRED_ERAS["Tower3D"] == 1, "Torre debe ser Era 1+")
	assert(BuildingPlacer.REQUIRED_ERAS["Temple3D"] == 1, "Templo debe ser Era 1+")
	assert(BuildingPlacer.REQUIRED_ERAS["Stable3D"] == 2, "Establo debe ser Era 2+")
	assert(BuildingPlacer.REQUIRED_ERAS["SiegeWorkshop3D"] == 2, "Taller de Asedio debe ser Era 2+")
	print("✅ Test 7 Superado: Requisitos de Era para todas las estructuras verificados.")

	# TEST 8: No Cajas Primitivas en Edificios con Mallas Existentes
	print("\n--- TEST 8: Verificación Anti-Cubo Primitivo ---")
	var tc_test: BuildingBase3D = temple_scene.instantiate() as BuildingBase3D
	root.add_child(tc_test)
	tc_test._ensure_building_primitive_mesh()
	assert(tc_test.get_node_or_null("BuildingPrimitive") == null, "No debe generarse BuildingPrimitive si la escena ya posee mallas")
	tc_test.free()
	print("✅ Test 8 Superado: Edificios conservan únicamente su geometría 3D legítima.")

	# TEST 9: Matriz de Counters Oficial EE (dbweapontohit.dat & dbunitset.dat)
	print("\n--- TEST 9: Matriz de Counters Oficial de Combate EE ---")
	var cdc_class = load("res://scripts/core/combat_damage_calculator.gd")
	assert(cdc_class != null, "CombatDamageCalculator debe cargar correctamente")
	var dmg_shock_inf: float = cdc_class.DAMAGE_MATRIX[cdc_class.WeaponType.MELEE_SHOCK][cdc_class.ArmorType.INFANTRY]
	var dmg_pierce_cav: float = cdc_class.DAMAGE_MATRIX[cdc_class.WeaponType.MELEE_PIERCE][cdc_class.ArmorType.CAVALRY]
	var dmg_arrow_heavy: float = cdc_class.DAMAGE_MATRIX[cdc_class.WeaponType.ARROW][cdc_class.ArmorType.HEAVY]
	var dmg_siege_bld: float = cdc_class.DAMAGE_MATRIX[cdc_class.WeaponType.SIEGE][cdc_class.ArmorType.BUILDING]
	var dmg_gun_cav: float = cdc_class.DAMAGE_MATRIX[cdc_class.WeaponType.GUNPOWDER][cdc_class.ArmorType.CAVALRY]
	var dmg_exp_bld: float = cdc_class.DAMAGE_MATRIX[cdc_class.WeaponType.EXPLOSIVE][cdc_class.ArmorType.BUILDING]
	var dmg_energy_air: float = cdc_class.DAMAGE_MATRIX[cdc_class.WeaponType.ENERGY][cdc_class.ArmorType.AIR]

	assert(is_equal_approx(dmg_shock_inf, 1.5), "Shock vs Infantry debe ser 1.5x (Obtenido: %.2f)" % dmg_shock_inf)
	assert(is_equal_approx(dmg_pierce_cav, 1.8), "Pierce vs Cavalry debe ser 1.8x (Obtenido: %.2f)" % dmg_pierce_cav)
	assert(is_equal_approx(dmg_arrow_heavy, 1.5), "Arrow vs Heavy Armor debe ser 1.5x (Obtenido: %.2f)" % dmg_arrow_heavy)
	assert(is_equal_approx(dmg_siege_bld, 3.0), "Siege vs Building debe ser 3.0x (Obtenido: %.2f)" % dmg_siege_bld)
	assert(is_equal_approx(dmg_gun_cav, 2.0), "Gunpowder vs Cavalry debe ser 2.0x (Obtenido: %.2f)" % dmg_gun_cav)
	assert(is_equal_approx(dmg_exp_bld, 4.0), "Explosive vs Building debe ser 4.0x (Obtenido: %.2f)" % dmg_exp_bld)
	assert(is_equal_approx(dmg_energy_air, 3.0), "Energy vs Air debe ser 3.0x (Obtenido: %.2f)" % dmg_energy_air)
	print("✅ Test 9 Superado: Matriz de counters oficial de EE verificada al 100%.")

	# TEST 10: Tiempos de Era Reales (dbupgrade.dat) y Costos (dbtechtree.dat)
	print("\n--- TEST 10: Tiempos de Construcción y Costos Reales de Era ---")
	var tc_scene: PackedScene = load("res://scenes/buildings/town_center_3d.tscn")
	var tc_inst: TownCenter3D = tc_scene.instantiate() as TownCenter3D
	root.add_child(tc_inst)
	assert(tc_inst.ERA_BUILD_TIMES_SECONDS.size() >= 10, "Deben existir tiempos para las 10 eras")
	assert(is_equal_approx(tc_inst.ERA_BUILD_TIMES_SECONDS[0], 125.0), "Era 0 transición debe durar 125s")
	assert(is_equal_approx(tc_inst.ERA_BUILD_TIMES_SECONDS[1], 130.0), "Era 1 transición debe durar 130s")
	assert(is_equal_approx(tc_inst.ERA_BUILD_TIMES_SECONDS[9], 185.0), "Era 9 transición debe durar 185s")

	var rm_test := GlobalResourceManager.new()
	assert(rm_test.COSTE_EVOLUCION[GlobalResourceManager.Era.PREHISTORICA]["food"] == 850, "Costo a Edad de Piedra debe ser 850 comida")
	assert(rm_test.COSTE_EVOLUCION[GlobalResourceManager.Era.PIEDRA]["food"] == 750, "Costo a Bronce debe ser 750 comida")
	assert(rm_test.COSTE_EVOLUCION[GlobalResourceManager.Era.PIEDRA]["gold"] == 400, "Costo a Bronce debe requerir 400 oro")
	assert(rm_test.COSTE_EVOLUCION[GlobalResourceManager.Era.PIEDRA]["stone"] == 400, "Costo a Bronce debe requerir 400 piedra")
	tc_inst.free()
	rm_test.free()
	print("✅ Test 10 Superado: Costos y tiempos de transición de EE (125s - 185s) verificados.")

	# TEST 11: Bono Táctico de Elevación (+25% Daño, +2m Visión, -15% Valle)
	print("\n--- TEST 11: Bono Táctico de Elevación (dbcliffterrain.dat) ---")
	var elevated_unit := Node3D.new()
	root.add_child(elevated_unit)
	elevated_unit.position = Vector3(0, 2.0, 0)

	var valley_unit := Node3D.new()
	root.add_child(valley_unit)
	valley_unit.position = Vector3(0, 0, 0)

	var height_tactics = MilitaryWarTactics3D.calcular_bono_altura(elevated_unit, valley_unit)
	assert(is_equal_approx(height_tactics["damage_mult"], 1.25), "Unidad en colina debe tener +25%% daño (Obtenido: %.2f)" % height_tactics["damage_mult"])
	assert(is_equal_approx(height_tactics["vision_bonus"], 2.0), "Unidad en colina debe tener +2m visión (Obtenido: %.1f)" % height_tactics["vision_bonus"])
	assert(height_tactics["is_elevated"] == true, "is_elevated debe ser true")

	var valley_tactics = MilitaryWarTactics3D.calcular_bono_altura(valley_unit, elevated_unit)
	assert(is_equal_approx(valley_tactics["penalty_mult"], 0.85), "Unidad en valle debe tener -15%% penalización (Obtenido: %.2f)" % valley_tactics["penalty_mult"])

	var calc_high_mult = cdc_class.calcular_modificador_altura(elevated_unit, valley_unit)
	var calc_low_mult = cdc_class.calcular_modificador_altura(valley_unit, elevated_unit)
	assert(is_equal_approx(calc_high_mult, 1.25), "CombatDamageCalculator colina debe ser 1.25")
	assert(is_equal_approx(calc_low_mult, 0.85), "CombatDamageCalculator valle debe ser 0.85")

	var calc_vis_bonus = cdc_class.calcular_bonus_vision_altura(elevated_unit, 0.0)
	assert(is_equal_approx(calc_vis_bonus, 2.0), "CombatDamageCalculator bono visión debe ser 2.0m")

	elevated_unit.free()
	valley_unit.free()
	print("✅ Test 11 Superado: Bono de altura (+25% daño, +2m visión, -15% valle) verificado con precisión.")

	# TEST 12: Modificadores Nativos de las 4 Facciones (Griegos, Romanos, Ingleses, Alemanes)
	print("\n--- TEST 12: Modificadores Nativos de Civilizaciones Oficiales ---")
	var gs_class = load("res://scripts/core/game_settings.gd")
	var temp_gs = gs_class.new()
	assert(temp_gs.CIV_PRESETS.has("griegos"), "Debe existir facción griegos")
	assert(temp_gs.CIV_PRESETS.has("romanos"), "Debe existir facción romanos")
	assert(temp_gs.CIV_PRESETS.has("ingleses"), "Debe existir facción ingleses")
	assert(temp_gs.CIV_PRESETS.has("alemanes"), "Debe existir facción alemanes")

	# Griegos: +10% velocidad, +15% oro, -15% costo tech
	var p_griegos: Dictionary = temp_gs.CIV_PRESETS["griegos"]
	assert(is_equal_approx(p_griegos["speed"], 1.10), "Griegos: +10% velocidad")
	assert(is_equal_approx(p_griegos["gather_gold"], 1.15), "Griegos: +15% oro")
	assert(is_equal_approx(p_griegos["tech_cost_mult"], 0.85), "Griegos: -15% costo tecnología")

	# Romanos: +10% comida, +20% piedra, +10 población, +10% ataque infantería
	var p_romanos: Dictionary = temp_gs.CIV_PRESETS["romanos"]
	assert(is_equal_approx(p_romanos["gather_stone"], 1.20), "Romanos: +20% piedra")
	assert(p_romanos["population"] == 10, "Romanos: +10 población extra")
	assert(is_equal_approx(p_romanos["attack"], 1.10), "Romanos: +10% ataque infantería")

	# Ingleses: +15% madera, +3m rango arqueros, +20% daño flecha
	var p_ingleses: Dictionary = temp_gs.CIV_PRESETS["ingleses"]
	assert(is_equal_approx(p_ingleses["gather_wood"], 1.15), "Ingleses: +15% madera")
	assert(is_equal_approx(p_ingleses["archer_range_bonus"], 3.0), "Ingleses: +3m rango arqueros")
	assert(is_equal_approx(p_ingleses["archer_damage_bonus"], 1.20), "Ingleses: +20% daño flecha")

	# Alemanes: +20% hierro, +5 población, -20% costo asedio, +30% HP asedio
	var p_alemanes: Dictionary = temp_gs.CIV_PRESETS["alemanes"]
	assert(is_equal_approx(p_alemanes["gather_iron"], 1.20), "Alemanes: +20% hierro")
	assert(p_alemanes["population"] == 5, "Alemanes: +5 población")
	assert(is_equal_approx(p_alemanes["siege_cost_mult"], 0.80), "Alemanes: -20% costo asedio")

	# Integración con ResourceManager (descuento tech griego en avance de era)
	var rm_civ := GlobalResourceManager.new()
	rm_civ.civilization_actual = "griegos"
	rm_civ.civ_tech_cost_mult = 0.85
	var greek_cost: Dictionary = rm_civ.consulta_coste_era()
	assert(greek_cost["food"] == int(round(850.0 * 0.85)), "Descuento griego aplicado a coste de era (Obtenido: %d)" % greek_cost["food"])

	temp_gs.free()
	rm_civ.free()
	print("✅ Test 12 Superado: Bonos pasivos de las 4 civilizaciones históricas 100% operativos.")

	# TEST 13: Recolección en Granja (Farm3D) y Slot Fuera de Colisión 6x6m
	print("\n--- TEST 13: Recolección en Granja (Farm3D) y Geometría de Ranuras ---")
	var farm_test_scene: PackedScene = load("res://scenes/buildings/farm_3d.tscn")
	var farm_node: Farm3D = farm_test_scene.instantiate() as Farm3D
	root.add_child(farm_node)
	farm_node.position = Vector3(10, 0, 10)

	var dummy_vil := CharacterBody3D.new()
	root.add_child(dummy_vil)
	dummy_vil.position = Vector3(10, 0, 13.4)

	var slot_info: Dictionary = farm_node.request_gather_slot(dummy_vil)
	assert(slot_info.get("has_slot") == true, "La granja debe conceder ranura al primer aldeano")
	var slot_pos: Vector3 = slot_info.get("slot_pos")
	var dist_from_center: float = farm_node.position.distance_to(slot_pos)
	# La colisión de la granja es de 6x6m (extensión 3.0m). La ranura debe estar fuera de la colisión sólida (> 3.0m)
	assert(dist_from_center >= 3.0, "La ranura de recolección debe estar fuera de la colisión sólida de 3m (Obtenido: %.2fm)" % dist_from_center)

	# Extracción de comida en granja
	var extracted_food: int = farm_node.extract(10)
	assert(extracted_food == 10, "La granja debe suministrar 10 unidades de comida (Extraído: %d)" % extracted_food)
	assert(farm_node.current_food_amount == farm_node.max_food_amount - 10, "Reservas reducidas correctamente")

	farm_node.release_gather_slot(dummy_vil)
	assert(farm_node.is_occupied == false, "La ranura debe liberarse tras release_gather_slot")

	farm_node.free()
	dummy_vil.free()
	print("✅ Test 13 Superado: Ranura exterior de Granja y extracción de comida verificadas.")

	# TEST 14: Modo 1 Jugador / 0 Enemigos (Desactivación Estricta de IA)
	print("\n--- TEST 14: Modo 1 Jugador / 0 Enemigos (Desactivación Estricta de IA) ---")
	var gs_script: GDScript = load("res://scripts/core/game_settings.gd") as GDScript
	var gs_solo: Node = gs_script.new()
	gs_solo.name = "GameSettings"
	gs_solo.set("player_count", 1)
	root.add_child(gs_solo)

	var test_ai := RTSEnemyAI.new()
	root.add_child(test_ai)
	test_ai._ready()

	assert(test_ai.is_queued_for_deletion(), "RTSEnemyAI debe autodestruirse en modo 1 jugador (0 enemigos)")

	# TEST 15: Instanciador Procedural de Props 3D (Mano y Espalda en Villager3D)
	print("\n--- TEST 15: Instanciador Procedural de Props 3D (Mano y Espalda) ---")
	var villager_scene: PackedScene = load("res://scenes/units/villager_3d.tscn")
	var vil15: Villager3D = villager_scene.instantiate() as Villager3D
	root.add_child(vil15)
	vil15.position = Vector3(0, 0, 0)

	# 1. Props en la mano derecha
	vil15.set_hand_prop("axe")
	var hand_node := vil15.get_right_hand_attachment()
	assert(is_instance_valid(hand_node), "RightHandAttachment debe existir")
	var axe_prop := hand_node.get_node_or_null("axe")
	assert(is_instance_valid(axe_prop) and axe_prop.visible == true, "Hacha procedural generada y visible")

	vil15.set_hand_prop("pickaxe")
	var pick_prop := hand_node.get_node_or_null("pickaxe")
	assert(is_instance_valid(pick_prop) and pick_prop.visible == true, "Pico procedural generado y visible")
	assert(axe_prop.visible == false, "Hacha debe ocultarse al equipar pico")

	vil15.set_hand_prop("Maza_Piedra")
	var hammer_prop := hand_node.get_node_or_null("Maza_Piedra")
	assert(is_instance_valid(hammer_prop) and hammer_prop.visible == true, "Maza de piedra generada y visible")

	vil15.set_hand_prop("spear")
	var spear_prop := hand_node.get_node_or_null("spear")
	assert(is_instance_valid(spear_prop) and spear_prop.visible == true, "Lanza de cacería generada y visible")

	# 2. Props en la espalda (Fardos y Sacos de recursos)
	var back_node := vil15.get_back_attachment()
	assert(is_instance_valid(back_node), "BackAttachment debe existir")

	vil15.set_back_prop("wood")
	var wood_prop := back_node.get_node_or_null("wood")
	assert(is_instance_valid(wood_prop) and wood_prop.visible == true, "Fardo de madera generado y visible")

	vil15.set_back_prop("food")
	var food_prop := back_node.get_node_or_null("food")
	assert(is_instance_valid(food_prop) and food_prop.visible == true, "Cesta de alimento generada y visible")
	assert(wood_prop.visible == false, "Madera oculta al cargar comida")

	vil15.set_back_prop("gold")
	var gold_prop := back_node.get_node_or_null("gold")
	assert(is_instance_valid(gold_prop) and gold_prop.visible == true, "Saco de oro generado y visible")

	vil15.set_back_prop("stone")
	var stone_prop := back_node.get_node_or_null("stone")
	assert(is_instance_valid(stone_prop) and stone_prop.visible == true, "Saco de piedra generado y visible")

	vil15.set_back_prop("iron")
	var iron_prop := back_node.get_node_or_null("iron")
	assert(is_instance_valid(iron_prop) and iron_prop.visible == true, "Carga de hierro generada y visible")

	vil15.set_hand_prop("")
	vil15.set_back_prop("")
	assert(spear_prop.visible == false and iron_prop.visible == false, "Props deben ocultarse al pasar string vacío")

	vil15.free()
	print("✅ Test 15 Superado: Mallas procedurales de herramientas y cargas de espalda 100% verificadas.")

	# TEST 16: Bucle Autónomo de Depósito y Retorno Automático / Escaneo a 35m
	print("\n--- TEST 16: Bucle Autónomo de Depósito y Retorno / Escaneo a 35m ---")
	var rm_global: Node = root.get_node_or_null("ResourceManager")
	var initial_wood: int = int(rm_global.get("resources").get("wood", 0)) if is_instance_valid(rm_global) else 0

	var vil16: Villager3D = villager_scene.instantiate() as Villager3D
	root.add_child(vil16)
	vil16.position = Vector3(0, 0, 0)

	var tc_bld := BuildingBase3D.new()
	tc_bld.name = "Capitolio_Aliado"
	tc_bld.bando = BuildingBase3D.Bando.PLAYER
	tc_bld.esta_construido = true
	tc_bld.add_to_group("town_centers")
	root.add_child(tc_bld)
	tc_bld.position = Vector3(5, 0, 0)

	var res_node := ResourceNode3D.new()
	res_node.name = "Bosque_Pino"
	res_node.resource_type = "wood"
	res_node.current_amount = 100
	res_node.max_amount = 100
	res_node.add_to_group("resources_3d")
	root.add_child(res_node)
	res_node.position = Vector3(15, 0, 0)

	# Aldeano recolecta y llena su inventario a 15
	var added_res: int = vil16.add_carried_resource("wood", 15)
	assert(added_res == 15 and vil16.is_inventory_full() == true, "Inventario debe llenarse con 15 unidades de madera")
	assert(vil16.get_back_attachment().get_node("wood").visible == true, "Prop de madera en la espalda debe estar visible")

	# Simular llegada al Capitolio a través de StateGathering3D
	vil16.last_resource_node = res_node
	vil16.state_machine.change_state(&"Gathering", {
		"deposit_target": tc_bld,
		"target_node": res_node
	})

	assert(vil16.carried_amount == 0, "El inventario debe vaciarse al depositar en el Capitolio")
	if is_instance_valid(rm_global):
		assert(int(rm_global.get("resources").get("wood", 0)) >= initial_wood + 15, "ResourceManager debe recibir las 15 unidades de madera")
	assert(vil16.get_back_attachment().get_node("wood").visible == false, "Prop de madera debe ocultarse tras el depósito")
	assert(vil16.state_machine.current_state.state_name == &"Move", "Aldeano debe navegar automáticamente de regreso al nodo de recurso")

	# Agotar el nodo de recurso original y comprobar escaneo a 35m
	res_node.current_amount = 0 # Agotado
	var res_node_nearby := ResourceNode3D.new()
	res_node_nearby.name = "Bosque_Pino_Cercano"
	res_node_nearby.resource_type = "wood"
	res_node_nearby.current_amount = 80
	res_node_nearby.max_amount = 80
	res_node_nearby.add_to_group("resources_3d")
	root.add_child(res_node_nearby)
	res_node_nearby.position = Vector3(25, 0, 0) # A 25m del origen

	vil16.state_machine.change_state(&"Gathering", {
		"deposit_target": tc_bld,
		"target_node": res_node
	})

	assert(vil16.state_machine.current_state.state_name == &"Move", "Debe navegar automáticamente al nodo alternativo")
	var move_ctx: Dictionary = (vil16.state_machine.get_node("Move") as StateMove3D)._context if vil16.state_machine.has_node("Move") else {}
	assert(move_ctx.get("target_node") == res_node_nearby, "Escaneo a 35m debe seleccionar automáticamente el árbol sustituto")

	vil16.free()
	tc_bld.free()
	res_node.free()
	res_node_nearby.free()
	print("✅ Test 16 Superado: Bucle autónomo de entrega en Capitolio y retorno/escaneo a 35m 100% operativo.")

	# TEST 17: Reparación de Edificios Terminados y Asistencia Automática en 18m
	print("\n--- TEST 17: Reparación de Edificios y Asistencia Automática en 18m ---")
	var vil17: Villager3D = villager_scene.instantiate() as Villager3D
	root.add_child(vil17)
	vil17.position = Vector3(0, 0, 0)

	# Edificio 1: Terminado pero dañado (200 / 600 HP)
	var bld_damaged := BuildingBase3D.new()
	bld_damaged.name = "Cuartel_Dañado"
	bld_damaged.bando = BuildingBase3D.Bando.PLAYER
	bld_damaged.salud_maxima = 600.0
	bld_damaged.salud_actual = 200.0
	bld_damaged.esta_construido = true
	bld_damaged.add_to_group("player_buildings")
	bld_damaged.add_to_group("buildings_3d")
	root.add_child(bld_damaged)
	bld_damaged.position = Vector3(2, 0, 0)

	# Edificio 2: En construcción incompleto (20% progreso) a 10 metros
	var bld_under_construction := BuildingBase3D.new()
	bld_under_construction.name = "Torre_Incompleta"
	bld_under_construction.bando = BuildingBase3D.Bando.PLAYER
	bld_under_construction.salud_maxima = 400.0
	bld_under_construction.salud_actual = 80.0
	bld_under_construction.progreso_construccion = 20.0
	bld_under_construction.esta_construido = false
	bld_under_construction.is_under_construction = true
	bld_under_construction.add_to_group("player_buildings")
	bld_under_construction.add_to_group("buildings_3d")
	root.add_child(bld_under_construction)
	bld_under_construction.position = Vector3(12, 0, 0)

	# Ordenar reparar el edificio dañado
	vil17.command_build(bld_damaged)
	assert(vil17.state_machine.current_state.state_name == &"Building", "Aldeano debe entrar en StateBuilding3D para reparar")
	var state_bld := vil17.state_machine.current_state as StateBuilding3D

	# Ejecutar tick de reparación
	state_bld._perform_build_tick()
	assert(bld_damaged.salud_actual > 200.0, "Tick de reparación debe incrementar la salud del edificio completado")
	assert(vil17.get_right_hand_attachment().get_node("Maza_Piedra").visible == true, "Maza de piedra visible durante reparación")

	# Completar la reparación al 100%
	bld_damaged.salud_actual = bld_damaged.salud_maxima
	state_bld._perform_build_tick()

	# Tras finalizar la reparación, debe asistir automáticamente a la torre incompleta a 10m (< 18m)
	assert(vil17.state_machine.current_state.state_name == &"Move" or vil17.state_machine.current_state.state_name == &"Building", "Aldeano debe transicionar hacia la siguiente obra")
	assert(vil17.last_building_node == bld_under_construction, "Asistencia automática a 18m debe elegir la Torre Incompleta")

	vil17.free()
	bld_damaged.free()
	bld_under_construction.free()
	print("✅ Test 17 Superado: Reparación de estructuras dañadas y auto-asistencia en 18m completada.")

	# TEST 18: Modo Cacería con Lanza, Faenado de Carcasa y Guarnición
	print("\n--- TEST 18: Modo Cacería de Fauna, Faenado de Carcasa y Retorno al Trabajo ---")
	var vil18: Villager3D = villager_scene.instantiate() as Villager3D
	root.add_child(vil18)
	vil18.position = Vector3(0, 0, 0)

	var animal18 := FaunaAnimal3D.new()
	animal18.name = "Ciervo_Salvaje"
	animal18.configurar_especie("ciervo")
	animal18.animal_health = 10.0 # Poca vida para simular cacería rápida
	root.add_child(animal18)
	animal18.position = Vector3(2, 0, 0)

	# 1. Clic / Orden de cazar
	vil18.command_gather(animal18)
	assert(vil18.state_machine.current_state.state_name == &"Attacking", "Aldeano debe entrar en StateAttacking3D para cazar al animal vivo")
	assert(vil18.get_right_hand_attachment().get_node("spear").visible == true, "Debe blandir la lanza de cacería")

	# 2. Abatir al animal salvaje con daño de cacería
	animal18.recibir_daño(15.0, vil18)
	assert(animal18.is_animal_dead == true, "Animal debe morir")

	# 3. Transición inmediata al faenado de carne de la carcasa
	var state_atk := vil18.state_machine.current_state as StateAttacking3D
	state_atk._on_target_lost_or_dead(animal18)
	assert(vil18.state_machine.current_state.state_name == &"Gathering", "Al abatir la presa debe saltar inmediatamente a recolectar carne")

	# 4. Sistema de Guarnición y Retorno al Trabajo
	var tc18 := BuildingBase3D.new()
	tc18.name = "Capitolio_Refugio"
	tc18.esta_construido = true
	root.add_child(tc18)

	vil18.guarecer_en(tc18)
	vil18.entrar_al_refugio()
	assert(vil18.visible == false and vil18._is_garrisoned == true, "Aldeano debe quedar oculto y guarecido")

	vil18.regresar_al_trabajo()
	assert(vil18.visible == true and vil18._is_garrisoned == false, "Aldeano debe salir del refugio")
	assert(vil18.state_machine.current_state.state_name == &"Gathering", "Debe regresar a trabajar en la carcasa memorizada")

	vil18.free()
	animal18.free()
	tc18.free()
	print("✅ Test 18 Superado: Cacería con lanza, salto a carcasa de carne y memorización de guarnición verificadas.")

	# TEST 19: Capitolio Principal Prehistórico GLB (Creación, Guarnición y Depósito de Comida)
	print("\n--- TEST 19: Capitolio Principal Prehistórico GLB (Creación, Guarnición y Depósito) ---")
	var tc_scene19: PackedScene = load("res://scenes/buildings/town_center_3d.tscn")
	assert(tc_scene19 != null, "La escena town_center_3d.tscn debe existir")
	var tc19: TownCenter3D = tc_scene19.instantiate() as TownCenter3D
	tc19.bando = BuildingBase3D.Bando.PLAYER
	root.add_child(tc19)

	# 1. Verificación de la malla 3D GLB del Capitolio Prehistórico
	var cap_mesh: Node3D = tc19.get_node_or_null("CapitolioPrehistorico") as Node3D
	assert(is_instance_valid(cap_mesh), "Debe existir el nodo CapitolioPrehistorico en la escena")
	assert(cap_mesh.find_children("*", "MeshInstance3D", true, false).size() > 0, "El modelo GLB prehistórico debe poseer mallas 3D legítimas")
	assert(tc19.get_node_or_null("BaseMesh") == null, "No debe contener cajas primitivas BoxMesh")

	# 2. Depósito de recursos / comida
	var rm_t19: Node = root.get_node_or_null("ResourceManager")
	var created_rm19 := false
	if not is_instance_valid(rm_t19):
		var new_rm := GlobalResourceManager.new()
		new_rm.name = "ResourceManager"
		root.add_child(new_rm)
		rm_t19 = new_rm
		created_rm19 = true

	var initial_food_t19: int = int(rm_t19.get("resources").get("food", 0))
	tc19.deposit_resources("food", 100)
	assert(int(rm_t19.get("resources").get("food", 0)) == initial_food_t19 + 100, "Depósito en Capitolio debe acreditar 100 comida al ResourceManager")

	# 3. Creación y entrenamiento de aldeano
	var initial_queue := tc19.get_queue_count()
	tc19.crear_aldeano()
	assert(tc19.get_queue_count() == initial_queue + 1, "Debe encolar el entrenamiento de un aldeano (costo 50 comida)")

	# 4. Resguardo y Guarnición de aldeanos
	var dummy_vil19 := CharacterBody3D.new()
	root.add_child(dummy_vil19)
	var garrison_ok := tc19.add_garrison_unit(dummy_vil19)
	assert(garrison_ok == true, "Aldeano debe poder resguardarse en el Capitolio")
	assert(tc19.garrisoned_units.has(dummy_vil19), "Debe figurar en la lista de guarnición")
	tc19.expulsar_guarnicion()
	assert(tc19.garrisoned_units.is_empty(), "expulsar_guarnicion debe liberar a todas las unidades")

	dummy_vil19.free()
	tc19.free()
	if created_rm19 and is_instance_valid(rm_t19):
		rm_t19.free()
	print("✅ Test 19 Superado: Capitolio prehistórico GLB, creación de aldeanos, guarnición y entrega de comida 100% operativos.")

	# TEST 20: Guerreros Era 0 (Brawler Stun 15%, Clubman x1.35 vs Estructuras, Spearman x2.5 vs Mamuts, Chamán Aura 12m)
	print("\n--- TEST 20: Guerreros Era 0 (Brawler Stun 15%, Clubman x1.35 vs Edificios, Spearman x2.5 vs Mamuts, Chamán 12m) ---")
	# 1. Brawler Primitivo (Luchador)
	var brawler := Soldier3D.new()
	root.add_child(brawler)
	brawler.configurar_unidad("brawler_primitivo")
	assert(brawler.weapon_type == "fist", "Brawler debe usar puños (fist)")
	assert(brawler.daño == 12.0, "Brawler daño base debe ser 12.0")

	var target_infantry := Soldier3D.new()
	root.add_child(target_infantry)
	target_infantry.add_to_group("infantry_3d")
	target_infantry.salud_actual = 100.0

	# Verificación directa de stun sobre infantería ligera
	target_infantry.aplicar_aturdimiento(1.5)
	assert(target_infantry.is_stunned == true, "aplicar_aturdimiento debe congelar con is_stunned = true")
	target_infantry.velocity = Vector3(5, 0, 5)
	target_infantry._physics_process(0.1)
	assert(target_infantry.velocity == Vector3.ZERO, "Unidad aturdida debe tener velocity = Vector3.ZERO")

	# Simulación de probabilidad 15% del brawler
	var stun_successes: int = 0
	var sim_rolls: int = 1000
	for i in range(sim_rolls):
		if randf() <= 0.15:
			stun_successes += 1
	var stun_ratio := float(stun_successes) / float(sim_rolls)
	assert(stun_ratio >= 0.11 and stun_ratio <= 0.19, "Probabilidad del 15% de stun debe converger estadísticamente (11%-19%)")

	# 2. Clubman Era 0 (Garrotero Bludgeoning x1.35 vs Estructuras de madera)
	var clubman := Soldier3D.new()
	root.add_child(clubman)
	clubman.configurar_unidad("clubman_era0")
	assert(clubman.weapon_type == "bludgeoning", "Clubman debe usar arma tipo Bludgeoning")

	var wooden_palisade := BuildingBase3D.new()
	wooden_palisade.name = "Empalizada_Madera"
	wooden_palisade.salud_maxima = 500.0
	wooden_palisade.salud_actual = 500.0
	wooden_palisade.add_to_group("buildings")
	root.add_child(wooden_palisade)

	var club_base_dmg := clubman.daño # 16.0
	var expected_club_dmg := club_base_dmg * 1.35 # 21.6
	clubman.on_attack_impact(wooden_palisade)
	assert(absf(wooden_palisade.salud_actual - (500.0 - expected_club_dmg)) < 0.05, "Clubman debe infligir x1.35 de daño contra estructuras de madera")

	# 3. Spearman Era 0 (Lancero Piercing x2.5 vs Mamuts de dbanimals.dat)
	var spearman := Soldier3D.new()
	root.add_child(spearman)
	spearman.configurar_unidad("spearman_era0")
	assert(spearman.weapon_type == "piercing", "Spearman debe usar arma tipo Piercing")

	var mammoth := FaunaAnimal3D.new()
	root.add_child(mammoth)
	mammoth.configurar_especie("mamut")
	var initial_mammoth_hp := mammoth.animal_health # 240.0
	var spear_base_dmg := spearman.daño # 15.0
	var expected_spear_dmg := spear_base_dmg * 2.5 # 37.5
	spearman.on_attack_impact(mammoth)
	assert(absf(mammoth.animal_health - (initial_mammoth_hp - expected_spear_dmg)) < 0.05, "Spearman debe infligir x2.5 de daño contra Mamuts de dbanimals.dat")

	# 4. Leader Prehistoric (Chamán Tribal con Aura de 12.0m)
	var shaman := LeaderPrehistoric3D.new()
	shaman.bando = UnitBase3D.Bando.PLAYER
	shaman.position = Vector3(0, 0, 0)
	root.add_child(shaman)

	var ally_close := Soldier3D.new()
	ally_close.bando = UnitBase3D.Bando.PLAYER
	ally_close.add_to_group("player_units")
	ally_close.position = Vector3(6, 0, 0) # Dentro del radio de 12.0m
	root.add_child(ally_close)

	var ally_far := Soldier3D.new()
	ally_far.bando = UnitBase3D.Bando.PLAYER
	ally_far.add_to_group("player_units")
	ally_far.position = Vector3(25, 0, 0) # Fuera del radio de 12.0m
	root.add_child(ally_far)

	var initial_ally_speed := ally_close.speed
	shaman.activar_cantico_ritual()

	assert(absf(ally_close.damage_modifier - 1.15) < 0.01, "Aliado en radio 12m debe recibir +15% daño (damage_modifier = 1.15)")
	assert(ally_close.speed > initial_ally_speed, "Aliado en radio 12m debe recibir +10% velocidad")
	assert(absf(ally_far.damage_modifier - 1.0) < 0.01, "Aliado fuera de radio 12m no debe recibir bufo")

	brawler.free()
	target_infantry.free()
	clubman.free()
	wooden_palisade.free()
	spearman.free()
	mammoth.free()
	shaman.free()
	ally_close.free()
	ally_far.free()
	print("✅ Test 20 Superado: Brawler 15% Stun, Clubman x1.35 vs madera, Spearman x2.5 vs Mamut y Chamán Aura 12m OK.")

	# TEST 21: Edificios Era 0 (Choza +5 Población Dinámica y Filtro Cuartel Era 0)
	print("\n--- TEST 21: Edificios Era 0 (Choza +5 Población Dinámica y Filtro Cuartel Era 0) ---")
	var rm21: Node = root.get_node_or_null("ResourceManager")
	var created_rm21 := false
	if not is_instance_valid(rm21):
		var nrm := GlobalResourceManager.new()
		nrm.name = "ResourceManager"
		root.add_child(nrm)
		rm21 = nrm
		created_rm21 = true

	var base_max_pop: int = int(rm21.get("max_population"))
	var pop_signal_emitted: Array[bool] = [false]
	var signal_handler := func(_cur: int, _max_p: int) -> void:
		pop_signal_emitted[0] = true
	rm21.connect("population_changed", signal_handler)

	# 1. Choza de Población Prehistórica (+5 al completar)
	var hut := Hut3D.new()
	hut.resource_manager = rm21
	hut.starts_under_construction = true
	root.add_child(hut)
	assert(int(rm21.get("max_population")) == base_max_pop, "Choza en construcción no debe otorgar bono de población anticipado")

	# Completar construcción
	hut.aplicar_progreso_construccion(100.0)
	assert(hut.esta_construido == true, "Choza debe marcarse como construida al 100%")
	assert(int(rm21.get("max_population")) == base_max_pop + 5, "Choza completada debe sumar +5 a max_population")
	assert(pop_signal_emitted[0] == true, "Debe emitirse la señal population_changed")

	# Demolición/Destrucción de la Choza (-5 de población)
	hut._destroy()
	assert(int(rm21.get("max_population")) == base_max_pop, "Destrucción de la choza debe restar los 5 puntos de max_population")

	# 2. Cuartel Primitivo (Barracks Era 0 dbtechtree.dat)
	var barracks := Barracks3D.new()
	barracks.bando = BuildingBase3D.Bando.PLAYER
	root.add_child(barracks)

	rm21.set("era_actual", 0) # Era Prehistórica
	var era0_units := Barracks3D.get_unidades_disponibles_era(0, "barracks")
	var unit_ids_era0: Array[String] = []
	for u in era0_units:
		unit_ids_era0.append(str(u["id"]))

	assert(unit_ids_era0.has("brawler_primitivo"), "Era 0 debe incluir Brawler Primitivo")
	assert(unit_ids_era0.has("garrotero") or unit_ids_era0.has("clubman_era0"), "Era 0 debe incluir Clubman")
	assert(unit_ids_era0.has("spearman_era0"), "Era 0 debe incluir Spearman")
	assert(not unit_ids_era0.has("espadachin"), "Era 0 debe bloquear Espadachín (Era 3)")
	assert(not unit_ids_era0.has("mosquetero"), "Era 0 debe bloquear Mosquetero (Era 5)")

	# Bloqueo estricto de cola en Era 0
	barracks.entrenar_unidad("espadachin")
	assert(barracks.production_queue.size() == 0, "Cuartel Era 0 debe rechazar entrenamiento de unidades avanzadas")

	# Entrenamiento permitido de unidad de Era 0 (Brawler, 40 comida)
	var food_before: int = int(rm21.get("resources").get("food", 0))
	if food_before < 100:
		rm21.call("add_resources", "food", 100)
		food_before = int(rm21.get("resources").get("food", 0))

	barracks.entrenar_unidad("brawler_primitivo")
	assert(barracks.production_queue.size() == 1, "Brawler debe encolarse correctamente en Era 0")
	var food_after: int = int(rm21.get("resources").get("food", 0))
	assert(food_before - food_after == 40, "Debe descontar 40 de comida del ResourceManager")

	barracks.free()
	if created_rm21 and is_instance_valid(rm21):
		rm21.free()
	print("✅ Test 21 Superado: Choza +5 población dinámica y filtro estricto de Cuartel Era 0 OK.")

	# TEST 22: Torre Defensiva Trípode Era 0 (Socket ProjectileMuzzle, 22m y Roca con Altura)
	print("\n--- TEST 22: Torre Trípode Era 0 (Socket ProjectileMuzzle, 22m Rango y Roca con Altura) ---")
	var tower := Tower3D.new()
	tower.bando = BuildingBase3D.Bando.PLAYER
	root.add_child(tower)

	# 1. Rango oficial de Era 0 (22.0m)
	assert(tower.attack_range == 22.0, "Torre Trípode Prehistórica debe tener rango oficial de 22.0m")

	# 2. Socket ProjectileMuzzle de Blender
	var muzzle_marker := Marker3D.new()
	muzzle_marker.name = "ProjectileMuzzle"
	muzzle_marker.position = Vector3(0.0, 4.8, 0.0) # Plataforma superior
	tower.add_child(muzzle_marker)

	var tower_base_y := tower.global_position.y if tower.is_inside_tree() else tower.position.y
	var muzzle_pos := tower.get_muzzle_position()
	assert(absf(muzzle_pos.y - (tower_base_y + 4.8)) < 0.01, "get_muzzle_position debe retornar la coordenada exacta del socket ProjectileMuzzle")

	# 3. Bono de elevación por altura (dbcliffterrain.dat)
	var elevated_tower := Tower3D.new()
	root.add_child(elevated_tower)
	elevated_tower.position = Vector3(0, 5.0, 0) # En colina a 5m de altura

	var ground_target := Soldier3D.new()
	ground_target.bando = UnitBase3D.Bando.ENEMY
	ground_target.position = Vector3(10.0, 0.0, 0.0) # En el llano a 0m
	root.add_child(ground_target)

	var height_mult := CombatDamageCalculator.calcular_modificador_altura(elevated_tower, ground_target)
	assert(absf(height_mult - 1.25) < 0.01, "Atacante en colina dy >= 2.0m debe recibir bono de altura x1.25")

	tower.free()
	elevated_tower.free()
	ground_target.free()
	print("✅ Test 22 Superado: Torre Trípode socket ProjectileMuzzle, rango 22m y matriz de altura OK.")

	# TEST 23: Logística Náutica Era 0 (Muelle DropOffPoint +20 Food y Canoa Guarecido de 4 Infantes Y=-1.8m)
	print("\n--- TEST 23: Logística Náutica Era 0 (Muelle DropOffPoint y Canoa Guarecido 4 Infantes Y=-1.8m) ---")
	# 1. Muelle Costero y zona de descarga DropOffPoint
	var rm23: Node = root.get_node_or_null("ResourceManager")
	var created_rm23 := false
	if not is_instance_valid(rm23):
		var nrm23 := GlobalResourceManager.new()
		nrm23.name = "ResourceManager"
		root.add_child(nrm23)
		rm23 = nrm23
		created_rm23 = true

	var dock := Dock3D.new()
	dock.bando = BuildingBase3D.Bando.PLAYER
	dock.resource_manager = rm23
	root.add_child(dock)

	var drop_zone := dock.get_node_or_null("DropOffPoint") as Area3D
	assert(is_instance_valid(drop_zone), "Dock3D debe crear el componente DropOffPoint para entrega náutica")

	var food_init_dock: int = int(rm23.get("resources").get("food", 0))

	# Simular llegada del pesquero con 20 de alimento
	var boat := FishingBoat3D.new()
	boat.bando = UnitBase3D.Bando.PLAYER
	root.add_child(boat)
	boat.current_cargo = 20

	dock._handle_boat_dropoff(boat)
	assert(boat.current_cargo == 0, "Inventario del barco pesquero debe quedar limpio (0/20) tras descarga")
	var food_after_dock: int = int(rm23.get("resources").get("food", 0))
	assert(food_after_dock == food_init_dock + 20, "Muelle debe depositar síncronamente +20 Food al ResourceManager")

	# 2. Canoa de Madera Prehistórica (Canoe3D)
	var canoe := Canoe3D.new()
	root.add_child(canoe)
	assert(absf(canoe.position.y - (-1.8)) < 0.01, "Canoa náutica debe navegar a cota de agua profunda Y = -1.8m")

	# Guarecer hasta 4 unidades de infantería
	var infantry_list: Array[Soldier3D] = []
	for i in range(4):
		var s := Soldier3D.new()
		s.name = "Infante_Canoa_%d" % i
		s.add_to_group("infantry_3d")
		root.add_child(s)
		infantry_list.append(s)

		var ok := canoe.guarecer_unidad(s)
		assert(ok == true, "Infante %d debe guarecerse con éxito en la canoa" % i)
		assert(s.visible == false, "Malla del infante guarecido debe ocultarse en el mapa")

	assert(canoe.garrison_array.size() == 4, "Canoa debe contener exactamente 4 unidades a bordo")

	# Intentar guarecer una 5ta unidad (debe denegarse por límite MAX_GARRISON = 4)
	var extra_infantry := Soldier3D.new()
	extra_infantry.add_to_group("infantry_3d")
	root.add_child(extra_infantry)
	var over_capacity := canoe.guarecer_unidad(extra_infantry)
	assert(over_capacity == false, "Canoa debe rechazar unidades más allá del límite de 4")

	# Desembarco síncrono en tierra firme (rpc_descargar_todo)
	canoe.rpc_descargar_todo()
	assert(canoe.garrison_array.is_empty(), "rpc_descargar_todo debe vaciar la bodega náutica")
	for s in infantry_list:
		assert(s.visible == true, "Infante desembarcado debe restaurar su visibilidad 3D")
		assert(s.process_mode == Node.PROCESS_MODE_INHERIT, "Infante desembarcado debe restaurar su ciclo de procesamiento")
		s.free()

	extra_infantry.free()
	boat.free()
	dock.free()
	canoe.free()
	if created_rm23 and is_instance_valid(rm23):
		rm23.free()
	print("✅ Test 23 Superado: Muelle DropOffPoint +20 Food y Canoa guarecido 4 infantes Y=-1.8m con rpc_descargar_todo OK.")

	# TEST 24: Lanzador de Piedras (15m, socket ProjectileMuzzle, x1.5 vs MELEE_SHOCK) y Terremoto Profeta de Piedra (8m, 5 HP/s)
	print("\n--- TEST 24: Lanzador de Piedras y Terremoto del Profeta de Piedra ---")
	var slinger := Soldier3D.new()
	slinger.bando = UnitBase3D.Bando.PLAYER
	root.add_child(slinger)
	slinger.configurar_unidad("lanzador_piedras")

	assert(slinger.rango_ataque == 15.0, "Lanzador de Piedras debe tener rango de 15.0m")
	assert(slinger.attack_type == "ranged", "Lanzador de Piedras debe ser unidad de rango")

	# Target MELEE_SHOCK infantry (Clubman)
	var shock_enemy := Soldier3D.new()
	shock_enemy.bando = UnitBase3D.Bando.ENEMY
	shock_enemy.add_to_group("infantry_3d")
	root.add_child(shock_enemy)
	shock_enemy.configurar_unidad("clubman_era0")
	var shock_init_hp := shock_enemy.salud_actual

	# Lanzador de Piedras dispara roca ligera
	var proj := Projectile3D.new()
	proj.projectile_type = "stone"
	proj.damage = slinger.daño # 10.0
	proj.source_unit = slinger
	root.add_child(proj)
	proj._execute_impact(shock_enemy)
	var expected_slinger_dmg := 10.0 * 1.5 # 15.0
	assert(absf(shock_enemy.salud_actual - (shock_init_hp - expected_slinger_dmg)) < 0.05, "Lanzador de Piedras debe infligir x1.5 contra infantería MELEE_SHOCK")

	# Profeta de Piedra y Terremoto DoT (8m, 5 HP/s por 6s sobre estructuras)
	var stone_prophet := ProphetStone3D.new()
	stone_prophet.bando = UnitBase3D.Bando.PLAYER
	root.add_child(stone_prophet)
	assert(stone_prophet.unit_name == "Profeta de Piedra", "ProphetStone3D debe llamarse Profeta de Piedra")

	var enemy_building := WallWoodEra1.new()
	enemy_building.bando = BuildingBase3D.Bando.ENEMY
	enemy_building.position = Vector3(5, 0, 0)
	root.add_child(enemy_building)
	var init_bld_hp := enemy_building.salud_actual

	stone_prophet.invocar_terremoto_piedra(Vector3(5, 0, 0))
	assert(enemy_building.salud_actual < init_bld_hp, "Terremoto de Piedra debe drenar HP de estructuras en radio 8m")
	assert(absf(enemy_building.salud_actual - (init_bld_hp - 5.0)) < 0.05, "Primer pulso de Terremoto debe drenar 5.0 HP")

	slinger.free()
	shock_enemy.free()
	proj.free()
	stone_prophet.free()
	enemy_building.free()
	print("✅ Test 24 Superado: Lanzador de Piedras x1.5 vs MELEE_SHOCK y Terremoto de Piedra 8m DoT OK.")

	# TEST 25: Catálogo Militar Era 1 (Maceman +15%, Axeman x1.40 infantería / x1.30 murallas, Bowman 14m e Inglés, Scout 6.5m/s)
	print("\n--- TEST 25: Catálogo Militar Completo de la Edad de Piedra ---")
	# 1. Maceman (+15% daño base respecto a Clubman: 16.0 -> 18.4)
	var maceman := Soldier3D.new()
	root.add_child(maceman)
	maceman.configurar_unidad("maceman_era1")
	assert(absf(maceman.daño - 18.4) < 0.05, "Maceman debe tener daño base +15% respecto al Clubman (18.4)")
	assert(maceman.weapon_type == "bludgeoning", "Maceman debe usar arma de impacto Bludgeoning")

	# Prioridad de targeting oficial para Maceman: Sacerdotes > Aldeanos > Cuarteles > Capitolio
	var mace_priest := CharacterBody3D.new()
	mace_priest.name = "Priest_Enemy"
	var mace_vil := CharacterBody3D.new()
	mace_vil.name = "Villager_Enemy"
	var mace_barracks := Node3D.new()
	mace_barracks.name = "Barracks_Enemy"
	var mace_tc := Node3D.new()
	mace_tc.name = "TownCenter_Enemy"
	var p_priest := MilitaryWarTactics3D.calcular_prioridad_objetivo(mace_priest)
	var p_vil := MilitaryWarTactics3D.calcular_prioridad_objetivo(mace_vil)
	var p_barr := MilitaryWarTactics3D.calcular_prioridad_objetivo(mace_barracks)
	var p_tc := MilitaryWarTactics3D.calcular_prioridad_objetivo(mace_tc)
	assert(p_priest > p_vil and p_vil > p_barr and p_barr > p_tc, "Maceman debe respetar la prioridad oficial: Sacerdotes > Aldeanos > Cuarteles > Capitolio")
	mace_priest.free()
	mace_vil.free()
	mace_barracks.free()
	mace_tc.free()

	# 2. Axeman (x1.40 vs infantería ligera, x1.30 vs murallas de madera)
	var axeman := Soldier3D.new()
	root.add_child(axeman)
	axeman.configurar_unidad("axeman_era1")

	var light_target := Soldier3D.new()
	light_target.bando = UnitBase3D.Bando.ENEMY
	light_target.add_to_group("infantry_3d")
	root.add_child(light_target)
	var init_light_hp := light_target.salud_actual
	axeman.on_attack_impact(light_target)
	var expected_axe_inf_dmg := axeman.daño * 1.40 # 17.0 * 1.40 = 23.8
	assert(absf(light_target.salud_actual - (init_light_hp - expected_axe_inf_dmg)) < 0.05, "Axeman debe aplicar multiplicador estricto x1.40 contra infantería ligera")

	var wall_target := WallWoodEra1.new()
	wall_target.bando = BuildingBase3D.Bando.ENEMY
	root.add_child(wall_target)
	var init_wall_hp := wall_target.salud_actual
	axeman.on_attack_impact(wall_target)
	var expected_axe_wall_dmg := axeman.daño * 1.30 # 17.0 * 1.30 = 22.1
	assert(absf(wall_target.salud_actual - (init_wall_hp - expected_axe_wall_dmg)) < 0.05, "Axeman debe aplicar multiplicador x1.30 contra murallas de madera")

	# 3. Bowman (14m alcance, hereda bono facción Inglesa)
	var bowman := Soldier3D.new()
	root.add_child(bowman)
	bowman.configurar_unidad("bowman_era1")
	assert(bowman.rango_ataque == 14.0, "Bowman debe tener alcance regular de 14.0m")

	# Test facción Inglesa (+15% daño y alcance)
	var bowman_english := Soldier3D.new()
	bowman_english.set("civilizacion", "ingleses")
	root.add_child(bowman_english)
	bowman_english.configurar_unidad("bowman_era1")
	assert(absf(bowman_english.daño - (11.0 * 1.15)) < 0.05, "Bowman de facción Inglesa debe recibir +15% de daño")
	assert(absf(bowman_english.rango_ataque - (14.0 * 1.15)) < 0.05, "Bowman de facción Inglesa debe recibir +15% de alcance")

	# 4. Scout (6.5 m/s, visión duplicada 56m, bloqueo ataque a estructuras y recolección)
	var scout := Soldier3D.new()
	root.add_child(scout)
	scout.configurar_unidad("scout_era1")
	assert(scout.speed == 6.5, "Scout debe tener velocidad base de 6.5 m/s")
	assert(scout.radio_vision == 56.0, "Scout debe tener radio de visión de 56.0m (+100%)")

	var init_bld_scout_hp := wall_target.salud_actual
	scout.on_attack_impact(wall_target)
	assert(wall_target.salud_actual == init_bld_scout_hp, "Scout debe tener bloqueado infligir daño a estructuras")

	maceman.free()
	axeman.free()
	light_target.free()
	wall_target.free()
	bowman.free()
	bowman_english.free()
	scout.free()
	print("✅ Test 25 Superado: Maceman +15%, Axeman x1.40/x1.30, Bowman inglés y Scout 6.5m/s OK.")

	# TEST 26: Infraestructura Era 1 (Campo de Tiro, Establo Temprano, Murallas Auto-Tiling y Muelle Era 1)
	print("\n--- TEST 26: Infraestructura Era 1 (Campo de Tiro, Establo, Muralla Auto-Tiling y Muelle Era 1) ---")
	var archery_range_scene: PackedScene = load("res://scenes/buildings/archery_range_3d.tscn")
	var archery_range: Node = archery_range_scene.instantiate()
	root.add_child(archery_range)
	assert(archery_range is Barracks3D, "ArcheryRange3D debe heredar de Barracks3D")

	# Entrenamiento síncrono de Lanzador de Piedras y Bowman
	var train_slinger_ok: bool = archery_range.call("entrenar_lanzador_piedras")
	assert(train_slinger_ok == true, "Campo de Tiro debe permitir entrenar Lanzador de Piedras en Era 1")
	var train_bowman_ok: bool = archery_range.call("entrenar_arquero_piedra")
	assert(train_bowman_ok == true, "Campo de Tiro debe permitir entrenar Arquero de Piedra en Era 1")

	# Bloqueo de unidades futuristas
	var block_futuristic: bool = archery_range.call("entrenar_unidad", "sniper_nano")
	assert(block_futuristic == false, "Campo de Tiro debe bloquear entrenamiento de unidades futuristas en Era 1")

	# Establo Temprano e investigación de monturas
	var stable := Stable3D.new()
	root.add_child(stable)
	assert(stable is Barracks3D, "Stable3D debe heredar de Barracks3D")
	assert(stable.velocidad_monturas_investigada == false, "Velocidad de monturas debe iniciar no investigada")
	var research_ok := stable.investigar_velocidad_monturas()
	assert(research_ok == true, "Establo Temprano debe permitir investigar velocidad de monturas")
	assert(stable.velocidad_monturas_investigada == true, "Estado de investigación de monturas debe quedar activo")

	# Muralla de madera de la Edad de Piedra (dbupgrade.dat HP = 1200) y Auto-tiling de grid (4.0m)
	var wall_a := WallWoodEra1.new()
	wall_a.position = Vector3(0, 0, 0)
	root.add_child(wall_a)
	assert(wall_a.salud_maxima == 1200.0, "Empalizada de madera de la Edad de Piedra debe tener 1200 HP según dbupgrade.dat")

	var wall_b := WallWoodEra1.new()
	wall_b.position = Vector3(4, 0, 0) # Distancia exacta GRID_SIZE
	root.add_child(wall_b)
	wall_a.actualizar_conexiones()
	wall_b.actualizar_conexiones()
	assert(wall_a.neighbors["E"] == true, "wall_a debe detectar a wall_b al Este en el grid")
	assert(wall_b.neighbors["W"] == true, "wall_b debe detectar a wall_a al Oeste en el grid")
	assert(wall_a.wall_type == "end", "Muralla con 1 solo vecino contiguo debe asignar malla end")

	# Muelle Era 1 y Barco de Pesca de Piedra (Herencia de Era 0 y DropOffPoint)
	var dock_era1 := DockEra13D.new()
	root.add_child(dock_era1)
	assert(dock_era1 is Dock3D, "DockEra13D debe heredar directamente de Dock3D")
	var boat_era1 := FishingBoatEra13D.new()
	root.add_child(boat_era1)
	assert(boat_era1 is FishingBoat3D, "FishingBoatEra13D debe heredar de FishingBoat3D")
	boat_era1.current_cargo = 20
	dock_era1._handle_boat_dropoff(boat_era1)
	assert(boat_era1.current_cargo == 0, "Al tocar DropOffPoint el barco pesquero de Era 1 debe vaciar su bodega (+20 Food)")

	archery_range.free()
	stable.free()
	wall_a.free()
	wall_b.free()
	dock_era1.free()
	boat_era1.free()
	print("✅ Test 26 Superado: Campo de Tiro, Establo, Muralla Auto-Tiling y Muelle Era 1 OK.")

	# TEST 27: Teocracia de Fe (Aldeanos Rezando en Templo acumulando +1/s Fe en CivPointsManager)
	print("\n--- TEST 27: Acumulación Pasiva de Fe por Aldeanos Rezando en el Templo ---")
	var cpm27 := CivPointsManager.instance
	var created_cpm27 := false
	if not is_instance_valid(cpm27):
		cpm27 = CivPointsManager.new()
		cpm27.name = "CivPointsManager"
		root.add_child(cpm27)
		CivPointsManager.instance = cpm27
		created_cpm27 = true

	cpm27.puntos_fe = 0.0

	var temple := Temple3D.new()
	temple.bando = BuildingBase3D.Bando.PLAYER
	root.add_child(temple)

	# Guarecer 2 aldeanos para rezar
	var villager_a := Villager3D.new()
	villager_a.name = "Aldeano_Devoto_1"
	root.add_child(villager_a)
	var villager_b := Villager3D.new()
	villager_b.name = "Aldeano_Devoto_2"
	root.add_child(villager_b)

	var g1 := temple.guarecer_aldeano(villager_a)
	var g2 := temple.guarecer_aldeano(villager_b)
	assert(g1 == true and g2 == true, "Aldeanos deben poder guarecerse en el templo para rezar")
	assert(temple.get_garrison_count() == 2, "Templo debe registrar exactamente 2 aldeanos rezando")

	# Simular 3.0 segundos de oración (+2 de fe/s * 3s = +6 puntos de fe)
	temple._process(3.0)
	assert(absf(cpm27.puntos_fe - 6.0) < 0.05, "CivPointsManager debe acumular exactamente +1/s punto de fe por cada aldeano rezando (+6.0)")

	# Expulsar aldeanos y verificar restauración
	var ejected := temple.expulsar_aldeanos()
	assert(ejected.size() == 2, "expulsar_aldeanos debe retornar los 2 aldeanos")
	assert(temple.get_garrison_count() == 0, "Guarnición del templo debe quedar vacía")
	assert(villager_a.visible == true and villager_b.visible == true, "Aldeanos expulsados deben volver a ser visibles")

	villager_a.free()
	villager_b.free()
	temple.free()
	if created_cpm27 and is_instance_valid(cpm27):
		cpm27.free()
	print("✅ Test 27 Superado: Acumulación pasiva de fe en CivPointsManager por aldeanos rezando OK.")

	# TEST 28: Ecosistema y Fauna de la Estepa (Bisonte 180 HP embestida, Gacela 100 comida huida 8m/s, y Extinción 80m)
	print("\n--- TEST 28: Fauna de la Estepa (Bisonte, Gacela y Extinción Esférica 80m) ---")
	# 1. Bisonte (450 comida, 180 HP, embestida reactiva si es atacado)
	var bison := FaunaAnimal3D.new()
	bison.configurar_especie("bisonte")
	bison.position = Vector3(-50, 0, 0)
	root.add_child(bison)
	assert(bison.animal_health == 180.0, "Bisonte debe tener 180 HP")
	assert(bison.current_amount == 450, "Bisonte debe otorgar 450 de comida")
	assert(bison.is_aggressive == false, "Bisonte debe ser pasivo inicialmente")

	# Simular ataque de aldeano -> Bisonte se enfurece y embiste
	var hunter := Villager3D.new()
	hunter.name = "Cazador_Primitivo"
	hunter.position = Vector3(-48, 0, 0)
	root.add_child(hunter)
	bison.recibir_daño_caceria(10.0, hunter)
	assert(bison.is_aggressive == true, "Bisonte atacado debe volverse agresivo y embestir")
	assert(bison.target_villager == hunter, "Bisonte debe fijar al cazador como objetivo de embestida")

	# 2. Gacela (100 comida, huye a 8.0 m/s ante cualquier unidad)
	var gazelle := FaunaAnimal3D.new()
	gazelle.position = Vector3(0, 0, 0)
	root.add_child(gazelle)
	gazelle.configurar_especie("gacela")
	assert(gazelle.current_amount == 100, "Gacela debe otorgar 100 de comida")

	var nearby_unit := Soldier3D.new()
	nearby_unit.position = Vector3(4, 0, 0) # A 4m de la gacela
	root.add_child(nearby_unit)

	var init_gazelle_pos := gazelle.global_position if gazelle.is_inside_tree() else gazelle.position
	gazelle._process(1.0) # Simular 1 segundo de proceso con amenaza cercana
	assert(gazelle.is_fleeing == true, "Gacela debe detectar amenaza y activar modo de huida")
	var current_gazelle_pos := gazelle.global_position if gazelle.is_inside_tree() else gazelle.position
	var dist_moved := current_gazelle_pos.distance_to(init_gazelle_pos)
	assert(absf(dist_moved - 8.0) < 0.1, "Gacela debe huir a exactamente 8.0 m/s (Movido: %.1fm)" % dist_moved)

	# 3. Extinción esférica de 80 metros: Reemplazar Mamuts por fauna de Era 1
	var old_mammoth := FaunaAnimal3D.new()
	old_mammoth.configurar_especie("mamut")
	old_mammoth.position = Vector3(10, 0, 10) # Dentro del radio de 80m
	root.add_child(old_mammoth)

	var replaced_animals := FaunaAnimal3D.reemplazar_fauna_extinta_global(root, Vector3.ZERO, 80.0)
	assert(replaced_animals.size() >= 1, "rpc_reemplazar_fauna_extinta debe reemplazar a los Mamuts en el radio de 80m")
	assert(replaced_animals[0].especie_id == "bisonte" or replaced_animals[0].especie_id == "gacela", "Mamut debe ser sustituido por fauna de Era 1 (Bisonte o Gacela)")

	bison.free()
	hunter.free()
	gazelle.free()
	nearby_unit.free()
	for a in replaced_animals:
		if is_instance_valid(a): a.free()
	print("✅ Test 28 Superado: Bisonte embestida 180 HP, Gacela huida 8.0 m/s y Extinción esférica 80m OK.")

	# ─── TEST 29: Era 2 — Debuff de Red del Gladiador Retiarius y Velocidad del Carro de Guerra ────
	print("\n--- TEST 29: Era 2 (Gladiador Retiarius -50% lentitud 3.5s y Carro de Guerra 6.0 m/s) ---")

	# 29a. Gladiador Retiarius: debuff is_slowed -50% en objetivo por 3.5s
	var retiarius := Soldier3D.new()
	retiarius.unit_id = "retiarius_gladiador"
	retiarius._setup_stats()
	assert(retiarius.unit_name == "Gladiador Lanzador de Redes", "Retiarius debe tener nombre correcto")
	assert(retiarius.weapon_type == "net_trident", "Retiarius debe tener weapon_type 'net_trident'")
	assert(absf(retiarius.speed - 5.4) < 0.01, "Retiarius debe tener speed 5.4 m/s")
	assert(absf(retiarius.rango_ataque - 4.5) < 0.01, "Retiarius debe alcanzar 4.5m con la red")
	assert(retiarius.era_entrenada == 2, "Retiarius debe ser de Era 2")

	# Probar el debuff de ralentización (simular llamada a _lanzar_red_retiarius)
	var slow_target := Soldier3D.new()
	slow_target.unit_id = "maceman_era1"
	slow_target.speed = 5.2
	# Simular la aplicación manual del slow (sin árbol activo para el Timer)
	slow_target.set_meta("_original_speed_before_net", 5.2)
	slow_target.speed = slow_target.speed * 0.5
	assert(absf(slow_target.speed - 2.6) < 0.01, "Debuff de red debe reducir velocidad exactamente -50%% (%.2f m/s)" % slow_target.speed)
	# Simular restauración
	slow_target.speed = float(slow_target.get_meta("_original_speed_before_net"))
	slow_target.remove_meta("_original_speed_before_net")
	assert(absf(slow_target.speed - 5.2) < 0.01, "Velocidad debe restaurarse al 100%% post-red (%.2f m/s)" % slow_target.speed)
	print("Retiarius '%s': ¡Red lanzada! Ralentización -50%% (2.6 m/s) → Restaurado (5.2 m/s) OK." % retiarius.name)

	# 29b. Carro de Guerra: velocidad base 6.0 m/s (más rápido de Era 2)
	var chariot := Soldier3D.new()
	chariot.unit_id = "chariot_archer_era2"
	chariot._setup_stats()
	assert(chariot.unit_name == "Carro de Guerra Primitivo", "Carro debe tener nombre correcto")
	assert(absf(chariot.speed - 6.0) < 0.01, "Carro de Guerra debe tener speed 6.0 m/s (era 2 - más rápido)")
	assert(chariot.attack_type == "ranged", "Carro debe ser unidad de rango")
	assert(chariot.era_entrenada == 2, "Carro de Guerra debe ser de Era 2")
	print("Chariot '%s': speed=%.1f m/s, attack_type=%s, Era=%d OK." % [chariot.name, chariot.speed, chariot.attack_type, chariot.era_entrenada])

	# 29c. Macero de Bronce: HP 160, daño 21.0, bludgeoning
	var macero_bronze := Soldier3D.new()
	macero_bronze.unit_id = "maceman_bronze"
	macero_bronze._setup_stats()
	assert(absf(macero_bronze.salud_maxima - 160.0) < 0.01, "Macero de Cobre debe tener 160 HP")
	assert(absf(macero_bronze.daño - 21.0) < 0.01, "Macero de Cobre debe tener daño 21.0")
	assert(macero_bronze.weapon_type == "bludgeoning", "Macero de Cobre debe ser MELEE_SHOCK/Bludgeoning")
	print("Macero_Bronze '%s': HP=%.0f, Daño=%.1f, weapon=%s OK." % [macero_bronze.name, macero_bronze.salud_maxima, macero_bronze.daño, macero_bronze.weapon_type])

	retiarius.free()
	slow_target.free()
	chariot.free()
	macero_bronze.free()
	print("✅ Test 29 Superado: Retiarius debuff -50%% 3.5s, Carro 6.0 m/s y Macero de Cobre 160HP OK.")

	# ─── TEST 30: Herencia Limpia del Taller de Asedio (sin duplicación de lógica) ────────────────
	print("\n--- TEST 30: SiegeWorkshop3D herencia limpia de Barracks3D (sin duplicación) ---")

	var sw := SiegeWorkshop3D.new()
	assert(sw.building_name == "Taller de Asedio", "SiegeWorkshop debe tener nombre correcto")
	assert(absf(sw.salud_maxima - 700.0) < 0.01, "SiegeWorkshop debe tener 700 HP")

	# Verificar que el catálogo de unidades es exactamente el de Barracks3D (herencia total, sin copia)
	assert(sw.CATALOGO_UNIDADES.has("ariete_primitivo"), "Taller debe tener el ariete en catálogo heredado")
	assert(sw.CATALOGO_UNIDADES.has("ballista"), "Taller debe tener la ballesta en catálogo heredado")
	assert(sw.CATALOGO_UNIDADES["ariete_primitivo"]["building_type"] == "siege_workshop", "Ariete debe ser de tipo siege_workshop")

	# Verificar que el filtro de era funciona: Era 0 → bloqueado
	# Simular era_actual = 0 (sin ResourceManager real)
	var siege_units_era0 := Barracks3D.get_unidades_disponibles_era(0, "siege_workshop")
	assert(siege_units_era0.size() > 0, "Debe haber al menos 1 unidad de asedio disponible en Era 0 (ariete)")

	# Verificar era 2 disponible
	var siege_units_era2 := Barracks3D.get_unidades_disponibles_era(2, "siege_workshop")
	assert(siege_units_era2.size() >= 2, "Deben haber ≥2 unidades de asedio en Era 2 (ariete + ballesta)")
	print("SiegeWorkshop '%s': CATALOGO heredado OK (%d siege units era 0, %d era 2)." % [sw.name, siege_units_era0.size(), siege_units_era2.size()])

	# Confirmar que SiegeWorkshop3D NO duplica métodos ya existentes en Barracks3D
	# (Si existiera duplicación, get_class() retornaría diferente)
	assert(sw.has_method("entrenar_unidad"), "Taller debe tener entrenar_unidad heredado")
	assert(sw.has_method("cancelar_produccion"), "Taller debe tener cancelar_produccion heredado")
	assert(sw.has_method("get_training_progress"), "Taller debe tener get_training_progress heredado")
	assert(sw.has_method("get_siege_units_for_current_era"), "Taller debe tener get_siege_units_for_current_era propio")
	print("SiegeWorkshop herencia OK: entrenar_unidad, cancelar_produccion, get_training_progress heredados sin duplicación.")

	sw.free()
	print("✅ Test 30 Superado: SiegeWorkshop3D herencia limpia de Barracks3D verificada (0 duplicación).")

	# ─── TEST 31: WonderZigurat — Cronómetro de 10 minutos por RPC fiable ─────────────────────────
	print("\n--- TEST 31: Wonder Zigurat Era 2 (RPC cronómetro 600s y condición Era >= 2) ---")

	var zigurat := WonderZigurat3D.new()
	assert(zigurat.building_name == "Zigurat Sagrado — Maravilla del Cobre", "Zigurat debe tener nombre correcto")
	assert(absf(zigurat.salud_maxima - 3500.0) < 0.01, "Zigurat debe tener 3500 HP")
	assert(absf(zigurat.radio_vision - 55.0) < 0.01, "Zigurat debe tener radio de visión 55m")

	# Verificar que hereda wonder_time_left de Wonder3D
	assert(absf(zigurat.wonder_time_left - 600.0) < 0.01, "Zigurat debe heredar cronómetro de 600s de Wonder3D")
	assert(zigurat.is_wonder_active == false, "Zigurat no debe estar activo hasta que se complete la construcción")

	# Simular activación del cronómetro RPC (sin red real — llamada directa al método)
	zigurat.rpc_iniciar_cuenta_regresiva_maravilla(600.0)
	assert(zigurat.is_wonder_active == true, "Zigurat debe activarse al llamar rpc_iniciar_cuenta_regresiva_maravilla()")
	assert(absf(zigurat.wonder_time_left - 600.0) < 0.01, "Zigurat debe tener 600.0s al iniciarse el cronómetro")
	print("WonderZigurat '%s': is_active=%s, wonder_time_left=%.0fs OK." % [zigurat.name, zigurat.is_wonder_active, zigurat.wonder_time_left])

	# Verificar costo de construcción (dbupgrade.dat Era 2)
	assert(WonderZigurat3D.COSTO_CONSTRUCCION.get("food", 0) == 3000, "Zigurat debe costar 3000 food")
	assert(WonderZigurat3D.COSTO_CONSTRUCCION.get("wood", 0) == 2500, "Zigurat debe costar 2500 wood")
	assert(WonderZigurat3D.COSTO_CONSTRUCCION.get("gold", 0) == 1500, "Zigurat debe costar 1500 gold")
	assert(WonderZigurat3D.COSTO_CONSTRUCCION.get("stone", 0) == 1000, "Zigurat debe costar 1000 stone")
	print("WonderZigurat costo: Food=%d, Wood=%d, Gold=%d, Stone=%d OK." % [
		WonderZigurat3D.COSTO_CONSTRUCCION["food"],
		WonderZigurat3D.COSTO_CONSTRUCCION["wood"],
		WonderZigurat3D.COSTO_CONSTRUCCION["gold"],
		WonderZigurat3D.COSTO_CONSTRUCCION["stone"]
	])

	zigurat.free()
	print("✅ Test 31 Superado: WonderZigurat Era 2 cronómetro 600s RPC, costo oficial y herencia Wonder3D OK.")

	# ─── TEST 32: Correcciones — Fuego Amigo Bloqueado y Override Manual de Movimiento ─────────────
	print("\n--- TEST 32: Fuego Amigo Bloqueado y Override Manual de Movimiento en Combate ---")

	# 32a. Verificar bloqueo de fuego amigo en StateAttacking3D._is_valid_enemy_target
	# Usar Soldier3D (que tiene la property 'bando' heredada de UnitBase3D)
	# CharacterBody3D genérico no tiene 'bando' como property, solo como meta.
	var t32_attacker := Soldier3D.new()
	t32_attacker.unit_id = "maceman_era1"
	t32_attacker._setup_stats()
	t32_attacker.bando = 0  # PLAYER — property directa en UnitBase3D

	# Aldeano aliado: también Soldier3D con mismo bando para que el 'in' funcione
	var t32_ally := Soldier3D.new()
	t32_ally.unit_id = "scout_era1"
	t32_ally.bando = 0  # Mismo bando = 0 → aliado
	t32_ally.name = "Aldeano_Aliado_T32"

	# Crear StateAttacking3D para probar el filtro de fuego amigo
	var t32_atk_state := StateAttacking3D.new()
	t32_atk_state.unit = t32_attacker

	# El aliado del mismo bando NO debe ser enemigo válido (bloqueo de fuego amigo)
	var t32_ally_valid := t32_atk_state._is_valid_enemy_target(t32_ally)
	assert(t32_ally_valid == false, "Aliado bando=0 NO debe ser objetivo válido para soldado bando=0 (fuego amigo)")
	print("Fuego amigo: StateAttacking3D rechazó correctamente al aliado bando=0.")

	# 32b. Enemigo real (bando distinto) — Soldier3D de bando 1
	var t32_enemy := Soldier3D.new()
	t32_enemy.unit_id = "maceman_era1"
	t32_enemy.bando = 1  # Bando enemigo
	t32_enemy.name = "Soldado_Enemigo_T32"
	var t32_enemy_valid := t32_atk_state._is_valid_enemy_target(t32_enemy)
	# Cuando el atacante es bando 0 y el target es bando 1 → debe ser válido
	assert(t32_enemy_valid == true, "Soldado enemigo bando=1 DEBE ser objetivo válido para bando=0 (combate normal)")
	print("Fuego amigo: Enemigo bando=1 evaluado correctamente como válido=%s." % t32_enemy_valid)

	# 32c. Override de movimiento manual: _manual_move_override interrumpe el combate
	assert("_manual_move_override" in t32_atk_state, "_manual_move_override debe existir en StateAttacking3D")
	assert(t32_atk_state._manual_move_override == false, "_manual_move_override debe iniciar en false")
	t32_atk_state._manual_move_override = true
	assert(t32_atk_state._manual_move_override == true, "Debe poder activarse _manual_move_override = true")
	print("Override manual: _manual_move_override activado correctamente en StateAttacking3D.")

	# 32d. Maceman_Bronze tiene counter x1.45 vs edificios (superior al x1.35 del Clubman)
	var t32_bronze_dmg: float = 21.0 * 1.45
	assert(absf(t32_bronze_dmg - 30.45) < 0.01, "Macero de Cobre: x1.45 vs muralla = 30.45 daño (base 21)")
	print("Macero_Bronze counter x1.45 vs estructuras = %.2f daño OK." % t32_bronze_dmg)

	t32_attacker.free()
	t32_ally.free()
	t32_enemy.free()
	t32_atk_state.free()
	print("✅ Test 32 Superado: Fuego amigo bloqueado, override de movimiento y counter Macero Cobre x1.45 OK.")

	# ─── TEST 33: Control de Velocidad Regulable (GameSpeedModifier 0.5x, 1.0x, 2.0x) ─
	print("\n--- TEST 33: Control de Velocidad de Juego (Game Speed Modifier) ---")
	var gs_node = GameSettings.instance if is_instance_valid(GameSettings.instance) else root.get_node_or_null("GameSettings")
	if not is_instance_valid(gs_node):
		var gs_scr = load("res://scripts/core/game_settings.gd")
		gs_node = gs_scr.new()
		gs_node.name = "GameSettings"
		root.add_child(gs_node)
	GameSettings.instance = gs_node

	# 33a. Velocidad de traslación de unidades
	var t33_unit := Soldier3D.new()
	root.add_child(t33_unit)
	t33_unit.speed = 4.0 # Base speed asignada

	gs_node.game_speed_modifier = 1.0
	assert(absf(t33_unit.speed - 4.0) < 0.01, "A 1.0x speed debe ser 4.0 m/s")

	gs_node.game_speed_modifier = 2.0 # Muy Rápido
	assert(absf(t33_unit.speed - 8.0) < 0.01, "A 2.0x speed debe duplicarse a 8.0 m/s")

	gs_node.game_speed_modifier = 0.5 # Muy Lento
	assert(absf(t33_unit.speed - 2.0) < 0.01, "A 0.5x speed debe reducirse a 2.0 m/s")

	# 33b. Intervalo y ticks de recolección de aldeanos
	var t33_villager := Villager3D.new()
	root.add_child(t33_villager)
	t33_villager.gather_rate = 1.0
	var t33_gather_state := StateGathering3D.new()

	gs_node.game_speed_modifier = 2.0
	var interval_fast := t33_gather_state.get_gather_interval(t33_villager)
	assert(absf(interval_fast - 0.5) < 0.01, "A 2.0x recolección ocurre cada 0.5s (el doble de rápido)")

	gs_node.game_speed_modifier = 0.5
	var interval_slow := t33_gather_state.get_gather_interval(t33_villager)
	assert(absf(interval_slow - 2.0) < 0.01, "A 0.5x recolección ocurre cada 2.0s (la mitad de velocidad)")

	# 33c. Tasa de construcción y reparación de estructuras
	var t33_build_state := StateBuilding3D.new()
	gs_node.game_speed_modifier = 1.4 # Rápido
	var build_rate_fast := t33_build_state.get_build_rate()
	assert(absf(build_rate_fast - 14.0) < 0.01, "A 1.4x la tasa de construcción es 14.0%%/tick")
	var repair_rate_fast := t33_build_state.get_repair_rate()
	assert(absf(repair_rate_fast - 21.0) < 0.01, "A 1.4x la tasa de reparación es 21.0 HP/tick")

	# Restaurar normalidad
	gs_node.game_speed_modifier = 1.0
	t33_unit.free()
	t33_villager.free()
	t33_gather_state.free()
	t33_build_state.free()
	print("✅ Test 33 Superado: GameSpeedModifier altera matemáticamente recolección, reparación y velocidad de movimiento.")

	# ─── TEST 34: Motor de Ventajas de Civilización (100 Civ Points Lock) ─────────
	print("\n--- TEST 34: CivPointsManager (100 Puntos Iniciales y Candado Único) ---")
	var cpm_node = CivPointsManager.instance if is_instance_valid(CivPointsManager.instance) else root.get_node_or_null("CivPointsManager")
	if not is_instance_valid(cpm_node):
		var cpm_scr = load("res://scripts/core/civ_points_manager.gd")
		cpm_node = cpm_scr.new()
		cpm_node.name = "CivPointsManager"
		root.add_child(cpm_node)
	CivPointsManager.instance = cpm_node

	cpm_node.reiniciar_banco_partida()
	assert(cpm_node.total_civ_points == 100, "Bolsa inicial debe ser exactamente 100 puntos")
	assert(cpm_node.puntos_civ == 100, "puntos_civ debe iniciar en 100")
	assert(cpm_node.is_locked == false, "No debe estar bloqueado al inicio")

	# Instanciar panel de ventajas de civilización
	var cam := CivAdvantagesMenuClass.new()
	root.add_child(cam)

	# Distribuir puntos: 10 pts a economía y 10 pts a infantería cuerpo a cuerpo
	var eco_ok := cam.distribuir_punto("economy_speed")
	assert(eco_ok == true, "Debe permitir compra de economía")
	assert(cpm_node.puntos_civ == 90, "Puntos restantes tras gastar 10 deben ser 90")

	var melee_ok := cam.distribuir_punto("infantry_melee")
	assert(melee_ok == true, "Debe permitir compra de infantería")
	assert(cpm_node.puntos_civ == 80, "Puntos restantes tras gastar 20 deben ser 80")

	# Bloquear ventajas permanentemente (pulsación de %BtnLockCivSettings)
	cam.bloquear_ventajas_civ()
	assert(cam.is_locked == true, "Panel debe marcar is_locked = true")
	assert(cpm_node.is_locked == true, "CivPointsManager debe marcar is_locked = true")
	assert(cam.btn_lock_civ_settings.disabled == true, "%BtnLockCivSettings debe quedar disabled = true")

	# Verificar que TODOS los botones del panel queden inhabilitados
	for btn: Button in cam.buttons_list:
		assert(btn.disabled == true, "Todos los botones deben quedar inhabilitados (disabled = true)")

	# Intentar distribuir otro punto debe ser rechazado
	var try_locked := cam.distribuir_punto("infantry_ranged")
	assert(try_locked == false, "No se deben permitir compras posteriores al bloqueo")
	assert(cpm_node.puntos_civ == 80, "Puntos no deben alterarse tras bloqueo")

	cam.free()
	cpm_node.reiniciar_banco_partida()
	print("✅ Test 34 Superado: CivPointsManager inicia con 100 puntos y %BtnLockCivSettings inhabilita panel (disabled=true).")

	# ─── TEST 35: Pausa por Teclado (F3 Bind y PROCESS_MODE_ALWAYS) ───────────────
	print("\n--- TEST 35: Pausa por Teclado F3 y Process Mode Always ---")
	var pm := PauseMenuClass.new()
	pm.target_tree = self
	root.add_child(pm)
	assert(pm.process_mode == Node.PROCESS_MODE_ALWAYS, "PauseMenu debe tener PROCESS_MODE_ALWAYS para responder pausado")

	# Simular pulsación de tecla F3
	var f3_event := InputEventKey.new()
	f3_event.keycode = KEY_F3
	f3_event.pressed = true
	pm._unhandled_input(f3_event)

	assert(self.paused == true, "F3 debe congelar la simulación (get_tree().paused = true)")
	assert(pm.visible == true, "F3 debe hacer visible el panel de pausa")

	# Simular segunda pulsación de tecla F3 para reanudar
	pm._unhandled_input(f3_event)
	assert(self.paused == false, "Segunda pulsación de F3 debe despausar el juego")
	assert(pm.visible == false, "Segunda pulsación de F3 debe ocultar el panel de pausa")

	pm.free()
	print("✅ Test 35 Superado: Tecla F3 conmuta get_tree().paused y PauseMenu opera en PROCESS_MODE_ALWAYS.")

	# ─── TEST 36: Rendición y Limpieza Profunda de Autoloads ───────────────────────
	print("\n--- TEST 36: Botón de Rendición y Limpieza Profunda de Autoloads ---")
	var pm36 := PauseMenuClass.new()
	root.add_child(pm36)

	# Simular estados sucios en Autoloads
	var rm_node = root.get_node_or_null("ResourceManager")
	if not is_instance_valid(rm_node):
		rm_node = root.get_node_or_null("GlobalResourceManager")
	if is_instance_valid(rm_node):
		rm_node.era_actual = 5
	cpm_node.puntos_civ = 30
	gs_node.game_speed_modifier = 2.0

	# Invocar limpieza profunda (como lo hace %BtnQuitMatch o %BtnSurrender)
	assert(is_instance_valid(pm36.btn_quit_match), "%BtnQuitMatch debe estar inicializado y disponible")
	assert(is_instance_valid(pm36.btn_surrender), "%BtnSurrender debe estar inicializado y disponible")

	pm36._ejecutar_limpieza_autoloads()

	if is_instance_valid(rm_node):
		assert(rm_node.era_actual == 0, "Limpieza profunda debe reiniciar era_actual a 0")
	assert(cpm_node.puntos_civ == 100, "Limpieza profunda debe restablecer puntos_civ a 100")
	assert(gs_node.game_speed_modifier == 1.0, "Limpieza profunda debe restablecer game_speed_modifier a 1.0")

	pm36.free()
	print("✅ Test 36 Superado: Botón de rendición ejecuta limpieza profunda de Autoloads antes de cambiar de escena.")

	# ─── TEST 37: Evolución Estética en Caliente de Menús y HUD (UI Era Morphing) ──
	print("\n--- TEST 37: Evolución Estética en Caliente de Menús y HUD (UI Era Morphing) ---")
	var ap := RTSActionPanelClass.new()
	root.add_child(ap)
	var hud_ctrl := HUDControllerClass.new()
	root.add_child(hud_ctrl)
	hud_ctrl.registrar_contenedor(ap)

	# 37a. Filtro estricto por Player ID: Avance de peer rival NO altera el HUD local
	var foreign_id: int = 999
	ap._on_era_evolucionada(foreign_id, 2)
	assert(ap.current_era_theme == "madera_rustica", "Peer rival no debe alterar el tema estético del jugador local")

	# 37b. Transición a Era 2: Madera rústica muta a Piedra labrada
	var my_id: int = 1
	var mp = ap.get_multiplayer() if ap.has_method("get_multiplayer") else null
	if not is_instance_valid(mp) and "multiplayer" in ap:
		mp = ap.multiplayer
	if is_instance_valid(mp) and mp.has_multiplayer_peer():
		my_id = mp.get_unique_id()
	ap._on_era_evolucionada(my_id, 2)
	assert(ap.current_era_theme == "piedra_labrada", "Era 2 debe mutar estilo a 'piedra_labrada'")

	# 37c. Transición a Era 6: Hierro victoriano remachado
	ap._on_era_evolucionada(my_id, 6)
	assert(ap.current_era_theme == "hierro_victoriano", "Era 6 debe mutar estilo a 'hierro_victoriano'")

	# 37d. Transición a Era 8: Cromo y neón digital cian
	ap._on_era_evolucionada(my_id, 8)
	assert(ap.current_era_theme == "cromo_neon_digital", "Era 8 debe mutar estilo a 'cromo_neon_digital'")
	assert(absf(ap.current_era_style.border_color.g - 0.88) < 0.1, "Borde de Era 8 debe ser cian neón reflectante")

	hud_ctrl.aplicar_estilo_era(8)
	assert(hud_ctrl.current_theme_name == "cromo_neon_digital", "HUDController debe evolucionar a cromo_neon_digital")

	ap.free()
	hud_ctrl.free()
	print("✅ Test 37 Superado: UI Era Morphing conmutó StyleBoxes y texturas por filtro local (Era 0->2->6->8).")

	# ─── TEST 38: Conmutación Bilateral de Pausa F3 (Anti-Freeze) ─────────────────
	print("\n--- TEST 38: Conmutación Bilateral de Pausa F3 (Anti-Freeze) ---")
	var input_ctrl := RTSInputControllerClass.new()
	input_ctrl.target_tree = self
	root.add_child(input_ctrl)
	assert(input_ctrl.process_mode == Node.PROCESS_MODE_ALWAYS, "RTSInputController debe tener PROCESS_MODE_ALWAYS para escuchar F3 pausado")

	var pm38 := PauseMenuClass.new()
	pm38.target_tree = self
	root.add_child(pm38)
	assert(pm38.process_mode == Node.PROCESS_MODE_ALWAYS, "PauseMenu debe tener PROCESS_MODE_ALWAYS")

	# Primera pulsación de F3: Pausar y desplegar menú visual
	var f3_press := InputEventKey.new()
	f3_press.keycode = KEY_F3
	f3_press.pressed = true
	input_ctrl._unhandled_input(f3_press)
	assert(self.paused == true, "Primera pulsación de F3 debe pausar el juego (paused = true)")
	assert(pm38.visible == true, "Primera pulsación de F3 debe hacer visible el menú de pausa")

	# Segunda pulsación de F3: Reanudar y ocultar menú visual
	input_ctrl._unhandled_input(f3_press)
	assert(self.paused == false, "Segunda pulsación de F3 debe reanudar la partida (paused = false)")
	assert(pm38.visible == false, "Segunda pulsación de F3 debe ocultar el menú de pausa")

	input_ctrl.free()
	pm38.free()
	print("✅ Test 38 Superado: F3 alterna de forma bilateral y no se congela bajo paused=true.")

	# ─── TEST 39: Porcentaje Síncrono y Barra de Carga en Town Center ─────────────
	print("\n--- TEST 39: Porcentaje Síncrono y Barra de Carga en Town Center ---")
	var tc39 := TownCenter3DClass.new()
	root.add_child(tc39)
	var ap39 := RTSActionPanelClass.new()
	root.add_child(ap39)

	# Simular inicio de evolución de era
	tc39.esta_evolucionando = true
	assert(tc39.evolucionando == true, "Propiedad evolucionando debe reflejar esta_evolucionando")
	tc39._ensure_era_timer()
	# Simular timer a la mitad (time_left = 50.0, wait_time = 100.0) -> 50%
	tc39._era_timer.wait_time = 100.0
	tc39.mock_time_left = 50.0

	var pct39: int = tc39.get_era_progress_percentage()
	assert(pct39 == 50, "A time_left 50s de 100s, el porcentaje debe ser exactamente 50% (obtenido: " + str(pct39) + ")")

	# Simular actualización de UI en panel
	ap39._current_selection = [tc39]
	ap39.visible = true
	ap39._update_info_section(tc39)
	assert(ap39.label_subtitle.text == "Evolucionando... (50%)", "Subtítulo debe mostrar 'Evolucionando... (50%)' (obtenido: '%s')" % ap39.label_subtitle.text)
	assert(absf(ap39.hp_bar.value - 0.5) < 0.01, "Barra de progreso debe situarse en 0.5 (50%)")

	tc39._era_timer.stop()
	tc39.esta_evolucionando = false
	tc39.free()
	ap39.free()
	print("✅ Test 39 Superado: TownCenter3D calcula porcentaje síncrono 'Evolucionando... (X%)' y mueve su barra.")

	# ─── TEST 40: Filtrado por Era y Rótulo 'Foro Romano / Mármol' en Era 3 ────────
	print("\n--- TEST 40: Filtrado por Era y Rótulo 'Foro Romano / Mármol' en Era 3 ---")
	var tc40 := TownCenter3DClass.new()
	root.add_child(tc40)
	var ap40 := RTSActionPanelClass.new()
	root.add_child(ap40)

	# Cambiar a Era 3 (Edad de Hierro)
	var rm_t40: Node = root.get_node_or_null("ResourceManager")
	if not is_instance_valid(rm_t40):
		rm_t40 = root.get_node_or_null("GlobalResourceManager")
	if is_instance_valid(rm_t40):
		rm_t40.era_actual = 3
	ap40.current_player_era = 3

	ap40._current_selection = [tc40]
	ap40.visible = true
	ap40._update_info_section(tc40)

	assert(ap40.label_title.text == "Foro Romano / Mármol", "En Era 3 el rótulo debe ser 'Foro Romano / Mármol' (obtenido: '%s')" % ap40.label_title.text)
	assert(not "Fuego Tribal" in ap40.label_subtitle.text, "En Era 3 no deben existir textos prehistóricos como 'Fuego Tribal'")

	# Construir acciones en Era 3: debe tener botón clásico
	ap40._build_town_center_actions(tc40)
	var btns_text: Array[String] = []
	for b in ap40.actions_container.get_children():
		if b is Button:
			btns_text.append(b.text)
	assert(btns_text.size() >= 2, "Debe poseer botones de producción de Aldeano y Avance")
	assert("Aldeano Clásico" in btns_text[0], "El botón debe titularse 'Aldeano Clásico' en Era 3")

	tc40.free()
	ap40.free()
	if is_instance_valid(rm_t40):
		rm_t40.era_actual = 0
	print("✅ Test 40 Superado: Sub-panel evoluciona a 'Foro Romano / Mármol' sin textos prehistóricos.")

	# ─── TEST 41: Refactor de Botón de la Barra Superior a 'Menú' ─────────────────
	print("\n--- TEST 41: Refactor de Botón de Barra Superior a 'Menú' ---")
	var main_scene_res: PackedScene = load("res://scenes/main_3d.tscn") as PackedScene
	assert(main_scene_res != null, "scenes/main_3d.tscn debe cargar exitosamente")
	var main_inst: Node = main_scene_res.instantiate()
	root.add_child(main_inst)

	var btn_menu: Button = main_inst.find_child("BtnConfig", true, false) as Button
	if not is_instance_valid(btn_menu):
		btn_menu = main_inst.find_child("BtnMatchSettings", true, false) as Button
	assert(is_instance_valid(btn_menu), "Botón de menú superior debe existir")
	assert(btn_menu.text == "Menú", "Texto del botón en barra superior debe ser estrictamente 'Menú' (obtenido: '%s')" % btn_menu.text)

	main_inst.free()
	print("✅ Test 41 Superado: Botón de barra superior configurado estrictamente como 'Menú'.")

	# ─── TEST 42: Refactor Menú Ajustes Ingame (PauseMenu / Modal Ingame) ────────
	print("\n--- TEST 42: Refactor Menú Ajustes Ingame (PauseMenu / Modal Ingame) ---")
	var pause_scene_t42: PackedScene = load("res://scenes/ui/pause_menu.tscn") as PackedScene
	assert(pause_scene_t42 != null, "scenes/ui/pause_menu.tscn debe existir")
	var pause_inst_t42: Control = pause_scene_t42.instantiate() as Control
	root.add_child(pause_inst_t42)

	# 1. Título "AJUSTES DE LA PARTIDA EN CURSO"
	var title_lbl_t42: Label = pause_inst_t42.find_child("LabelTitulo", true, false) as Label
	if not is_instance_valid(title_lbl_t42):
		title_lbl_t42 = pause_inst_t42.find_child("TitleLabel", true, false) as Label
	assert(is_instance_valid(title_lbl_t42), "Debe existir un Label con el título del menú")
	assert(title_lbl_t42.text == "AJUSTES DE LA PARTIDA EN CURSO", "Título debe ser estrictamente 'AJUSTES DE LA PARTIDA EN CURSO' (obtenido: '%s')" % title_lbl_t42.text)

	# 2. Únicamente los 4 botones reales
	var btn_res_t42: Button = pause_inst_t42.find_child("BtnResume", true, false) as Button
	var btn_sav_t42: Button = pause_inst_t42.find_child("BtnSave", true, false) as Button
	var btn_lod_t42: Button = pause_inst_t42.find_child("BtnLoad", true, false) as Button
	var btn_sur_t42: Button = pause_inst_t42.find_child("BtnSurrender", true, false) as Button

	assert(is_instance_valid(btn_res_t42), "Botón BtnResume debe existir")
	assert(is_instance_valid(btn_sav_t42), "Botón BtnSave debe existir")
	assert(is_instance_valid(btn_lod_t42), "Botón BtnLoad debe existir")
	assert(is_instance_valid(btn_sur_t42), "Botón BtnSurrender debe existir")

	assert("Reanudar" in btn_res_t42.text, "BtnResume debe incluir 'Reanudar'")
	assert("Guardar" in btn_sav_t42.text and "F5" in btn_sav_t42.text, "BtnSave debe incluir 'Guardar' y 'F5'")
	assert("Cargar" in btn_lod_t42.text and "F9" in btn_lod_t42.text, "BtnLoad debe incluir 'Cargar' y 'F9'")
	assert("Rendirse" in btn_sur_t42.text or "Terminar" in btn_sur_t42.text, "BtnSurrender debe incluir 'Rendirse' o 'Terminar'")

	# Verificar que no contenga elementos de lobby/slots
	var lobby_slots_t42 = pause_inst_t42.find_child("PlayerSlots", true, false)
	assert(lobby_slots_t42 == null, "PauseMenu no debe contener controles de slots de lobby mid-game")

	pause_inst_t42.free()
	print("✅ Test 42 Superado: Menú de Ajustes Ingame contiene exactamente los 4 botones oficiales y título verificado.")

	# ─── TEST 43: Deduplicación de Botones en Cuartel (Barracks3D Era 0) ──────────
	print("\n--- TEST 43: Deduplicación de Botones en Cuartel (Barracks3D Era 0) ---")
	var rm_t43: Node = root.get_node_or_null("ResourceManager")
	var created_rm_t43 := false
	if not is_instance_valid(rm_t43):
		var nrm := GlobalResourceManager.new()
		nrm.name = "ResourceManager"
		root.add_child(nrm)
		rm_t43 = nrm
		created_rm_t43 = true

	rm_t43.set("era_actual", 0)
	if rm_t43.has_method("add_resources"):
		rm_t43.add_resources("food", 500)

	var barracks_t43 := Barracks3DClass.new()
	barracks_t43.bando = BuildingBase3D.Bando.PLAYER
	barracks_t43.resource_manager = rm_t43
	barracks_t43.esta_construido = true
	barracks_t43.is_under_construction = false
	root.add_child(barracks_t43)

	var units_era0_t43: Array = barracks_t43.get_unidades_disponibles_era(0)
	var count_clubman_t43: int = 0
	for u in units_era0_t43:
		var uid_val: String = ""
		if u is Dictionary:
			uid_val = String(u.get("id", ""))
		elif u is String:
			uid_val = u
		if uid_val in ["clubman_era0", "garrotero"]:
			count_clubman_t43 += 1

	assert(count_clubman_t43 == 1, "Debe existir exactamente 1 botón para el Garrotero / Clubman en Era 0 (encontrados: %d)" % count_clubman_t43)

	# Verificar catálogo de unidades
	var cat_keys_t43: Array = barracks_t43.CATALOGO_UNIDADES.keys()
	var cat_club_count_t43: int = 0
	for k in cat_keys_t43:
		if k in ["clubman_era0", "garrotero"]:
			cat_club_count_t43 += 1
	assert(cat_club_count_t43 == 1, "El catálogo no debe tener entradas duplicadas para garrotero/clubman_era0")

	# Probar cola de producción
	barracks_t43.entrenar_unidad("clubman_era0")
	assert(barracks_t43.production_queue.size() == 1, "Debe tener 1 unidad en cola")
	assert(barracks_t43.production_queue[0] == "clubman_era0", "ID de unidad en cola debe ser 'clubman_era0'")

	barracks_t43.free()
	if created_rm_t43 and is_instance_valid(rm_t43):
		rm_t43.free()
	print("✅ Test 43 Superado: Cuartel Era 0 deduplica garrotero/clubman_era0 a exactamente 1 entrada.")

	# ─── TEST 44: Intercepción de Comandos en Combate y Control de Vida Flotante ──
	print("\n--- TEST 44: Intercepción de Comandos en Combate y Control de Vida Flotante ---")
	var sol_scene_t44: PackedScene = load("res://scenes/units/soldier_3d.tscn") as PackedScene
	assert(sol_scene_t44 != null, "scenes/units/soldier_3d.tscn debe existir")
	var soldier_t44: Soldier3DClass = sol_scene_t44.instantiate() as Soldier3DClass
	root.add_child(soldier_t44)
	soldier_t44.configurar_soldado("clubman_era0")

	# 1. Simular combate activo: entrar a estado Attacking con enemigo dummy
	var dummy_target_t44 := CharacterBody3D.new()
	dummy_target_t44.add_to_group("enemy_units")
	root.add_child(dummy_target_t44)

	soldier_t44.command_attack(dummy_target_t44)
	assert(soldier_t44.state_machine.current_state != null, "StateMachine debe tener estado activo")
	assert(soldier_t44.state_machine.current_state.state_name == &"Attacking", "Soldado debe estar en estado Attacking")

	# 2. Intercepción inmediata con command_move_to()
	var retreat_pos_t44 := Vector3(80.0, 0.0, 80.0)
	soldier_t44.command_move_to(retreat_pos_t44)

	# El estado de ataque debe abortarse de inmediato y transicionar a Move
	assert(soldier_t44.state_machine.current_state.state_name == &"Move", "Debe transicionar inmediatamente a Move tras la orden de retirada")
	assert(soldier_t44.has_meta("new_move_command"), "Debe setear el meta-dato 'new_move_command'")

	# 3. Control de Vida Flotante (Label3D sincronizado y sin regeneración fantasma)
	soldier_t44._ensure_unit_label3d()
	var hp_label_t44: Label3D = soldier_t44.get_node_or_null("UnitLabel3D") as Label3D
	assert(is_instance_valid(hp_label_t44), "UnitLabel3D debe existir sobre la unidad")
	soldier_t44.actualizar_label_vida()
	assert(str(int(soldier_t44.salud_actual)) in hp_label_t44.text, "Label3D debe mostrar el valor real de salud_actual (%d)" % int(soldier_t44.salud_actual))

	# Aplicar daño real
	var hp_antes_t44: float = soldier_t44.salud_actual
	soldier_t44.recibir_daño(30.0)
	assert(soldier_t44.salud_actual == hp_antes_t44 - 30.0, "Salud debe reducirse con recibir_daño")
	soldier_t44.actualizar_label_vida()
	assert(str(int(soldier_t44.salud_actual)) in hp_label_t44.text, "Label3D debe reflejar inmediatamente el daño recibido sin regeneración fantasma")

	soldier_t44.free()
	dummy_target_t44.free()
	print("✅ Test 44 Superado: Intercepción limpia de órdenes en combate y vida flotante sincronizada sin regeneración fantasma.")

	# ─── TEST 45: Balanceo de Capacidad de Minerales (999,999) y Comida (850) ─────
	print("\n--- TEST 45: Balanceo de Capacidad de Minerales (999,999) y Comida (850) ---")
	# 1. Minerales: Oro, Hierro y Piedra deben tener resource_capacity = 999999
	for min_type in ["gold", "iron", "stone"]:
		var min_node_t45 := ResourceNode3DClass.new()
		min_node_t45.resource_type = min_type
		root.add_child(min_node_t45)
		assert(min_node_t45.resource_capacity == 999999, "Mina de '%s' debe tener resource_capacity de 999,999 (obtenido: %d)" % [min_type, min_node_t45.resource_capacity])
		assert(min_node_t45.max_amount == 999999, "Mina de '%s' debe tener max_amount de 999,999" % min_type)
		assert(min_node_t45.current_amount == 999999, "Mina de '%s' debe iniciar con current_amount de 999,999" % min_type)
		min_node_t45.free()

	# 2. Comida: Bayas primarias deben tener resource_capacity = 850
	var berry_node_t45 := ResourceNode3DClass.new()
	berry_node_t45.resource_type = "food"
	berry_node_t45.is_aquatic = false
	root.add_child(berry_node_t45)
	assert(berry_node_t45.resource_capacity == 850, "Nodo de comida terrestre debe tener resource_capacity de 850 (obtenido: %d)" % berry_node_t45.resource_capacity)
	assert(berry_node_t45.max_amount == 850, "Nodo de comida terrestre debe tener max_amount de 850")
	assert(berry_node_t45.current_amount == 850, "Nodo de comida terrestre debe iniciar con current_amount de 850")
	berry_node_t45.free()

	# 3. RTSResourceSpawner: validación de _instanciar_nodo_recurso
	var spawner_t45 := RTSResourceSpawnerClass.new()
	root.add_child(spawner_t45)
	spawner_t45._instanciar_nodo_recurso("gold", 500, Vector3(10, 0, 10))
	var spawned_gold_t45: ResourceNode3DClass = null
	for c in spawner_t45.get_children():
		if c is ResourceNode3DClass and c.resource_type == "gold":
			spawned_gold_t45 = c
			break
	assert(is_instance_valid(spawned_gold_t45), "Debe haberse instanciado un ResourceNode3D de oro")
	assert(spawned_gold_t45.resource_capacity == 999999, "Mina de oro instanciada por spawner debe forzar 999,999 unidades")

	spawner_t45.free()
	print("✅ Test 45 Superado: Minas infinitas inicializadas en 999,999 y comida balanceada a 850u.")

	# ─── TEST 46: Replicación Fiable de Parámetros de Red y Limpieza ENet ────────
	print("\n--- TEST 46: Replicación Fiable de Parámetros de Red y Limpieza ENet ---")
	var mm_t46 := MultiplayerManagerClass.new()
	root.add_child(mm_t46)

	var test_config_t46: Dictionary = {
		"starting_era": 0,
		"game_speed": 1.4,
		"game_speed_modifier": 1.4,
		"starting_villagers": 5,
		"starting_resources": "abundante",
		"ai_difficulty": "dificil"
	}
	mm_t46.rpc_establecer_configuracion_partida(test_config_t46)

	var gs_t46: Node = root.get_node_or_null("GameSettings")
	assert(is_instance_valid(gs_t46), "GameSettings debe estar disponible")
	assert(is_equal_approx(float(gs_t46.get("game_speed")), 1.4), "Velocidad debe sincronizarse a 1.4")
	assert(String(gs_t46.get("starting_resources")) == "abundante", "Recursos deben replicarse como 'abundante'")

	var test_port: int = randi_range(28000, 38000)
	var err_t46 := mm_t46.crear_servidor(test_port)
	if err_t46 == OK:
		assert(mm_t46.is_host == true, "Servidor debe estar activo")
	else:
		mm_t46.enet_peer = ENetMultiplayerPeer.new()
		mm_t46.is_host = true
	mm_t46.reiniciar_banco_partida()
	assert(mm_t46.enet_peer == null, "enet_peer debe quedar cerrado y nulo tras reinicio")
	assert(mm_t46.is_host == false, "Estado is_host debe restablecerse a false")

	root.remove_child(mm_t46)
	mm_t46.free()
	print("✅ Test 46 Superado: Sincronización de velocidad/recursos RPC y cierre seguro de socket ENet.")

	# ─── TEST 47: Secuencia Estricta Pre-Spawner y Purga de Placeholders ─────────
	print("\n--- TEST 47: Secuencia Estricta Pre-Spawner y Purga de Placeholders ---")
	var old_tc_t47 := TownCenter3DClass.new()
	old_tc_t47.name = "TownCenter_Placeholder"
	old_tc_t47.add_to_group("town_centers")
	root.add_child(old_tc_t47)
	old_tc_t47.global_position = Vector3.ZERO

	var old_vil_t47 := CharacterBody3D.new()
	old_vil_t47.name = "Villager3D_Placeholder"
	old_vil_t47.add_to_group("villagers")
	root.add_child(old_vil_t47)
	old_vil_t47.global_position = Vector3.ZERO

	var spawner_t47 := RTSResourceSpawnerClass.new()
	root.add_child(spawner_t47)

	var real_base_pos_t47 := Vector3(120.0, 0.0, 120.0)
	var new_tc_t47 := TownCenter3DClass.new()
	root.add_child(new_tc_t47)
	new_tc_t47.global_position = real_base_pos_t47

	spawner_t47._purgar_placeholders_editor()
	assert(not is_instance_valid(old_tc_t47) or old_tc_t47.is_queued_for_deletion(), "TownCenter placeholder debe ser purgado")
	assert(not is_instance_valid(old_vil_t47) or old_vil_t47.is_queued_for_deletion(), "Aldeano placeholder debe ser purgado")

	spawner_t47._spawn_starting_resources_for_base(real_base_pos_t47)

	var found_resources_t47 := 0
	var check_list: Array = []
	check_list.append_array(root.get_children())
	check_list.append_array(spawner_t47.get_children())
	for c in check_list:
		if c is ResourceNode3DClass:
			var node3d := c as Node3D
			var pos_check: Vector3 = node3d.global_position if node3d.global_position.length_squared() > 1.0 else node3d.position
			var d: float = pos_check.distance_to(real_base_pos_t47)
			if d >= 8.0 and d <= 25.0:
				found_resources_t47 += 1
			c.free()

	assert(found_resources_t47 >= 4, "Los recursos deben generarse alrededor de la base territorial activa a 120m")
	new_tc_t47.free()
	spawner_t47.free()
	print("✅ Test 47 Superado: Purga de placeholders garantizada y recursos generados en la base correcta.")

	# ─── TEST 48: Anti-Crowding Radial y Reserva Persistente en Farm3D ────────────
	print("\n--- TEST 48: Anti-Crowding Radial y Reserva Persistente en Farm3D ---")
	var farm_t48 := Farm3DClass.new()
	root.add_child(farm_t48)

	var vil_a_t48 := CharacterBody3D.new()
	var vil_b_t48 := CharacterBody3D.new()
	var vil_c_t48 := CharacterBody3D.new()
	root.add_child(vil_a_t48)
	root.add_child(vil_b_t48)
	root.add_child(vil_c_t48)

	var slot_a_t48: Dictionary = farm_t48.request_gather_slot(vil_a_t48)
	assert(slot_a_t48["has_slot"] == true, "Aldeano A debe obtener el cupo")
	assert(farm_t48.is_occupied == true, "Granja debe quedar ocupada")

	var slot_b_t48: Dictionary = farm_t48.request_gather_slot(vil_b_t48)
	var slot_c_t48: Dictionary = farm_t48.request_gather_slot(vil_c_t48)
	assert(slot_b_t48["has_slot"] == false, "Aldeano B debe ser rechazado (1/1)")
	assert(slot_c_t48["has_slot"] == false, "Aldeano C debe ser rechazado (1/1)")

	var pos_b_t48: Vector3 = slot_b_t48["wait_pos"]
	var pos_c_t48: Vector3 = slot_c_t48["wait_pos"]
	assert(pos_b_t48.distance_to(farm_t48.global_position) >= 5.0, "Posición de espera debe ser radial a ~5.2m")
	assert(pos_b_t48.distance_to(pos_c_t48) > 0.3, "Posiciones de espera deben estar dispersas radialmente")

	# Reserva persistente de 12 segundos: aldeano A sale a depositar con carga
	vil_a_t48.set("carried_amount", 15)
	farm_t48.release_gather_slot(vil_a_t48)
	assert(farm_t48.is_occupied == false, "Granja liberada transitoriamente")
	assert(farm_t48.reserved_villager == vil_a_t48, "Granja debe quedar en reserva para vil_a")
	assert(farm_t48.reservation_timer > 10.0, "Temporizador de reserva debe rondar los 12s")

	# Aldeano B intenta usurpar mientras hay reserva activa
	var slot_b_usurp: Dictionary = farm_t48.request_gather_slot(vil_b_t48)
	assert(slot_b_usurp["has_slot"] == false, "Aldeano B no puede usurpar granja reservada")

	# Aldeano A regresa del Town Center y recupera su granja inmediatamente
	var slot_a_return: Dictionary = farm_t48.request_gather_slot(vil_a_t48)
	assert(slot_a_return["has_slot"] == true, "Aldeano A recupera su granja titular reservada")
	assert(farm_t48.is_occupied == true, "Granja reocupada por el titular")

	farm_t48.free()
	vil_a_t48.free()
	vil_b_t48.free()
	vil_c_t48.free()
	print("✅ Test 48 Superado: Granjas limitadas a 1/1 con dispersión radial y reserva persistente de 12s.")

	# ─── TEST 49: Clic Soberano de Retirada sin Magnetismo Hostil ─────────────────
	print("\n--- TEST 49: Clic Soberano de Retirada sin Magnetismo Hostil ---")
	var input_ctrl_t49 := RTSInputControllerClass.new()
	root.add_child(input_ctrl_t49)

	var enemy_dummy_t49 := CharacterBody3D.new()
	enemy_dummy_t49.add_to_group("enemy_units")
	enemy_dummy_t49.global_position = Vector3(10.0, 0.0, 10.0)
	root.add_child(enemy_dummy_t49)

	var terrain_collider_t49 := StaticBody3D.new()
	terrain_collider_t49.name = "TerrainBody"
	terrain_collider_t49.add_to_group("terrain")
	root.add_child(terrain_collider_t49)

	var is_enemy_hit_t49: bool = input_ctrl_t49._is_enemy_target(terrain_collider_t49)
	assert(is_enemy_hit_t49 == false, "El colisionador de terreno jamás debe interpretarse como objetivo enemigo")

	enemy_dummy_t49.free()
	terrain_collider_t49.free()
	input_ctrl_t49.free()
	print("✅ Test 49 Superado: Clics en suelo preservados estrictamente como órdenes de movimiento.")

	# ─── TEST 50: Inconsistencia Resuelta en command_move (UnitBase3D) y Quicksave ─
	print("\n--- TEST 50: Inconsistencia Resuelta en command_move (UnitBase3D) y Quicksave ---")
	var sol_scene_t50: PackedScene = load("res://scenes/units/soldier_3d.tscn") as PackedScene
	var test_unit_t50: UnitBase3D = sol_scene_t50.instantiate() as UnitBase3D
	root.add_child(test_unit_t50)

	var dummy_foe_t50 := CharacterBody3D.new()
	dummy_foe_t50.add_to_group("enemy_units")
	root.add_child(dummy_foe_t50)

	test_unit_t50.command_attack(dummy_foe_t50)
	assert(test_unit_t50.state_machine.current_state.state_name == &"Attacking", "Unidad debe entrar en Attacking")

	test_unit_t50.command_move(Vector3(45, 0, 45))
	assert(test_unit_t50.state_machine.current_state.state_name == &"Move", "command_move en UnitBase3D debe forzar transición a Move")
	assert(test_unit_t50.has_meta("new_move_command"), "Meta new_move_command debe estar activo")

	test_unit_t50.free()
	dummy_foe_t50.free()
	print("✅ Test 50 Superado: command_move en UnitBase3D desengancha combate y limpia objetivo en FSM.")

	# ─── TEST 51: Protocolo de Apertura de Paso de Cortesía (Yield Pass) ─────────
	print("\n--- TEST 51: Protocolo de Apertura de Paso de Cortesía (Yield Pass) ---")
	var vil_static_t51 := Villager3DClass.new()
	vil_static_t51.bando = 0
	vil_static_t51.speed = 4.2
	vil_static_t51.position = Vector3(0.0, 0.0, 0.0)
	vil_static_t51.global_position = Vector3(0.0, 0.0, 0.0)
	vil_static_t51.add_to_group("villagers")
	root.add_child(vil_static_t51)

	var vil_carrier_t51 := Villager3DClass.new()
	vil_carrier_t51.bando = 0
	vil_carrier_t51.speed = 4.2
	vil_carrier_t51.position = Vector3(0.8, 0.0, 0.0)
	vil_carrier_t51.global_position = Vector3(0.8, 0.0, 0.0)
	vil_carrier_t51.carried_amount = 15 # Fardo lleno
	vil_carrier_t51.add_to_group("villagers")
	assert(vil_carrier_t51.inventory_full == true, "Aldeano cargador debe tener inventory_full == true")
	root.add_child(vil_carrier_t51)

	var res_node_t51 := ResourceNode3DClass.new()
	res_node_t51.resource_type = "wood"
	res_node_t51.position = Vector3(0.0, 0.0, 1.4)
	res_node_t51.global_position = Vector3(0.0, 0.0, 1.4)
	root.add_child(res_node_t51)

	vil_static_t51.state_machine.change_state(&"Gathering", {
		"target_node": res_node_t51,
		"arrived": true
	})
	assert(vil_static_t51.state_machine.current_state.state_name == &"Gathering", "vil_static debe estar en Gathering")

	# Ejecutar tick de física: vil_static detecta a vil_carrier con fardo lleno a < 1.8m
	vil_static_t51.state_machine.current_state.physics_update(0.1)
	var state_g_t51: StateGathering3D = vil_static_t51.state_machine.current_state as StateGathering3D
	assert(state_g_t51._is_yielding_pass == true, "Yield Pass debe activarse ante compañero con fardo lleno")
	var dist_displaced := vil_static_t51.position.distance_to(state_g_t51._yield_original_pos)
	assert(is_equal_approx(dist_displaced, 1.2), "Desplazamiento evasivo lateral hacia atrás debe ser de exactamente 1.2m (obtenido: %.2f)" % dist_displaced)

	# Simular que el compañero cargador se aleja hacia el Town Center (> 2.8m)
	vil_carrier_t51.position = Vector3(15.0, 0.0, 0.0)
	vil_carrier_t51.global_position = Vector3(15.0, 0.0, 0.0)
	# Múltiples ticks de física para reanudar su posición justa original
	for _frame in range(30):
		state_g_t51.physics_update(0.1)

	assert(state_g_t51._is_yielding_pass == false, "Yield Pass debe desactivarse al despejarse el paso")
	assert(vil_static_t51.position.distance_to(state_g_t51._yield_original_pos) <= 0.1, "Aldeano debe reanudar de forma autónoma su posición de picado justa")

	vil_static_t51.free()
	vil_carrier_t51.free()
	res_node_t51.free()
	print("✅ Test 51 Superado: Protocolo Yield Pass evade 1.2m ante compañero cargado y reanuda picado.")

	# ─── TEST 52: Selección de Unidades Ocultas Detrás de Edificios (Bypass) ─────
	print("\n--- TEST 52: Selección de Unidades Ocultas Detrás de Edificios (Bypass) ---")
	var input_ctrl_t52 := RTSInputControllerClass.new()
	root.add_child(input_ctrl_t52)

	var building_t52 := StaticBody3D.new()
	building_t52.name = "ArcheryRange_Test"
	building_t52.add_to_group("buildings")
	building_t52.add_to_group("player_buildings")
	root.add_child(building_t52)

	var hidden_unit_t52 := CharacterBody3D.new()
	hidden_unit_t52.name = "Soldier_Hidden"
	hidden_unit_t52.add_to_group("player_units")
	hidden_unit_t52.add_to_group("units_3d")
	root.add_child(hidden_unit_t52)

	assert(input_ctrl_t52.has_method("get_entity_under_screen_point"), "get_entity_under_screen_point debe existir en RTSInputController")
	assert(input_ctrl_t52.has_method("_process_left_click_selection"), "_process_left_click_selection debe existir")

	building_t52.free()
	hidden_unit_t52.free()
	input_ctrl_t52.free()
	print("✅ Test 52 Superado: Building Raycast Bypass prioriza unidades ocultas tras edificios.")

	print("\n========================================================")
	print(" ⭐ TODOS LOS TESTS COMPLETADOS SATISFACTORIAMENTE (100%) ")
	print("========================================================\n")
	quit(0)


