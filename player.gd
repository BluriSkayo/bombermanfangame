extends CharacterBody2D

# ========================================
# VARIABLES EXPORTADAS (configurables)
# ========================================

# Velocidad del personaje
@export var speed = 150.0

# Tamaño del tile (para el magnetismo hacia el centro)
@export var tile_size: float = 32.0

# Fuerza del magnetismo hacia el centro del tile (0 = sin magnetismo, 1 = muy fuerte)
@export_range(0.0, 1.0) var snap_strength: float = 0.2

# Tolerancia de alineación - si está más cerca que esto, no aplicar magnetismo
@export var alignment_tolerance: float = 8.0

# Tiempo que se recuerda un input bloqueado (input forgiveness)
@export var input_buffer_time: float = 0.15

# Tamaño de la hitbox del jugador (debe ser menor que tile_size)
@export var hitbox_size: Vector2 = Vector2(26, 26)

# ========================================
# VARIABLES INTERNAS
# ========================================

# Referencia al AnimatedSprite2D
@onready var animated_sprite = $AnimatedSprite2D

# Variable para recordar la última dirección
var last_direction = Vector2.DOWN  # Empieza mirando abajo

# Buffer de input: almacena la dirección que el jugador quiso tomar pero estaba bloqueado
var buffered_input: Vector2 = Vector2.ZERO
var buffer_timer: float = 0.0

# ========================================
# FUNCIONES DE INICIALIZACIÓN
# ========================================

func _ready():
	# Configurar la hitbox automáticamente
	setup_collision_shape()

func setup_collision_shape():
	# Buscar el CollisionShape2D hijo y configurar su tamaño
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape and collision_shape is CollisionShape2D:
		var shape = collision_shape.shape
		if shape is RectangleShape2D:
			shape.size = hitbox_size

# ========================================
# FÍSICA Y MOVIMIENTO
# ========================================

func _physics_process(delta: float):
	# Obtener la dirección del input del jugador
	var input_direction = get_input_direction()
	
	# Gestionar el buffer de input
	handle_input_buffer(input_direction, delta)
	
	# Determinar la dirección de movimiento (puede ser del input o del buffer)
	var movement_direction = get_movement_direction(input_direction)
	
	# Aplicar velocidad
	velocity = movement_direction * speed
	
	# Mover el personaje
	move_and_slide()
	
	# Aplicar magnetismo hacia el centro del tile
	apply_tile_snapping(movement_direction, delta)
	
	# Actualizar la última dirección si se está moviendo
	if movement_direction.length() > 0:
		last_direction = movement_direction
	
	# Actualizar animaciones
	update_animation(movement_direction)

func get_input_direction() -> Vector2:
	# Obtener input del jugador en los 4 ejes
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	# Normalizar la dirección para evitar movimiento más rápido en diagonal
	if direction.length() > 0:
		direction = direction.normalized()
	
	return direction

func handle_input_buffer(input_direction: Vector2, delta: float):
	# Si hay input del jugador, guardarlo en el buffer
	if input_direction.length() > 0:
		buffered_input = input_direction
		buffer_timer = input_buffer_time
	else:
		# Decrementar el timer del buffer
		buffer_timer = max(0.0, buffer_timer - delta)

func get_movement_direction(input_direction: Vector2) -> Vector2:
	# Si hay input directo, usarlo
	if input_direction.length() > 0:
		return input_direction
	
	# Si no hay input pero hay un input en el buffer, intentar usarlo
	if buffer_timer > 0 and buffered_input.length() > 0:
		# Verificar si ahora es posible moverse en la dirección del buffer
		if can_move_in_direction(buffered_input):
			return buffered_input
	
	return Vector2.ZERO

func can_move_in_direction(direction: Vector2) -> bool:
	# Hacer un test de colisión pequeño en la dirección deseada
	var test_motion_params = PhysicsTestMotionParameters2D.new()
	test_motion_params.from = global_transform
	test_motion_params.motion = direction * 2.0  # Pequeño movimiento de prueba
	
	var result = PhysicsTestMotionResult2D.new()
	return not PhysicsServer2D.body_test_motion(get_rid(), test_motion_params, result)

func apply_tile_snapping(movement_direction: Vector2, delta: float):
	# Solo aplicar magnetismo si nos estamos moviendo
	if movement_direction.length() == 0:
		return
	
	# Si nos movemos horizontalmente, corregir la posición Y hacia el centro del tile
	if abs(movement_direction.x) > abs(movement_direction.y):
		apply_axis_snapping(false)  # false = eje Y
	
	# Si nos movemos verticalmente, corregir la posición X hacia el centro del tile
	if abs(movement_direction.y) > abs(movement_direction.x):
		apply_axis_snapping(true)  # true = eje X

func apply_axis_snapping(is_x_axis: bool):
	# Obtener la posición actual en el eje a corregir
	var current_pos = position.x if is_x_axis else position.y
	
	# Calcular el centro del tile más cercano
	var tile_center = round(current_pos / tile_size) * tile_size
	
	# Calcular la distancia al centro
	var distance_to_center = abs(current_pos - tile_center)
	
	# Si estamos lo suficientemente cerca, no aplicar corrección (para evitar vibraciones)
	if distance_to_center < alignment_tolerance:
		return
	
	# Calcular la corrección a aplicar
	var correction = (tile_center - current_pos) * snap_strength
	
	# Aplicar la corrección
	if is_x_axis:
		position.x += correction
	else:
		position.y += correction

# ========================================
# ANIMACIONES
# ========================================

func update_animation(direction: Vector2):
	if direction.length() == 0:
		# Si no se mueve, usar idle según la última dirección
		if abs(last_direction.x) > abs(last_direction.y):
			# Última dirección fue horizontal
			if last_direction.x > 0:
				animated_sprite.play("idle_right")
			else:
				animated_sprite.play("idle_left")
		else:
			# Última dirección fue vertical
			if last_direction.y > 0:
				animated_sprite.play("idle_down")
			else:
				animated_sprite.play("idle_up")
	else:
		# Si se está moviendo, usar animación de caminar
		if abs(direction.x) > abs(direction.y):
			# Movimiento horizontal
			if direction.x > 0:
				animated_sprite.play("walk_right")
			else:
				animated_sprite.play("walk_left")
		else:
			# Movimiento vertical
			if direction.y > 0:
				animated_sprite.play("walk_down")
			else:
				animated_sprite.play("walk_up")
