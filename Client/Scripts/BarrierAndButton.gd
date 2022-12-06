extends Node2D

func _ready():
	$Animations.play("ButtonUp")

func _on_Area2D_body_entered(body):
	if body.name == "Espeon" || body.name == "Umbreon":
		$Animations.play("ButtonDown")
		$ButtonPressed.play()
		$Animations.play_backwards("BarrierAction")
		$BarrierS.play()

func _on_Area2D_body_exited(body):
	$Animations.play("ButtonUp")
	$Animations.play("BarrierAction")
	$BarrierS.play()
