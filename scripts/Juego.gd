extends Node2D

# —— Escenas y límites ——
@export var escena_basura: PackedScene
@export var limites_mapa: Rect2 = Rect2(Vector2(64, 64), Vector2(1024, 576))

# —— Parámetros de ronda y dificultad ——
@export var duracion_ronda_seg: int = 90
@export var intervalo_spawn_base: float = 2.0
@export var intervalo_spawn_min: float = 1.0
@export var paso_dificultad_seg: float = 20.0

# —— Modelo de limpieza/contaminación ——
@export var limpieza_inicial: float = 70.0
@export var contaminacion_por_seg: float = 5.0
@export var contaminacion_por_basura: float = 0.35
@export var limpieza_por_recoger: float = 8.0   # cuanto sube al recoger (%)

@onready var contenedor_basura: Node = $TrashContainer
@onready var temporizador_spawn: Timer = $SpawnTimer
@onready var temporizador_ronda: Timer = $RoundTimer
@onready var temporizador_dificultad: Timer = $DifficultyTimer
@onready var jugador: Node2D = $Player
@onready var hud: CanvasLayer = $HUD

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# —— Estado de la partida ——
var limpieza: float
var seg_restantes: int
var muestras_limpieza: int = 0
var limpieza_acumulada: float = 0.0
var ronda_activa: bool = false
var intervalo_spawn_actual: float

func _ready() -> void:
	add_to_group("juego")
	rng.randomize()

	_asegurar_timers()
	_conectar_timers()

	# Conectar señales del HUD (pausa + resultados)
	if is_instance_valid(hud):
		if hud.has_signal("config_requested"):
			hud.connect("config_requested", Callable(self, "_on_hud_config"))
		if hud.has_signal("exit_requested"):
			hud.connect("exit_requested", Callable(self, "_on_hud_exit"))
		if hud.has_signal("retry_requested"):
			hud.connect("retry_requested", Callable(self, "_on_hud_retry"))
		if hud.has_signal("select_world_requested"):
			hud.connect("select_world_requested", Callable(self, "_on_hud_select_world"))

	_iniciar_ronda()

# ————————————————— Timers —————————————————

func _asegurar_timers() -> void:
	if not is_instance_valid(temporizador_spawn):
		temporizador_spawn = Timer.new()
		add_child(temporizador_spawn)
	if not is_instance_valid(temporizador_ronda):
		temporizador_ronda = Timer.new()
		add_child(temporizador_ronda)
	if not is_instance_valid(temporizador_dificultad):
		temporizador_dificultad = Timer.new()
		add_child(temporizador_dificultad)

func _conectar_timers() -> void:
	temporizador_spawn.timeout.connect(_spawn_basura)
	temporizador_ronda.timeout.connect(_tick_ronda)
	temporizador_dificultad.timeout.connect(_subir_dificultad)

# ————————————————— Ronda —————————————————

func _iniciar_ronda() -> void:
	# Estado inicial
	limpieza = limpieza_inicial
	seg_restantes = duracion_ronda_seg
	muestras_limpieza = 0
	limpieza_acumulada = 0.0
	ronda_activa = true
	intervalo_spawn_actual = intervalo_spawn_base
	_limpiar_basuras()

	# UI
	(hud as Node).call("set_estado", "")
	(hud as Node).call("set_stars", 0)
	(hud as Node).call("set_limpieza", limpieza)
	(hud as Node).call("set_tiempo", seg_restantes)
	# Por si venimos de resultados/pausa, pide al HUD ocultar overlays si tiene esos métodos
	if (hud as Node).has_method("_hide_results_ui"):
		(hud as Node).call("_hide_results_ui")
	if (hud as Node).has_method("_hide_pause_ui"):
		(hud as Node).call("_hide_pause_ui")

	# Timers
	temporizador_spawn.one_shot = false
	temporizador_spawn.wait_time = intervalo_spawn_actual
	temporizador_spawn.start()

	temporizador_ronda.one_shot = false
	temporizador_ronda.wait_time = 1.0
	temporizador_ronda.start()

	temporizador_dificultad.one_shot = false
	temporizador_dificultad.wait_time = paso_dificultad_seg
	temporizador_dificultad.start()

func _end_ronda(victoria: bool) -> void:
	ronda_activa = false
	temporizador_spawn.stop()
	temporizador_ronda.stop()
	temporizador_dificultad.stop()

	var limpieza_media: float = (limpieza_acumulada / float(muestras_limpieza)) if muestras_limpieza > 0 else limpieza
	var estrellas: int = _estrellas_por_limpieza(limpieza_media)

	(hud as Node).call("set_stars", estrellas)
	(hud as Node).call("set_estado", "")

	# Muestra panel de resultados (pausa el juego desde el HUD)
	(hud as Node).call("show_results", victoria, estrellas, limpieza_media)

# ————————————————— Bucle de juego —————————————————

func _process(delta: float) -> void:
	if not ronda_activa:
		return

	# Subida de contaminación continua + por basura en escena
	var n_basura: int = contenedor_basura.get_child_count()
	var delta_contaminacion: float = contaminacion_por_seg * delta + float(n_basura) * contaminacion_por_basura * delta
	limpieza -= delta_contaminacion
	limpieza = clampf(limpieza, 0.0, 100.0)
	(hud as Node).call("set_limpieza", limpieza)

	if limpieza <= 0.0:
		_end_ronda(false)

func _tick_ronda() -> void:
	if not ronda_activa:
		return
	seg_restantes -= 1
	(hud as Node).call("set_tiempo", seg_restantes)

	# Muestreo para limpieza media
	limpieza_acumulada += clampf(limpieza, 0.0, 100.0)
	muestras_limpieza += 1

	if seg_restantes <= 0:
		_end_ronda(true)

func _subir_dificultad() -> void:
	intervalo_spawn_actual = maxf(intervalo_spawn_min, intervalo_spawn_actual - 0.25)
	temporizador_spawn.wait_time = intervalo_spawn_actual

# ————————————————— Basura —————————————————

func _spawn_basura() -> void:
	if escena_basura == null:
		push_warning("Asigna 'escena_basura' en el Inspector (Trash.tscn).")
		return
	var t: Area2D = escena_basura.instantiate()
	t.position = _punto_aleatorio()
	t.collected.connect(_al_recoger_basura)
	contenedor_basura.add_child(t)

func collect_nearby() -> void:
	# Llamado por el Player al presionar 'recoger' / 'ui_accept'
	for c in contenedor_basura.get_children():
		if c.has_method("try_collect") and c.try_collect():
			break

func _al_recoger_basura() -> void:
	# Recompensa al recoger
	limpieza = clampf(limpieza + limpieza_por_recoger, 0.0, 100.0)
	(hud as Node).call("set_limpieza", limpieza)
	# Si tienes SFX: $SfxPickup.play()

# ————————————————— Utilidades —————————————————

func _punto_aleatorio() -> Vector2:
	return Vector2(
		rng.randf_range(limites_mapa.position.x, limites_mapa.position.x + limites_mapa.size.x),
		rng.randf_range(limites_mapa.position.y, limites_mapa.position.y + limites_mapa.size.y)
	)

func _limpiar_basuras() -> void:
	for c in contenedor_basura.get_children():
		c.queue_free()

func _estrellas_por_limpieza(avg: float) -> int:
	if avg >= 90.0:
		return 3
	if avg >= 75.0:
		return 2
	if avg >= 60.0:
		return 1
	return 0

# ————————————————— Callbacks del HUD —————————————————

func _on_hud_retry() -> void:
	get_tree().paused = false
	# Pide al HUD cerrar overlays si expone métodos internos (los añadimos en HUD.gd)
	if (hud as Node).has_method("_hide_results_ui"):
		(hud as Node).call("_hide_results_ui")
	if (hud as Node).has_method("_hide_pause_ui"):
		(hud as Node).call("_hide_pause_ui")
	_iniciar_ronda()

func _on_hud_select_world() -> void:
	get_tree().paused = false
	if (hud as Node).has_method("_hide_results_ui"):
		(hud as Node).call("_hide_results_ui")
	if (hud as Node).has_method("_hide_pause_ui"):
		(hud as Node).call("_hide_pause_ui")
	# Cambia a tu selector de ambientes cuando lo tengas:
	# get_tree().change_scene_to_file("res://escenas/WorldSelect.tscn")
	print("Ir al selector de ambientes… (cambia la escena aquí)")

func _on_hud_config() -> void:
	# Abre tu escena/panel de configuración
	# get_tree().paused = false
	# get_tree().change_scene_to_file("res://escenas/configuracion.tscn")
	print("Abrir configuración…")

func _on_hud_exit() -> void:
	get_tree().paused = false
	# O cambia a menú principal si lo tienes:
	# get_tree().change_scene_to_file("res://escenas/MainMenu.tscn")
	get_tree().quit()
