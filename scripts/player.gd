extends CharacterBody2D

@export_category("Status") # for showing the status bar (no coding input purpose)
@export var speed: int = 400 # speed of the character
@export var attack_speed: float = 0.6

# adding animation
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

var move_direction: Vector2 = Vector2.ZERO # current direction of the player

# different state of player
enum State {
	IDLE, RUN, ATTACK, DEAD
}
var state: State = State.IDLE # initial state

func update_animation() -> void:
	# matching state
	match state:
		State.IDLE:
			animation_playback.travel("idle") # changing the state to that match
		State.RUN:
			animation_playback.travel("run")
		State.ATTACK:
			animation_playback.travel("attack")

func movement_loop() -> void:
	# updating positions after each movement
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	
	# calculating motion
	# normalization done to get direction instead of motion
	var motion: Vector2 = move_direction.normalized() * speed
	set_velocity(motion) # applying the motion
	
	# horijontal flipping
	if state == State.IDLE or  State.RUN:
		if move_direction.x < -0.01:
			$Sprite2D.flip_h = true
		elif move_direction.x > 0.01:
			$Sprite2D.flip_h = false
	
	move_and_slide() # for 4-direction movement
	
	#updating animation
	if motion != Vector2.ZERO and state == State.IDLE:
		state = State.RUN
		update_animation()
	elif motion == Vector2.ZERO and state == State.RUN:
		state = State.IDLE
		update_animation()

func attack() -> void:
	# if the player is attacking nothing to do
	if state == State.ATTACK:
		return
	state = State.ATTACK
	
	# finding attack direction
	var mouse_position: Vector2 = get_global_mouse_position() # position of the mouse
	var attack_direction: Vector2 = (mouse_position - global_position).normalized() # getting direction form vector by normalization
	
	$Sprite2D.flip_h = attack_direction.x < 0 and abs(attack_direction.x) >= abs(attack_direction.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_direction)
	update_animation()
	
	await get_tree().create_timer(attack_speed).timeout
	state = State.IDLE
	update_animation()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		attack()

func _physics_process(delta: float) -> void: # default physics
	if state != State.ATTACK:
		movement_loop() # appling physics to movement_loop func
