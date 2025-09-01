extends CharacterBody2D
@export var speed: float = 220.0
var _juego: Node = null

func _ready() -> void:
	_juego = get_tree().get_first_node_in_group("juego")
	_ensure_input_actions()

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()

func _unhandled_input(e: InputEvent) -> void:
	var pressed_recoger := InputMap.has_action("recoger") and e.is_action_pressed("recoger")
	if e.is_action_pressed("ui_accept") or pressed_recoger:
		if _juego == null:
			_juego = get_tree().get_first_node_in_group("juego")
		if _juego and _juego.has_method("collect_nearby"):
			_juego.collect_nearby()

func _ensure_input_actions() -> void:
	if not InputMap.has_action("recoger"):
		InputMap.add_action("recoger")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_SPACE
		InputMap.action_add_event("recoger", ev)
	# añade WASD a ui_*
	_ensure_wasd("ui_left", KEY_A)
	_ensure_wasd("ui_right", KEY_D)
	_ensure_wasd("ui_up", KEY_W)
	_ensure_wasd("ui_down", KEY_S)

func _ensure_wasd(a:String,k:int)->void:
	if not InputMap.has_action(a): return
	for ev in InputMap.action_get_events(a):
		var kev := ev as InputEventKey
		if kev and kev.physical_keycode == k: return
	var e := InputEventKey.new(); e.physical_keycode = k
	InputMap.action_add_event(a, e)
