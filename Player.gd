extends KinematicBody2D

export var speed: = Vector2(1000.0, 2000.0)
export var gravity: = 4000.0
var FLOOR_NORMAL = Vector2.UP

var hp = 500 setget set_hp
var velocity = Vector2(0, 0)
var can_shoot = true
var is_reloading = false
var double_jump = true
var direction = Vector2()
var past_dir : = 0
var left_right : = 1
var scaleNW = scale.x


var player_bullet = load("res://Player_bullet.tscn")
var username_text = load("res://Username_text.tscn")

var username setget username_set
var username_text_instance = null

puppet var puppet_hp = 500 setget puppet_hp_set
puppet var puppet_position = Vector2(0, 0) setget puppet_position_set
puppet var puppet_velocity = Vector2()
puppet var puppet_rotation = 0
puppet var puppet_username = "" setget puppet_username_set
puppet var puppet_double_jump = true
#puppet var puppet_scaleNW = 1 setget puppet_scaleNW_set

onready var tween = $Tween
onready var sprite = $Sprite
onready var reload_timer = $Reload_timer
onready var shoot_point = $Shoot_point
onready var hit_timer = $Hit_timer

func _ready():
	get_tree().connect("network_peer_connected", self, "_network_peer_connected")
	
	username_text_instance = Global.instance_node_at_location(username_text, Persistent_nodes, global_position)
	username_text_instance.player_following = self
	
	update_shoot_mode(false)
	Global.alive_players.append(self)
	
	yield(get_tree(), "idle_frame")
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = self

func _physics_process(delta: float) -> void:
	if username_text_instance != null:
		username_text_instance.name = "username" + name
	
	if get_tree().has_network_peer():
		if is_network_master() and visible:
			# Remembers the previous direction the player was moving
			past_dir = direction.x
			# Finds the new direction and velocity
			direction = get_direction()
			velocity = calculate_move_velocity(velocity, direction, speed)
			velocity = move_and_slide(velocity, Vector2.UP)
			# If the player no longer is following the same direction as it used to
			# it will flip the player about and all its children
			# statement makes sure the player does not flip if it moves in the same direction again
			# after stopping
			if(past_dir != direction.x and left_right != sign(direction.x) and direction.x != 0):
				# The print statements helped debug the code and keep track of the variables
				#print("Past dir: ", past_dir)
				#print("Curr dir: ", direction.x)
				#print("Scale.x: ", scale.x)
				# scale.x is the size in the x-axis of the character
				# setting scale.x to negative 1 will competely flip the character
				# and all of its children in the opposite direction
				scale.x *= -1
				# left_right is a variable which helps keep track of which
				# direction the character is looking at: left or right
				left_right *= -1
#				rset_unreliable("puppet_scaleNW", -1)
				#print("Scale.x AFTER: ", scale.x)
				#print("\n\n\n\n")
			
#			if (abs(velocity.x) > 1):
#				if(velocity.x < -1):
#					sprite.flip.h = true
#
#				elif(velocity.x < 1):
#					sprite.flip.h = false
			
			
			if Input.is_action_pressed("click") and can_shoot and not is_reloading:
				rpc("instance_bullet", get_tree().get_network_unique_id())
				is_reloading = true
				reload_timer.start()
		else:
			if not tween.is_active():
				move_and_slide(puppet_velocity * speed)
	if hp <= 0:
		if username_text_instance != null:
			username_text_instance.visible = false
		
		if get_tree().has_network_peer():
			if get_tree().is_network_server():
				rpc("destroy")







func lerp_angle(from, to, weight):
	return from + short_angle_dist(from, to) * weight

func short_angle_dist(from, to):
	var max_angle = PI * 2
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference

func puppet_position_set(new_value) -> void:
	puppet_position = new_value
	
	tween.interpolate_property(self, "global_position", global_position, puppet_position, 0.1)
	tween.start()

func set_hp(new_value):
	hp = new_value
	if hp == 100:
		$"../QuestionPopup".popup_centered()
	if get_tree().has_network_peer():
		if is_network_master():
			rset("puppet_hp", hp)

func puppet_hp_set(new_value):
	puppet_hp = new_value
	if puppet_hp == 100:
		$"../QuestionPopup".popup()
	if get_tree().has_network_peer():
		if not is_network_master():
			hp = puppet_hp

func username_set(new_value) -> void:
	username = new_value
	
	if get_tree().has_network_peer():
		if is_network_master() and username_text_instance != null:
			username_text_instance.text = username
			rset("puppet_username", username)

func puppet_username_set(new_value) -> void:
	puppet_username = new_value
	
	if get_tree().has_network_peer():
		if not is_network_master() and username_text_instance != null:
			username_text_instance.text = puppet_username

func _network_peer_connected(id) -> void:
	rset_id(id, "puppet_username", username)

func _on_Network_tick_rate_timeout():
	if get_tree().has_network_peer():
		if is_network_master():
			rset_unreliable("puppet_position", global_position)
			rset_unreliable("puppet_velocity", velocity)
			rset_unreliable("puppet_rotation", rotation)
			#rset_unreliable("puppet_scaleNW", -1)

sync func instance_bullet(id):
	var player_bullet_instance = Global.instance_node_at_location(player_bullet, Persistent_nodes, shoot_point.global_position)
	player_bullet_instance.name = "Bullet" + name + str(Network.networked_object_name_index)
	player_bullet_instance.set_network_master(id)
	player_bullet_instance.player_rotation = rotation
	player_bullet_instance.player_owner = id
	Network.networked_object_name_index += 1

sync func update_position(pos):
	global_position = pos
	puppet_position = pos
	
#sync func puppet_scaleNW_set(newScale):
#	scale.x = newScale

func update_shoot_mode(shoot_mode):
	if not shoot_mode:
		sprite.set_region_rect(Rect2(0, 1500, 256, 250))
	else:
		sprite.set_region_rect(Rect2(512, 1500, 256, 250))
	
	can_shoot = shoot_mode

func _on_Reload_timer_timeout():
	is_reloading = false

func _on_Hit_timer_timeout():
	modulate = Color(1, 1, 1, 1)

func _on_Hitbox_area_entered(area):
	if get_tree().is_network_server():
		if area.is_in_group("Player_damager") and area.get_parent().player_owner != int(name):
			rpc("hit_by_damager", area.get_parent().damage)
			
			area.get_parent().rpc("destroy")

sync func hit_by_damager(damage):
	hp -= damage
	if hp == 100:
		$CanvasLayer/QuestionPopup.popup_centered()
		print("\nHERE IS THE VISIBILITY TEST\n",$CanvasLayer/QuestionPopup.visible, "\nTESTING IF THIS WILL PRINT VISIBILITY\n")

	modulate = Color(5, 5, 5, 1)
	hit_timer.start()

sync func enable() -> void:
	hp = 500
	can_shoot = false
	update_shoot_mode(false)
	username_text_instance.visible = true
	visible = true
	$CollisionShape2D.disabled = false
	$Hitbox/CollisionShape2D.disabled = false
	
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = self
	
	if not Global.alive_players.has(self):
		Global.alive_players.append(self)

sync func destroy() -> void:
	username_text_instance.visible = false
	visible = false
	$CollisionShape2D.disabled = true
	$Hitbox/CollisionShape2D.disabled = true
	Global.alive_players.erase(self)
	
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = null

func _exit_tree() -> void:
	Global.alive_players.erase(self)
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = null





func calculate_move_velocity(
	linear_velocity: Vector2,
	direction: Vector2,
	speed: Vector2
	) -> Vector2:
	var new_velocity: = linear_velocity
	new_velocity.x = speed.x * direction.x
	new_velocity.y += gravity * get_physics_process_delta_time()
	if direction.y == -1.0:
		new_velocity.y = speed.y * direction.y
	
	return new_velocity
	
	
func get_direction () -> Vector2:
	if is_on_floor():
		double_jump = true
	var jump_val: = 0
	if (Input.is_action_just_pressed("up") and double_jump and !is_on_floor()):
		jump_val = -1.0
		double_jump = false
	elif (Input.is_action_just_pressed("up") and is_on_floor()):
		jump_val = -1.0
	else:
		 jump_val = 1.0
	
	
	return Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		jump_val
	)
