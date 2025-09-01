extends Area2D
signal collected

@export var auto_free_on_pick: bool = true

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $SpriteTrash2D

func _ready() -> void:
	monitoring = true  # asegura que detecta overlaps

# Lo llama Juego.gd desde collect_nearby()
func try_collect() -> bool:
	if _is_player_in_range():
		_collect()
		return true
	return false

func _is_player_in_range() -> bool:
	# Busca si el PickupArea del jugador está tocando esta basura
	for a in get_overlapping_areas():
		if a.is_in_group("player_pickup") or a.name == "PickupArea":
			return true
	return false

func _collect() -> void:
	emit_signal("collected")
	# animación opcional llamada "pickup"
	if anim and anim.has_animation("pickup"):
		anim.play("pickup")
		if auto_free_on_pick:
			await anim.animation_finished
			queue_free()
	elif auto_free_on_pick:
		queue_free()
