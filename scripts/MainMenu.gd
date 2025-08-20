# MainMenu.gd — Godot 4.4.1
# Carga la fuente TTF directamente, aplica theme y conecta botones.

extends Control

# ---------- Configuración ----------
const FONT_TTF_PATH  := "res://fuentes/ComicNeue-Bold.ttf"
const CONFIG_SCENE   := "res://escenas/configuracion.tscn"
const JUEGO_SCENE    := "res://escenas/juego.tscn"

# Si los botones tienen otros nombres en la escena, cámbialos aquí:
const BTN_CONFIG_NAME := "BtnConfig"
const BTN_JUGAR_NAME  := "BtnJugar"
const BTN_SALIR_NAME  := "BtnSalir"

# ---------- Ciclo de vida ----------
func _ready() -> void:
	_estilizar_ui()
	_conectar_botones()

# ---------- Estilo ----------
func _estilizar_ui() -> void:
	var font_res := _cargar_fuente_ttf(FONT_TTF_PATH)
	if font_res != null:
		var theme := Theme.new()
		theme.default_font = font_res
		theme.default_font_size = 28
		theme.set_font_size("font_size", "Label", 28)
		theme.set_font_size("font_size", "Button", 48)

		self.theme = theme
		get_tree().root.theme = theme
	else:
		push_warning("No se pudo cargar la fuente TTF en: %s" % FONT_TTF_PATH)

func _cargar_fuente_ttf(path: String) -> Font:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		return null
	var res := ResourceLoader.load(path)
	if res is Font:
		return res
	return null

# ---------- Conexión de botones ----------
func _conectar_botones() -> void:
	var btn_config = find_child(BTN_CONFIG_NAME, true, false)
	if btn_config is Button:
		btn_config.pressed.connect(_on_btn_config_pressed)
	else:
		push_warning("No se encontró el botón '%s'" % BTN_CONFIG_NAME)

	var btn_jugar = find_child(BTN_JUGAR_NAME, true, false)
	if btn_jugar is Button:
		btn_jugar.pressed.connect(_on_btn_jugar_pressed)
	else:
		push_warning("No se encontró el botón '%s'" % BTN_JUGAR_NAME)

	var btn_salir = find_child(BTN_SALIR_NAME, true, false)
	if btn_salir is Button:
		btn_salir.pressed.connect(_on_btn_salir_pressed)
	else:
		push_warning("No se encontró el botón '%s'" % BTN_SALIR_NAME)

# ---------- Handlers ----------
func _on_btn_config_pressed() -> void:
	_ir_a_escena(CONFIG_SCENE)

func _on_btn_jugar_pressed() -> void:
	_ir_a_escena(JUEGO_SCENE)

func _on_btn_salir_pressed() -> void:
	get_tree().quit()

# ---------- Utilidad ----------
func _ir_a_escena(path: String) -> void:
	if ResourceLoader.exists(path):
		var err := get_tree().change_scene_to_file(path)
		if err != OK:
			push_error("Error al cambiar de escena: %s (código %d)" % [path, err])
	else:
		push_error("No se encontró la escena: %s" % path)
