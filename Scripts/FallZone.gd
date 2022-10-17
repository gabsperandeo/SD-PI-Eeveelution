extends Area2D

func _ready():
	pass 

func _on_FallZone_body_entered(body):
	yield(get_tree().create_timer(1), "timeout")
	get_owner().reset()
