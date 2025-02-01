class_name StoryParser
extends Node

const INSTRUCTION_MARKER = ">>>"
const INSTRUCTION_SEPARATOR = ","
const INSTRUCTIONS = [
	{"keyword":"sound","args":1},
	{"keyword":"transition_to","args":1},
]


### returns clean text for the story controller + parses instructions
func parse_line(text:String)->String:
	var clean_text = text.strip_edges()
	if clean_text.begins_with(INSTRUCTION_MARKER):
		# this is a special line with instructions for the engine -> parse and then skip line
		_parse_instruction(clean_text.trim_prefix(INSTRUCTION_MARKER))
		return ""
	if clean_text.is_empty():
		# case of empty line with no instruction -> skip to the next line
		StoryController.continue_story()
	return clean_text

# Returns an Array of Dictionary (format depending on the type of choice)
# from an Array of InkChoice
func parse_choices(choices:Array) -> Array: 
	var parsed_choices = [] # Reset choices_dict first !
	parsed_choices.resize(choices.size())
	for i in choices.size():
		var choice_text : String = choices[i].text.strip_edges()
		parsed_choices[i] = {
				"text":choice_text,
				"id":i,
				"disabled":"DISABLED" in choices[i].tags if choices[i].tags else false,
			}
	return parsed_choices

func parse_tags(tags:Array) -> Dictionary:
	var clean_tags : Dictionary = {}
	for tag in tags:
		if not tag is String:
			continue
		var clean_tag = tag.strip_edges()
		if ":" in tag:
			var split_tag = clean_tag.split(":")
			clean_tags[split_tag[0].strip_edges()] = split_tag[1].strip_edges()
		else:
			clean_tags[clean_tag] = true
	return clean_tags

func _parse_instruction(instruction:String):
	var instruction_clean = instruction.strip_edges()
	var components : PackedStringArray = instruction_clean.split(":", true, 1)

	var keyword : String = components[0].strip_edges().to_lower()

	var args : PackedStringArray
	if components.size() > 1:
		args = components[1].strip_edges().split(INSTRUCTION_SEPARATOR)
	else:
		args = []

	if keyword.is_empty():
		printerr("STORY PARSER : keyword is empty !! colon missing in instruction ? '%s'" % instruction_clean)
		return
	
	var relevant_instructions = INSTRUCTIONS.filter(func(i): return i.keyword == keyword)
	if relevant_instructions.is_empty():
		printerr("No relevant instruction matching %s" % instruction)
		StoryController.continue_story()
		return
	var command = relevant_instructions[0]
	if (command.args is int and command.args == args.size()) or (command.args is Array and args.size() in command.args):
		call("_parse_instruction_%s" % keyword, args)
	else:
		print("Invalid instruction %s with args %s" % [keyword, str(args)])
		if command.args is int:
			printerr("number of arguments for '%s' is incorrect (expected %d, got %d)" % [keyword, command.args, args.size()])
		elif command.args is Array:
			printerr("number of arguments for '%s' is incorrect (got %d, but should be in %s)" % [keyword, args.size(), str(command.args)])


func _parse_instruction_sound(args:Array):
	var sound_id = args[0].strip_edges()
	StoryController.story_instruction_sound.emit(sound_id)

func _parse_instruction_transition_to(args:Array):
	var scene_id = args[0].strip_edges()
