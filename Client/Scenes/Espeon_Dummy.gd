extends KinematicBody2D

var velocity = Vector2.ZERO	##eixos x e y
var moveSpeed = 1400
var gravity = 720 ##pois o kinematicBody não tem gravidade padrão
var jumpForce = -520 ##invertemos o eixo y
var isGrounded
var hurted = false
onready var raycasts = $raycasts

onready var tween = $Tween
var puppet_pos = Vector2()
var puppet_vel = Vector2()

func _physics_process(delta: float) -> void:
	if!isGrounded:
		velocity.y += gravity * delta

	isGrounded = _check_is_ground()

	_set_animation()

func _check_is_ground():
	for raycast in raycasts.get_children():
		if raycast.is_colliding():
			return true
	
	return false

func _set_animation():
	var anim = "Idle"
	
	if !isGrounded && velocity.x != 0:
		anim = "JumpSide"
	elif velocity.x != 0:
		anim = "Walk"
	elif !isGrounded:
		anim = "Jump"
		
	if hurted:
		anim = "Hurt"
		
	if $anim.assigned_animation != anim:
		$anim.play(anim)


func _on_hurtbox_body_entered(body):
	if("Foco de Escuridão" in body.name):
		hurted = true
		$Sounds/Hurt.play()
		yield(get_tree().create_timer(1.5), "timeout")
		hurted = false
		$Sounds/Hurt.stop()

func update_transform(_puppet_pos, _puppet_vel):
	# print("Enviando")
	new_puppet_pos(_puppet_pos)
	puppet_vel = _puppet_vel

func new_puppet_pos(value):
	# print("Recebendo " + str(value.x))
	puppet_pos = value
	tween.interpolate_property(self, "global_position", global_position, puppet_pos, 0.05)
	tween.start()
