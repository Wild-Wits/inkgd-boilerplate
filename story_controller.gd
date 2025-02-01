# StoryController
extends Node

signal story_loading
signal story_loaded
signal story_ended
signal state_changed
signal story_new_line(text:String, tags:Dictionary)
signal story_choices_prompted(choices:Array)
signal choice_selected(source_path:String,chosen_idx:int)

signal story_instruction_sound(sound_id:String)

@export var story_json_file : InkResource

@onready var parser : StoryParser = $Parser
@onready var ink_player = InkPlayerFactory.create()

var is_story_loaded : bool = false
var is_story_loading : bool = false

func _ready():
	add_child(ink_player)
	
func load_story():
	if not ink_player.loaded.is_connected(_loaded):
		_connect_signals()
	if not ink_player.is_node_ready():
		await ink_player.ready
	if not is_node_ready():
		await ready
	if is_story_loading:
		# Already loading
		return
	if is_story_loaded:
		await get_tree().process_frame
		# Already loaded
		story_loaded.emit()
		return
	if not story_json_file:
		printerr("Cannot load %s : not a valid InkResource" % story_json_file)
		return
	print("Loading story...")
	is_story_loading = true
	is_story_loaded = false
	story_loading.emit()
	ink_player.ink_file = story_json_file
	ink_player.destroy()
	ink_player.create_story()

func continue_story_maximally() -> String:
	return ink_player.continue_story_maximally()

func get_story_state() -> String:
	return ink_player.get_state() if is_story_loaded else ""
	
func get_current_choices() -> Array:
	return ink_player.current_choices
	
func get_current_path() -> String:
	if ink_player.current_choices.is_empty():
		return ink_player.current_path
	return ink_player.current_choices.front().source_path
	
func get_state() -> String:
	return ink_player.get_state()
	
func get_current_flow_name() -> String:
	return ink_player.current_flow_name

func create_ink_list_with_origin(single_origin_list_name: String) -> InkList:
	return ink_player.create_ink_list_with_origin(single_origin_list_name)
	
func visit_count_at_path(path: String) -> int:
	return ink_player.visit_count_at_path(path)

func evaluate_function(function_name: String, arguments = []) -> InkFunctionResult:
	return ink_player.evaluate_function(function_name, arguments)
	
func switch_flow(flow_name:String):
	ink_player.switch_flow(flow_name)
	
func switch_to_default_flow():
	ink_player.switch_to_default_flow()
	
func set_state(state:String):
	ink_player.set_state(state)
	await get_tree().process_frame
	state_changed.emit()
	
func observe_variables(variable_names: Array, object: Object, method_name: String):
	ink_player.observe_variables(variable_names, object, method_name)
	
func remove_variable_observer_for_all_variables(object: Object, method_name: String):
	ink_player.remove_variable_observer_for_all_variables(object, method_name)


func get_variable(var_name):
	if not is_story_loaded:
		return false
	return ink_player.get_variable(var_name)

func set_variable(var_name, value):
	if not is_story_loaded:
		return
	ink_player.set_variable(var_name, value)

func get_current_node() -> String :
	return ink_player.get_current_path().split(".")[0].strip_edges()
	
func is_in_parallel_flow() -> bool:
	return get_current_flow_name() != "DEFAULT_FLOW"

func can_continue() -> bool:
	if not is_story_loaded:
		return false
	return ink_player.can_continue

func continue_story():
	if not is_story_loaded:
		return
	ink_player.continue_story()

func goto(path, auto_continue:bool=true) -> String:
	if not is_story_loaded:
		return "[color=red]Cannot go to %s : story not loaded[/red]" % path
	if not is_path_valid(path):
		printerr("%s is not a valid ink path" % path)
		return "[color=red]Cannot go to %s : this path does not exist[/color]" % path
	print("Diverting path to %s" % path)
	ink_player.choose_path(path)
	if not auto_continue:
		return "[color=green]Going to %s ...[/color]" % path
	ink_player.continue_story()
	return "[color=green]Going to %s (and continuing) ...[/color]" % path
	
func select_choice(id:int):
	if not is_story_loaded:
		return
	if not ink_player.has_choices:
		return
	choice_selected.emit(get_current_path(),id)
	ink_player.choose_choice_index(id)
	
func select_choice_and_continue(id:int):
	if not is_story_loaded:
		return
	select_choice(id)
	ink_player.continue_story()

func is_path_valid(path: String) -> bool:
	return ink_player.is_path_valid(path)

func _loaded(successfully):
	is_story_loading = false
	if !successfully:
		printerr("The story couldn't be created.")
		return
	ink_player.bind_external_function("displayLocutorAndTone",self,"ink_displayLocutorAndTone",true)
	ink_player.bind_external_function("get_influence",self,"ink_get_influence",true)
	ink_player.bind_external_function("test_influence",self,"ink_test_influence",false)
	ink_player.bind_external_function("notify_affinity_test_result",self,"ink_notify_affinity_test_result",false)
	print("Story loaded !")
	is_story_loaded = true
	story_loaded.emit()

func _story_continued(text:String, tags:Array):
	var clean_text := parser.parse_line(text)
	var clean_tags := parser.parse_tags(tags)
	if clean_text.is_empty():
		# we don't know if this is the result of the line being an instruction
		# or a dummy empty line. In both cases, the Parser will take care of it.
		return

	story_new_line.emit(clean_text,clean_tags)

	# To be able to print the choices at the same time as the line of
	# content, the choices are manually retrieved here.
	if ink_player.has_choices:
		_choices_prompted(ink_player.current_choices)

func _choices_prompted(choices):
	story_choices_prompted.emit(parser.parse_choices(choices))
	

func _story_ended():
	story_ended.emit()

func _exception_raised(message, _stack_trace):
	printerr(message)

func _error_encountered(message, _type):
	printerr(message)

func debug(message:String):
	print("[Ink Debug]: %s" % message)
	if ink_player.can_continue:
		ink_player.continue_story()

func error(message:String):
	printerr("[Ink Error]: %s" % message)
	if ink_player.can_continue:
		ink_player.continue_story()

func _connect_signals():
	ink_player.loaded.connect(_loaded)
	ink_player.continued.connect(_story_continued)
	ink_player.prompt_choices.connect(_choices_prompted)
	ink_player.ended.connect(_story_ended)
	ink_player.exception_raised.connect(_exception_raised)
	ink_player.error_encountered.connect(_error_encountered)

func reset():
	story_loading.emit()
	ink_player.reset()
	await get_tree().process_frame
	story_loaded.emit()
	
