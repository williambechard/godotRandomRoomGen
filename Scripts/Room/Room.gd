extends Node2D
class_name Room

@export var wall_T : Node2D
@export var wall_R : Node2D
@export var wall_L : Node2D
@export var wall_B : Node2D

@export var topDoor : Node2D
@export var rightDoor : Node2D
@export var bottomDoor : Node2D
@export var leftDoor : Node2D

@export var size : Vector2

@export var openDoors:Array[Node2D]

var x:int
var y:int

var pos : Vector2

enum NodeState {
	Available,
	Current,
	Completed,
	Start,
	Final
}

var state : NodeState

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
