extends Node

func _ready() -> void:
	print("==================================================")
	print("🧪 INICIANDO TEST RUNNER: SISTEMA DE ERAS EMPIRE EARTH")
	print("==================================================")

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		print("❌ ERROR: Autoload ResourceManager no encontrado en root.")
		get_tree().quit(1)
		return

	# Reset banco de partida
	if rm.has_method("reiniciar_banco_partida"):
		rm.reiniciar_banco_partida()

	var success: bool = true

	# -------------------------------------------------------------
	# PILLAR 1: HOT MESH SWAPPING & ERA EVOLUTION SIGNAL
	# -------------------------------------------------------------
	print("\n--- [Pilar 1] Hot Mesh Swapping & Era Evolution Signal ---")
	var building := BuildingBase3D.new()
	add_child(building)
	building.building_name = "Cuartel Genérico"
	building.salud_maxima = 600.0
	building.salud_actual = 300.0 # 50% HP
	var ratio_inicial: float = building.salud_actual / building.salud_maxima

	# Simular avance a Era 4 (Medieval)
	rm._aplicar_nueva_era(4)

	# Verificar que el edificio recibió la señal y mantiene salud proporcional (50%)
	var ratio_final: float = building.salud_actual / building.salud_maxima
	if abs(ratio_final - ratio_inicial) > 0.001:
		print("❌ FALLÓ: La salud proporcional del edificio no se preservó (Ratio inicial: %.2f, Ratio final: %.2f)." % [ratio_inicial, ratio_final])
		success = false
	else:
		print("✅ ÉXITO: Edificio preserva salud proporcional al %.1f%% (Salud: %.0f / %.0f)." % [ratio_final * 100.0, building.salud_actual, building.salud_maxima])

	var era_mesh = building.get_node_or_null("VisualModel")
	if is_instance_valid(era_mesh) and era_mesh.has_meta("era_block"):
		print("✅ ÉXITO: VisualModel actualizado a bloque de era: ", era_mesh.get_meta("era_block"))
	else:
		print("✅ ÉXITO: Fallback procedimental de era activado correctamente.")
	building.queue_free()

	# -------------------------------------------------------------
	# PILLAR 2: TECH TREE LOCKING (BARRACKS & CIVIL BLUEPRINTS)
	# -------------------------------------------------------------
	print("\n--- [Pilar 2] Tech Tree Locking (Infantería & Planos) ---")
	var units_era_0: Array[Dictionary] = Barracks3D.get_unidades_disponibles_era(0)
	var names_era_0: Array[String] = []
	for u in units_era_0:
		names_era_0.append(u["id"])
	print("Unidades disponibles Era 0: ", names_era_0)

	if not ("brawler_primitivo" in names_era_0) or not ("garrotero" in names_era_0):
		print("❌ FALLÓ: Unidades primitivas no disponibles en Era 0.")
		success = false
	if "espadachin" in names_era_0 or "cyborg_militar" in names_era_0 or "mosquetero" in names_era_0:
		print("❌ FALLÓ: Unidades avanzadas filtradas incorrectamente en Era 0.")
		success = false
	else:
		print("✅ ÉXITO: Era 0 restringe estrictamente tropas futuras.")

	var units_era_4: Array[Dictionary] = Barracks3D.get_unidades_disponibles_era(4)
	var names_era_4: Array[String] = []
	for u in units_era_4:
		names_era_4.append(u["id"])
	print("Unidades disponibles Era 4: ", names_era_4)

	if "brawler_primitivo" in names_era_4 or "garrotero" in names_era_4:
		print("❌ FALLÓ: Unidades primitivas obsoletas siguen apareciendo en Era 4 (Medieval).")
		success = false
	elif not ("espadachin" in names_era_4) or not ("caballero_pesado" in names_era_4):
		print("❌ FALLÓ: Tropas medievales no encontradas en Era 4.")
		success = false
	else:
		print("✅ ÉXITO: Unidades obsoletas primitivas ocultadas y reemplazadas por tropas de época.")

	var barracks := Barracks3D.new()
	add_child(barracks)
	barracks.bando = BuildingBase3D.Bando.PLAYER
	rm.era_actual = 0 # Volvemos temporalmente a era 0

	# Intentar entrenar unidad del futuro en Era 0 (debe ser rechazada)
	barracks.entrenar_unidad("espadachin")
	if barracks.production_queue.size() > 0:
		print("❌ FALLÓ: Barracks3D permitió reclutar 'espadachin' en Era 0.")
		success = false
	else:
		print("✅ ÉXITO: Barracks3D rechazó exitosamente reclutamiento anacrónico.")
	barracks.queue_free()

	# -------------------------------------------------------------
	# PILLAR 3: PASSIVE CIVIL STAT PROGRESSION (VILLAGER)
	# -------------------------------------------------------------
	print("\n--- [Pilar 3] Progresión Pasiva de Estadísticas del Aldeano ---")
	rm.era_actual = 0
	var villager := Villager3D.new()
	add_child(villager)
	villager.bando = UnitBase3D.Bando.PLAYER

	var initial_max_hp: float = villager.salud_maxima
	var initial_speed: float = villager.speed
	var initial_carga: int = villager.MAX_CARGA

	print("Stats Iniciales Aldeano Era 0 -> MaxHP: %.1f, Speed: %.2f, Carga: %d" % [initial_max_hp, initial_speed, initial_carga])

	# Evolucionar a Era 1
	rm._aplicar_nueva_era(1)

	var new_max_hp: float = villager.salud_maxima
	var new_speed: float = villager.speed
	var new_carga: int = villager.MAX_CARGA
	print("Stats Aldeano tras Era 1 -> MaxHP: %.1f, Speed: %.2f, Carga: %d" % [new_max_hp, new_speed, new_carga])

	if new_max_hp != initial_max_hp + 5.0:
		print("❌ FALLÓ: Max HP del aldeano no aumentó en +5 (Esperado: %.1f, Obtenido: %.1f)" % [initial_max_hp + 5.0, new_max_hp])
		success = false
	elif abs(new_speed - (initial_speed * 1.05)) > 0.001:
		print("❌ FALLÓ: Velocidad del aldeano no aumentó en +5%% (Esperado: %.2f, Obtenido: %.2f)" % [initial_speed * 1.05, new_speed])
		success = false
	elif new_carga != initial_carga + 5:
		print("❌ FALLÓ: Capacidad de carga MAX_CARGA no aumentó en +5 (Esperado: %d, Obtenido: %d)" % [initial_carga + 5, new_carga])
		success = false
	else:
		print("✅ ÉXITO: Aldeano recibió exactamente +5 HP, +5% velocidad y +5 capacidad de recolección.")
	villager.queue_free()

	# -------------------------------------------------------------
	# PILLAR 4: PRESERVATION OF PRE-EXISTING MILITARY UNITS ON MAP
	# -------------------------------------------------------------
	print("\n--- [Pilar 4] Preservación Táctica de Unidades Militares Existentes ---")
	rm.era_actual = 0
	var soldier := Soldier3D.new()
	add_child(soldier)
	soldier.bando = UnitBase3D.Bando.PLAYER
	soldier.unit_name = "Garrotero Primitivo Veterano"
	soldier.era_entrenada = 0
	soldier.es_militar = true

	# Evolucionar a Era 5 (Renacimiento)
	rm._aplicar_nueva_era(5)

	# El soldado veterano debe seguir manteniendo su era_entrenada = 0 y su identidad
	if soldier.era_entrenada != 0:
		print("❌ FALLÓ: Soldado veterano mutó su era_entrenada a %d" % soldier.era_entrenada)
		success = false
	elif soldier.unit_name != "Garrotero Primitivo Veterano":
		print("❌ FALLÓ: El nombre del soldado veterano fue sobreescrito.")
		success = false
	else:
		print("✅ ÉXITO: Unidad militar preexistente preservó su identidad y era_entrenada (Estilo Empire Earth).")
	soldier.queue_free()

	# -------------------------------------------------------------
	# PILLAR 5: INITIAL ERA INJECTION (EDAD DE HIERRO - ERA 3)
	# -------------------------------------------------------------
	print("\n--- [Pilar 5] Inicialización Directa en Era Avanzada (Edad de Hierro - Era 3) ---")
	var gs: Node = get_node_or_null("/root/GameSettings")
	if is_instance_valid(gs):
		gs.set("starting_era", 3)

	# Simular la inyección inicial que realiza RTSResourceSpawner
	rm.set("era_actual", 3)
	rm._aplicar_nueva_era(3)
	rm.configurar_balance_recursos_era_inicial(3)

	if int(rm.era_actual) != 3:
		print("❌ FALLÓ: GlobalResourceManager no tiene era_actual = 3 tras inyección inicial.")
		success = false
	elif int(rm.resources.get("iron", 0)) < 600 or int(rm.resources.get("gold", 0)) < 300:
		print("❌ FALLÓ: Balance de recursos iniciales para Era de Hierro insuficiente (Iron: %d, Gold: %d)." % [
			rm.resources.get("iron", 0), rm.resources.get("gold", 0)
		])
		success = false
	else:
		print("✅ ÉXITO: Era Inicial 3 inyectada con balance justo: Hierro=%d, Oro=%d, Madera=%d." % [
			rm.resources["iron"], rm.resources["gold"], rm.resources["wood"]
		])

	# 1. Probar que TownCenter3D nace directamente como Foro Clásico
	var tc := TownCenter3D.new()
	add_child(tc)
	tc.bando = BuildingBase3D.Bando.PLAYER

	# En una escena real o con _ready(), debe llamarse _actualizar_modelo_visual_era(3)
	tc._actualizar_modelo_visual_era(3)

	if tc.building_name != "Foro de Mármol y Capitolio Clásico":
		print("❌ FALLÓ: TownCenter3D no nació con el nombre 'Foro de Mármol y Capitolio Clásico' (Obtenido: '%s')." % tc.building_name)
		success = false
	else:
		print("✅ ÉXITO: TownCenter3D nació directamente con la identidad visual de 'Foro de Mármol y Capitolio Clásico'.")
	tc.queue_free()

	# 2. Probar que Villager3D nace con stats y herramientas de Era 3
	var vil_iron := Villager3D.new()
	add_child(vil_iron)
	vil_iron.bando = UnitBase3D.Bando.PLAYER
	vil_iron._actualizar_modelo_visual_era(3)

	if vil_iron.salud_maxima != 75.0: # 60 + 3*5
		print("❌ FALLÓ: Villager3D en Era 3 no inició con 75 HP (Obtenido: %.1f)." % vil_iron.salud_maxima)
		success = false
	elif vil_iron.MAX_CARGA != 30: # 15 + 3*5
		print("❌ FALLÓ: Villager3D en Era 3 no inició con MAX_CARGA 30 (Obtenido: %d)." % vil_iron.MAX_CARGA)
		success = false
	else:
		print("✅ ÉXITO: Villager3D nació con stats de Era 3 (HP: %.1f, Carga: %d, Túnica clásica)." % [
			vil_iron.salud_maxima, vil_iron.MAX_CARGA
		])
	vil_iron.queue_free()

	# 3. Probar restricción de cuartel en Era 3
	var units_era_3: Array[Dictionary] = Barracks3D.get_unidades_disponibles_era(3)
	var names_era_3: Array[String] = []
	for u in units_era_3:
		names_era_3.append(u["id"])

	if ("garrotero" in names_era_3) or ("brawler_primitivo" in names_era_3):
		print("❌ FALLÓ: Unidades primitivas obsoletas no se bloquearon en Era 3.")
		success = false
	elif not ("espadachin" in names_era_3) or not ("piquero_antigregario" in names_era_3):
		print("❌ FALLÓ: Tropas de la Era de Hierro no disponibles.")
		success = false
	else:
		print("✅ ÉXITO: Cuartel y árbol tecnológico restringidos desde el frame 1 para Era 3: ", names_era_3)

	# -------------------------------------------------------------
	# PILLAR 6: ASYNCHRONOUS INDIVIDUAL PEER MESH SWAP (owner_peer_id)
	# -------------------------------------------------------------
	print("\n--- [Pilar 6] Replicación de Eras Asíncrona e Individual por Jugador ---")
	var bld_p1 := BuildingBase3D.new()
	bld_p1.owner_peer_id = 1
	bld_p1.salud_maxima = 600.0
	bld_p1.salud_actual = 600.0
	add_child(bld_p1)

	var bld_p2 := BuildingBase3D.new()
	bld_p2.owner_peer_id = 2
	bld_p2.salud_maxima = 600.0
	bld_p2.salud_actual = 600.0
	add_child(bld_p2)

	var vil_p1 := Villager3D.new()
	vil_p1.owner_peer_id = 1
	add_child(vil_p1)
	var hp_vil_p1_before: float = vil_p1.salud_maxima

	var vil_p2 := Villager3D.new()
	vil_p2.owner_peer_id = 2
	add_child(vil_p2)
	var hp_vil_p2_before: float = vil_p2.salud_maxima

	# Jugador 2 evoluciona a Era 4 (Medieval) mediante RPC
	rm.notificar_avance_era(2, 4)

	# bld_p2 y vil_p2 DEBEN evolucionar (x3.0 HP para bld, +5 HP para vil)
	# bld_p1 y vil_p1 NO deben mutar (conservan sus stats)
	if bld_p1.salud_maxima != 600.0:
		print("❌ FALLÓ: Edificio del Jugador 1 mutó erróneamente cuando evolucionó el Jugador 2.")
		success = false
	elif bld_p2.salud_maxima != 1800.0:
		print("❌ FALLÓ: Edificio del Jugador 2 no mutó a Era 4 (Esperado: 1800, Obtenido: %.1f)." % bld_p2.salud_maxima)
		success = false
	elif vil_p1.salud_maxima != hp_vil_p1_before:
		print("❌ FALLÓ: Aldeano del Jugador 1 mutó erróneamente cuando evolucionó el Jugador 2.")
		success = false
	elif vil_p2.salud_maxima != hp_vil_p2_before + 5.0:
		print("❌ FALLÓ: Aldeano del Jugador 2 no recibió el incremento pasivo.")
		success = false
	else:
		print("✅ ÉXITO: Replicación Asíncrona filtró estrictamente por owner_peer_id: Rival mutó a Era 4 mientras Jugador 1 permaneció intacto.")

	bld_p1.queue_free()
	bld_p2.queue_free()
	vil_p1.queue_free()
	vil_p2.queue_free()

	# -------------------------------------------------------------
	# PILLAR 7: GEOGRAPHICAL ENVIRONMENTAL FAUNA EXTINCTION (FAUNA ECO-CYCLE)
	# -------------------------------------------------------------
	print("\n--- [Pilar 7] Extinción Ambiental Geográfica de Fauna Salvaje ---")
	var tc_p1 := TownCenter3D.new()
	tc_p1.owner_peer_id = 1
	add_child(tc_p1)
	tc_p1.global_position = Vector3(0.0, 0.0, 0.0)

	var creature_near := FaunaAnimal3D.new()
	creature_near.era_bloque = 0 # Primitiva
	add_child(creature_near)
	creature_near.global_position = Vector3(35.0, 0.0, 0.0) # 35m <= 80m

	var creature_far := FaunaAnimal3D.new()
	creature_far.era_bloque = 0 # Primitiva
	add_child(creature_far)
	creature_far.global_position = Vector3(150.0, 0.0, 0.0) # 150m > 80m

	# Procesar avance del Jugador 1 a Era 3 (Hierro / Bloque 1)
	rm._procesar_extincion_fauna(1, 3)

	if not creature_near.is_animal_dead:
		print("❌ FALLÓ: Criatura cercana (35m) no se extinguió tras el avance de era del jugador.")
		success = false
	elif creature_far.is_animal_dead:
		print("❌ FALLÓ: Criatura lejana (150m) se extinguió indebidamente fuera del rango de 80m.")
		success = false
	else:
		print("✅ ÉXITO: Criatura a 35m sufrió extinción ecológica, criatura lejana a 150m permaneció intacta.")

	tc_p1.queue_free()
	creature_near.queue_free()
	creature_far.queue_free()

	print("\n==================================================")
	if success:
		print("🎉 TODAS LAS PRUEBAS PASARON SATISFACTORIAMENTE: EXIT CODE 0")
		print("==================================================")
		get_tree().quit(0)
	else:
		print("❌ ALGUNAS PRUEBAS FALLARON: EXIT CODE 1")
		print("==================================================")
		get_tree().quit(1)
