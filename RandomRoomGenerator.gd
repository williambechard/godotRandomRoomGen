extends Node2D

var room = preload("res://Prefabs/Room.tscn")
var bridge = preload("res://Prefabs/Bridge.tscn")

@export var targetNumberOfRooms: int
@export var timeToWait: float
@export var spaceBetween: int

var AllRooms: Array[Room] 
var PossibleRooms: Array[Vector2] 
var OpenRooms: Array[Room] 
var AllBridges: Array[Node2D]
var screenSize
var centerScreenPosition
# Called when the node enters the scene tree for the first time.
func _ready():
	buildRandomMap()


func buildRandomMap():
	var crashCounter=0
	
	screenSize= get_viewport_rect().size
	centerScreenPosition = Vector2(screenSize.x / 2, screenSize.y/2)
	self.position = centerScreenPosition

	#create init room
	spawnRoom(Vector2(0,0))
	#init room creation
	while AllRooms.size() < targetNumberOfRooms:
		if PossibleRooms.size() > 0:
			var index = randi() % PossibleRooms.size()
			var newRoomPosition :Vector2 = PossibleRooms[index]
			PossibleRooms.remove_at(index)
			spawnRoom(newRoomPosition)
			await get_tree().create_timer(timeToWait).timeout
		else:
			print("Possible rooms ran out")
			crashCounter=crashCounter+1		
		if crashCounter>=10:  
			break
	print('rooms generated')
	closeOffDoors();
	closeExtra();
	
	# if we have space between, lets build bridges
	if (spaceBetween>0) : 
		buildBridges()


func buildBridges():
	for r in AllRooms:
		var top = r.global_position + Vector2(0, -(r.size.y + spaceBetween) * 0.5)
		var bottom = r.global_position + Vector2(0, (r.size.y + spaceBetween) * 0.5)
		var left = r.global_position + Vector2(-(r.size.x + spaceBetween) * 0.5, 0)
		var right = r.global_position + Vector2((r.size.x + spaceBetween) * 0.5, 0)

		for door in r.openDoors:
			match door.name:
				"Door_T":
					if bridge_possible(top):
						create_bridge(top, r.name, door.name)
				"Door_B":
					if bridge_possible(bottom):
						create_bridge(bottom, r.name, door.name)
				"Door_L":
					if bridge_possible(left):
						create_bridge(left, r.name, door.name)
				"Door_R":
					if bridge_possible(right):
						create_bridge(right, r.name, door.name)

func bridge_possible(pos: Vector2) -> bool:
	var can_build = true
	for g in AllBridges:
		if g.global_position == pos:
			can_build = false
			break
	return can_build

func create_bridge(pos: Vector2, id: String, name: String) -> void:
	var b = bridge.instantiate()
	b.global_position = pos - centerScreenPosition + Vector2(AllRooms[0].size.x /2, AllRooms[0].size.y/2)
	#if name == "Top" || name == "Bottom":
	#	b.rotation_degrees = Vector3(0, 0, 90)
	#b.parent = self
	b.name = "Bridge for " + id + " " + name
	add_child(b)
	AllBridges.append(b)


func closeExtra():
	while OpenRooms.size() > 0:
		var tRoom = OpenRooms[randi() % OpenRooms.size()]
		# Determine what doors are open and randomly close one
		if tRoom.openDoors.size() > 1:
			var doorToClose :Node2D = tRoom.openDoors[randi() % tRoom.openDoors.size()]
			# Use path finding to ensure the path to the start room is accessible
			# Double check that the room this connects to has another opening
			DFS2(tRoom, doorToClose)

		# Remove from OpenRooms
		OpenRooms.erase(tRoom)
	

func roomCheck(arrayToCheck : Array[Room], direction : Vector2):
	var foundRoom =null
	for tRoom in arrayToCheck:
		if(tRoom.x == direction.x and tRoom.y == direction.y):
			foundRoom = tRoom
			break
	
	return foundRoom		

func DFS2(targetRoom, doorToClose):
	var currentPath: Array[Room]
	var otherDoor : Node2D = null
	var otherRoom :Room = null
	var r : Room= targetRoom
	currentPath.push_front(r)

	var found = false
	var escape = 0
	
	# Close door
	targetRoom.openDoors.erase(doorToClose)
	doorToClose.get_node('Sprite2D').set_visible(false)  # Assuming door visibility should be managed

	var topDirection = Vector2(targetRoom.x, targetRoom.y) + Vector2(0, -1)
	var bottomDirection = Vector2(targetRoom.x, targetRoom.y) + Vector2(0, 1)
	var leftDirection = Vector2(targetRoom.x, targetRoom.y) + Vector2(-1, 0)
	var rightDirection = Vector2(targetRoom.x, targetRoom.y) + Vector2(1, 0)
	
	match doorToClose.name:
		"Door_T":
			var roomCheck = roomCheck(AllRooms, topDirection)
			if(roomCheck !=null):
				roomCheck.openDoors.erase(roomCheck.bottomDoor)
				otherDoor = roomCheck.bottomDoor
				otherRoom = roomCheck
				otherDoor.get_node('Sprite2D').set_visible(false)   # Assuming door visibility should be managed
		"Door_B":
			var roomCheck = roomCheck(AllRooms, bottomDirection)
			if(roomCheck !=null):
				roomCheck.openDoors.erase(roomCheck.topDoor)
				otherDoor = roomCheck.topDoor
				otherRoom = roomCheck
				otherDoor.get_node('Sprite2D').set_visible(false)     # Assuming door visibility should be managed
		"Door_L":
			var roomCheck = roomCheck(AllRooms, leftDirection)
			if(roomCheck !=null):
				roomCheck.openDoors.erase(roomCheck.rightDoor)
				otherDoor = roomCheck.rightDoor
				otherRoom = roomCheck
				otherDoor.get_node('Sprite2D').set_visible(false)    # Assuming door visibility should be managed
		"Door_R":
			var roomCheck = roomCheck(AllRooms, rightDirection)
			if(roomCheck !=null):
				roomCheck.openDoors.erase(roomCheck.leftDoor)
				otherDoor = roomCheck.leftDoor
				otherRoom = roomCheck
				otherDoor.get_node('Sprite2D').set_visible(false)     # Assuming door visibility should be managed

	var NumberOfRooms = 0
	var DiscoveredRoom = []
	DiscoveredRoom.append(targetRoom)

	while currentPath.size() > 0:
		escape += 1
		if escape >= 1000:
			break
		
		var testRoom = currentPath.pop_front()

		var tDirection = Vector2(testRoom.x, testRoom.y) + Vector2(0, -1)
		var bDirection = Vector2(testRoom.x, testRoom.y) + Vector2(0, 1)
		var lDirection = Vector2(testRoom.x, testRoom.y) + Vector2(-1, 0)
		var rDirection = Vector2(testRoom.x, testRoom.y) + Vector2(1, 0)

		var rCheck = roomCheck(AllRooms, tDirection)
		if rCheck!=null and testRoom.openDoors.has(testRoom.topDoor):
			if not DiscoveredRoom.has(rCheck):
				DiscoveredRoom.append(rCheck)
				currentPath.push_front(rCheck)

		rCheck = roomCheck(AllRooms, bDirection)
		if  rCheck!=null and testRoom.openDoors.has(testRoom.bottomDoor):
			if not DiscoveredRoom.has(rCheck):
				DiscoveredRoom.append(rCheck)
				currentPath.push_front(rCheck)

		rCheck = roomCheck(AllRooms, rDirection)
		if rCheck!=null and testRoom.openDoors.has(testRoom.rightDoor) :
			if not DiscoveredRoom.has(rCheck):
				DiscoveredRoom.append(rCheck)
				currentPath.push_front(rCheck)

		rCheck = roomCheck(AllRooms, lDirection)
		if rCheck!=null and testRoom.openDoors.has(testRoom.leftDoor) :
			if not DiscoveredRoom.has(rCheck):
				DiscoveredRoom.append(rCheck)
				currentPath.push_front(rCheck)

	if DiscoveredRoom.size() == AllRooms.size():
		found = true

	if found ==false:
		# Restore
		if(otherDoor!=null):
			otherDoor.get_node('Sprite2D').set_visible(true) 
			if(otherRoom.openDoors.size()==0 or not otherRoom.openDoors.has(otherDoor)) :
				otherRoom.openDoors.append(otherDoor)
			if(targetRoom.openDoors.size()==0 or not targetRoom.openDoors.has(doorToClose)):
				targetRoom.openDoors.append(doorToClose)
		doorToClose.get_node('Sprite2D').set_visible(true)   # Assuming door visibility should be managed
	return found



func closeOffDoors():
	for tRoom in AllRooms:
		var topDirection=Vector2(tRoom.x, tRoom.y) + Vector2(0,-1)
		var bottomDirection = Vector2(tRoom.x, tRoom.y) + Vector2(0, 1)
		var leftDirection = Vector2(tRoom.x, tRoom.y) + Vector2(-1, 0)
		var rightDirection = Vector2(tRoom.x, tRoom.y) + Vector2(1, 0)
		
		var openings = 0
		
		if attemptCloseDoor(tRoom, topDirection, tRoom.topDoor): openings += 1
		if attemptCloseDoor(tRoom, bottomDirection, tRoom.bottomDoor): openings += 1
		if attemptCloseDoor(tRoom, leftDirection, tRoom.leftDoor): openings += 1
		if attemptCloseDoor(tRoom, rightDirection, tRoom.rightDoor):openings += 1
		
		if openings >= 3:
			OpenRooms.append(tRoom)

func attemptCloseDoor(targetRoom, targetDirection, door):
	var foundTargetRoom = null
	
	for tRoom in AllRooms:
		if tRoom.x == targetDirection.x and tRoom.y == targetDirection.y:
			foundTargetRoom = tRoom
			break
	# foundTargetRoom means there is a room in the direction we are checking
	# as such we need to return true and do nothing as door is already open
	# else we need to close the door and return false
	if foundTargetRoom == null:
		var d :Sprite2D = door.get_node('Sprite2D')
		if(d!=null): 
			d.visible=false  # Assuming door visibility should be managed
			targetRoom.openDoors.erase(door)
		else: print('door sprite not found')
		
		return false
	else:
		return true



func spawnRoom(pos: Vector2):
	var r = room.instantiate()
	
	r.position = pos * Vector2(r.size.x + spaceBetween, r.size.y + spaceBetween)
	r.pos = r.position

	r.x = int(pos.x)
	r.y = int(pos.y)
	r.name = "[" + str(r.x) + "," + str(r.y) + "]"
	
	AllRooms.append(r)

	var topPosition = Vector2(r.x, r.y) + Vector2(0, -1)
	var bottomPosition = Vector2(r.x, r.y) + Vector2(0, 1)
	var leftPosition = Vector2(r.x, r.y) + Vector2(-1, 0)
	var rightPosition = Vector2(r.x, r.y) + Vector2(1, 0)
	
	add_child(r)
	
	# Determine possible other spawn locations and add them to our list of possible rooms
	# Check if the (x, y) coordinates are not in AllRooms and not in PossibleRooms
	if is_not_in_all_rooms(topPosition) and is_not_in_possible_rooms(topPosition):
		PossibleRooms.append(topPosition)

	if is_not_in_all_rooms(bottomPosition) and is_not_in_possible_rooms(bottomPosition):
		PossibleRooms.append(bottomPosition)

	if is_not_in_all_rooms(rightPosition) and is_not_in_possible_rooms(rightPosition):
		PossibleRooms.append(rightPosition)

	if is_not_in_all_rooms(leftPosition) and is_not_in_possible_rooms(leftPosition):
		PossibleRooms.append(leftPosition)



# Create a function to check if a coordinate is not in AllRooms
func is_not_in_all_rooms(coordinate):
	for room in AllRooms:
		if room.x == coordinate.x and room.y == coordinate.y:
			return false
	return true

func is_not_in_possible_rooms(coordinate):
	return not PossibleRooms.has(coordinate)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
