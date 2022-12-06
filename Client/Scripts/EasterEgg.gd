extends Node2D

func _ready():
	var anim = "Idle"

	if $anim.assigned_animation != anim:
		$anim.play(anim)
		
		


func _on_area_body_entered(body):
	if body.name == "Umbreon" || body.name == "Espeon":
		$anim.play("EasterEgg")
		$EasterEgg.play()
