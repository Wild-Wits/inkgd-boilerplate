extends PanelContainer

@export var vbox_container : VBoxContainer

func setup_choices(choices:Array): # {"text":choice_text,"id":i,"disabled":bool}
	clear_choices()
	for choice in choices:
		var choice_button := Button.new()
		choice_button.text = choice.text
		choice_button.disabled = choice.disabled
		choice_button.pressed.connect(_on_choice_button_pressed.bind(choice.id))
		vbox_container.add_child(choice_button)

func clear_choices():
	for button in vbox_container.get_children():
		vbox_container.remove_child(button)
		button.queue_free()

func disable_choices():
	for button in vbox_container.get_children():
		if not button is Button or button.is_queued_for_deletion(): 
			continue
		button.disabled = true


func _on_choice_button_pressed(choice_id:int):
	disable_choices()
	StoryController.select_choice_and_continue(choice_id)
