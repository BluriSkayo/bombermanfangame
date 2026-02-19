extends CharacterBody2D

# Velocidad del personaje
@export var speed = 150.0

# Referencia al AnimatedSprite2D
@onready var animated_sprite = $AnimatedSprite2D

# Variable para recordar la última dirección
var last_direction = Vector2.DOWN  # Empieza mirando abajo

func _physics_process(delta):
	# Obtener la dirección del input
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	# Normalizar la dirección (para que no vaya más rápido en diagonal)
	if direction.length() > 0:
		direction = direction.normalized()
		# Actualizar la última dirección cuando se mueve
		last_direction = direction
	
	# Aplicar velocidad
	velocity = direction * speed
	
	# Mover el personaje
	move_and_slide()
	
	# Actualizar animaciones
	update_animation(direction)

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
