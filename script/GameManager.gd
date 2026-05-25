extends Node

signal manual_acquired_changed(acquired: bool)
signal ship_lights_changed(value: bool)
signal puzzle_solved(puzzle_id: String)
signal puzzle_unsolved(puzzle_id: String)

var puzzles: Dictionary = {
	"keypad1" = false,
	"cable1" = false,
	"lights" = false,
	"main_door" = false,
	"storage_door" = false,
	"right_engin_door" = false,
	"left_engin_door" = false,
	"treibstoff" = false,
	
}

var ship_health
var ship_shilds
var ship_engin
var ship_signal
var ship_system

var ship_lights: bool = false:
	set(value):
		ship_lights = value
		ship_lights_changed.emit(value)
		
var manule_aquiered: bool = false:
	set(value):
		manule_aquiered = value
		manual_acquired_changed.emit(value)

func solve_puzzle(puzzle_id: String) -> void:
	puzzles[puzzle_id] = true
	puzzle_solved.emit(puzzle_id)

func unsolve_puzzle(puzzle_id: String) -> void:
	puzzles[puzzle_id] = false
	puzzle_unsolved.emit(puzzle_id)

func is_puzzle_solved(puzzle_id: String) -> bool:
	return puzzles.get(puzzle_id, false)

func remove_puzzle(puzzle_id: String) -> void:
	puzzles.erase(puzzle_id)
