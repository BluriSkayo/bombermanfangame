extends CharacterBody2D

# Velocidad del personaje
@export var speed: float = 120.0

# Tamaño del tile (debe coincidir con tu TileMap)
@export var tile_size: float = 16.0

# Tiempo máximo para recordar el input secundario (el toque breve)
@export var intent_buffer_time: float = 0.15

# Tiempo máximo que dura la corrección automática
@export var correction_duration: float = 0.12

# Distancia máxima para corregir cuando estás bloqueado (en px)
@export var blocked_snap_threshold: float = 7.0

# Fuerza de corrección cuando estás bloqueado
@export_range(0.0, 1.0) var blocked_snap_strength: float = 0.15

# Referencia al AnimatedSprite2D
@onready var animated_sprite = $AnimatedSprite2D

# Última dirección para las animaciones idle
var last_direction: Vector2 = Vector2.DOWN

# Sistema de intención de giro
var intent_direction: Vector2 = Vector2.ZERO
var intent_timer: float = 0.0
var intent_target: float = 0.0
var intent_axis: String = ""
var is_correcting: bool = false
var correction_timer: float = 0.0

# Sub-píxel para movimiento en píxeles enteros
var sub_pixel: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	detect_intent(direction, delta)
	
	if is_correcting:
		apply_correction(direction, delta)
	
	if direction.length() > 0:
		direction = direction.normalized()
		last_direction = direction
	
	# Guardar posición antes de mover
	var pos_before: Vector2 = position
	
	# Acumular movimiento con sub-píxeles
	sub_pixel += direction * speed * delta
	
	# Extraer solo los píxeles enteros
	var move: Vector2 = Vector2(int(sub_pixel.x), int(sub_pixel.y))
	sub_pixel -= move
	
	velocity = move / delta
	move_and_slide()
	
	# Si está bloqueado y NO está en corrección de intención, intentar snap
	if not is_correcting and direction != Vector2.ZERO:
		try_blocked_snap(direction, pos_before)
	
	update_animation(direction)

func try_blocked_snap(direction: Vector2, pos_before: Vector2) -> void:
	var stuck_x: bool = direction.x != 0 and abs(position.x - pos_before.x) < 0.5
	var stuck_y: bool = direction.y != 0 and abs(position.y - pos_before.y) < 0.5
	
	# Si se mueve horizontal pero está atascado, corregir Y si está cerca del centro
	if direction.x != 0 and direction.y == 0 and stuck_x:
		var target_y: float = round(position.y / tile_size) * tile_size
		var dist: float = abs(position.y - target_y)
		if dist > 1.0 and dist < blocked_snap_threshold:
			position.y = lerp(position.y, target_y, blocked_snap_strength)
			position.y = round(position.y)
	
	# Si se mueve vertical pero está atascado, corregir X si está cerca del centro
	if direction.y != 0 and direction.x == 0 and stuck_y:
		var target_x: float = round(position.x / tile_size) * tile_size
		var dist: float = abs(position.x - target_x)
		if dist > 1.0 and dist < blocked_snap_threshold:
			position.x = lerp(position.x, target_x, blocked_snap_strength)
			position.x = round(position.x)

func detect_intent(direction: Vector2, delta: float) -> void:
	if direction.x != 0 and direction.y != 0:
		intent_direction = direction
		intent_timer = intent_buffer_time
		is_correcting = false
		return
	
	if intent_timer > 0 and not is_correcting:
		intent_timer -= delta
		
		if direction.x != 0 and direction.y == 0:
			if intent_direction.y != 0:
				intent_target = round(position.y / tile_size) * tile_size + sign(intent_direction.y) * 8.0
				intent_axis = "y"
				is_correcting = true
				correction_timer = correction_duration
				intent_timer = 0.0
		
		elif direction.y != 0 and direction.x == 0:
			if intent_direction.x != 0:
				intent_target = round(position.x / tile_size) * tile_size + sign(intent_direction.x) * 8.0
				intent_axis = "x"
				is_correcting = true
				correction_timer = correction_duration
				intent_timer = 0.0
	
	if direction == Vector2.ZERO:
		cancel_correction()

func apply_correction(direction: Vector2, delta: float) -> void:
	correction_timer -= delta
	if correction_timer <= 0:
		cancel_correction()
		return
	
	var current: float
	var diff: float
	
	if intent_axis == "x":
		current = position.x
		diff = intent_target - current
		
		if abs(diff) < 2.0:
			position.x = intent_target
			cancel_correction()
			return
		
		position.x += sign(diff) * speed * delta * 0.5
		position.x = round(position.x)
		
		if direction.y == 0:
			cancel_correction()
	
	elif intent_axis == "y":
		current = position.y
		diff = intent_target - current
		
		if abs(diff) < 2.0:
			position.y = intent_target
			cancel_correction()
			return
		
		position.y += sign(diff) * speed * delta * 0.5
		position.y = round(position.y)
		
		if direction.x == 0:
			cancel_correction()

func cancel_correction() -> void:
	is_correcting = false
	intent_direction = Vector2.ZERO
	intent_timer = 0.0
	intent_axis = ""
	correction_timer = 0.0

func update_animation(direction: Vector2) -> void:
	if direction.length() == 0:
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				animated_sprite.play("idle_right")
			else:
				animated_sprite.play("idle_left")
		else:
			if last_direction.y > 0:
				animated_sprite.play("idle_down")
			else:
				animated_sprite.play("idle_up")
	else:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				animated_sprite.play("walk_right")
			else:
				animated_sprite.play("walk_left")
		else:
			if direction.y > 0:
				animated_sprite.play("walk_down")
			else:
				animated_sprite.play("walk_up")
