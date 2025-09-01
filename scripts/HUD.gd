extends CanvasLayer
# class_name HUD  # opcional

signal config_requested
signal exit_requested
signal retry_requested
signal select_world_requested

# --------- Referencias por ruta (según tu árbol actual de las capturas) ----------
@onready var limpieza_bar: ProgressBar       = get_node_or_null("Root/VBoxContainer/HBoxContainer/LimpiezaBar")
@onready var tiempo_label: Label             = get_node_or_null("Root/VBoxContainer/HBoxContainer/TiempoLabel")
@onready var estado_label: Label             = get_node_or_null("Root/VBoxContainer/EstadoLabel")
@onready var stars_box: HBoxContainer        = get_node_or_null("Root/VBoxContainer/HBoxContainer2/HBoxContainer")

@onready var dim: ColorRect                  = get_node_or_null("Dim")
@onready var pause_panel: Panel              = get_node_or_null("PausePanel")
@onready var btn_resume: Button              = get_node_or_null("PausePanel/VBoxContainer/BtnResume")
@onready var btn_config: Button              = get_node_or_null("PausePanel/VBoxContainer/BtnConfig")
@onready var btn_exit: Button                = get_node_or_null("PausePanel/VBoxContainer/BtnExit")

@onready var result_panel: Panel             = get_node_or_null("ResultPanel")
@onready var result_title: Label             = get_node_or_null("ResultPanel/VBoxContainer/ResultTitle")
@onready var result_msg: Label               = get_node_or_null("ResultPanel/VBoxContainer/ResultMsg")
@onready var result_stars_box: HBoxContainer = get_node_or_null("ResultPanel/VBoxContainer/ResultStarBox")
@onready var btn_retry: Button               = get_node_or_null("ResultPanel/VBoxContainer/HBoxContainer2/BtnRetry")
@onready var btn_select: Button              = get_node_or_null("ResultPanel/VBoxContainer/HBoxContainer2/BtnSelect")

var _pause_open := false
var _results_open := false

func _ready() -> void:
	# El HUD debe procesar en pausa (también ponlo en el Inspector).
	set_process_unhandled_input(true)

	# Fuerza estado inicial oculto de overlays
	if dim:          dim.hide()
	if pause_panel:  pause_panel.hide()
	if result_panel: result_panel.hide()

	# Conecta botones si existen
	if btn_resume: btn_resume.pressed.connect(_on_btn_resume)
	if btn_config: btn_config.pressed.connect(_on_btn_config)
	if btn_exit:   btn_exit.pressed.connect(_on_btn_exit)

	if btn_retry:  btn_retry.pressed.connect(func(): emit_signal("retry_requested"))
	if btn_select: btn_select.pressed.connect(func(): emit_signal("select_world_requested"))

# ---------- API que llama Juego.gd ----------
func set_limpieza(v: float) -> void:
	if limpieza_bar: limpieza_bar.value = clampf(v, 0.0, 100.0)

func set_tiempo(seg: int) -> void:
	if not tiempo_label: return
	var m: int = floori(seg / 60.0)
	var s: int = seg % 60
	tiempo_label.text = "%02d:%02d" % [m, s]

func set_estado(txt: String) -> void:
	if estado_label: estado_label.text = txt

func set_stars(n: int) -> void:
	if not stars_box: return
	for i in range(stars_box.get_child_count()):
		var star_node := stars_box.get_child(i) as TextureRect
		if star_node:
			star_node.modulate = Color(1,1,1,1) if i < n else Color(1,1,1,0.15)

# ---------- Resultados ----------
func show_results(victoria: bool, estrellas: int, limpieza_media: float) -> void:
	_results_open = true
	get_tree().paused = true
	_show_results_ui()

	if result_title: result_title.text = "¡Victoria!" if victoria else "¡Derrota!"
	if result_msg:   result_msg.text   = "Limpieza media: %d%%" % int(limpieza_media)

	if result_stars_box:
		for i in range(result_stars_box.get_child_count()):
			var rstar := result_stars_box.get_child(i) as TextureRect
			if rstar:
				rstar.modulate = Color(1,1,1,1) if i < estrellas else Color(1,1,1,0.15)

	await get_tree().process_frame
	if btn_retry: btn_retry.grab_focus()

# ---------- Pausa ----------
func _unhandled_input(event: InputEvent) -> void:
	if _results_open:
		return
	if event.is_action_pressed("ui_cancel"): # Esc
		toggle_pause()

func toggle_pause(force_on: bool = false) -> void:
	if _results_open: return
	if not _pause_open and not force_on:
		_open_pause()
	elif _pause_open:
		_close_pause()
	elif force_on:
		_open_pause()

func _open_pause() -> void:
	_pause_open = true
	get_tree().paused = true
	_show_pause_ui()
	await get_tree().process_frame
	if btn_resume: btn_resume.grab_focus()

func _close_pause() -> void:
	_pause_open = false
	_hide_pause_ui()
	get_tree().paused = false

func _show_pause_ui() -> void:
	if dim:         dim.show()
	if pause_panel: pause_panel.show()

func _hide_pause_ui() -> void:
	if pause_panel: pause_panel.hide()
	if dim and not _results_open:
		dim.hide()

func _show_results_ui() -> void:
	if dim:          dim.show()
	if result_panel: result_panel.show()
	if pause_panel:  pause_panel.hide()

func _hide_results_ui() -> void:
	if result_panel: result_panel.hide()
	if dim and not _pause_open:
		dim.hide()

# ---------- Botones pausa ----------
func _on_btn_resume() -> void:
	_close_pause()

func _on_btn_config() -> void:
	emit_signal("config_requested")

func _on_btn_exit() -> void:
	emit_signal("exit_requested")
