extends ColorRect

var  progress = 0.0

func _ready():
	material.set("shader_param/progress", progress)
