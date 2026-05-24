extends Node

signal manual_acquired_changed(acquired: bool)
signal ship_lights_changed(value: bool)

var puzzles: Dictionary = {
	"keypad1" = false,
	"cable1" = false,
	"lights" = false
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

func unsolve_puzzle(puzzle_id: String) -> void:
	puzzles[puzzle_id] = false

func is_puzzle_solved(puzzle_id: String) -> bool:
	return puzzles.get(puzzle_id, false)

func remove_puzzle(puzzle_id: String) -> void:
	puzzles.erase(puzzle_id)
