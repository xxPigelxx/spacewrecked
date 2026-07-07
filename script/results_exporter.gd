extends Node
## ResultsExporter (Autoload) — Datenerhebung der Studie.
##
## Lauscht auf GameState.run_finished und sendet die Ergebnisse per HTTP
## (fire-and-forget) an ein Google Sheet via Apps Script Web-App.
## Verknuepft ueber run_id. GameManager weiss nichts vom Export — er baut nur
## das results-Dictionary und feuert run_finished.

## Apps Script Web-App URL — nach dem Deployment hier eintragen.
const SHEET_URL := "https://script.google.com/macros/s/AKfycbxcDLo86UI7y4sMGBlWF7Yi14kRsgg0IvaS9zZYo0vtrKvRathwdnkuXtjmQmZGs7zuMg/exec"

func _ready() -> void:
	GameState.run_finished.connect(deliver_results)

func deliver_results(results: Dictionary) -> void:
	_send_to_sheet({
		"type": "run",
		"run_id": results.get("run_id", ""),
		"timestamp": results.get("timestamp", ""),
		"participant_id": results.get("participant_id", ""),
		"dyslexia_enabled": results.get("dyslexia_enabled", false),
		"stress_from_health": results.get("stress_from_health", false),
		"run_duration_s": results.get("run_duration", 0.0),
		"time_used_s": results.get("time_used", 0.0),
		"malfunctions_solved": results.get("malfunctions_solved", 0),
		"died_early": results.get("died_early", false),
	})

	var task_log: Array = results.get("log", [])
	for i in task_log.size():
		var entry: Dictionary = task_log[i]
		_send_to_sheet({
			"type": "task",
			"run_id": results.get("run_id", ""),
			"participant_id": results.get("participant_id", ""),
			"task_no": i + 1,
			"category": str(entry.get("puzzle_id", "?")),
			"solved_at_s": entry.get("elapsed", 0.0),
			"time_left_s": entry.get("time_left", 0.0),
		})

	print("=== Run %s an Google Sheet gesendet (%d Task-Zeilen) ===" % [
		results.get("run_id", "?"), task_log.size()])

## Sendet ein Ergebnis-Dictionary per POST ans Google-Sheet-Backend.
## Content-Type text/plain vermeidet einen CORS-Preflight im HTML5-Export
## (Apps Script setzt selbst keine CORS-Header fuer OPTIONS).
func _send_to_sheet(payload: Dictionary) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result, _code, _headers, _body): http.queue_free())
	var json := JSON.stringify(payload)
	var headers := ["Content-Type: text/plain"]
	var err := http.request(SHEET_URL, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		push_error("Sheet-Upload fehlgeschlagen: " + str(err))
		http.queue_free()
