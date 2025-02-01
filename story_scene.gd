extends Control

const AUDIO_FILES : Dictionary = {
	"beep" : "res://computerNoise_001.ogg"
}

@export var story_line_scene : PackedScene
@export var choice_scene : PackedScene
@export var vbox_container : VBoxContainer
@export var continue_button : Button
@export var scroll_container : ScrollContainer
@export var sound_player : AudioStreamPlayer

func _ready():
	clear()
	connect_signals()
	if not StoryController.is_story_loaded:
		if not StoryController.is_story_loading:
			StoryController.load_story()
		await StoryController.story_loaded
	if StoryController.can_continue():
		print("Continuing ...")
		StoryController.continue_story()

func clear():
	for child in vbox_container.get_children():
		child.queue_free()

func scroll_to_bottom():
	await get_tree().process_frame
	await get_tree().process_frame
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var scroll_max := vbox_container.size.y - scroll_container.size.y + 50
	tween.tween_property(scroll_container,"scroll_vertical",scroll_max,0.2)

func connect_signals():
	StoryController.story_new_line.connect(_on_story_new_line)
	StoryController.story_choices_prompted.connect(_on_story_choices_prompted)
	StoryController.story_instruction_sound.connect(_on_story_instruction_sound)
	StoryController.story_ended.connect(_on_story_ended)
	continue_button.pressed.connect(_on_continue_pressed)

func _on_continue_pressed():
	StoryController.continue_story()

func _on_story_new_line(text:String, _tags:Dictionary):
	var line : Label = story_line_scene.instantiate()
	line.text = text
	vbox_container.add_child(line)
	scroll_to_bottom()
	continue_button.disabled = false
	continue_button.grab_focus()

func _on_story_choices_prompted(choices:Array):
	var choice : PanelContainer = choice_scene.instantiate()
	vbox_container.add_child(choice)
	choice.setup_choices(choices)
	scroll_to_bottom()
	continue_button.disabled = true
	choice.vbox_container.get_child(0).grab_focus()

func _on_story_instruction_sound(sound_id:String):
	sound_id = sound_id.to_lower()
	if sound_id == "stop":
		if sound_player.playing:
			var tween := create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			tween.tween_property(sound_player,"volume_db",-80,2.0)
	if sound_id in AUDIO_FILES:
		sound_player.volume_db = 0.0
		sound_player.stream = load(AUDIO_FILES[sound_id])
		sound_player.play()
	StoryController.continue_story()


func _on_story_ended():
	get_tree().quit()
