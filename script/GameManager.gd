extends Node

var puzzles: Dictionary = {
	"keypad1" = false,
	"cable1" = false
}

var ship_health
var ship_shilds
var ship_engin
var ship_signal
var ship_system

func solve_puzzle(puzzle_id: String) -> void:
	puzzles[puzzle_id] = true

func unsolve_puzzle(puzzle_id: String) -> void:
	puzzles[puzzle_id] = false

func is_puzzle_solved(puzzle_id: String) -> bool:
	return puzzles.get(puzzle_id, false)

func remove_puzzle(puzzle_id: String) -> void:
	puzzles.erase(puzzle_id)
