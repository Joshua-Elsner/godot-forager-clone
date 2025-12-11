extends CharacterBody2D

const SPEED = 250.0

@onready var interaction_area: Area2D = $InteractionArea
@onready var camera: Camera2D = $Camera2D

@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

func _ready():
	for child in get_children():
		print(" - ", child.name)
		
	# this camera is enabled only for the player instance this client controls
	if multiplayer.get_unique_id() == player_id:
		print("This player is MINE. Enabling camera.")
		camera.make_current()
	else:
		print("This is a remote player. Disabling camera.")
		camera.enabled = false

func _physics_process(_delta):
	#the server is the only authority that can apply movement
	if multiplayer.is_server():
		_apply_movement_from_input()
	
	#check for interaction input only if this is the local player
	if multiplayer.get_unique_id() == player_id:
		if Input.is_action_just_pressed("craft_test"):
			#TODO: make this not be planks every time
			var plank_recipe_id = "wooden_plank"
			CraftingManager.server_try_craft_recipe.rpc_id(1, plank_recipe_id)
			
		#mining input
		if Input.is_action_just_pressed("interact"):
			# instead of interacting directly send a request to the server
			server_perform_interaction.rpc_id(1)
			
		#ui toggle input
		if Input.is_action_just_pressed("menu_bar_toggle"):
			MultiplayerManager.game_manager.toggle_menu_bar()

func _apply_movement_from_input():
	# movement is calculated from the synchronized input vector
	var input_vector = %InputSynchronizer.input_vector
	velocity = input_vector.normalized() * SPEED
	move_and_slide()

@rpc("call_local", "reliable")
func add_item_to_inventory(item_path: String, quantity: int):
	# This code runs on the client's machine
	print("CLIENT: Received item ", item_path, " from server.")
	var item_data: ItemData = load(item_path)
	InventoryManager.add_item(item_data, quantity)

@rpc("call_local", "reliable")
func remove_item_from_inventory(item_path: String, quantity: int):
	var item_data: ItemData = load(item_path)
	InventoryManager.remove_item(item_data, quantity)
	
@rpc("any_peer", "call_local")
func server_perform_interaction():
	var nearby_objects = interaction_area.get_overlapping_bodies()

	if not nearby_objects.is_empty():
		var target = nearby_objects[0]
		if target.has_method("interact"):
			print("SERVER: Player ", player_id, " is interacting with ", target.name)
			target.interact(self)
		

#this function is better for non movement input like mouse clicks
func _unhandled_input(event):
	#only care about the local players input
	if multiplayer.get_unique_id() != player_id:
		return

	#check if the player left clicked
	if event.is_action_pressed("build"):
		
		#if we are in build mode place the object
		if BuildManager.pending_build_data != null:
			var mouse_pos = get_global_mouse_position()
			# TODO: snap this position to grid.
			
			var data_path = BuildManager.pending_build_data.resource_path
			
			#send the request to the server to place the building
			BuildManager.server_place_building.rpc_id(1, data_path, mouse_pos)
			
			# exit build mode after placing the item
			BuildManager.exit_build_mode()
			
			# this stops the click from also triggering an interaction
			get_viewport().set_input_as_handled()
			
		# If not in build mode perform a normal interaction
		elif Input.is_action_just_pressed("interact"):
			server_perform_interaction.rpc_id(1)
