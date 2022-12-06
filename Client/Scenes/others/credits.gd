extends Node2D

export var finished : bool
export var next_scene : String
export var reset_var : bool

func _ready():
	finished = false
	next_scene = "res://Scenes/others/credits.tscn"

func reset():
	reset_var = true
