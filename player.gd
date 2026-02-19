extends CharacterBody2D

# Configuración
@export var speed: float = 80.0

# Referencia al nodo de animación (Asegúrate que el nombre coincida con tu árbol de nodos)
# Si usas AnimationPlayer, cambia AnimatedSprite2D por AnimationPlayer
@onready var anim = $AnimatedSprite2D 

# Variable para recordar la última dirección y saber qué IDLE poner
var last_direction: String = "down" 

func _physics_process(_delta):
	# Obtenemos el vector de entrada. 
	# Input.get_vector maneja automáticamente las diagonales y normaliza la velocidad.
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Aplicar movimiento
	if input_vector != Vector2.ZERO:
		velocity = input_vector * speed
		update_walk_animation(input_vector)
	else:
		velocity = Vector2.ZERO
		update_idle_animation()

	# move_and_slide maneja las colisiones y el deslizamiento en paredes automáticamente
	move_and_slide()

func update_walk_animation(direction: Vector2):
	# Determinamos qué eje es más fuerte para decidir la animación.
	# Esto evita que la animación parpadee si vas en diagonal.
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			last_direction = "right"
		else:
			last_direction = "left"
	else:
		# Si la Y es mayor o igual, priorizamos animaciones verticales (estilo RPG/Bomberman)
		if direction.y > 0:
			last_direction = "down"
		else:
			last_direction = "up"
	
	# Reproducir la animación de caminar
	anim.play("walk_" + last_direction)

func update_idle_animation():
	# Reproducir la animación de idle basada en la última dirección
	anim.play("idle_" + last_direction)
