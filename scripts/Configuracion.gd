extends Control
class_name MenuConfiguracion

# ---------- Utils ----------
func _lin_to_db(value: float) -> float:
	if value <= 0.0001:
		return -80.0
	return linear_to_db(value)

# ---------- Resoluciones ----------
const RES_LIST: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

# ---------- Archivo de configuración ----------
const CFG_PATH := "user://settings.cfg"
const CFG_SECTION := "video_audio"

# ---------- Referencias UI (usan % + Unique Name) ----------
@onready var btn_volver: Button       = %ButtonVolver
@onready var btn_guardar: Button      = %Guardar

@onready var chk_fullscreen: CheckBox = %PantallaCompleta
@onready var chk_vsync: CheckBox      = %VSync
@onready var opt_res: OptionButton    = %OptionButton

@onready var sld_master: HSlider      = %HSliderVolumen
@onready var chk_music: CheckBox      = %ChkMusica
@onready var sld_music: HSlider       = %SldMusica
@onready var chk_fx: CheckBox         = %ChkFX
@onready var sld_fx: HSlider          = %SldFX

# ---------- Estado ----------
var settings := {
	"fullscreen": false,
	"vsync": true,
	"resolution": Vector2i(1280, 720),
	"master": 0.8,
	"music": 0.8,
	"sfx": 0.8,
	"music_enabled": true,
	"sfx_enabled": true
}

func _ready() -> void:
	# Poblar resoluciones
	opt_res.clear()
	for i in RES_LIST.size():
		var r: Vector2i = RES_LIST[i]
		opt_res.add_item("%dx%d" % [r.x, r.y], i)

	_load_cfg()
	_sync_ui_from_settings()
	_apply_all_settings()

	# Conexiones
	btn_guardar.pressed.connect(_on_guardar_pressed)
	btn_volver.pressed.connect(_on_volver_pressed)

	chk_fullscreen.toggled.connect(_on_fullscreen_toggled)
	chk_vsync.toggled.connect(_on_vsync_toggled)
	opt_res.item_selected.connect(_on_res_selected)

	sld_master.value_changed.connect(_on_master_changed)
	chk_music.toggled.connect(_on_music_enabled_toggled)
	sld_music.value_changed.connect(_on_music_changed)
	chk_fx.toggled.connect(_on_fx_enabled_toggled)
	sld_fx.value_changed.connect(_on_fx_changed)

# ----------------- VIDEO -----------------
func _apply_video() -> void:
	if settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	if settings.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	if not settings.fullscreen:
		get_window().size = settings.resolution

# ----------------- AUDIO -----------------
func _apply_audio() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_idx, _lin_to_db(settings.master))
	AudioServer.set_bus_mute(master_idx, settings.master <= 0.001)

	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, _lin_to_db(settings.music))
		AudioServer.set_bus_mute(music_idx, (not settings.music_enabled) or settings.music <= 0.001)

	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, _lin_to_db(settings.sfx))
		AudioServer.set_bus_mute(sfx_idx, (not settings.sfx_enabled) or settings.sfx <= 0.001)

func _apply_all_settings() -> void:
	_apply_video()
	_apply_audio()

# ----------------- HANDLERS UI -----------------
func _on_guardar_pressed() -> void:
	_save_cfg()
	print("Preferencias guardadas en ", CFG_PATH)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://tu_escena_menu_principal.tscn")

func _on_fullscreen_toggled(pressed: bool) -> void:
	settings.fullscreen = pressed
	_apply_video()

func _on_vsync_toggled(pressed: bool) -> void:
	settings.vsync = pressed
	_apply_video()

func _on_res_selected(index: int) -> void:
	var id := opt_res.get_item_id(index)
	settings.resolution = RES_LIST[id]
	if not settings.fullscreen:
		get_window().size = settings.resolution

func _on_master_changed(v: float) -> void:
	settings.master = clamp(v, 0.0, 1.0)
	_apply_audio()

func _on_music_enabled_toggled(pressed: bool) -> void:
	settings.music_enabled = pressed
	sld_music.editable = pressed
	_apply_audio()

func _on_music_changed(v: float) -> void:
	settings.music = clamp(v, 0.0, 1.0)
	_apply_audio()

func _on_fx_enabled_toggled(pressed: bool) -> void:
	settings.sfx_enabled = pressed
	sld_fx.editable = pressed
	_apply_audio()

func _on_fx_changed(v: float) -> void:
	settings.sfx = clamp(v, 0.0, 1.0)
	_apply_audio()

# ----------------- UI SYNC -----------------
func _sync_ui_from_settings() -> void:
	chk_fullscreen.button_pressed = settings.fullscreen
	chk_vsync.button_pressed = settings.vsync

	var idx := 0
	for i in RES_LIST.size():
		if RES_LIST[i] == settings.resolution:
			idx = i
			break
	var item_index := opt_res.get_item_index(idx)
	if item_index >= 0:
		opt_res.select(item_index)

	sld_master.value = settings.master

	chk_music.button_pressed = settings.music_enabled
	sld_music.editable = settings.music_enabled
	sld_music.value = settings.music

	chk_fx.button_pressed = settings.sfx_enabled
	sld_fx.editable = settings.sfx_enabled
	sld_fx.value = settings.sfx

# ----------------- Guardar / Cargar -----------------
func _save_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(CFG_SECTION, "fullscreen", settings.fullscreen)
	cfg.set_value(CFG_SECTION, "vsync", settings.vsync)
	cfg.set_value(CFG_SECTION, "resolution_x", settings.resolution.x)
	cfg.set_value(CFG_SECTION, "resolution_y", settings.resolution.y)
	cfg.set_value(CFG_SECTION, "master", settings.master)
	cfg.set_value(CFG_SECTION, "music", settings.music)
	cfg.set_value(CFG_SECTION, "sfx", settings.sfx)
	cfg.set_value(CFG_SECTION, "music_enabled", settings.music_enabled)
	cfg.set_value(CFG_SECTION, "sfx_enabled", settings.sfx_enabled)
	var err := cfg.save(CFG_PATH)
	if err != OK:
		push_error("No se pudo guardar config: %s" % error_string(err))

func _load_cfg() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CFG_PATH)
	if err != OK:
		return
	settings.fullscreen    = cfg.get_value(CFG_SECTION, "fullscreen", settings.fullscreen)
	settings.vsync         = cfg.get_value(CFG_SECTION, "vsync", settings.vsync)
	var rx: int            = cfg.get_value(CFG_SECTION, "resolution_x", settings.resolution.x)
	var ry: int            = cfg.get_value(CFG_SECTION, "resolution_y", settings.resolution.y)
	settings.resolution    = Vector2i(rx, ry)
	settings.master        = float(cfg.get_value(CFG_SECTION, "master", settings.master))
	settings.music         = float(cfg.get_value(CFG_SECTION, "music", settings.music))
	settings.sfx           = float(cfg.get_value(CFG_SECTION, "sfx", settings.sfx))
	settings.music_enabled = cfg.get_value(CFG_SECTION, "music_enabled", settings.music_enabled)
	settings.sfx_enabled   = cfg.get_value(CFG_SECTION, "sfx_enabled", settings.sfx_enabled)
