extends KinematicBody2D

var velocity = Vector2.ZERO	##eixos x e y
var moveSpeed = 1400
var gravity = 720 ##pois o kinematicBody não tem gravidade padrão
var jumpForce = -520 ##invertemos o eixo y
var isGrounded
var hurted = false
onready var raycasts = $raycasts

func _physics_process(delta: float) -> void:
	if!isGrounded:
		velocity.y += gravity * delta

	_get_input()

	move_and_slide(velocity)

	isGrounded = _check_is_ground()

	_set_animation()

func _get_input():
	velocity.x = 0
	var moveDirection = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	velocity.x = lerp(velocity.x, moveSpeed * moveDirection, 0.1)
	
	if moveDirection != 0:
		$texture.scale.x = moveDirection
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and isGrounded:
		velocity.y = jumpForce / 2
		$Sounds/Jump.play()

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
		Server.reset_level()
		hurted = false
		$Sounds/Hurt.stop()

func _on_Timer_timeout():
	if not is_network_master():
		# print("Enviando pos: " + str(global_position.x) + ", " + str(global_position.y))
		Server.rpc_unreliable_id(1, "update_transform", global_position, velocity)
