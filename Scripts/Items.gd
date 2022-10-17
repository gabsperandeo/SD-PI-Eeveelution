extends Area2D

var timer = null
var adjustJumpForceDelay = 0.9
var player

func _on_frutas_body_entered(body):
	player = body	
	timer = Timer.new()
	timer.set_wait_time(adjustJumpForceDelay)
	timer.connect("timeout", self, "_on_timeout_complete")
	add_child(timer)
	
	if ("rowap" in name && player.name == "Umbreon") || ("payapa" in name && player.name == "Espeon"):
		$anim.play("collected")
		player.jumpForce = -590
		player.gravity = 520
		timer.start()
		$FruitCollected.play()
		
		
func _on_timeout_complete():
	player.jumpForce = -520
	player.gravity = 720


func _on_anim_animation_finished(anim_name):
	if anim_name == "collected":
		queue_free()
