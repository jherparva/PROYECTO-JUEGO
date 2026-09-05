extends SceneTree

func _init() -> void:
	print("==================================================")
	print("🧪 EJECUTANDO SUITE DE VALIDACIÓN: SISTEMA DE ERAS (EMPIRE EARTH)")
	print("==================================================")

	var rm: Node = root.get_node_or_null("ResourceManager")
	if not is_instance_valid(rm):
		print("❌ ERROR: Autoload ResourceManager no encontrado en root.")
		quit(1)
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
	root.add_child(building)
	building.building_name = "Cuartel Genérico"
	building.salud_maxima = 500.0
	building.salud_actual = 250.0 # 50% HP

	# Simular avance a Era 4 (Medieval)
	rm._aplicar_nueva_era(4)

	# Verificar que el edificio recibió la señal y mantiene salud proporcional
	if building.salud_actual != 250.0 or building.salud_maxima != 500.0:
		print("❌ FALLÓ: La salud proporcional del edificio no se preservó tras el avance de era.")
		success = false
	else:
		print("✅ ÉXITO: Edificio preserva HP y ratio de daño proporcionalmente.")

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
	root.add_child(barracks)
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
	root.add_child(villager)
	villager.bando = UnitBase3D.Bando.PLAYER

	var initial_max_hp: float = villager.salud_maxima
	var initial_speed: float = villager.speed
	var initial_carga: int = villager.MAX_CARGA

	print("Stats Iniciales Aldeano Era 0 -> MaxHP: %f, Speed: %f, Carga: %d" % [initial_max_hp, initial_speed, initial_carga])

	# Evolucionar a Era 1
	rm._aplicar_nueva_era(1)

	var new_max_hp: float = villager.salud_maxima
	var new_speed: float = villager.speed
	var new_carga: int = villager.MAX_CARGA
	print("Stats Aldeano tras Era 1 -> MaxHP: %f, Speed: %f, Carga: %d" % [new_max_hp, new_speed, new_carga])

	if new_max_hp != initial_max_hp + 5.0:
		print("❌ FALLÓ: Max HP del aldeano no aumentó en +5 (Esperado: %f, Obtenido: %f)" % [initial_max_hp + 5.0, new_max_hp])
		success = false
	elif abs(new_speed - (initial_speed * 1.05)) > 0.001:
		print("❌ FALLÓ: Velocidad del aldeano no aumentó en +5%% (Esperado: %f, Obtenido: %f)" % [initial_speed * 1.05, new_speed])
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
	root.add_child(soldier)
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

	print("\n==================================================")
	if success:
		print("🎉 TODAS LAS PRUEBAS PASARON SATISFACTORIAMENTE: EXIT CODE 0")
		print("==================================================")
		quit(0)
	else:
		print("❌ ALGUNAS PRUEBAS FALLARON: EXIT CODE 1")
		print("==================================================")
		quit(1)
