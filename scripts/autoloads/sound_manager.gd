## SoundManager — Gestor Autónomo y Sintetizador Procedural de Audio RTS (GDScript 2.0 / Godot 4).
##
## Proporciona canales estéreo UI (jugar_sfx_interfaz) y posicionales 3D (jugar_sfx_3d) sintetizados en memoria.

extends Node

# ─── Instancia Autoload / Acceso Global ─────────────────────────────────────────
static var instance: Node = null

# ─── Pool de Reproductores Audio Estéreo y 3D ────────────────────────────────
var _audio_players: Array[AudioStreamPlayer] = []
var _audio_players_3d: Array[AudioStreamPlayer3D] = []
const POOL_SIZE: int = 16
var _current_player_idx: int = 0
var _current_player_3d_idx: int = 0

# ─── Streams de Audio Procedurales Pre-generados ──────────────────────────────
var stream_hit: AudioStreamWAV = null
var stream_alert: AudioStreamWAV = null
var stream_build: AudioStreamWAV = null
var stream_era: AudioStreamWAV = null
var stream_bell: AudioStreamWAV = null
var stream_click: AudioStreamWAV = null
var stream_chop: AudioStreamWAV = null
var stream_explosion: AudioStreamWAV = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	instance = self
	process_mode = PROCESS_MODE_ALWAYS

	# Generar muestras de audio sintetizadas
	_generate_procedural_streams()

	# Inicializar el pool de reproductores estéreo (UI)
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "RTSAudioPlayer_%d" % i
		player.bus = &"Master"
		add_child(player)
		_audio_players.append(player)

	# Inicializar el pool de reproductores 3D (Mundo 3D)
	for i in range(POOL_SIZE):
		var player_3d := AudioStreamPlayer3D.new()
		player_3d.name = "RTSAudioPlayer3D_%d" % i
		player_3d.bus = &"Master"
		player_3d.max_distance = 60.0
		player_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(player_3d)
		_audio_players_3d.append(player_3d)

	print("SoundManager: Pool de audio UI y 3D posicional (%d canales) inicializado." % POOL_SIZE)

# ─── Generación de Audio Procedural en Memoria ────────────────────────────────

func _generate_procedural_streams() -> void:
	stream_hit = _create_noise_hit_wav(0.12, 44100, 350.0, 80.0)
	stream_alert = _create_tone_wav(0.35, 44100, 784.0, 523.0)
	stream_build = _create_build_wav(0.15, 44100, 220.0, 440.0)
	stream_era = _create_fanfare_wav(0.6, 44100)
	stream_bell = _create_bell_wav(0.8, 44100, 880.0)
	stream_click = _create_click_wav(0.05, 44100, 1200.0)
	stream_chop = _create_chop_wav(0.1, 44100, 180.0)
	stream_explosion = _create_explosion_wav(0.5, 44100)

func _create_noise_hit_wav(duration: float, sample_rate: int, start_freq: float, end_freq: float) -> AudioStreamWAV:
	var num_samples := int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase := 0.0
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var progress: float = t / duration
		var freq := lerpf(start_freq, end_freq, progress)
		phase += (TAU * freq) / float(sample_rate)
		var noise := randf_range(-0.5, 0.5)
		var tone := sin(phase) * 0.5
		var env := exp(-progress * 8.0)
		var val := clampf((noise * 0.6 + tone * 0.4) * env, -1.0, 1.0)
		data[i] = int(clampi(int(val * 127.0 + 128.0), 0, 255))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_tone_wav(duration: float, sample_rate: int, freq1: float, freq2: float) -> AudioStreamWAV:
	var num_samples := int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase := 0.0
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var progress: float = t / duration
		var freq := freq1 if fmod(t, 0.15) < 0.075 else freq2
		phase += (TAU * freq) / float(sample_rate)
		var env := sin(progress * PI)
		var val := clampf(sin(phase) * env * 0.7, -1.0, 1.0)
		data[i] = int(clampi(int(val * 127.0 + 128.0), 0, 255))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_build_wav(duration: float, sample_rate: int, f1: float, f2: float) -> AudioStreamWAV:
	var num_samples := int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase := 0.0
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var progress: float = t / duration
		var freq := lerpf(f1, f2, progress)
		phase += (TAU * freq) / float(sample_rate)
		var env := exp(-progress * 6.0)
		var val := clampf((sin(phase) + randf_range(-0.2, 0.2)) * env * 0.8, -1.0, 1.0)
		data[i] = int(clampi(int(val * 127.0 + 128.0), 0, 255))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_fanfare_wav(duration: float, sample_rate: int) -> AudioStreamWAV:
	var num_samples := int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(num_samples)
	var notes: Array[float] = [261.63, 329.63, 392.00, 523.25]
	var note_duration := duration / float(notes.size())
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var note_idx: int = mini(int(t / note_duration), notes.size() - 1)
		var freq: float = notes[note_idx]
		var sub_t := fmod(t, note_duration)
		var env := sin((sub_t / note_duration) * PI)
		var val := clampf(sin(t * TAU * freq) * env * 0.7, -1.0, 1.0)
		data[i] = int(clampi(int(val * 127.0 + 128.0), 0, 255))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_bell_wav(duration: float, sample_rate: int, freq: float) -> AudioStreamWAV:
	var num_samples := int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 4.0)
		var tone := sin(t * TAU * freq) + sin(t * TAU * freq * 1.5) * 0.4
		var val := clampf(tone * env * 0.6, -1.0, 1.0)
		data[i] = int(clampi(int(val * 127.0 + 128.0), 0, 255))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_click_wav(duration: float, sample_rate: int, freq: float) -> AudioStreamWAV:
	var num_samples := int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 40.0)
		var val := clampf(sin(t * TAU * freq) * env * 0.5, -1.0, 1.0)
		data[i] = int(clampi(int(val * 127.0 + 128.0), 0, 255))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_chop_wav(duration: float, sample_rate: int, freq: float) -> AudioStreamWAV:
	var num_samples := int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 15.0)
		var noise := randf_range(-0.6, 0.6)
		var tone := sin(t * TAU * freq) * 0.3
		var val := clampf((noise + tone) * env * 0.7, -1.0, 1.0)
		data[i] = int(clampi(int(val * 127.0 + 128.0), 0, 255))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_explosion_wav(duration: float, sample_rate: int) -> AudioStreamWAV:
	var num_samples := int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 5.0)
		var noise := randf_range(-1.0, 1.0)
		var val := clampf(noise * env * 0.8, -1.0, 1.0)
		data[i] = int(clampi(int(val * 127.0 + 128.0), 0, 255))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

# ─── API Pública de Sonido UI e Interfaz ──────────────────────────────────────

func jugar_sfx_interfaz(sfx_id: String) -> void:
	match sfx_id.to_lower():
		"town_bell":
			play_stream(stream_bell, 2.0, 1.0)
		"minimap_alert", "alert":
			play_stream(stream_alert, 0.0, 1.0)
		"buy_click", "click":
			play_stream(stream_click, -4.0, randf_range(0.95, 1.05))
		"era_evolution", "era":
			play_stream(stream_era, 2.0, 1.0)
		_:
			play_stream(stream_click, -4.0, 1.0)

# ─── API Pública de Sonido 3D Posicional ──────────────────────────────────────

func jugar_sfx_3d(sfx_id: String, posicion_3d: Vector3) -> void:
	if _audio_players_3d.is_empty():
		return

	var st: AudioStream = stream_hit
	var vol: float = 0.0
	var pitch: float = 1.0

	match sfx_id.to_lower():
		"wood_chop", "chop":
			st = stream_chop
			pitch = randf_range(0.9, 1.1)
		"mining_pick", "mine":
			st = stream_hit
			pitch = randf_range(1.2, 1.4)
		"arrow_fly", "arrow":
			st = stream_hit
			pitch = randf_range(1.5, 1.8)
		"cannon_explosion", "explosion":
			st = stream_explosion
			vol = 3.0
			pitch = randf_range(0.8, 1.0)
		"prophet_chant", "chant":
			st = stream_bell
			pitch = 0.7
		_:
			st = stream_hit
			pitch = randf_range(0.9, 1.1)

	var player3d := _audio_players_3d[_current_player_3d_idx]
	_current_player_3d_idx = (_current_player_3d_idx + 1) % POOL_SIZE

	player3d.stop()
	player3d.global_position = posicion_3d
	player3d.stream = st
	player3d.volume_db = vol
	player3d.pitch_scale = pitch
	player3d.play()

# ─── Métodos Auxiliares Directos ──────────────────────────────────────────────

func play_stream(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null or _audio_players.is_empty():
		return
	var player := _audio_players[_current_player_idx]
	_current_player_idx = (_current_player_idx + 1) % POOL_SIZE
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func play_hit_sound(_pos: Vector3 = Vector3.ZERO) -> void:
	jugar_sfx_3d("hit", _pos)

func play_attack_alert() -> void:
	jugar_sfx_interfaz("minimap_alert")

func play_build_sound() -> void:
	play_stream(stream_build, -2.0, randf_range(0.9, 1.1))

func play_era_sound() -> void:
	jugar_sfx_interfaz("era_evolution")
