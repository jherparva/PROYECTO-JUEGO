## TerrainModifierManager — Gestor de Ventaja Táctica por Altura del Terreno (GDScript 2.0 / Godot 4).
##
## Calcula los modificadores de daño en combate 3D según el diferencial en el eje Y:
## - Atacante en colina (Y_atacante - Y_objetivo > 1.5m): +25% Daño Extra (1.25x).
## - Atacante en terreno bajo (Y_atacante - Y_objetivo < -1.5m): -15% Penalización de Daño (0.85x).
## - Terreno llano (|delta_y| <= 1.5m): Daño estándar (1.0x).

class_name TerrainModifierManager
extends Node

const ALTURA_UMBRAL_METROS: float = 1.5
const MULTIPLICADOR_ALTURA_ALTA: float = 1.25 # +25% daño
const MULTIPLICADOR_ALTURA_BAJA: float = 0.85 # -15% daño
const MULTIPLICADOR_ESTANDAR: float = 1.0

# ─── API Estática de Geometría de Combate ─────────────────────────────────────

## Retorna el multiplicador de daño resultante según la elevación en el eje Y.
static func calcular_modificador_daño(atacante: Node3D, objetivo: Node3D) -> float:
	if not is_instance_valid(atacante) or not is_instance_valid(objetivo):
		return MULTIPLICADOR_ESTANDAR

	var delta_y := atacante.global_position.y - objetivo.global_position.y

	if delta_y > ALTURA_UMBRAL_METROS:
		return MULTIPLICADOR_ALTURA_ALTA
	elif delta_y < -ALTURA_UMBRAL_METROS:
		return MULTIPLICADOR_ALTURA_BAJA

	return MULTIPLICADOR_ESTANDAR

## Retorna true si la unidad se encuentra en posición de ventaja de altura frente al mapa circundante.
static func tiene_ventaja_altura(unidad: Node3D) -> bool:
	if not is_instance_valid(unidad):
		return false
	return unidad.global_position.y > ALTURA_UMBRAL_METROS
