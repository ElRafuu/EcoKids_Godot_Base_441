extends Area2D
signal collected

@export var play_appear_on_ready: bool = true
@export var auto_despawn_seconds: float = 0.0
@export var textures: Array[Texture2D] = []
@export var require_pickup_area: bool = true
@export var can_click_collect: bool = false
@export var pick_radius_px: float = 16.0
@export var adjust_shape_by_pick_radius: bool = false

@onready var sprite: Sprite2D = $SpriteTrash2D
@onready var colshape: CollisionShape2D = $CollisionShapeTrash2D
@onready var anim: AnimationPlayer = $AnimationPlayer

var _can_collect: bool = false

func _ready() -> void:
	# Randomiza sprite si hay lista
	if textures.size() > 0 and sprite.texture == null:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		sprite.texture = textures[rng.randi_range(0, textures.size() - 1)]

	# Detección con PickupArea
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	# Click/tap directo (si lo habilitas)
	input_pickable = can_click_collect

	# Autodespawn
	if auto_despawn_seconds > 0.0:
		var t: Timer = Timer.new()
		t.one_shot = true
		t.wait_time = auto_despawn_seconds
		add_child(t)
		t.timeout.connect(_on_life_timeout)
		t.start()

	# Ajustar colisión a píxeles visibles aunque el nodo esté escalado
	if adjust_shape_by_pick_radius and colshape and colshape.shape is CircleShape2D:
		var s: float = maxf(global_scale.x, 0.0001)
		(colshape.shape as CircleShape2D).radius = pick_radius_px / s

	# Animación inicial
	if play_appear_on_ready and anim and anim.has_animation("appear"):
		anim.play("appear")
	elif anim and anim.has_animation("idle"):
		anim.play("idle")

func _on_area_entered(a: Area2D) -> void:
	if a.name == "PickupArea":
		_can_collect = true

func _on_area_exited(a: Area2D) -> void:
	if a.name == "PickupArea":
		_can_collect = false

# Llamado por Player/Game al presionar "recoger"
func try_collect() -> bool:
	if require_pickup_area and not _can_collect:
		return false
	_do_collect()
	return true

# Alternativa sin PickupArea: por distancia
func try_collect_from(position_world: Vector2, max_dist: float = 36.0) -> bool:
	if global_position.distance_to(position_world) <= max_dist:
		_do_collect()
		return true
	return false

# Clic/tap directo sobre la basura
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not can_click_collect:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_do_collect()

func _do_collect() -> void:
	emit_signal("collected")
	if colshape:
		colshape.disabled = true
	if anim and anim.has_animation("collect"):
		anim.play("collect")
		await anim.animation_finished
	queue_free()

func _on_life_timeout() -> void:
	if colshape:
		colshape.disabled = true
	if anim and anim.has_animation("collect"):
		anim.play("collect")
		await anim.animation_finished
	queue_free()
