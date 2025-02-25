@tool
# ############################################################################ #
# Copyright © 2018-2021 Paul Joannon
# Copyright © 2019-2023 Frédéric Maquin <fred@ephread.com>
# Licensed under the MIT License.
# See LICENSE in the project root for license information.
# ############################################################################ #

extends RefCounted

class_name InkPlayerFactory

const USE_MONO_RUNTIME_SETTING = "inkgd/use_mono_runtime"

# ############################################################################ #
# Methods
# ############################################################################ #

static func create():
	if _should_use_mono():
		var InkPlayer_Sharp = load("res://addons/inkgd/mono/InkPlayer.cs")
		if InkPlayer_Sharp.can_instantiate():
			return InkPlayer_Sharp.new()
		else:
			printerr(
					"[inkgd] [ERROR] InkPlayer can't be instantiated. Make sure that a suitable " +
					"copy of 'ink-runtime-engine.dll' can be found in project and double check " +
					"that the .csproj file contains a <RefCounted> item pointing to it. " +
					"If everything is configured correctly, you may need to rebuild " +
					"the C# solution. Please refer to [TO BE ADDED] for additional help."
			)
			print("[inkgd] [INFO] Falling back to the GDScript runtime.")

	# Falling back to GDscript.
	return load("res://addons/inkgd/ink_player.gd").new()


static func _should_use_mono() -> bool:
	if ProjectSettings.has_setting(USE_MONO_RUNTIME_SETTING):
		var use_mono = ProjectSettings.get_setting(USE_MONO_RUNTIME_SETTING)
		if use_mono == null:
			use_mono = false

		return _can_run_mono() && use_mono
	else:
		return _can_run_mono()

static func _can_run_mono() -> bool:
	return type_exists("GodotSharp")
