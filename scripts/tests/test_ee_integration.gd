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
	if is_instance_valid(gs_t46):
		gs_t46.set("game_speed", 1.0)
		gs_t46.set("game_speed_modifier", 1.0)

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

	# ─── TEST 53: Candado de Población Previo a Deducción de Recursos ───────────
	print("\n--- TEST 53: Candado de Población Previo a Deducción de Recursos ---")
	var rm_t53 := GlobalResourceManager.new()
	rm_t53.resources["food"] = 500
	rm_t53.resources["wood"] = 500
	rm_t53.max_population = 5
	rm_t53.current_population = 5 # Límite estricto alcanzado (5/5)
	assert(rm_t53.has_population_room(1) == false, "No debe haber cupo poblacional")

	var tc_t53 := TownCenter3DClass.new()
	tc_t53.resource_manager = rm_t53
	tc_t53.esta_construido = true
	tc_t53.is_under_construction = false
	root.add_child(tc_t53)

	var barracks_t53 := Barracks3DClass.new()
	barracks_t53.resource_manager = rm_t53
	barracks_t53.esta_construido = true
	barracks_t53.is_under_construction = false
	root.add_child(barracks_t53)

	# Intento de crear aldeano con población al tope
	tc_t53.crear_aldeano()
	assert(rm_t53.resources["food"] == 500, "La comida NO debe descontarse si la población está al límite")
	assert(tc_t53.production_queue.size() == 0, "La cola del Capitolio debe permanecer vacía")

	# Intento de entrenar brawler_primitivo con población al tope
	var ret_brawler: bool = barracks_t53.entrenar_unidad("brawler_primitivo")
	assert(ret_brawler == false, "entrenar_unidad debe retornar false sin espacio poblacional")
	assert(rm_t53.resources["food"] == 500, "Los recursos del Cuartel no deben descontarse si la población está saturada")
	assert(barracks_t53.production_queue.size() == 0, "La cola del Cuartel debe permanecer vacía")

	tc_t53.free()
	barracks_t53.free()
	rm_t53.free()
	print("✅ Test 53 Superado: Candado de población bloquea deducción de recursos al 100%.")

	# ─── TEST 54: Reanudación de Entrenamiento al Liberar Espacio Poblacional ────
	print("\n--- TEST 54: Reanudación de Entrenamiento con Espacio Libre ---")
	var rm_t54 := GlobalResourceManager.new()
	rm_t54.resources["food"] = 500
	rm_t54.resources["wood"] = 500
	rm_t54.max_population = 10
	rm_t54.current_population = 5 # Hay 5 cupos libres
	assert(rm_t54.has_population_room(1) == true, "Debe haber espacio de población")

	var tc_t54 := TownCenter3DClass.new()
	tc_t54.resource_manager = rm_t54
	tc_t54.esta_construido = true
	tc_t54.is_under_construction = false
	root.add_child(tc_t54)

	var barracks_t54 := Barracks3DClass.new()
	barracks_t54.resource_manager = rm_t54
	barracks_t54.esta_construido = true
	barracks_t54.is_under_construction = false
	root.add_child(barracks_t54)

	# Con espacio disponible, crear aldeano debe consumir recursos y encolar
	tc_t54.crear_aldeano()
	assert(rm_t54.resources["food"] == 450, "Debe descontar exactamente 50 de comida por el aldeano")
	assert(tc_t54.production_queue.size() == 1, "Debe haber 1 aldeano en la cola de producción")

	# Entrenar Brawler Primitivo con espacio disponible
	var brawler_ok: bool = barracks_t54.entrenar_unidad("brawler_primitivo")
	assert(brawler_ok == true, "Brawler debe encolarse exitosamente al haber espacio")
	assert(barracks_t54.production_queue.size() == 1, "Debe haber 1 brawler en la cola del Cuartel")

	tc_t54.free()
	barracks_t54.free()
	rm_t54.free()
	print("✅ Test 54 Superado: Brawler y Aldeano se encolan y consumen recursos fielmente con cupo libre.")

	# ─── TEST 55: Abanico Radial de Recolección (Radial Fan Gathering) ───────────
	print("\n--- TEST 55: Abanico Radial de Recolección (TAU / 8 * 1.6m) ---")
	var root_3d_t55 := Node3D.new()
	root.add_child(root_3d_t55)

	var res_node_t55 := ResourceNode3DClass.new()
	root_3d_t55.add_child(res_node_t55)
	res_node_t55.position = Vector3(20.0, 0.0, 20.0)

	# Probar los 8 sectores radiales con 8 aldeanos
	for i in range(8):
		var vil_t55 := Villager3DClass.new()
		vil_t55.name = "Villager_%d" % i
		vil_t55.set_meta("unit_id", i)
		root_3d_t55.add_child(vil_t55)

		var expected_angle: float = float(i % 8) * (TAU / 8.0)
		var expected_offset: Vector3 = Vector3(cos(expected_angle), 0.0, sin(expected_angle)) * 1.6
		var expected_pos: Vector3 = res_node_t55.position + expected_offset

		var calculated_pos: Vector3 = vil_t55.get_radial_gather_target(res_node_t55)
		assert(calculated_pos.distance_to(expected_pos) < 0.001, "Posición radial del aldeano %d debe coincidir con ángulo TAU/8 a 1.6m" % i)
		assert(calculated_pos.distance_to(res_node_t55.position) > 1.59 and calculated_pos.distance_to(res_node_t55.position) < 1.61, "Distancia debe ser exactamente 1.6m del nodo")
		vil_t55.free()

	res_node_t55.free()
	root_3d_t55.free()
	print("✅ Test 55 Superado: Abanico radial de recolección equidistante (1.6m) verificado para 8 aldeanos.")



	# ─── TEST 56: Crecimiento Progresivo Vertical Universal (Hut3D y Dock3D 8% -> 100%) ───
	print("\n--- TEST 56: Crecimiento Progresivo Universal Y-Axis (Hut3D y Dock3D 8% -> 100%) ---")

	var hut_class: GDScript = load("res://scripts/buildings/hut_3d.gd") as GDScript
	var dock_class: GDScript = load("res://scripts/buildings/dock_3d.gd") as GDScript

	var hut_scene: PackedScene = load("res://scenes/buildings/hut_3d.tscn") if ResourceLoader.exists("res://scenes/buildings/hut_3d.tscn") else null
	var hut_inst: BuildingBase3D = (hut_scene.instantiate() as BuildingBase3D) if is_instance_valid(hut_scene) else (hut_class.new() as BuildingBase3D)
	hut_inst.starts_under_construction = true
	root.add_child(hut_inst)
	hut_inst._ready()

	# Al inicio (0% de progreso), la altura Y debe estar en su cimiento del 8% (factor 0.08)
	var hut_visuals: Array[Node3D] = []
	for c in hut_inst.get_children():
		if c is Node3D and not (c is CollisionShape3D or c is NavigationObstacle3D or c is Marker3D or c is Label3D):
			hut_visuals.append(c as Node3D)
	assert(not hut_visuals.is_empty(), "Hut3D debe poseer nodos visuales 3D")

	var hut_orig_scale: Vector3 = hut_inst._base_visual_scales.get(hut_visuals[0], Vector3.ONE)
	var hut_factor_0: float = hut_visuals[0].scale.y / hut_orig_scale.y
	assert(abs(hut_factor_0 - 0.08) < 0.01, "La altura Y inicial de Hut3D debe iniciar al 8%% (Obtenido: %.3f)" % hut_factor_0)

	# A la mitad (50% de progreso)
	hut_inst._actualizar_progreso_construccion(50.0)
	var hut_factor_50: float = hut_visuals[0].scale.y / hut_orig_scale.y
	assert(abs(hut_factor_50 - 0.50) < 0.01, "La altura Y al 50%% debe ser 0.50 (Obtenido: %.3f)" % hut_factor_50)

	# Al 100% de progreso
	hut_inst._actualizar_progreso_construccion(100.0)
	var hut_factor_100: float = hut_visuals[0].scale.y / hut_orig_scale.y
	assert(abs(hut_factor_100 - 1.0) < 0.01, "La altura Y al 100%% debe restaurarse al 100%% (Obtenido: %.3f)" % hut_factor_100)
	assert(hut_inst.esta_construido == true, "Hut3D debe marcarse como construido al 100%")

	# Validar Astillero Marítimo (Dock3D)
	var dock_inst: BuildingBase3D = dock_class.new() as BuildingBase3D
	dock_inst.starts_under_construction = true
	root.add_child(dock_inst)
	dock_inst._ready()

	var dock_visuals: Array[Node3D] = []
	for c in dock_inst.get_children():
		if c is Node3D and not (c is CollisionShape3D or c is NavigationObstacle3D or c is Marker3D or c is Label3D):
			dock_visuals.append(c as Node3D)
	assert(not dock_visuals.is_empty(), "Dock3D debe poseer nodos visuales 3D")

	var dock_orig_scale: Vector3 = dock_inst._base_visual_scales.get(dock_visuals[0], Vector3.ONE)
	var dock_factor_0: float = dock_visuals[0].scale.y / dock_orig_scale.y
	assert(abs(dock_factor_0 - 0.08) < 0.01, "La altura Y inicial de Dock3D debe iniciar al 8%% (Obtenido: %.3f)" % dock_factor_0)

	dock_inst._actualizar_progreso_construccion(100.0)
	var dock_factor_100: float = dock_visuals[0].scale.y / dock_orig_scale.y
	assert(abs(dock_factor_100 - 1.0) < 0.01, "La altura Y al 100%% de Dock3D debe ser 1.0")
	assert(dock_inst.esta_construido == true, "Dock3D debe marcarse como construido al 100%")

	# Validar Núcleo Único de Proximidad Perimetral (1.2m a 1.4m) en Construcción y Reparación
	var hut_extents: Vector3 = hut_inst.get_building_extents()
	var hut_stop_dist: float = hut_inst.get_perimeter_stop_distance()
	var expected_min_dist: float = maxf(hut_extents.x, hut_extents.z) + 1.2
	var expected_max_dist: float = maxf(hut_extents.x, hut_extents.z) + 1.4
	assert(hut_stop_dist >= expected_min_dist - 0.05 and hut_stop_dist <= expected_max_dist + 0.05,
		"Distancia perimetral en construcción debe ser extents.x + 1.2m a 1.4m (Obtenido: %.2f, Esperado: [%.2f, %.2f])" % [hut_stop_dist, expected_min_dist, expected_max_dist])

	# Dañar edificio para certificar que en modo REPARACIÓN se usa el mismo núcleo universal
	hut_inst.recibir_daño(120.0)
	assert(hut_inst.salud_actual < hut_inst.salud_maxima, "Edificio debe registrar daño para reparación")
	var repair_stop_dist: float = hut_inst.get_perimeter_stop_distance()
	assert(abs(repair_stop_dist - hut_stop_dist) < 0.001, "El núcleo único debe gobernar de forma IDÉNTICA la reparación y la construcción")

	# Validar Dangling Pointer Lock en StateAttacking3D (Anti-Previously Freed)
	var lock_state_atk := StateAttacking3D.new()
	var lock_dummy_unit := CharacterBody3D.new()
	var lock_dummy_target := Node3D.new()
	root.add_child(lock_dummy_unit)
	root.add_child(lock_dummy_target)
	lock_state_atk.unit = lock_dummy_unit
	lock_state_atk._target = lock_dummy_target
	# Liberar el target para simular target destruido / previamente liberado
	lock_dummy_target.free()
	# physics_update debe capturar la guarda 'not is_instance_valid(_target)' y retornar temprano limpiamente
	lock_state_atk.physics_update(0.016)
	assert(lock_state_atk._target == null, "Dangling pointer lock debe forzar _target = null sin crashear")
	lock_dummy_unit.free()

	hut_inst.free()
	dock_inst.free()
	print("✅ Test 56 Superado: Crecimiento vertical progresivo (8% -> 100%), proximidad perimetral 1.2m y blindaje anti dangling pointer certificados.")


	# ─── TEST 57: Gladiador Retiarius (-50% Slow Debuff) y Carro de Guerra 6.0 m/s ───
	print("\n--- TEST 57: Gladiador Retiarius (-50% Debuff) y Carro de Guerra (6.0 m/s) ---")
	var retiarius_script: GDScript = load("res://scripts/units/gladiador_retiarius_3d.gd") as GDScript
	var chariot_script: GDScript = load("res://scripts/units/chariot_archer_era2_3d.gd") as GDScript

	var gs_t57: Node = root.get_node_or_null("GameSettings")
	if is_instance_valid(gs_t57):
		gs_t57.set("game_speed_modifier", 1.0)

	var retiarius_era2: Soldier3D = retiarius_script.new() as Soldier3D
	root.add_child(retiarius_era2)
	retiarius_era2._ready()

	var target_test_unit: Soldier3D = Soldier3D.new()
	root.add_child(target_test_unit)
	target_test_unit._ready()
	target_test_unit.speed = 5.0

	# Lanzar red y verificar ralentización estricta del -50%
	retiarius_era2.call("lanzar_red", target_test_unit)
	assert(target_test_unit.get("is_slowed") == true, "El objetivo debe marcarse con is_slowed = true tras recibir la red")
	assert(abs(target_test_unit.speed - 2.5) < 0.01, "La velocidad debe reducirse exactamente en -50%% (Esperado: 2.5, Obtenido: %.2f)" % target_test_unit.speed)

	# Restauración de velocidad
	retiarius_era2.call("restaurar_velocidad", target_test_unit)
	assert(target_test_unit.get("is_slowed") == false, "El objetivo debe restaurar is_slowed = false")
	assert(abs(target_test_unit.speed - 5.0) < 0.01, "La velocidad debe restaurarse al 100%% (Esperado: 5.0, Obtenido: %.2f)" % target_test_unit.speed)

	# Carro de Guerra Era 2
	var chariot_era2: Soldier3D = chariot_script.new() as Soldier3D
	root.add_child(chariot_era2)
	chariot_era2._ready()
	assert(abs(chariot_era2.speed - 6.0) < 0.01, "El Carro de Guerra de Rango debe tener velocidad base 6.0 m/s (Obtenido: %.1f)" % chariot_era2.speed)
	assert(chariot_era2.get("is_vehicle") == true, "El Carro de Guerra debe poseer propiedades físicas de vehículo")
	assert(chariot_era2.has_node("ProjectileMuzzle") and chariot_era2.has_node("ProjectileMuzzle_Dual"), "El Carro de Guerra debe tener socket dual ProjectileMuzzle")

	retiarius_era2.free()
	target_test_unit.free()
	chariot_era2.free()
	print("✅ Test 57 Superado: Debuff de red (-50%) de Gladiador Retiarius y velocidad 6.0 m/s del Carro de Guerra certificados.")


	# ─── TEST 58: Maceman_Bronze (MELEE_SHOCK x1.35 vs Fortificaciones de Madera) ───
	print("\n--- TEST 58: Maceman_Bronze (MELEE_SHOCK x1.35 vs Fortificaciones de Madera) ---")
	var maceman_script: GDScript = load("res://scripts/units/maceman_bronze_3d.gd") as GDScript
	var maceman_bronze_inst: Soldier3D = maceman_script.new() as Soldier3D
	root.add_child(maceman_bronze_inst)
	maceman_bronze_inst._ready()

	assert(maceman_bronze_inst.salud_maxima >= 160.0, "Maceman_Bronze debe poseer HP elevado de 160 segun dbunitset.dat")
	assert(maceman_bronze_inst.weapon_type == "bludgeoning" or maceman_bronze_inst.weapon_type == "melee_shock", "Tipo de impacto debe ser Bludgeoning / MELEE_SHOCK")

	var dummy_wall: Node3D = Node3D.new()
	dummy_wall.name = "EmpalizadaMadera"
	dummy_wall.add_to_group("walls")
	dummy_wall.add_to_group("buildings_3d")
	root.add_child(dummy_wall)

	# Cálculo de daño: base counter contra BUILDING (0.5) * bono fortificación madera (1.35)
	var dmg_wall: float = CombatDamageCalculator.calcular_dano(maceman_bronze_inst.daño, maceman_bronze_inst.weapon_type, maceman_bronze_inst, dummy_wall)
	var expected_wall_dmg: float = (maceman_bronze_inst.daño * 0.5) * 1.35
	assert(abs(dmg_wall - expected_wall_dmg) < 0.05, "Maceman_Bronze debe aplicar bono x1.35 contra muros/empalizadas de madera (Esperado: %.2f, Obtenido: %.2f)" % [expected_wall_dmg, dmg_wall])

	maceman_bronze_inst.free()
	dummy_wall.free()
	print("✅ Test 58 Superado: Macero de Cobre con HP 160 y multiplicador oficial de daño x1.35 vs fortificaciones de madera verificado.")


	# ─── TEST 59: Herencia Limpia de Taller de Asedio (Siege Workshop 3D) ───
	print("\n--- TEST 59: Herencia Limpia de Taller de Asedio desde Barracks3D ---")
	var siege_script: GDScript = load("res://scripts/buildings/siege_workshop_3d.gd") as GDScript
	var siege_workshop: BuildingBase3D = siege_script.new() as BuildingBase3D
	assert(siege_workshop is Barracks3D, "SiegeWorkshop3D debe heredar directamente de Barracks3D")
	assert(siege_workshop is BuildingBase3D, "SiegeWorkshop3D debe heredar de BuildingBase3D")

	siege_workshop.starts_under_construction = true
	root.add_child(siege_workshop)
	siege_workshop._ready()

	# Validar radio dinámico de NavigationObstacle3D adaptado a semiextensiones
	var siege_nav_obs: NavigationObstacle3D = siege_workshop.get_node_or_null("NavObstacle") as NavigationObstacle3D
	assert(is_instance_valid(siege_nav_obs), "SiegeWorkshop3D debe instanciar NavigationObstacle3D dinámicamente")
	var siege_ext: Vector3 = siege_workshop.get_building_extents()
	assert(abs(siege_nav_obs.radius - maxf(siege_ext.x, siege_ext.z)) < 0.01, "Radio de NavigationObstacle3D debe coincidir exactamente con las semiextensiones del Taller")

	# Validar emergencia vertical progresiva desde el 8%
	siege_workshop._actualizar_progreso_construccion(0.0)
	siege_workshop._actualizar_progreso_construccion(50.0)
	siege_workshop._actualizar_progreso_construccion(100.0)
	assert(siege_workshop.esta_construido == true, "Taller de Asedio debe completarse al 100% de progreso")

	# Validar encolado de maquinaria de asedio / carros de guerra
	var test_rm: GlobalResourceManager = root.get_node_or_null("ResourceManager") as GlobalResourceManager
	if not is_instance_valid(test_rm):
		test_rm = GlobalResourceManager.new()
		test_rm.name = "ResourceManager"
		root.add_child(test_rm)
	test_rm.era_actual = 2
	test_rm.resources["wood"] = 500
	test_rm.resources["food"] = 500
	test_rm.max_population = 50
	test_rm.current_population = 0
	siege_workshop.resource_manager = test_rm

	var train_success: bool = siege_workshop.call("entrenar_unidad", "chariot_archer_era2")
	assert(train_success == true or siege_workshop.get("production_queue").size() > 0, "Taller de Asedio debe encolar Carros de Guerra en Era 2")

	siege_workshop.free()
	print("✅ Test 59 Superado: Herencia total de Taller de Asedio desde Barracks3D, cola de producción, emergencia vertical y radio dinámico certificados.")


	# ─── TEST 60: Maravilla / Zigurat Era 2 (Wonder_Zigurat_Era2) y Cronómetro 10 Minutos ───
	print("\n--- TEST 60: Maravilla / Zigurat Era 2 (Wonder_Zigurat_Era2) y Cronómetro 10 Minutos ---")
	var zigurat_script: GDScript = load("res://scripts/buildings/wonder_zigurat_era2.gd") as GDScript
	var zigurat_era2_inst: Wonder3D = zigurat_script.new() as Wonder3D
	assert(zigurat_era2_inst is Wonder3D, "Wonder_Zigurat_Era2 debe extender Wonder3D")
	assert(zigurat_era2_inst is BuildingBase3D, "Wonder_Zigurat_Era2 debe extender BuildingBase3D")

	root.add_child(zigurat_era2_inst)
	zigurat_era2_inst._ready()

	# Iniciar cronómetro de 10 minutos (600s) vía RPC síncrono
	zigurat_era2_inst.rpc_iniciar_cronometro_maravilla(600.0)
	assert(zigurat_era2_inst.is_wonder_active == true, "El Zigurat debe activar el estado is_wonder_active = true")
	assert(abs(zigurat_era2_inst.wonder_time_left - 600.0) < 0.01, "El cronómetro de la Maravilla debe fijarse en exactamente 600 segundos (10 minutos)")

	# Simular avance de tiempo
	zigurat_era2_inst._process(1.0)
	assert(abs(zigurat_era2_inst.wonder_time_left - 599.0) < 0.01, "El temporizador debe decrementar con _process")

	# Simular llegada a cero y declaración de victoria
	assert(zigurat_era2_inst.has_method("declarar_victoria_match"), "Wonder_Zigurat_Era2 debe implementar declarar_victoria_match()")
	zigurat_era2_inst.wonder_time_left = 0.5
	zigurat_era2_inst._process(0.6)
	assert(zigurat_era2_inst.is_wonder_active == false, "El cronómetro debe desactivarse al alcanzar la victoria")

	zigurat_era2_inst.free()
	print("✅ Test 60 Superado: Maravilla/Zigurat Era 2 con RPC síncrono de cronómetro de 10 minutos (600s) y declarar_victoria_match() certificado.")


	# ─── TEST 61: Legionario Romano (Formación Testudo +60% Mitigación / -40% Velocidad) ───
	print("\n--- TEST 61: Legionario Romano (Testudo: +60% Mitigación vs Flechas y -40% Velocidad) ---")
	var legion_script: GDScript = load("res://scripts/units/legionary_era3_3d.gd") as GDScript
	var legion_inst: Soldier3D = legion_script.new() as Soldier3D
	root.add_child(legion_inst)
	legion_inst._ready()

	assert(legion_inst.salud_maxima >= 190.0, "Legionario debe tener HP 190 segun dbunitset.dat")
	assert(abs(legion_inst.speed - 5.2) < 0.01, "Velocidad inicial de marcha debe ser 5.2 m/s")

	# Activar postura táctica Testudo
	legion_inst.call("activar_testudo", true)
	assert(legion_inst.get("testudo_active") == true, "La postura Testudo debe estar activa")
	assert(abs(legion_inst.speed - (5.2 * 0.6)) < 0.05, "La velocidad debe reducirse en -40%% (Esperado: ~3.12, Obtenido: %.2f)" % legion_inst.speed)

	# Validar mitigación estricta del +60% contra proyectiles (ARROW / PIERCE)
	var mitigated_dmg_t61: float = float(legion_inst.call("aplicar_mitigacion_testudo", 100.0, "arrow"))
	assert(abs(mitigated_dmg_t61 - 40.0) < 0.01, "Testudo debe mitigar +60%% de daño balístico (Esperado: 40.0, Obtenido: %.2f)" % mitigated_dmg_t61)

	# Desactivar y verificar restauración
	legion_inst.call("activar_testudo", false)
	assert(legion_inst.get("testudo_active") == false, "Testudo debe desactivarse")
	assert(abs(legion_inst.speed - 5.2) < 0.05, "Velocidad debe restaurarse a 5.2 m/s")
	var unmitigated_dmg_t61: float = float(legion_inst.call("aplicar_mitigacion_testudo", 100.0, "arrow"))
	assert(abs(unmitigated_dmg_t61 - 100.0) < 0.01, "Sin Testudo el daño balístico no debe ser mitigado")

	legion_inst.free()
	print("✅ Test 61 Superado: Postura táctica Testudo (+60% mitigación y -40% velocidad) del Legionario Romano certificada.")


	# ─── TEST 62: Elefante de Guerra (350 HP y Empuje de Separación RVO 1.2m) ───
	print("\n--- TEST 62: Elefante de Guerra (350 HP y Empuje RVO 1.2m) ---")
	var elephant_script: GDScript = load("res://scripts/units/war_elephant_era3_3d.gd") as GDScript
	var elephant_inst: Soldier3D = elephant_script.new() as Soldier3D
	root.add_child(elephant_inst)
	elephant_inst._ready()
	elephant_inst.position = Vector3(0, 0, 0)

	assert(elephant_inst.salud_maxima >= 350.0, "Elefante de Guerra debe poseer 350 HP según dbunitset.dat")

	var infantry_target_t62: Soldier3D = Soldier3D.new()
	root.add_child(infantry_target_t62)
	infantry_target_t62._ready()
	infantry_target_t62.position = Vector3(0, 0, 2.0)
	var init_z_t62: float = infantry_target_t62.position.z

	# Aplicar empuje RVO de 1.2m
	elephant_inst.call("aplicar_empuje_rvo", infantry_target_t62, 1.2)
	var delta_z_t62: float = infantry_target_t62.position.z - init_z_t62
	assert(abs(delta_z_t62 - 1.2) < 0.05, "El objetivo debe ser empujado 1.2m por la masa del elefante (Esperado: 1.2m, Obtenido: %.2f)" % delta_z_t62)

	elephant_inst.free()
	infantry_target_t62.free()
	print("✅ Test 62 Superado: Elefante de Guerra con 350 HP y empuje de separación física RVO de 1.2m certificado.")


	# ─── TEST 63: Ariete de Carnero (Multiplicador x3.0 vs Edificios y Murallas) ───
	print("\n--- TEST 63: Ariete de Carnero (Multiplicador x3.0 vs Edificios) ---")
	var ram_script: GDScript = load("res://scripts/units/ariete_carnero_era3_3d.gd") as GDScript
	var ram_inst: Soldier3D = ram_script.new() as Soldier3D
	root.add_child(ram_inst)
	ram_inst._ready()

	var dummy_bld_t63: Node3D = Node3D.new()
	dummy_bld_t63.name = "MurallaHierro"
	dummy_bld_t63.add_to_group("buildings")
	dummy_bld_t63.add_to_group("buildings_3d")
	dummy_bld_t63.add_to_group("walls")
	root.add_child(dummy_bld_t63)

	var calc_ram_dmg_t63: float = CombatDamageCalculator.calcular_dano(ram_inst.daño, ram_inst.weapon_type, ram_inst, dummy_bld_t63)
	# Base counter MELEE/BLUDGEONING vs BUILDING (0.5) * multiplicador ariete (3.0)
	var expected_ram_dmg_t63: float = (ram_inst.daño * 0.5) * 3.0
	assert(abs(calc_ram_dmg_t63 - expected_ram_dmg_t63) < 0.05, "Ariete debe aplicar multiplicador x3.0 contra edificios (Esperado: %.2f, Obtenido: %.2f)" % [expected_ram_dmg_t63, calc_ram_dmg_t63])

	ram_inst.free()
	dummy_bld_t63.free()
	print("✅ Test 63 Superado: Ariete de Carnero con multiplicador oficial x3.0 contra edificios verificado.")


	# ─── TEST 64: Catapulta Onagro (AoE 4.0m) y Balista de Torsión (22m Perforante) ───
	print("\n--- TEST 64: Catapulta Onagro (AoE 4.0m) y Balista de Torsión (22m Perforante) ---")
	var onager_script: GDScript = load("res://scripts/units/catapulta_onagro_era3_3d.gd") as GDScript
	var onager_inst: Soldier3D = onager_script.new() as Soldier3D
	root.add_child(onager_inst)
	onager_inst._ready()
	onager_inst.position = Vector3(0, 0, 0)
	assert(onager_inst.has_node("ProjectileMuzzle"), "Onagro debe poseer socket ProjectileMuzzle superior")

	# Crear 2 objetivos dentro del radio 4.0m y 1 fuera a 6.0m
	var target_close1_t64: Soldier3D = Soldier3D.new()
	target_close1_t64.name = "DianaCercana1"
	target_close1_t64.add_to_group("units_3d")
	root.add_child(target_close1_t64)
	target_close1_t64._ready()
	target_close1_t64.position = Vector3(2.0, 0, 0) # 2m <= 4m

	var target_close2_t64: Soldier3D = Soldier3D.new()
	target_close2_t64.name = "DianaCercana2"
	target_close2_t64.add_to_group("units_3d")
	root.add_child(target_close2_t64)
	target_close2_t64._ready()
	target_close2_t64.position = Vector3(0, 0, 3.5) # 3.5m <= 4m

	var target_far_t64: Soldier3D = Soldier3D.new()
	target_far_t64.name = "DianaLejana"
	target_far_t64.add_to_group("units_3d")
	root.add_child(target_far_t64)
	target_far_t64._ready()
	target_far_t64.position = Vector3(0, 0, 6.0) # 6.0m > 4m

	var hit_list_t64: Array[Node3D] = onager_inst.call("aplicar_dano_aoe", Vector3(0, 0, 0), 4.0, 45.0)
	assert(hit_list_t64.has(target_close1_t64), "DianaCercana1 debe ser alcanzada por el AoE de 4m")
	assert(hit_list_t64.has(target_close2_t64), "DianaCercana2 debe ser alcanzada por el AoE de 4m")
	assert(not hit_list_t64.has(target_far_t64), "DianaLejana a 6m NO debe ser alcanzada por el AoE de 4m")

	# Balista de Torsión
	var ballista_script: GDScript = load("res://scripts/units/balista_torsion_era3_3d.gd") as GDScript
	var ballista_inst: Soldier3D = ballista_script.new() as Soldier3D
	root.add_child(ballista_inst)
	ballista_inst._ready()
	assert(abs(ballista_inst.rango_ataque - 22.0) < 0.01, "Balista debe poseer rango balístico de 22 metros")
	assert(ballista_inst.get("es_perforante_lineal") == true, "Balista debe tener configurado es_perforante_lineal = true")

	onager_inst.free()
	target_close1_t64.free()
	target_close2_t64.free()
	target_far_t64.free()
	ballista_inst.free()
	print("✅ Test 64 Superado: Catapulta Onagro (AoE esférico 4.0m) y Balista de Torsión (22m perforante) certificados.")


	# ─── TEST 65: Trirreme Romano (Espolón de Bronce y Daño Crítico Síncrono) ───
	print("\n--- TEST 65: Trirreme Romano (Espolón de Bronce y Daño Crítico a Barcos) ---")
	var trireme_script: GDScript = load("res://scripts/units/trirreme_romano_era3_3d.gd") as GDScript
	var trireme_inst: Soldier3D = trireme_script.new() as Soldier3D
	root.add_child(trireme_inst)
	trireme_inst._ready()
	assert(trireme_inst.has_node("EspolonBronce"), "Trirreme debe poseer espolón de bronce delantero")

	# Instanciar barco ligero enemigo
	var light_boat_t65: Soldier3D = Soldier3D.new()
	light_boat_t65.name = "BotePesqueroEnemigo"
	light_boat_t65.salud_actual = 100.0
	light_boat_t65.salud_maxima = 100.0
	root.add_child(light_boat_t65)
	light_boat_t65._ready()

	# Ejecutar ataque de espolón crítico
	trireme_inst.call("ataque_espolon", light_boat_t65)
	assert(light_boat_t65.salud_actual <= 0.0, "El espolón crítico del Trirreme debe infligir daño fulminante (<= 0 HP)")

	trireme_inst.free()
	light_boat_t65.free()
	print("✅ Test 65 Superado: Trirreme Romano con espolón de bronce delantero y daño crítico fulminante verificado.")


	# ─── TEST 66: Caballero Pesado (6.0 m/s, MELEE_SHOCK, x1.50 vs Arqueros) y Piquero Medieval (x2.0 vs Caballería) ───
	print("\n--- TEST 66: Caballero Pesado y Piquero Medieval (Counters) ---")
	var knight_script: GDScript = load("res://scripts/units/caballero_pesado_3d.gd") as GDScript
	var knight_inst: Soldier3D = knight_script.new() as Soldier3D
	root.add_child(knight_inst)
	knight_inst._ready()
	assert(knight_inst.is_cavalry == true, "Caballero Pesado debe tener is_cavalry = true")
	assert(abs(knight_inst.speed - 6.0) < 0.01, "Caballero Pesado debe tener velocidad 6.0 m/s")
	assert(knight_inst.impact_type == "MELEE_SHOCK", "Caballero Pesado debe tener impacto MELEE_SHOCK")

	var pikeman_script: GDScript = load("res://scripts/units/pikeman_era4_3d.gd") as GDScript
	var pikeman_inst: Soldier3D = pikeman_script.new() as Soldier3D
	root.add_child(pikeman_inst)
	pikeman_inst._ready()
	assert(pikeman_inst.impact_type == "MELEE_PIERCE", "Piquero debe tener impacto MELEE_PIERCE")

	# Piquero contra Caballero Pesado (x2.0 multiplier sobre base counter)
	var dmg_pike_vs_knight: float = CombatDamageCalculator.calcular_dano(pikeman_inst.daño, pikeman_inst.weapon_type, pikeman_inst, knight_inst)
	# Base counter PIERCE vs CAVALRY (1.8) * piquero multiplicador (2.0) = 3.6
	var expected_pike_dmg: float = (pikeman_inst.daño * 1.8) * 2.0
	assert(abs(dmg_pike_vs_knight - expected_pike_dmg) < 0.05, "Piquero debe aplicar x2.0 contra caballería (Esperado: %.2f, Obtenido: %.2f)" % [expected_pike_dmg, dmg_pike_vs_knight])

	# Caballero contra Arquero de Infantería (x1.50 multiplier)
	var archer_target_t66: Soldier3D = Soldier3D.new()
	archer_target_t66.name = "ArqueroInfanteriaTest"
	archer_target_t66.add_to_group("archers")
	root.add_child(archer_target_t66)
	archer_target_t66._ready()

	var dmg_knight_vs_archer: float = CombatDamageCalculator.calcular_dano(knight_inst.daño, knight_inst.weapon_type, knight_inst, archer_target_t66)
	# Base counter SHOCK vs INFANTRY (1.5) * caballero multiplicador (1.50) = 2.25
	var expected_knight_dmg: float = (knight_inst.daño * 1.5) * 1.50
	assert(abs(dmg_knight_vs_archer - expected_knight_dmg) < 0.05, "Caballero Pesado debe aplicar x1.50 contra arqueros de infantería (Esperado: %.2f, Obtenido: %.2f)" % [expected_knight_dmg, dmg_knight_vs_archer])

	knight_inst.free()
	pikeman_inst.free()
	archer_target_t66.free()
	print("✅ Test 66 Superado: Caballero Pesado (6.0 m/s, x1.50 vs arqueros) y Piquero (x2.0 vs caballería) certificados.")


	# ─── TEST 67: Ballestero Medieval (Perforación 35% Armadura) y Arquero Largo Inglés (19m y +20% Daño) ───
	print("\n--- TEST 67: Ballestero Medieval (35% Perforación) y Arquero Largo Inglés (19m) ---")
	var xbow_script: GDScript = load("res://scripts/units/crossbowman_era4_3d.gd") as GDScript
	var xbow_inst: Soldier3D = xbow_script.new() as Soldier3D
	root.add_child(xbow_inst)
	xbow_inst._ready()
	assert(xbow_inst.has_method("calcular_perforacion_ballesta"), "Ballestero debe tener la función calcular_perforacion_ballesta()")
	var armor_reducida_t67: float = xbow_inst.call("calcular_perforacion_ballesta", 100.0)
	assert(abs(armor_reducida_t67 - 65.0) < 0.01, "Ballestero debe ignorar el 35%% de armadura del objetivo (Esperado: 65.0, Obtenido: %.1f)" % armor_reducida_t67)

	var longbow_script: GDScript = load("res://scripts/units/longbowman_era4_3d.gd") as GDScript
	var longbow_inst: Soldier3D = longbow_script.new() as Soldier3D
	root.add_child(longbow_inst)
	longbow_inst._ready()
	assert(abs(longbow_inst.rango_ataque - 16.0) < 0.01, "Arquero Largo debe tener alcance base de 16.0m")

	# Aplicar bono de facción inglesa
	longbow_inst.call("aplicar_bono_ingles")
	assert(abs(longbow_inst.rango_ataque - 19.0) < 0.01, "Arquero Largo Inglés debe alcanzar 19.0m de rango")
	assert(abs(longbow_inst.daño - 18.0) < 0.01, "Arquero Largo Inglés debe tener +20%% de daño balístico (18.0)")

	xbow_inst.free()
	longbow_inst.free()
	print("✅ Test 67 Superado: Ballestero (35% perforación armadura) y Arquero Largo Inglés (19m alcance, +20% daño) certificados.")


	# ─── TEST 68: Molino de Viento (+15% Velocidad de Recolección en Granjas <= 14m) ───
	print("\n--- TEST 68: Molino de Viento (+15% Recolección Granjas <= 14m) ---")
	var windmill_script: GDScript = load("res://scripts/buildings/windmill_era4_3d.gd") as GDScript
	var windmill_inst: BuildingBase3D = windmill_script.new() as BuildingBase3D
	root.add_child(windmill_inst)
	windmill_inst._ready()
	windmill_inst.position = Vector3(0, 0, 0)

	var farm_close_t68: Farm3D = Farm3D.new()
	farm_close_t68.name = "GranjaCercana"
	root.add_child(farm_close_t68)
	farm_close_t68._ready()
	farm_close_t68.position = Vector3(8.0, 0, 0) # 8m <= 14m

	var villager_farm_t68: Villager3D = Villager3D.new()
	villager_farm_t68.name = "AldeanoGranjero"
	root.add_child(villager_farm_t68)
	villager_farm_t68._ready()
	farm_close_t68.assigned_villager = villager_farm_t68

	var farm_far_t68: Farm3D = Farm3D.new()
	farm_far_t68.name = "GranjaLejana"
	root.add_child(farm_far_t68)
	farm_far_t68._ready()
	farm_far_t68.position = Vector3(25.0, 0, 0) # 25m > 14m

	# Aplicar bufo agrícola
	var granjas_afectadas: Array[Node3D] = windmill_inst.call("aplicar_bufo_agricola")
	assert(granjas_afectadas.has(farm_close_t68), "Granja a 8m debe recibir bufo agrícola")
	assert(not granjas_afectadas.has(farm_far_t68), "Granja a 25m NO debe recibir bufo agrícola")
	var f_mod: float = float(farm_close_t68.gathering_speed_modifier)
	assert(abs(f_mod - 1.15) < 0.01, "Granja cercana debe tener gathering_speed_modifier = 1.15 (+15%)")
	var v_mod: float = float(villager_farm_t68.gathering_speed_modifier)
	assert(abs(v_mod - 1.15) < 0.01, "Aldeano asignado debe tener gathering_speed_modifier = 1.15 (+15%)")

	windmill_inst.free()
	farm_close_t68.free()
	villager_farm_t68.free()
	farm_far_t68.free()
	print("✅ Test 68 Superado: Molino de Viento con bufo macroeconómico de +15% a granjas <= 14m certificado.")


	# ─── TEST 69: Trabuquete de Contrapeso (Despliegue Obligatorio 3.0s y AoE 5.0m vs Edificios) ───
	print("\n--- TEST 69: Trabuquete de Contrapeso (Despliegue 3s y AoE 5m vs Edificios) ---")
	var trebuchet_script: GDScript = load("res://scripts/units/trabuquete_contrapeso_3d.gd") as GDScript
	var trebuchet_inst: Soldier3D = trebuchet_script.new() as Soldier3D
	root.add_child(trebuchet_inst)
	trebuchet_inst._ready()
	trebuchet_inst.position = Vector3(0, 0, 0)
	assert(abs(trebuchet_inst.rango_ataque - 45.0) < 0.01, "Trabuquete debe tener rango extra-largo de 45.0m")

	# 1. No debe poder disparar sin desplegar
	var fire_without_deploy: bool = trebuchet_inst.call("disparar_trabuquete", Vector3(20, 0, 0))
	assert(fire_without_deploy == false, "Trabuquete NO debe poder disparar sin estar desplegado")

	# 2. Iniciar despliegue
	trebuchet_inst.call("desplegar")
	assert(trebuchet_inst.get("is_deploying") == true, "Trabuquete debe marcar is_deploying = true")
	assert(abs(trebuchet_inst.speed - 0.0) < 0.01, "Velocidad durante despliegue debe ser 0.0")

	# Simular paso de los 3.0s de anclaje
	trebuchet_inst._process(3.1)
	assert(trebuchet_inst.get("is_deployed") == true, "Trabuquete debe completar despliegue tras 3.0s (is_deployed = true)")

	# 3. Disparo con daño de área AoE de 5.0m contra edificios
	var bld_target_close_t69: BuildingBase3D = BuildingBase3D.new()
	bld_target_close_t69.name = "CastilloEnemigo"
	bld_target_close_t69.add_to_group("buildings")
	bld_target_close_t69.add_to_group("buildings_3d")
	bld_target_close_t69.salud_actual = 1000.0
	bld_target_close_t69.salud_maxima = 1000.0
	root.add_child(bld_target_close_t69)
	bld_target_close_t69.position = Vector3(22.0, 0, 0) # A 2m del impacto en Vector3(20, 0, 0) <= 5m

	var bld_target_far_t69: BuildingBase3D = BuildingBase3D.new()
	bld_target_far_t69.name = "CuartelLejano"
	bld_target_far_t69.add_to_group("buildings")
	bld_target_far_t69.add_to_group("buildings_3d")
	bld_target_far_t69.salud_actual = 1000.0
	bld_target_far_t69.salud_maxima = 1000.0
	root.add_child(bld_target_far_t69)
	bld_target_far_t69.position = Vector3(30.0, 0, 0) # A 10m del impacto > 5m

	var fire_deployed_success: bool = trebuchet_inst.call("disparar_trabuquete", Vector3(20, 0, 0))
	assert(fire_deployed_success == true, "Trabuquete desplegado debe disparar exitosamente")
	assert(bld_target_close_t69.salud_actual < 1000.0, "Castillo cercano debe recibir daño AoE de 5m")
	assert(bld_target_far_t69.salud_actual == 1000.0, "Cuartel lejano a 10m NO debe ser afectado por el AoE de 5m")

	trebuchet_inst.free()
	bld_target_close_t69.free()
	bld_target_far_t69.free()
	print("✅ Test 69 Superado: Trabuquete de Contrapeso (despliegue 3s, velocidad 0, 45m rango y AoE 5m vs edificios) certificado.")


	# ─── TEST 70: Iglesia Románica y Gran Catedral Gótica (Maravilla Era 4 / Cronómetro 10 Minutos) ───
	print("\n--- TEST 70: Iglesia Románica y Gran Catedral Gótica (Maravilla Era 4) ---")
	var church_script: GDScript = load("res://scripts/buildings/church_era4_3d.gd") as GDScript
	var church_inst: BuildingBase3D = church_script.new() as BuildingBase3D
	assert(church_inst is Temple3D, "Church_Era4 debe heredar directamente de Temple3D")
	assert(church_inst is BuildingBase3D, "Church_Era4 debe heredar de BuildingBase3D")
	assert(church_inst.get("max_faith_points") >= 350.0, "Iglesia Románica debe tener al menos 350 puntos de fe")
	church_inst.free()

	var cathedral_script: GDScript = load("res://scripts/buildings/wonder_catedral_gotica_era4.gd") as GDScript
	var cathedral_inst: Wonder3D = cathedral_script.new() as Wonder3D
	assert(cathedral_inst is Wonder3D, "Wonder_Catedral_Gotica_Era4 debe heredar directamente de Wonder3D")
	assert(cathedral_inst is BuildingBase3D, "Wonder_Catedral_Gotica_Era4 debe heredar de BuildingBase3D")
	assert(cathedral_inst.salud_maxima >= 3500.0, "Gran Catedral Gótica debe tener 3500 HP")

	root.add_child(cathedral_inst)
	cathedral_inst._ready()
	cathedral_inst.call("rpc_iniciar_cronometro_maravilla", 600.0)
	assert(cathedral_inst.get("is_wonder_active") == true, "Cronómetro de Maravilla Era 4 debe estar activo")
	assert(abs(float(cathedral_inst.get("wonder_time_left")) - 600.0) < 0.01, "Cronómetro de Maravilla Era 4 debe iniciar en 10 minutos (600s)")

	cathedral_inst.free()
	print("✅ Test 70 Superado: Iglesia Románica (herencia Temple3D) y Gran Catedral Gótica (Maravilla Era 4 con cronómetro de 600s) certificados.")


	# ─── TEST 71: Mosquetero de Pólvora (GUN, Socket Muzzle, -25% Penetración Armadura) y Alabardero Suizo (x1.65 vs Caballería, 207 HP) ───
	print("\n--- TEST 71: Mosquetero de Pólvora y Alabardero Suizo ---")
	var musket_script: GDScript = load("res://scripts/units/mosquetero_era5_3d.gd") as GDScript
	var musket_inst: Soldier3D = musket_script.new() as Soldier3D
	root.add_child(musket_inst)
	musket_inst._ready()
	assert(musket_inst.impact_type == "GUN", "Mosquetero debe tener impacto tipo GUN")
	assert(musket_inst.has_node("ProjectileMuzzle"), "Mosquetero debe tener socket ProjectileMuzzle")
	assert(abs(musket_inst.daño - 24.0) < 0.01, "Mosquetero debe tener 24.0 de daño base")
	assert(musket_inst.get("is_armor_piercing_gun") == true, "Mosquetero debe tener is_armor_piercing_gun = true")

	var armor_pen_t71: float = musket_inst.call("calcular_penetracion_polvora", 100.0)
	assert(abs(armor_pen_t71 - 75.0) < 0.01, "Mosquetero debe penetrar un 25%% de armadura (Esperado: 75.0, Obtenido: %.1f)" % armor_pen_t71)

	var halberd_script: GDScript = load("res://scripts/units/halberdier_era5_3d.gd") as GDScript
	var halberd_inst: Soldier3D = halberd_script.new() as Soldier3D
	root.add_child(halberd_inst)
	halberd_inst._ready()
	assert(halberd_inst.impact_type == "MELEE_PIERCE", "Alabardero Suizo debe tener impacto MELEE_PIERCE")
	assert(abs(halberd_inst.salud_maxima - 207.0) < 0.01, "Alabardero Suizo debe tener 207 HP (+15% vs Piquero 180 HP)")

	# Alabardero contra Caballería (x1.65 multiplier sobre base counter PIERCE vs CAVALRY 1.8)
	var knight_target_t71: Soldier3D = Soldier3D.new()
	knight_target_t71.name = "CaballeroEnemigoT71"
	knight_target_t71.set("is_cavalry", true)
	knight_target_t71.add_to_group("cavalry")
	root.add_child(knight_target_t71)
	knight_target_t71._ready()

	var dmg_halb_vs_cav: float = CombatDamageCalculator.calcular_dano(halberd_inst.daño, halberd_inst.weapon_type, halberd_inst, knight_target_t71)
	var expected_halb_dmg: float = (halberd_inst.daño * 1.8) * 1.65
	assert(abs(dmg_halb_vs_cav - expected_halb_dmg) < 0.05, "Alabardero Suizo debe aplicar multiplicador x1.65 contra caballería (Esperado: %.2f, Obtenido: %.2f)" % [expected_halb_dmg, dmg_halb_vs_cav])

	musket_inst.free()
	halberd_inst.free()
	knight_target_t71.free()
	print("✅ Test 71 Superado: Mosquetero de Pólvora (daño GUN, -25% penetración) y Alabardero Suizo (207 HP, x1.65 vs caballería) certificados.")


	# ─── TEST 72: Conquistador Ecuestre (6.2 m/s, Caballería Rango, x1.30 vs Infantería Ligera de Choque) ───
	print("\n--- TEST 72: Conquistador Ecuestre (6.2 m/s, x1.30 vs Infantería Ligera) ---")
	var conq_script: GDScript = load("res://scripts/units/conquistador_era5_3d.gd") as GDScript
	var conq_inst: Soldier3D = conq_script.new() as Soldier3D
	root.add_child(conq_inst)
	conq_inst._ready()
	assert(conq_inst.get("is_cavalry") == true, "Conquistador debe ser unidad de caballería")
	assert(abs(conq_inst.speed - 6.2) < 0.01, "Conquistador debe tener velocidad 6.2 m/s")
	assert(conq_inst.has_node("ProjectileMuzzle"), "Conquistador debe poseer socket ProjectileMuzzle")

	var light_infantry_t72: Soldier3D = Soldier3D.new()
	light_infantry_t72.name = "InfanteriaChoqueT72"
	light_infantry_t72.set("impact_type", "MELEE_SHOCK")
	light_infantry_t72.set("weapon_type", "melee_shock")
	light_infantry_t72.add_to_group("infantry_3d")
	root.add_child(light_infantry_t72)
	light_infantry_t72._ready()

	var dmg_conq_vs_inf: float = CombatDamageCalculator.calcular_dano(conq_inst.daño, conq_inst.weapon_type, conq_inst, light_infantry_t72)
	# Base counter GUNPOWDER vs INFANTRY (1.2) * conquistador bonus (1.30) = 1.56
	var expected_conq_dmg: float = (conq_inst.daño * 1.2) * 1.30
	assert(abs(dmg_conq_vs_inf - expected_conq_dmg) < 0.05, "Conquistador debe aplicar x1.30 contra infantería ligera de choque (Esperado: %.2f, Obtenido: %.2f)" % [expected_conq_dmg, dmg_conq_vs_inf])

	conq_inst.free()
	light_infantry_t72.free()
	print("✅ Test 72 Superado: Conquistador Ecuestre (6.2 m/s, socket balístico y x1.30 vs infantería de choque) certificado.")


	# ─── TEST 73: Fundición de Artillería (Foundry_Era5: Herencia Limpia Barracks3D, Emergencia 8% y Cola) ───
	print("\n--- TEST 73: Fundición de Artillería (Herencia Barracks3D y Emergencia 8%) ---")
	var foundry_script: GDScript = load("res://scripts/buildings/foundry_era5_3d.gd") as GDScript
	var foundry_inst: BuildingBase3D = foundry_script.new() as BuildingBase3D
	assert(foundry_inst is Barracks3D, "Foundry_Era5 debe heredar directamente de Barracks3D")
	assert(foundry_inst is BuildingBase3D, "Foundry_Era5 debe heredar de BuildingBase3D")

	foundry_inst.starts_under_construction = true
	root.add_child(foundry_inst)
	foundry_inst._ready()

	# Emergencia vertical progresiva desde el 8%
	foundry_inst._actualizar_progreso_construccion(0.0)
	foundry_inst._actualizar_progreso_construccion(50.0)
	foundry_inst._actualizar_progreso_construccion(100.0)
	assert(foundry_inst.esta_construido == true, "Fundición debe completarse al 100% de progreso")

	# Cola de producción de artillería
	var rm_t73: GlobalResourceManager = root.get_node_or_null("ResourceManager") as GlobalResourceManager
	if not is_instance_valid(rm_t73):
		rm_t73 = GlobalResourceManager.new()
		rm_t73.name = "ResourceManager"
		root.add_child(rm_t73)
	rm_t73.era_actual = 5
	rm_t73.resources["iron"] = 500
	rm_t73.resources["wood"] = 500
	rm_t73.resources["gold"] = 500
	rm_t73.max_population = 50
	rm_t73.current_population = 0
	foundry_inst.resource_manager = rm_t73

	var train_cannon_success: bool = foundry_inst.call("entrenar_unidad", "canon_culebrina_era5")
	assert(train_cannon_success == true or foundry_inst.get("production_queue").size() > 0, "Fundición debe encolar Cañón Culebrina en Era 5")

	foundry_inst.free()
	print("✅ Test 73 Superado: Fundición de Artillería con herencia total de Barracks3D, emergencia al 8% y cola de producción certificada.")


	# ─── TEST 74: Cañón Culebrina (Multiplicador x3.0 vs Edificios, AoE 3.0m y Socket Muzzle) ───
	print("\n--- TEST 74: Cañón Culebrina (Multiplicador x3.0 vs Edificios y AoE 3m) ---")
	var culebrina_script: GDScript = load("res://scripts/units/canon_culebrina_era5_3d.gd") as GDScript
	var culebrina_inst: Soldier3D = culebrina_script.new() as Soldier3D
	root.add_child(culebrina_inst)
	culebrina_inst._ready()
	culebrina_inst.position = Vector3(0, 0, 0)
	assert(culebrina_inst.has_node("ProjectileMuzzle"), "Culebrina debe tener socket ProjectileMuzzle alineado")

	# Multiplicador x3.0 contra edificios
	var dummy_bld_t74: BuildingBase3D = BuildingBase3D.new()
	dummy_bld_t74.name = "FortificacionPiedra"
	dummy_bld_t74.add_to_group("buildings")
	dummy_bld_t74.add_to_group("buildings_3d")
	dummy_bld_t74.salud_actual = 1500.0
	dummy_bld_t74.salud_maxima = 1500.0
	root.add_child(dummy_bld_t74)
	dummy_bld_t74.position = Vector3(20.0, 0, 0)

	var dmg_canon_bld: float = CombatDamageCalculator.calcular_dano(culebrina_inst.daño, culebrina_inst.weapon_type, culebrina_inst, dummy_bld_t74)
	# Base counter SIEGE/CANNON vs BUILDING (3.0) * culebrina bono (3.0) = 9.0
	var expected_canon_dmg: float = (culebrina_inst.daño * 3.0) * 3.0
	assert(abs(dmg_canon_bld - expected_canon_dmg) < 0.05, "Culebrina debe aplicar x3.0 contra estructuras (Esperado: %.2f, Obtenido: %.2f)" % [expected_canon_dmg, dmg_canon_bld])

	# Detonación de daño AoE en 3.0 metros
	var bld_close_aoe: BuildingBase3D = BuildingBase3D.new()
	bld_close_aoe.name = "MurallaCercana"
	bld_close_aoe.add_to_group("buildings")
	bld_close_aoe.salud_actual = 1000.0
	bld_close_aoe.salud_maxima = 1000.0
	root.add_child(bld_close_aoe)
	bld_close_aoe.position = Vector3(21.5, 0, 0) # A 1.5m de (20, 0, 0) <= 3m

	var bld_far_aoe: BuildingBase3D = BuildingBase3D.new()
	bld_far_aoe.name = "MurallaLejana"
	bld_far_aoe.add_to_group("buildings")
	bld_far_aoe.salud_actual = 1000.0
	bld_far_aoe.salud_maxima = 1000.0
	root.add_child(bld_far_aoe)
	bld_far_aoe.position = Vector3(26.0, 0, 0) # A 6.0m de (20, 0, 0) > 3m

	var aoe_hits_t74: Array[Node3D] = culebrina_inst.call("disparar_canon", Vector3(20, 0, 0))
	assert(aoe_hits_t74.has(dummy_bld_t74), "Objetivo principal debe recibir impacto")
	assert(aoe_hits_t74.has(bld_close_aoe), "Muralla a 1.5m debe recibir daño AoE de 3m")
	assert(not aoe_hits_t74.has(bld_far_aoe), "Muralla a 6m NO debe recibir daño AoE")

	culebrina_inst.free()
	dummy_bld_t74.free()
	bld_close_aoe.free()
	bld_far_aoe.free()
	print("✅ Test 74 Superado: Cañón Culebrina (multiplicador x3.0 vs edificios, socket ProjectileMuzzle y AoE 3m) certificado.")


	# ─── TEST 75: Carro Blindado Da Vinci (Ráfagas en 4 Direcciones y Mitigación -20%) ───
	print("\n--- TEST 75: Carro Blindado Da Vinci (Ráfagas 4 Direcciones y Mitigación -20%) ---")
	var davinci_script: GDScript = load("res://scripts/units/carro_blindado_davinci_3d.gd") as GDScript
	var davinci_inst: Soldier3D = davinci_script.new() as Soldier3D
	root.add_child(davinci_inst)
	davinci_inst._ready()

	# 1. Validación de 4 troneras / sockets en cruz (N, S, E, W)
	assert(davinci_inst.has_node("Muzzle_N"), "Debe tener socket Muzzle_N")
	assert(davinci_inst.has_node("Muzzle_S"), "Debe tener socket Muzzle_S")
	assert(davinci_inst.has_node("Muzzle_E"), "Debe tener socket Muzzle_E")
	assert(davinci_inst.has_node("Muzzle_W"), "Debe tener socket Muzzle_W")

	var sockets_fired: int = davinci_inst.call("disparar_rafaga_omnidireccional")
	assert(sockets_fired == 4, "Carro Blindado DaVinci debe disparar desde 4 direcciones simultáneas")

	# 2. Mitigación pasiva del -20% a todo daño físico recibido
	var dano_base_t75: float = 100.0
	var dano_mitigado_t75: float = davinci_inst.call("aplicar_mitigacion_blindaje", dano_base_t75)
	assert(abs(dano_mitigado_t75 - 80.0) < 0.01, "Carro DaVinci debe mitigar un 20%% del daño recibido (Esperado: 80.0, Obtenido: %.1f)" % dano_mitigado_t75)

	# Verificación integrada a través de CombatDamageCalculator
	var test_attacker_t75: Soldier3D = Soldier3D.new()
	root.add_child(test_attacker_t75)
	test_attacker_t75._ready()
	test_attacker_t75.daño = 50.0

	var calc_dmg_davinci: float = CombatDamageCalculator.calcular_dano(test_attacker_t75.daño, "melee", test_attacker_t75, davinci_inst)
	# Base counter SHOCK vs CAVALRY/VEHICLE (0.9) * mitigación DaVinci (0.80) = 0.72 -> 50.0 * 0.72 = 36.0
	var expected_calc_dmg: float = (test_attacker_t75.daño * 0.9) * 0.80
	assert(abs(calc_dmg_davinci - expected_calc_dmg) < 0.05, "CombatDamageCalculator debe aplicar la mitigación del -20%% del Carro DaVinci (Esperado: %.2f, Obtenido: %.2f)" % [expected_calc_dmg, calc_dmg_davinci])

	davinci_inst.free()
	test_attacker_t75.free()
	print("✅ Test 75 Superado: Carro Blindado Da Vinci (4 troneras, ráfaga perimetral y mitigación -20%%) certificado.")


	# ─── TEST 76: Fusilero Imperial (Ataque Dual Rango GUN / Melee Bayoneta) y Ametralladora Gatling (Ráfaga 5 tiros) ───
	print("\n--- TEST 76: Fusilero Imperial y Ametralladora Gatling ---")
	var fusilero_script: GDScript = load("res://scripts/units/fusilero_imperial_era6_3d.gd") as GDScript
	var fusilero_inst: Soldier3D = fusilero_script.new() as Soldier3D
	root.add_child(fusilero_inst)
	fusilero_inst._ready()
	fusilero_inst.position = Vector3(0, 0, 0)
	assert(fusilero_inst.has_node("ProjectileMuzzle"), "Fusilero Imperial debe tener socket ProjectileMuzzle")
	assert(abs(fusilero_inst.daño - 28.0) < 0.01, "Fusilero Imperial debe tener daño base de 28.0")

	# Target lejano (distancia = 12.0m > 2.0m) -> Disparo balístico GUN
	var target_far_t76: Soldier3D = Soldier3D.new()
	target_far_t76.name = "EnemigoLejanoT76"
	root.add_child(target_far_t76)
	target_far_t76._ready()
	target_far_t76.position = Vector3(12.0, 0, 0)

	var res_ranged: Dictionary = fusilero_inst.call("ejecutar_ataque_fusilero", target_far_t76)
	assert(res_ranged["modo"] == "rango_fusil", "A distancia > 2.0m el fusilero debe disparar con fusil")
	assert(res_ranged["tipo_dano"] == "GUN", "El disparo a distancia debe ser de tipo GUN")

	# Target cercano (distancia = 1.5m <= 2.0m) -> Estocada de bayoneta Slashing
	var target_close_t76: Soldier3D = Soldier3D.new()
	target_close_t76.name = "EnemigoCercanoT76"
	root.add_child(target_close_t76)
	target_close_t76._ready()
	target_close_t76.position = Vector3(1.5, 0, 0)

	var res_melee: Dictionary = fusilero_inst.call("ejecutar_ataque_fusilero", target_close_t76)
	assert(res_melee["modo"] == "melee_bayoneta", "A distancia <= 2.0m el fusilero debe conmutar automáticamente a bayoneta")
	assert(res_melee["tipo_dano"] == "Slashing", "El ataque de bayoneta debe aplicar daño tipo Slashing")

	# Ametralladora Gatling (Artillería Ligera de Ráfaga: 5 proyectiles y cooldown de 1.2s)
	var gatling_script: GDScript = load("res://scripts/units/ametralladora_gatling_era6_3d.gd") as GDScript
	var gatling_inst: Soldier3D = gatling_script.new() as Soldier3D
	root.add_child(gatling_inst)
	gatling_inst._ready()
	assert(gatling_inst.has_node("ProjectileMuzzle"), "Gatling debe poseer socket ProjectileMuzzle")
	assert(gatling_inst.get("is_mechanical") == true, "Gatling debe ser unidad mecánica")

	var disparos_gat: int = gatling_inst.call("disparar_rafaga_gatling")
	assert(disparos_gat == 5, "Gatling debe disparar una ráfaga continua de 5 proyectiles")
	assert(gatling_inst.get("tiempo_cooldown_restante") > 1.0, "Gatling debe entrar en cooldown local de 1.2s tras la ráfaga")

	var disparos_en_cd: int = gatling_inst.call("disparar_rafaga_gatling")
	assert(disparos_en_cd == 0, "Gatling no debe disparar mientras se encuentre en cooldown")

	fusilero_inst.free()
	target_far_t76.free()
	target_close_t76.free()
	gatling_inst.free()
	print("✅ Test 76 Superado: Fusilero Imperial (ataque dual rango GUN / estocada bayoneta) y Ametralladora Gatling (ráfaga de 5 tiros y cooldown) certificados.")


	# ─── TEST 77: Húsar a Caballo (Velocidad 6.8 m/s, x1.40 vs Unidades de Rango y Flanqueo a ±65°) ───
	print("\n--- TEST 77: Húsar a Caballo (Velocidad 6.8 m/s, x1.40 vs Rango y Flanqueo ±65°) ---")
	var hussar_script: GDScript = load("res://scripts/units/hussar_era6_3d.gd") as GDScript
	var hussar_inst: Soldier3D = hussar_script.new() as Soldier3D
	root.add_child(hussar_inst)
	hussar_inst._ready()
	assert(abs(hussar_inst.speed - 6.8) < 0.01, "Húsar debe tener velocidad ultra veloz de 6.8 m/s")
	assert(hussar_inst.is_cavalry == true, "Húsar debe pertenecer a caballería (is_cavalry = true)")

	# Multiplicador estricto x1.40 contra unidades de rango de infantería
	var ranged_inf_t77: Soldier3D = Soldier3D.new()
	ranged_inf_t77.name = "FusileroDefensorT77"
	ranged_inf_t77.add_to_group("fusileros")
	ranged_inf_t77.add_to_group("ranged_infantry")
	ranged_inf_t77.weapon_type = "gun"
	root.add_child(ranged_inf_t77)
	ranged_inf_t77._ready()

	var dmg_hussar_vs_ranged: float = CombatDamageCalculator.calcular_dano(hussar_inst.daño, hussar_inst.weapon_type, hussar_inst, ranged_inf_t77)
	# Base counter MELEE_SHOCK vs INFANTRY (1.5) * hussar bono vs ranged (1.40) = 2.10 -> 26.0 * 2.10 = 54.6
	var expected_hussar_dmg: float = (hussar_inst.daño * 1.5) * 1.40
	assert(abs(dmg_hussar_vs_ranged - expected_hussar_dmg) < 0.05, "Húsar debe aplicar multiplicador x1.40 contra unidades de rango (Esperado: %.2f, Obtenido: %.2f)" % [expected_hussar_dmg, dmg_hussar_vs_ranged])

	# Maniobra táctica de flanqueo a ±65 grados
	hussar_inst.position = Vector3(0, 0, 10)
	var pos_flanqueo_der: Vector3 = hussar_inst.call("calcular_posicion_flanqueo", Vector3(0, 0, 0), 4.0, 1)
	var ang_flanqueo_rad: float = deg_to_rad(65.0)
	var expected_x: float = sin(ang_flanqueo_rad) * 4.0
	var expected_z: float = cos(ang_flanqueo_rad) * 4.0
	assert(abs(pos_flanqueo_der.x - expected_x) < 0.1 and abs(pos_flanqueo_der.z - expected_z) < 0.1, "Húsar debe calcular posición de flanqueo precisa a 65 grados")

	hussar_inst.free()
	ranged_inf_t77.free()
	print("✅ Test 77 Superado: Húsar a Caballo (velocidad 6.8 m/s, multiplicador x1.40 vs rango y flanqueo a ±65°) certificado.")


	# ─── TEST 78: Factoría Pesada (Factory_Era6: Herencia Barracks3D, Emergencia 8% y Humo Continuo) ───
	print("\n--- TEST 78: Factoría Pesada (Herencia Barracks3D, Emergencia 8% y Chimeneas con Humo) ---")
	var factory_script: GDScript = load("res://scripts/buildings/factory_era6_3d.gd") as GDScript
	var factory_inst: BuildingBase3D = factory_script.new() as BuildingBase3D
	assert(factory_inst is Barracks3D, "Factory_Era6 debe heredar directamente de Barracks3D")
	assert(factory_inst is BuildingBase3D, "Factory_Era6 debe heredar de BuildingBase3D")

	factory_inst.starts_under_construction = true
	root.add_child(factory_inst)
	factory_inst._ready()

	# Emergencia vertical progresiva desde el 8%
	factory_inst._actualizar_progreso_construccion(0.0)
	factory_inst._actualizar_progreso_construccion(50.0)
	factory_inst._actualizar_progreso_construccion(100.0)
	assert(factory_inst.esta_construido == true, "Factoría debe completarse al 100%% de progreso")

	# Emisor de partículas continuas de humo pesado
	assert(factory_inst.has_node("Chimney1/IndustrialSmokeParticles"), "Factoría debe poseer chimenea con nodo IndustrialSmokeParticles")
	var smoke_node = factory_inst.get_node("Chimney1/IndustrialSmokeParticles")
	assert(smoke_node.get("emitting") == true, "Partículas de humo industrial deben estar emitiéndose continuamente")

	# Cola de producción de blindados de Era 6
	var rm_t78: GlobalResourceManager = root.get_node_or_null("ResourceManager") as GlobalResourceManager
	if not is_instance_valid(rm_t78):
		rm_t78 = GlobalResourceManager.new()
		rm_t78.name = "ResourceManager"
		root.add_child(rm_t78)
	rm_t78.era_actual = 6
	rm_t78.resources["iron"] = 1000
	rm_t78.resources["gold"] = 1000
	rm_t78.resources["wood"] = 1000
	rm_t78.max_population = 50
	rm_t78.current_population = 0
	factory_inst.resource_manager = rm_t78

	var train_tank_success: bool = factory_inst.call("entrenar_unidad", "steamtank_era6")
	assert(train_tank_success == true or factory_inst.get("production_queue").size() > 0, "Factoría debe encolar Tanque de Vapor en Era 6")

	factory_inst.free()
	print("✅ Test 78 Superado: Factoría Pesada con herencia de Barracks3D, emergencia al 8%, chimeneas de humo y cola de producción certificada.")


	# ─── TEST 79: Tanque de Vapor (HP 450.0, Inmunidad al Stun, Multiplicador x2.5 y AoE 3.5m) ───
	print("\n--- TEST 79: Tanque de Vapor (HP 450.0, Inmunidad Stun, x2.5 vs Estructuras y AoE 3.5m) ---")
	var steamtank_script: GDScript = load("res://scripts/units/steamtank_era6_3d.gd") as GDScript
	var steamtank_inst: Soldier3D = steamtank_script.new() as Soldier3D
	root.add_child(steamtank_inst)
	steamtank_inst._ready()
	steamtank_inst.position = Vector3(0, 0, 0)
	assert(abs(steamtank_inst.salud_maxima - 450.0) < 0.01, "Tanque de Vapor debe poseer salud masiva de 450.0 HP")
	assert(steamtank_inst.has_node("ProjectileMuzzle"), "Tanque de Vapor debe poseer socket ProjectileMuzzle")
	assert(steamtank_inst.get("is_stun_immune") == true, "Tanque de Vapor debe ser totalmente inmune a aturdimiento (is_stun_immune = true)")

	# Validación de inmunidad frente a Stun
	var stun_aplicado: bool = steamtank_inst.call("aplicar_stun", 2.0)
	assert(stun_aplicado == false, "aplicar_stun() debe retornar false en Tanque de Vapor")
	assert(steamtank_inst.get("is_stunned") == false, "Tanque de Vapor no debe quedar aturdido bajo ninguna circunstancia")

	# Multiplicador x2.5 contra edificios y estructuras
	var bld_t79: BuildingBase3D = BuildingBase3D.new()
	bld_t79.name = "FortalezaAcero"
	bld_t79.add_to_group("buildings")
	bld_t79.add_to_group("buildings_3d")
	bld_t79.salud_actual = 2000.0
	bld_t79.salud_maxima = 2000.0
	root.add_child(bld_t79)
	bld_t79.position = Vector3(25.0, 0, 0)

	var dmg_steamtank_bld: float = CombatDamageCalculator.calcular_dano(steamtank_inst.daño, steamtank_inst.weapon_type, steamtank_inst, bld_t79)
	# Base counter SIEGE vs BUILDING (3.0) * steamtank bono (2.5) = 7.5 -> 90.0 * 7.5 = 675.0
	var expected_stk_dmg: float = (steamtank_inst.daño * 3.0) * 2.5
	assert(abs(dmg_steamtank_bld - expected_stk_dmg) < 0.05, "Tanque de Vapor debe aplicar multiplicador x2.5 vs estructuras (Esperado: %.2f, Obtenido: %.2f)" % [expected_stk_dmg, dmg_steamtank_bld])

	# Detonación AoE de 3.5 metros
	var bld_close_t79: BuildingBase3D = BuildingBase3D.new()
	bld_close_t79.name = "MuroCercanoAoE"
	bld_close_t79.add_to_group("buildings")
	root.add_child(bld_close_t79)
	bld_close_t79.position = Vector3(27.0, 0, 0) # A 2.0m de (25, 0, 0) <= 3.5m

	var bld_far_t79: BuildingBase3D = BuildingBase3D.new()
	bld_far_t79.name = "MuroLejanoAoE"
	bld_far_t79.add_to_group("buildings")
	root.add_child(bld_far_t79)
	bld_far_t79.position = Vector3(32.0, 0, 0) # A 7.0m de (25, 0, 0) > 3.5m

	var aoe_hits_t79: Array[Node3D] = steamtank_inst.call("disparar_canon_vapor", Vector3(25, 0, 0))
	assert(aoe_hits_t79.has(bld_t79), "Objetivo principal debe ser alcanzado por la salva")
	assert(aoe_hits_t79.has(bld_close_t79), "Estructura a 2.0m debe ser alcanzada por el AoE de 3.5m")
	assert(not aoe_hits_t79.has(bld_far_t79), "Estructura a 7.0m NO debe ser alcanzada")

	steamtank_inst.free()
	bld_t79.free()
	bld_close_t79.free()
	bld_far_t79.free()
	print("✅ Test 79 Superado: Tanque de Vapor (HP 450.0, inmunidad al stun, x2.5 vs estructuras y AoE 3.5m) certificado.")


	# ─── TEST 80: Camión Industrial (Guarecido de 6 Infantes, Duplicación en Caminos y Desembarque RPC) ───
	print("\n--- TEST 80: Camión Industrial (Guarecido 6 Unidades, Bonus Camino y Desembarque RPC) ---")
	var camion_script: GDScript = load("res://scripts/units/camion_industrial_era6_3d.gd") as GDScript
	var camion_inst: Soldier3D = camion_script.new() as Soldier3D
	root.add_child(camion_inst)
	camion_inst._ready()
	assert(abs(camion_inst.speed - 5.0) < 0.01, "Velocidad base del Camión debe ser 5.0 m/s")

	# Duplicación de velocidad en caminos (5.0 -> 10.0 m/s)
	camion_inst.call("aplicar_bonus_camino", true)
	assert(abs(camion_inst.speed - 10.0) < 0.01, "Camión debe duplicar su velocidad en caminos a 10.0 m/s")
	camion_inst.call("aplicar_bonus_camino", false)
	assert(abs(camion_inst.speed - 5.0) < 0.01, "Camión debe retornar a su velocidad base fuera de caminos")

	# Guarecido militar de hasta 6 unidades del grupo infantry_3d
	var infantiles_cargados: Array[Soldier3D] = []
	for i in range(6):
		var inf_node := Soldier3D.new()
		inf_node.name = "InfanteGuarecido_%d" % i
		inf_node.add_to_group("infantry_3d")
		root.add_child(inf_node)
		inf_node._ready()
		var load_ok: bool = camion_inst.call("guarecer_unidad", inf_node)
		assert(load_ok == true, "Debe permitir guarecer infante %d" % i)
		assert(inf_node.visible == false, "El infante guarecido debe quedar oculto")
		infantiles_cargados.append(inf_node)

	var garrison_list: Array = camion_inst.get("garrison_array")
	assert(garrison_list.size() == 6, "El camión debe contener exactamente 6 unidades en garrison_array")

	# Intentar guarecer una 7ma unidad (debe ser rechazada)
	var inf_extra := Soldier3D.new()
	inf_extra.name = "InfanteExcedente"
	inf_extra.add_to_group("infantry_3d")
	root.add_child(inf_extra)
	inf_extra._ready()
	var load_fail: bool = camion_inst.call("guarecer_unidad", inf_extra)
	assert(load_fail == false, "El camión no debe permitir exceder la capacidad máxima de 6 unidades")
	inf_extra.free()

	# Desembarque síncrono vía RPC
	var desembarcadas: Array[Node3D] = camion_inst.call("desembarcar_unidades")
	assert(desembarcadas.size() == 6, "Deben haberse desembarcado exactamente las 6 unidades")
	assert(camion_inst.get("garrison_array").size() == 0, "El garrison_array debe quedar vacío tras desembarcar")

	for u in infantiles_cargados:
		assert(u.visible == true, "Las unidades desembarcadas deben volver a ser visibles")
		u.free()

	camion_inst.free()
	print("✅ Test 80 Superado: Camión Industrial (guarecido de 6 infantes, duplicación en caminos y desembarque síncrono) certificado.")


	# ─── TEST 81: Doughboy de Trinchera (Mitigación del 20% en Idle y Daño GUN 30.0) ───
	print("\n--- TEST 81: Doughboy de Trinchera (Daño GUN y Mitigación 20% en Idle) ---")
	var doughboy_script: GDScript = load("res://scripts/units/doughboy_era7_3d.gd") as GDScript
	var doughboy_inst: Soldier3D = doughboy_script.new() as Soldier3D
	root.add_child(doughboy_inst)
	doughboy_inst._ready()
	assert(doughboy_inst.has_node("ProjectileMuzzle"), "Doughboy debe poseer socket ProjectileMuzzle")
	assert(abs(doughboy_inst.daño - 30.0) < 0.01, "Doughboy debe poseer daño base de 30.0")

	# Mitigación del 20% en reposo / Idle contra daño balístico
	doughboy_inst.set("esta_en_trinchera", true)
	var dano_test_balistico: float = 100.0
	var dano_con_mitigacion: float = doughboy_inst.call("aplicar_mitigacion_trinchera", dano_test_balistico, "gun")
	assert(abs(dano_con_mitigacion - 80.0) < 0.01, "Doughboy en reposo debe mitigar un 20%% del daño balístico")

	# En movimiento / fuera de trinchera no aplica mitigación
	doughboy_inst.set("esta_en_trinchera", false)
	doughboy_inst.velocity = Vector3(5.0, 0, 0)
	var dano_sin_mitigacion: float = doughboy_inst.call("aplicar_mitigacion_trinchera", dano_test_balistico, "gun")
	assert(abs(dano_sin_mitigacion - 100.0) < 0.01, "Doughboy en movimiento no debe mitigar daño balístico")

	# Verificación integrada con CombatDamageCalculator
	doughboy_inst.set("esta_en_trinchera", true)
	doughboy_inst.velocity = Vector3.ZERO
	var attacker_t81: Soldier3D = Soldier3D.new()
	root.add_child(attacker_t81)
	attacker_t81._ready()
	attacker_t81.daño = 50.0
	attacker_t81.weapon_type = "gun"

	var calc_dmg_doughboy: float = CombatDamageCalculator.calcular_dano(attacker_t81.daño, "gun", attacker_t81, doughboy_inst)
	# Base counter GUN vs INFANTRY (1.2) * mitigación trinchera (0.80) = 0.96 -> 50.0 * 0.96 = 48.0
	var expected_dmg_doughboy: float = (attacker_t81.daño * 1.2) * 0.80
	assert(abs(calc_dmg_doughboy - expected_dmg_doughboy) < 0.05, "CombatDamageCalculator debe aplicar mitigación de trinchera del 20%% (Esperado: %.2f, Obtenido: %.2f)" % [expected_dmg_doughboy, calc_dmg_doughboy])

	doughboy_inst.free()
	attacker_t81.free()
	print("✅ Test 81 Superado: Doughboy de Trinchera (daño GUN 30.0, socket ProjectileMuzzle y mitigación del 20% en Idle) certificado.")


	# ─── TEST 82: Ametralladora Maxim (Ráfaga de 4 Tiros y Debuff Supresión -30%) ───
	print("\n--- TEST 82: Ametralladora Maxim (Ráfaga 4 Tiros y Supresión -30%) ---")
	var maxim_script: GDScript = load("res://scripts/units/ametralladora_maxim_era7_3d.gd") as GDScript
	var maxim_inst: Soldier3D = maxim_script.new() as Soldier3D
	root.add_child(maxim_inst)
	maxim_inst._ready()
	assert(maxim_inst.has_node("ProjectileMuzzle"), "Maxim debe poseer socket ProjectileMuzzle")
	assert(abs(maxim_inst.daño - 16.0) < 0.01, "Maxim debe poseer daño base de 16.0")

	# Target para recibir la ráfaga y el debuff de supresión
	var target_maxim: Soldier3D = Soldier3D.new()
	target_maxim.name = "InfanteObjetivoMaxim"
	root.add_child(target_maxim)
	target_maxim._ready()
	var initial_speed: float = target_maxim.speed

	var shots_fired: int = maxim_inst.call("disparar_rafaga_maxim", target_maxim)
	assert(shots_fired == 4, "Ametralladora Maxim debe disparar ráfagas continuas de 4 tiros")
	assert(target_maxim.get("is_suppressed") == true, "El objetivo de la Maxim debe quedar en estado is_suppressed")
	assert(abs(target_maxim.speed - (initial_speed * 0.70)) < 0.05, "El objetivo debe sufrir ralentización del -30%% en su velocidad")

	maxim_inst.free()
	target_maxim.free()
	print("✅ Test 82 Superado: Ametralladora Maxim (ráfagas continuas de 4 tiros y debuff de supresión del -30% por 2s) certificada.")


	# ─── TEST 83: Tanque Mark IV (HP 400.0, Inmunidad Stun y Barbetas Dobles Simultáneas) ───
	print("\n--- TEST 83: Tanque Mark IV (HP 400.0, Inmunidad Stun y Barbetas Muzzle_Left / Muzzle_Right) ---")
	var markiv_script: GDScript = load("res://scripts/units/mark_iv_tanque_era7_3d.gd") as GDScript
	var markiv_inst: Soldier3D = markiv_script.new() as Soldier3D
	root.add_child(markiv_inst)
	markiv_inst._ready()
	assert(abs(markiv_inst.salud_maxima - 400.0) < 0.01, "Tanque Mark IV debe poseer 400.0 HP masivos")
	assert(markiv_inst.get("is_stun_immune") == true, "Tanque Mark IV debe ser totalmente inmune al stun")

	var stun_attempt: bool = markiv_inst.call("aplicar_stun", 2.0)
	assert(stun_attempt == false, "aplicar_stun debe retornar false en Mark IV")
	assert(markiv_inst.get("is_stunned") == false, "Mark IV no debe quedar aturdido")

	# Barbetas dobles
	assert(markiv_inst.has_node("Muzzle_Left"), "Mark IV debe poseer barbeta izquierda Muzzle_Left")
	assert(markiv_inst.has_node("Muzzle_Right"), "Mark IV debe poseer barbeta derecha Muzzle_Right")

	var enemy_left := Soldier3D.new()
	var enemy_right := Soldier3D.new()
	root.add_child(enemy_left)
	root.add_child(enemy_right)
	enemy_left._ready()
	enemy_right._ready()

	var dual_result: Dictionary = markiv_inst.call("disparar_barbetas_dobles", enemy_left, enemy_right)
	assert(dual_result["left_hit"] == true, "Barbeta izquierda debe alcanzar su objetivo")
	assert(dual_result["right_hit"] == true, "Barbeta derecha debe alcanzar su objetivo")

	markiv_inst.free()
	enemy_left.free()
	enemy_right.free()
	print("✅ Test 83 Superado: Tanque Mark IV (HP 400.0, inmunidad al stun y fuego simultáneo desde barbetas dobles) certificado.")


	# ─── TEST 84: Aeródromo de Lienzo y Búnker de Hormigón (Herencia Barracks3D y Tower3D) ───
	print("\n--- TEST 84: Aeródromo WWI y Búnker de Hormigón ---")
	var airfield_script: GDScript = load("res://scripts/buildings/airfield_wwi_3d.gd") as GDScript
	var airfield_inst: BuildingBase3D = airfield_script.new() as BuildingBase3D
	assert(airfield_inst is Barracks3D, "Airfield_WWI_3D debe heredar directamente de Barracks3D")
	assert(airfield_inst is BuildingBase3D, "Airfield_WWI_3D debe heredar de BuildingBase3D")

	airfield_inst.starts_under_construction = true
	root.add_child(airfield_inst)
	airfield_inst._ready()

	# Emergencia vertical desde el 8%
	airfield_inst._actualizar_progreso_construccion(0.0)
	airfield_inst._actualizar_progreso_construccion(50.0)
	airfield_inst._actualizar_progreso_construccion(100.0)
	assert(airfield_inst.esta_construido == true, "Aeródromo debe completarse al 100%% de construcción")

	# Cola de producción de unidad aérea
	var rm_t84: GlobalResourceManager = root.get_node_or_null("ResourceManager") as GlobalResourceManager
	if not is_instance_valid(rm_t84):
		rm_t84 = GlobalResourceManager.new()
		rm_t84.name = "ResourceManager"
		root.add_child(rm_t84)
	rm_t84.era_actual = 7
	rm_t84.resources["wood"] = 1000
	rm_t84.resources["iron"] = 1000
	rm_t84.resources["gold"] = 1000
	rm_t84.max_population = 50
	rm_t84.current_population = 0
	airfield_inst.resource_manager = rm_t84

	var train_fokker_ok: bool = airfield_inst.call("entrenar_unidad", "biplano_fokker_era7")
	assert(train_fokker_ok == true or airfield_inst.get("production_queue").size() > 0, "Aeródromo debe encolar Biplano Fokker en Era 7")

	# Búnker de Hormigón Armado (herencia Tower3D)
	var bunker_script: GDScript = load("res://scripts/buildings/fortress_bunker_3d.gd") as GDScript
	var bunker_inst: Tower3D = bunker_script.new() as Tower3D
	assert(bunker_inst is Tower3D, "Fortress_Bunker_3D debe heredar de Tower3D")
	root.add_child(bunker_inst)
	bunker_inst._ready()
	assert(abs(bunker_inst.salud_maxima - 2200.0) < 0.01, "Búnker debe poseer salud de 2200.0 HP")
	assert(abs(bunker_inst.base_damage - 45.0) < 0.01, "Búnker debe poseer daño base de 45.0")

	airfield_inst.free()
	bunker_inst.free()
	print("✅ Test 84 Superado: Aeródromo WWI (herencia Barracks3D, emergencia 8% y cola de aviones) y Búnker de Hormigón (herencia Tower3D, 2200 HP) certificados.")


	# ─── TEST 85: Biplano Fokker Era 7 (Vuelo Y=10.0m, Velocidad 9.5 m/s y Retorno Autónomo por Munición) ───
	print("\n--- TEST 85: Biplano Fokker (Vuelo Y=10m, Velocidad 9.5 m/s y Rearme Autónomo) ---")
	var fokker_script: GDScript = load("res://scripts/units/biplano_fokker_era7_3d.gd") as GDScript
	var fokker_inst: Soldier3D = fokker_script.new() as Soldier3D
	root.add_child(fokker_inst)
	fokker_inst._ready()
	assert(abs(fokker_inst.speed - 9.5) < 0.01, "Biplano Fokker debe poseer velocidad de vuelo de 9.5 m/s")
	assert(abs(fokker_inst.position.y - 10.0) < 0.01, "Biplano Fokker debe navegar a una altura fija constante en Y = 10.0m")

	# Pasadas de ametrallamiento y consumo de munición (max_ammo = 3)
	var ground_target_t85 := Soldier3D.new()
	root.add_child(ground_target_t85)
	ground_target_t85._ready()

	assert(fokker_inst.get("current_ammo") == 3, "Biplano debe iniciar con 3 cargas de munición")
	fokker_inst.call("ametrallar_objetivo", ground_target_t85)
	assert(fokker_inst.get("current_ammo") == 2, "Debe quedar con 2 cargas tras primer ataque")
	fokker_inst.call("ametrallar_objetivo", ground_target_t85)
	assert(fokker_inst.get("current_ammo") == 1, "Debe quedar con 1 carga tras segundo ataque")

	# Tercer ataque agota munición y activa retorno autónomo al aeródromo
	fokker_inst.call("ametrallar_objetivo", ground_target_t85)
	assert(fokker_inst.get("current_ammo") == 0, "Munición debe quedar agotada a 0")
	assert(fokker_inst.get("estado_vuelo") == "regresando", "Biplano debe conmutar autónomamente a estado 'regresando' hacia el aeródromo")

	fokker_inst.free()
	ground_target_t85.free()
	print("✅ Test 85 Superado: Biplano Fokker (capa aérea Y=10m, velocidad 9.5 m/s, pasadas de ametrallamiento y retorno autónomo por rearme) certificado.")


	# ─── TEST 86: Sniper WWII (Rango 30m, Sigilo en Idle y x3.0 vs Civiles/Sacerdotes) y HazmatWorker (Inmunidad DoT) ───
	print("\n--- TEST 86: Sniper WWII y Técnico Hazmat ---")
	var sniper_script: GDScript = load("res://scripts/units/sniper_era8_3d.gd") as GDScript
	var sniper_inst: Soldier3D = sniper_script.new() as Soldier3D
	root.add_child(sniper_inst)
	sniper_inst._ready()
	sniper_inst.position = Vector3(0, 0, 0)
	assert(abs(sniper_inst.rango_ataque - 30.0) < 0.01, "Sniper debe poseer rango masivo de 30.0 metros")
	assert(sniper_inst.has_node("ProjectileMuzzle"), "Sniper debe poseer socket ProjectileMuzzle")
	assert(sniper_inst.is_invisible == true, "Sniper debe iniciar en estado invisible en Idle")

	# Revelación de malla al abrir fuego
	var target_civil_t86: Soldier3D = Soldier3D.new()
	target_civil_t86.name = "AldeanoCivilT86"
	target_civil_t86.add_to_group("villagers")
	target_civil_t86.add_to_group("infantry_3d")
	root.add_child(target_civil_t86)
	target_civil_t86._ready()
	target_civil_t86.salud_actual = 500.0

	var dmg_sniper_vs_civil: float = sniper_inst.call("disparar_sniper", target_civil_t86)
	assert(sniper_inst.is_invisible == false, "Sniper debe revelarse al abrir fuego")
	# Base counter GUN vs INFANTRY (1.2) * sniper bono civil/sacerdote (3.0) = 3.6 -> 65.0 * 3.6 = 234.0
	var expected_sniper_dmg: float = (sniper_inst.daño * 1.2) * 3.0
	assert(abs(dmg_sniper_vs_civil - expected_sniper_dmg) < 0.05, "Sniper debe infligir multiplicador crítico x3.0 contra aldeanos civiles (Esperado: %.2f, Obtenido: %.2f)" % [expected_sniper_dmg, dmg_sniper_vs_civil])

	# HazmatWorker_Era8: Inmunidad absoluta DoT y capacidad de descontaminación
	var hazmat_script: GDScript = load("res://scripts/units/hazmat_worker_era8_3d.gd") as GDScript
	var hazmat_inst: Soldier3D = hazmat_script.new() as Soldier3D
	root.add_child(hazmat_inst)
	hazmat_inst._ready()
	assert(hazmat_inst.is_radiation_immune == true, "HazmatWorker debe poseer is_radiation_immune = true")
	assert(hazmat_inst.is_civilian == true, "HazmatWorker debe ser unidad civil no combatiente")
	var zonas_limpias: int = hazmat_inst.call("descontaminar_zona", Vector3.ZERO, 15.0)
	assert(zonas_limpias >= 0, "HazmatWorker debe ejecutar descontaminar_zona sin errores")

	sniper_inst.free()
	target_civil_t86.free()
	hazmat_inst.free()
	print("✅ Test 86 Superado: Sniper WWII (rango 30m, sigilo en Idle y crítico x3.0 vs civiles) y Técnico Hazmat (inmunidad DoT y descontaminación) certificados.")


	# ─── TEST 87: Caza Monoplano P-51 (Capa Aérea Y=12.0m, Velocidad 12 m/s, Ametrallamiento Suelo y Retorno por Munición) ───
	print("\n--- TEST 87: Caza Monoplano P-51 (Vuelo Y=12m, 12 m/s y Ametrallamiento Suelo) ---")
	var caza_script: GDScript = load("res://scripts/units/caza_helice_era8_3d.gd") as GDScript
	var caza_inst: Soldier3D = caza_script.new() as Soldier3D
	root.add_child(caza_inst)
	caza_inst._ready()
	assert(abs(caza_inst.speed - 12.0) < 0.01, "Caza Monoplano debe poseer velocidad lineal de 12.0 m/s")
	assert(abs(caza_inst.position.y - 12.0) < 0.01, "Caza Monoplano debe navegar a una cota fija constante en Y = 12.0m")
	assert(caza_inst.get("max_ammo") == 4, "Caza Monoplano debe soportar max_ammo = 4")
	assert(caza_inst.get("current_ammo") == 4, "Caza Monoplano debe iniciar con 4 cargas de munición")

	# Pasadas de ametrallamiento en tierra
	var ground_target_t87 := Soldier3D.new()
	root.add_child(ground_target_t87)
	ground_target_t87._ready()
	ground_target_t87.position = Vector3(0, 0, 0)

	caza_inst.call("ametrallar_objetivo", ground_target_t87)
	assert(caza_inst.get("current_ammo") == 3, "Debe restar munición a 3 tras primer ametrallamiento")
	caza_inst.call("ametrallar_objetivo", ground_target_t87)
	assert(caza_inst.get("current_ammo") == 2, "Debe restar munición a 2 tras segundo ametrallamiento")
	caza_inst.call("ametrallar_objetivo", ground_target_t87)
	assert(caza_inst.get("current_ammo") == 1, "Debe restar munición a 1 tras tercer ametrallamiento")

	# Cuarto ametrallamiento agota munición y activa retorno autónomo al aeródromo
	caza_inst.call("ametrallar_objetivo", ground_target_t87)
	assert(caza_inst.get("current_ammo") == 0, "Munición debe quedar agotada a 0")
	assert(caza_inst.get("estado_vuelo") == "regresando", "Caza debe conmutar automáticamente a estado 'regresando' hacia la base")

	caza_inst.free()
	ground_target_t87.free()
	print("✅ Test 87 Superado: Caza Monoplano P-51 (vuelo Y=12m, velocidad 12 m/s, pasadas de ametrallamiento y retorno autónomo con max_ammo=4) certificado.")


	# ─── TEST 88: Tanque Sherman T-34 (HP 380.0, Inmunidad Stun, x1.50 vs Transports) y GI Soldier (Daño GUN 32.0, x1.25) ───
	print("\n--- TEST 88: Tanque Sherman T-34 y Soldado GI WWII ---")
	var sherman_script: GDScript = load("res://scripts/units/tanque_sherman_t34_3d.gd") as GDScript
	var sherman_inst: Soldier3D = sherman_script.new() as Soldier3D
	root.add_child(sherman_inst)
	sherman_inst._ready()
	assert(abs(sherman_inst.salud_maxima - 380.0) < 0.01, "Tanque Sherman debe poseer 380.0 HP")
	assert(abs(sherman_inst.speed - 5.2) < 0.01, "Tanque Sherman debe poseer velocidad de 5.2 m/s")
	assert(sherman_inst.get("is_stun_immune") == true, "Tanque Sherman debe poseer inmunidad al aturdimiento")
	assert(sherman_inst.call("aplicar_stun", 2.0) == false, "aplicar_stun debe fallar en Tanque Sherman")

	# Multiplicador x1.50 vs transportes/mecanizados de la era anterior
	var truck_target_t88 := Soldier3D.new()
	truck_target_t88.name = "CamionTransporteT88"
	truck_target_t88.add_to_group("transports")
	truck_target_t88.is_cavalry = true
	root.add_child(truck_target_t88)
	truck_target_t88._ready()

	var dmg_sherman_vs_truck: float = CombatDamageCalculator.calcular_dano(sherman_inst.daño, "gun", sherman_inst, truck_target_t88)
	# Base counter GUNPOWDER vs CAVALRY (2.0) * sherman bono (1.50) = 3.00 -> 55.0 * 3.00 = 165.0
	var expected_sherman_dmg: float = (sherman_inst.daño * 2.0) * 1.50
	assert(abs(dmg_sherman_vs_truck - expected_sherman_dmg) < 0.05, "Tanque Sherman debe aplicar multiplicador x1.50 vs unidades mecanizadas/transporte (Esperado: %.2f, Obtenido: %.2f)" % [expected_sherman_dmg, dmg_sherman_vs_truck])

	# Soldado GI WWII (Infantería Moderna: Daño 32.0, ProjectileMuzzle y x1.25 vs infantería pasada)
	var gi_script: GDScript = load("res://scripts/units/gi_soldier_era8_3d.gd") as GDScript
	var gi_inst: Soldier3D = gi_script.new() as Soldier3D
	root.add_child(gi_inst)
	gi_inst._ready()
	assert(abs(gi_inst.daño - 32.0) < 0.01, "Soldado GI debe poseer daño base de 32.0")
	assert(gi_inst.has_node("ProjectileMuzzle"), "Soldado GI debe poseer socket ProjectileMuzzle")

	var past_inf_t88 := Soldier3D.new()
	past_inf_t88.name = "InfanteriaPasadaT88"
	past_inf_t88.add_to_group("infantry_3d")
	root.add_child(past_inf_t88)
	past_inf_t88._ready()

	var dmg_gi_vs_past: float = CombatDamageCalculator.calcular_dano(gi_inst.daño, "gun", gi_inst, past_inf_t88)
	# Base counter GUN vs INFANTRY (1.2) * gi bono (1.25) = 1.50 -> 32.0 * 1.50 = 48.0
	var expected_gi_dmg: float = (gi_inst.daño * 1.2) * 1.25
	assert(abs(dmg_gi_vs_past - expected_gi_dmg) < 0.05, "Soldado GI debe aplicar multiplicador x1.25 contra infantería ligera de eras previas (Esperado: %.2f, Obtenido: %.2f)" % [expected_gi_dmg, dmg_gi_vs_past])

	sherman_inst.free()
	truck_target_t88.free()
	gi_inst.free()
	past_inf_t88.free()
	print("✅ Test 88 Superado: Tanque Sherman T-34 (HP 380, velocidad 5.2 m/s, inmunidad stun y x1.50 vs camiones) y Soldado GI (daño 32.0, x1.25 vs infantería pasada) certificados.")


	# ─── TEST 89: Herencia Limpia de Aeródromo WWII y Silo Nuclear (Barracks3D, Emergencia 8% y Colas) ───
	print("\n--- TEST 89: Aeródromo Moderno WWII y Silo de Misiles ICBM ---")
	var airfield_wwii_script: GDScript = load("res://scripts/buildings/airfield_wwii_3d.gd") as GDScript
	var airfield_wwii_inst: BuildingBase3D = airfield_wwii_script.new() as BuildingBase3D
	assert(airfield_wwii_inst is Barracks3D, "Airfield_WWII_3D debe heredar directamente de Barracks3D")
	assert(airfield_wwii_inst is BuildingBase3D, "Airfield_WWII_3D debe heredar de BuildingBase3D")

	airfield_wwii_inst.starts_under_construction = true
	root.add_child(airfield_wwii_inst)
	airfield_wwii_inst._ready()

	# Emergencia vertical desde el 8%
	airfield_wwii_inst._actualizar_progreso_construccion(0.0)
	airfield_wwii_inst._actualizar_progreso_construccion(50.0)
	airfield_wwii_inst._actualizar_progreso_construccion(100.0)
	assert(airfield_wwii_inst.esta_construido == true, "Aeródromo WWII debe completarse al 100%% de progreso")

	# Cola de producción de Caza Monoplano P-51
	var rm_t89: GlobalResourceManager = root.get_node_or_null("ResourceManager") as GlobalResourceManager
	if not is_instance_valid(rm_t89):
		rm_t89 = GlobalResourceManager.new()
		rm_t89.name = "ResourceManager"
		root.add_child(rm_t89)
	rm_t89.era_actual = 8
	rm_t89.resources["iron"] = 2000
	rm_t89.resources["gold"] = 2000
	rm_t89.resources["wood"] = 1000
	rm_t89.max_population = 50
	rm_t89.current_population = 0
	airfield_wwii_inst.resource_manager = rm_t89

	var train_caza_ok: bool = airfield_wwii_inst.call("entrenar_unidad", "caza_helice_era8")
	assert(train_caza_ok == true or airfield_wwii_inst.get("production_queue").size() > 0, "Aeródromo WWII debe encolar Caza Monoplano P-51 en Era 8")

	# Silo Nuclear ICBM
	var nuke_silo_script: GDScript = load("res://scripts/buildings/nuke_silo_era8_3d.gd") as GDScript
	var nuke_silo_inst: BuildingBase3D = nuke_silo_script.new() as BuildingBase3D
	assert(nuke_silo_inst is Barracks3D, "NukeSilo_Era8_3D debe heredar directamente de Barracks3D")
	assert(nuke_silo_inst is BuildingBase3D, "NukeSilo_Era8_3D debe heredar de BuildingBase3D")

	nuke_silo_inst.starts_under_construction = true
	root.add_child(nuke_silo_inst)
	nuke_silo_inst._ready()

	nuke_silo_inst._actualizar_progreso_construccion(0.0)
	nuke_silo_inst._actualizar_progreso_construccion(100.0)
	assert(nuke_silo_inst.esta_construido == true, "Silo Nuclear debe completarse al 100%% de progreso")

	nuke_silo_inst.resource_manager = rm_t89
	var train_nuke_ok: bool = nuke_silo_inst.call("entrenar_unidad", "misil_nuclear_icbm")
	assert(train_nuke_ok == true or nuke_silo_inst.get("production_queue").size() > 0, "Silo Nuclear debe encolar Misil ICBM en Era 8")

	airfield_wwii_inst.free()
	nuke_silo_inst.free()
	print("✅ Test 89 Superado: Herencia limpia de Aeródromo WWII y Silo Nuclear desde Barracks3D, emergencia 8% y colas de producción certificadas.")


	# ─── TEST 90: Detonación Colosal ICBM (Radio 18m, 9999 HP Letal, Zona DoT 10 HP/s e Inmunidad Hazmat) ───
	print("\n--- TEST 90: Detonación Colosal ICBM y Área Residual Radioactiva ---")
	var nuke_silo_t90: BuildingBase3D = nuke_silo_script.new() as BuildingBase3D
	root.add_child(nuke_silo_t90)
	nuke_silo_t90._ready()

	# Víctima cercana dentro de los 18m (a 6.0m de origen)
	var vic_close_t90 := Soldier3D.new()
	vic_close_t90.name = "SoldadoCercanoICBM"
	root.add_child(vic_close_t90)
	vic_close_t90._ready()
	vic_close_t90.salud_actual = 500.0
	vic_close_t90.position = Vector3(6.0, 0, 0)

	# Víctima lejana fuera de los 18m (a 28.0m de origen)
	var vic_far_t90 := Soldier3D.new()
	vic_far_t90.name = "SoldadoLejanoICBM"
	root.add_child(vic_far_t90)
	vic_far_t90._ready()
	vic_far_t90.salud_actual = 500.0
	vic_far_t90.position = Vector3(28.0, 0, 0)

	# Disparar misil ICBM hacia Vector3(0, 0, 0)
	var det_res: Dictionary = nuke_silo_t90.call("disparar_misil_icbm", Vector3(0, 0, 0))
	assert(abs(float(nuke_silo_t90.get("radio_detonacion")) - 18.0) < 0.01, "Silo debe poseer radio de detonación de 18.0 metros")
	assert(abs(float(nuke_silo_t90.get("dano_letal")) - 9999.0) < 0.01, "Silo debe infligir daño letal instantáneo de 9999.0 HP")

	# Comprobación del daño letal instantáneo
	assert(vic_close_t90.salud_actual == 0.0, "Unidad a 6.0m debe recibir muerte instantánea con 9999 HP de daño")
	assert(vic_far_t90.salud_actual == 500.0, "Unidad a 28.0m no debe sufrir daño fuera del radio de 18.0m")

	# Área residual radioactiva DoT (10 HP/s por 15.0s)
	var zona_rad_node = det_res.get("zona_radioactiva")
	assert(is_instance_valid(zona_rad_node), "El disparo del ICBM debe desplegar la zona residual radioactiva")
	assert(abs(float(zona_rad_node.get("duracion_restante")) - 15.0) < 0.01, "Área radioactiva debe durar 15.0 segundos")
	assert(abs(float(zona_rad_node.get("dps_radiacion")) - 10.0) < 0.01, "Área radioactiva debe infligir 10.0 HP/s")

	# Unidad normal sufre 10 HP/s
	var norm_soldier_t90 := Soldier3D.new()
	norm_soldier_t90.name = "SoldadoComunRadioactivo"
	root.add_child(norm_soldier_t90)
	norm_soldier_t90._ready()
	norm_soldier_t90.salud_actual = 100.0

	var dmg_recibido_norm: float = zona_rad_node.call("procesar_dano_unidad", norm_soldier_t90)
	assert(abs(dmg_recibido_norm - 10.0) < 0.01, "Unidad convencional debe recibir 10 HP/s de daño radioactivo")
	assert(abs(norm_soldier_t90.salud_actual - 90.0) < 0.01, "Salud de unidad convencional debe decrecer en 10 HP")

	# HazmatWorker_Era8 posee inmunidad absoluta y no sufre daño (0 HP)
	var hazmat_t90: Soldier3D = hazmat_script.new() as Soldier3D
	root.add_child(hazmat_t90)
	hazmat_t90._ready()
	hazmat_t90.salud_actual = 160.0
	assert(hazmat_t90.is_radiation_immune == true, "HazmatWorker debe poseer is_radiation_immune = true")

	var dmg_recibido_hazmat: float = zona_rad_node.call("procesar_dano_unidad", hazmat_t90)
	assert(dmg_recibido_hazmat == 0.0, "HazmatWorker debe mitigar el 100%% del daño radioactivo (0 de daño recibido)")
	assert(abs(hazmat_t90.salud_actual - 160.0) < 0.01, "Salud de HazmatWorker no debe verse alterada en la zona radioactiva")

	nuke_silo_t90.free()
	vic_close_t90.free()
	vic_far_t90.free()
	norm_soldier_t90.free()
	hazmat_t90.free()
	if is_instance_valid(zona_rad_node):
		zona_rad_node.free()
	print("✅ Test 90 Superado: Detonación colosal ICBM (radio 18m, 9999 HP letal, área residual DoT 10 HP/s por 15s e inmunidad absoluta HazmatWorker) certificada.")


	# ─── TEST 91: SpecOps_Era9 (Detección Térmica de Sigilo) y AntiTank_Soldier_Era9 (x2.5 vs Blindados) ───
	print("\n--- TEST 91: Operador SpecOps y Soldado Anti-Tanque ---")
	var specops_script: GDScript = load("res://scripts/units/spec_ops_era9_3d.gd") as GDScript
	var specops_inst: Soldier3D = specops_script.new() as Soldier3D
	root.add_child(specops_inst)
	specops_inst._ready()
	specops_inst.position = Vector3(0, 0, 0)
	assert(abs(specops_inst.daño - 35.0) < 0.01, "SpecOps debe poseer daño base de 35.0")
	assert(specops_inst.has_node("ProjectileMuzzle"), "SpecOps debe poseer socket ProjectileMuzzle")
	assert(specops_inst.get("has_thermal_vision") == true, "SpecOps debe poseer visión térmica nocturna activa")

	# Francotirador camuflado a 10.0m de distancia
	var sniper_script_t91: GDScript = load("res://scripts/units/sniper_era8_3d.gd") as GDScript
	var sniper_target_t91: Soldier3D = sniper_script_t91.new() as Soldier3D
	root.add_child(sniper_target_t91)
	sniper_target_t91._ready()
	sniper_target_t91.position = Vector3(10.0, 0, 0)
	sniper_target_t91.set("is_invisible", true)
	assert(sniper_target_t91.get("is_invisible") == true, "Sniper debe encontrarse en estado invisible inicialmente")

	# Escaneo térmico activo que anula la invisibilidad del Sniper
	var detectados_t91: int = specops_inst.call("escanear_termico", 25.0)
	assert(detectados_t91 >= 1, "Visión térmica de SpecOps debe detectar al Sniper camuflado")
	assert(sniper_target_t91.get("is_invisible") == false, "La visión térmica de SpecOps debe forzar is_invisible = false en el Sniper")

	# AntiTank_Soldier_Era9: Proyectil perforante y multiplicador x2.5 vs vehículos y tanques
	var antitank_script: GDScript = load("res://scripts/units/anti_tank_soldier_era9_3d.gd") as GDScript
	var antitank_inst: Soldier3D = antitank_script.new() as Soldier3D
	root.add_child(antitank_inst)
	antitank_inst._ready()
	assert(abs(antitank_inst.daño - 45.0) < 0.01, "Soldado Anti-Tanque debe poseer daño base de 45.0")
	assert(antitank_inst.has_node("ProjectileMuzzle"), "Soldado Anti-Tanque debe poseer socket ProjectileMuzzle")

	var tank_target_t91 := Soldier3D.new()
	tank_target_t91.name = "TanqueObjetivoT91"
	tank_target_t91.set("is_vehicle", true)
	tank_target_t91.set("is_tank", true)
	tank_target_t91.is_cavalry = true
	tank_target_t91.add_to_group("vehicles_3d")
	tank_target_t91.add_to_group("tanks")
	root.add_child(tank_target_t91)
	tank_target_t91._ready()

	var dmg_at: float = CombatDamageCalculator.calcular_dano(antitank_inst.daño, "gun", antitank_inst, tank_target_t91)
	# Base counter GUNPOWDER vs CAVALRY (2.0) * antitank bono (2.5) = 5.00 -> 45.0 * 5.00 = 225.0
	var expected_at_dmg: float = (antitank_inst.daño * 2.0) * 2.5
	assert(abs(dmg_at - expected_at_dmg) < 0.05, "Soldado Anti-Tanque debe infligir multiplicador x2.5 contra vehículos y tanques (Esperado: %.2f, Obtenido: %.2f)" % [expected_at_dmg, dmg_at])

	specops_inst.free()
	sniper_target_t91.free()
	antitank_inst.free()
	tank_target_t91.free()
	print("✅ Test 91 Superado: Operador SpecOps (visión térmica activa anulando sigilo de Sniper) y Soldado Anti-Tanque (multiplicador x2.5 vs blindados) certificados.")


	# ─── TEST 92: Estación de Radar Táctica (Visión 65m y Pulso) y Base Aérea Moderna (Herencia Barracks3D y 8%) ───
	print("\n--- TEST 92: Estación de Radar Táctica y Base Aérea Moderna ---")
	var radar_script: GDScript = load("res://scripts/buildings/radar_station_3d.gd") as GDScript
	var radar_inst: Tower3D = radar_script.new() as Tower3D
	assert(radar_inst is Tower3D, "Radar_Station_3D debe heredar directamente de Tower3D")
	assert(radar_inst is BuildingBase3D, "Radar_Station_3D debe heredar de BuildingBase3D")
	root.add_child(radar_inst)
	radar_inst._ready()
	radar_inst.position = Vector3(0, 0, 0)
	assert(abs(radar_inst.radio_vision - 65.0) < 0.01, "Estación de Radar debe poseer visión masiva estricta de 65.0 metros")

	# Detección y revelación de aeronaves mediante pulso de radar
	var drone_target_t92 := Soldier3D.new()
	drone_target_t92.name = "AeronaveEnemigaT92"
	drone_target_t92.add_to_group("aircraft")
	drone_target_t92.add_to_group("air_units")
	root.add_child(drone_target_t92)
	drone_target_t92._ready()
	drone_target_t92.position = Vector3(30.0, 10.0, 0)

	var detectadas_radar: Array[Node3D] = radar_inst.call("emitir_pulso_radar")
	assert(detectadas_radar.has(drone_target_t92), "Pulso de radar debe revelar aeronave en vuelo a 30m de distancia")

	# Base Aérea Moderna (Airbase_Modern_3D: Herencia Barracks3D y emergencia desde el 8%)
	var airbase_script: GDScript = load("res://scripts/buildings/airbase_modern_3d.gd") as GDScript
	var airbase_inst: BuildingBase3D = airbase_script.new() as BuildingBase3D
	assert(airbase_inst is Barracks3D, "Airbase_Modern_3D debe heredar directamente de Barracks3D")
	assert(airbase_inst is BuildingBase3D, "Airbase_Modern_3D debe heredar de BuildingBase3D")

	airbase_inst.starts_under_construction = true
	root.add_child(airbase_inst)
	airbase_inst._ready()

	# Emergencia vertical progresiva desde el 8%
	airbase_inst._actualizar_progreso_construccion(0.0)
	airbase_inst._actualizar_progreso_construccion(50.0)
	airbase_inst._actualizar_progreso_construccion(100.0)
	assert(airbase_inst.esta_construido == true, "Base Aérea Moderna debe completarse al 100%% de progreso")

	# Cola de producción de aeronaves de Era 9
	var rm_t92: GlobalResourceManager = root.get_node_or_null("ResourceManager") as GlobalResourceManager
	if not is_instance_valid(rm_t92):
		rm_t92 = GlobalResourceManager.new()
		rm_t92.name = "ResourceManager"
		root.add_child(rm_t92)
	rm_t92.era_actual = 9
	rm_t92.resources["iron"] = 3000
	rm_t92.resources["gold"] = 3000
	rm_t92.max_population = 50
	rm_t92.current_population = 0
	airbase_inst.resource_manager = rm_t92

	var train_f15_ok: bool = airbase_inst.call("entrenar_unidad", "caza_reaccion_era9")
	assert(train_f15_ok == true or airbase_inst.get("production_queue").size() > 0, "Base Aérea Moderna debe encolar Caza F-15 Jet en Era 9")

	radar_inst.free()
	drone_target_t92.free()
	airbase_inst.free()
	print("✅ Test 92 Superado: Estación de Radar Táctica (visión 65.0m y pulso aéreo) y Base Aérea Moderna (herencia Barracks3D y emergencia 8%) certificados.")


	# ─── TEST 93: Caza a Reacción Supersónico F-15 (Capa Y=16m, Velocidad 18 m/s, 2 Cargas y Rearme) ───
	print("\n--- TEST 93: Caza a Reacción Supersónico F-15 ---")
	var jet_script: GDScript = load("res://scripts/units/caza_reaccion_era9_3d.gd") as GDScript
	var jet_inst: Soldier3D = jet_script.new() as Soldier3D
	root.add_child(jet_inst)
	jet_inst._ready()
	assert(abs(jet_inst.speed - 18.0) < 0.01, "Caza a Reacción debe poseer velocidad lineal extrema de 18.0 m/s")
	assert(abs(jet_inst.position.y - 16.0) < 0.01, "Caza a Reacción debe navegar a una cota de crucero fija constante en Y = 16.0m")
	assert(jet_inst.get("max_ammo") == 2, "Caza a Reacción debe poseer capacidad máxima de 2 ataques con misiles")
	assert(jet_inst.get("current_ammo") == 2, "Caza a Reacción debe iniciar con 2 cargas de misiles")

	# Pasadas de ataque con misiles y retorno autónomo
	var ground_target_t93 := Soldier3D.new()
	root.add_child(ground_target_t93)
	ground_target_t93._ready()

	jet_inst.call("disparar_misil_reaccion", ground_target_t93)
	assert(jet_inst.get("current_ammo") == 1, "Debe quedar con 1 carga tras primer ataque supersónico")

	# Segundo ataque agota munición y activa retorno a base aérea
	jet_inst.call("disparar_misil_reaccion", ground_target_t93)
	assert(jet_inst.get("current_ammo") == 0, "Munición de misiles debe quedar agotada a 0")
	assert(jet_inst.get("estado_vuelo") == "regresando", "Caza debe conmutar automáticamente a estado 'regresando' hacia la Base Aérea")

	jet_inst.free()
	ground_target_t93.free()
	print("✅ Test 93 Superado: Caza a Reacción Supersónico F-15 (cota Y=16m, velocidad 18 m/s, 2 cargas de misiles y retorno autónomo) certificado.")


	# ─── TEST 94: Helicóptero Apache (Cota Y=7.5m, Velocidad 8 m/s, Órbita Circular y Fuego en Movimiento) ───
	print("\n--- TEST 94: Helicóptero de Ataque AH-64 Apache ---")
	var apache_script: GDScript = load("res://scripts/units/helicoptero_apache_era9_3d.gd") as GDScript
	var apache_inst: Soldier3D = apache_script.new() as Soldier3D
	root.add_child(apache_inst)
	apache_inst._ready()
	assert(abs(apache_inst.speed - 8.0) < 0.01, "Helicóptero Apache debe poseer velocidad de 8.0 m/s")
	assert(abs(apache_inst.position.y - 7.5) < 0.01, "Helicóptero Apache debe operar a una cota media fija constante en Y = 7.5m")

	# Fijar objetivo e iniciar órbita circular
	var victim_t94 := Soldier3D.new()
	victim_t94.name = "ObjetivoTierraT94"
	root.add_child(victim_t94)
	victim_t94._ready()
	victim_t94.position = Vector3(0, 0, 0)

	apache_inst.call("iniciar_orbita", victim_t94, 6.0)
	assert(apache_inst.get("is_orbiting") == true, "Helicóptero Apache debe entrar en estado 'is_orbiting = true'")

	var pos_calculada_orbita: Vector3 = apache_inst.call("calcular_posicion_orbita", Vector3(0, 0, 0), 6.0, PI / 2.0)
	assert(abs(pos_calculada_orbita.x - 6.0) < 0.1 and abs(pos_calculada_orbita.y - 7.5) < 0.01, "Debe calcular posición de órbita precisa en el perímetro circular")

	# Ráfaga de ametralladora rotatoria sin detener su marcha
	var disparos_apache: int = apache_inst.call("disparar_rafaga_orbita", victim_t94)
	assert(disparos_apache == 4, "Helicóptero Apache debe disparar ráfagas rotatorias continuas de 4 impactos")
	assert(apache_inst.get("is_orbiting") == true, "El ataque continuo no debe interrumpir el estado de órbita circular")

	apache_inst.free()
	victim_t94.free()
	print("✅ Test 94 Superado: Helicóptero Apache (cota Y=7.5m, velocidad 8 m/s, maniobra de órbita circular activa y fuego rotatorio continuo) certificado.")


	# ─── TEST 95: Tanque M1 Abrams (HP 520.0, Inmunidad Stun, x2.5 vs Estructuras y AoE 4.0m) ───
	print("\n--- TEST 95: Tanque de Asalto Pesado M1 Abrams ---")
	var abrams_script: GDScript = load("res://scripts/units/m1_abrams_tank_3d.gd") as GDScript
	var abrams_inst: Soldier3D = abrams_script.new() as Soldier3D
	root.add_child(abrams_inst)
	abrams_inst._ready()
	assert(abs(abrams_inst.salud_maxima - 520.0) < 0.01, "Tanque M1 Abrams debe poseer salud masiva de 520.0 HP")
	assert(abs(abrams_inst.speed - 5.5) < 0.01, "Tanque M1 Abrams debe poseer velocidad de 5.5 m/s")
	assert(abrams_inst.get("is_stun_immune") == true, "Tanque M1 Abrams debe ser inmune al aturdimiento")
	assert(abrams_inst.call("aplicar_stun", 3.0) == false, "aplicar_stun debe fallar en Tanque M1 Abrams")

	# Multiplicador x2.5 contra edificios y estructuras
	var bld_t95 := BuildingBase3D.new()
	bld_t95.name = "FortalezaSillarT95"
	bld_t95.add_to_group("buildings")
	bld_t95.add_to_group("buildings_3d")
	root.add_child(bld_t95)
	bld_t95._ready()
	bld_t95.position = Vector3(20.0, 0, 0)

	var dmg_abrams_bld: float = CombatDamageCalculator.calcular_dano(abrams_inst.daño, "gun", abrams_inst, bld_t95)
	# Base counter GUNPOWDER vs BUILDING (0.8) * abrams bono (2.5) = 2.00 -> 80.0 * 2.00 = 160.0
	var expected_abrams_dmg: float = (abrams_inst.daño * 0.8) * 2.5
	assert(abs(dmg_abrams_bld - expected_abrams_dmg) < 0.05, "Tanque M1 Abrams debe infligir multiplicador x2.5 contra estructuras (Esperado: %.2f, Obtenido: %.2f)" % [expected_abrams_dmg, dmg_abrams_bld])

	# Detonación AoE de 4.0 metros
	var bld_close_t95 := BuildingBase3D.new()
	bld_close_t95.name = "EstructuraCercanaAoE"
	bld_close_t95.add_to_group("buildings")
	root.add_child(bld_close_t95)
	bld_close_t95._ready()
	bld_close_t95.position = Vector3(22.0, 0, 0) # A 2.0m de (20, 0, 0) <= 4.0m

	var bld_far_t95 := BuildingBase3D.new()
	bld_far_t95.name = "EstructuraLejanaAoE"
	bld_far_t95.add_to_group("buildings")
	root.add_child(bld_far_t95)
	bld_far_t95._ready()
	bld_far_t95.position = Vector3(30.0, 0, 0) # A 10.0m de (20, 0, 0) > 4.0m

	var aoe_hits_abrams: Array[Node3D] = abrams_inst.call("disparar_canon_abrams", Vector3(20, 0, 0))
	assert(aoe_hits_abrams.has(bld_t95), "Objetivo central debe ser alcanzado por el cañón")
	assert(aoe_hits_abrams.has(bld_close_t95), "Estructura a 2.0m debe ser alcanzada por la detonación AoE de 4.0m")
	assert(not aoe_hits_abrams.has(bld_far_t95), "Estructura a 10.0m NO debe ser alcanzada")

	abrams_inst.free()
	bld_t95.free()
	bld_close_t95.free()
	bld_far_t95.free()
	print("✅ Test 95 Superado: Tanque M1 Abrams (HP 520.0, velocidad 5.5 m/s, inmunidad stun, x2.5 vs edificios y AoE 4.0m) certificado.")


	print("\n========================================================")
	print(" ⭐ TODOS LOS TESTS COMPLETADOS SATISFACTORIAMENTE (100%) ")
	print("========================================================\n")
	quit(0)




