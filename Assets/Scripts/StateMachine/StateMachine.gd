extends Node
class_name StateMachine

var current_state : State

var entity: Entity

# Called when the node enters the scene tree for the first time.
func _ready():
	# if this is a part of an entity, store ref here
	entity = get_node_or_null("..")
	if not entity:
		print_debug("no entity in statemachine parent: "+name)
		
	setup_states(self)
			
	# connect signal to animationplayer - when its anim finishes, lets the state know its animtion is done
	entity.get_node("AnimationPlayer").animation_finished.connect(_on_anim_finished)

# For each child node of the given node, if it is a State, set up its entity reference to the entity this state machine is for
func setup_states(state_parent: Node):
	for state in state_parent.get_children():
		if state is State:
			#print("registered state ", state.name)
			# if statemachine is part of an entity, store it here
			if entity: state.entity = entity
			# make sure all inactive states are not being processed
			state.set_process(false)

func _process(delta):
	if not current_state:
		switch_to(get_child(0))
		
	current_state.time_elapsed += delta
	
	var next_state: State = current_state.check_transition(delta)
	if next_state:
		switch_to(next_state)
		
	current_state.update(delta)
		
	# after this, all inactive states will be disabled
	# and only the active one will have inherit (pausable)

func _physics_process(delta):
	if (current_state): current_state.physics_update(delta)

func switch_to_state_name(state_name: String):
	var target_state: State = get_node_or_null(state_name)
	if target_state:
		switch_to(target_state)
	else:
		print_debug("state %s does not exist" % state_name)

# switch to the new state. Will look for a child node with the given name (path).
func switch_to(state: State):
	# make sure inactive states are not being processed
	if (current_state):
		current_state.on_exit_state()
		current_state.set_process(false)
	
	current_state = state
		
	current_state.time_elapsed = 0
	current_state.anim_finished = false
	current_state.set_process(true)
	current_state.on_enter_state()
	
	#print(entity.name+"'s state changed to "+current_state.name)

func is_in_state(state_name: String):
	return current_state and current_state.name == state_name

func _on_anim_finished(anim_name: StringName) -> void:
	if current_state:
		current_state.anim_finished = true
