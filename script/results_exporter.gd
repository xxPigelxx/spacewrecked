extends Node
## ResultsExporter (Autoload) — Datenerhebung der Studie.
##
## Tasks: sofort einzeln bei run_finished.
## Run + Manual-Zeiten: zusammen in einer Zeile, gesendet sobald die
## Manual-Zeiten eintreffen (Run-Daten warten kurz darauf).
## Fragebogen: eigene Zeile, separat beim Submit.
## Alle drei ueber run_id verknuepft.

const SHEET_URL := "https://script.google.com/macros/s/AKfycbxcDLo86UI7y4sMGBlWF7Yi14kRsgg0IvaS9zZYo0vtrKvRathwdnkuXtjmQmZGs7zuMg/exec"

var _pending_run: Dictionary = {}   ## wartet auf Manual-Zeiten

func _ready() -> void:
	GameState.run_finished.connect(_on_run_finished)
	GameState.questionnaire_submitted.connect(_on_questionnaire_submitted)

func _on_run_finished(results: Dictionary) -> void:
	# Run-Basisdaten zwischenspeichern, warten auf Manual-Zeiten.
	_pending_run = {
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
	}

	# Tasks: sofort, einzeln, unabhaengig vom Rest.
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

	print("=== Run %s: %d Task-Zeilen gesendet, warte auf Manual-Zeiten ===" % [
		results.get("run_id", "?"), task_log.size()])

## Manual-Zeiten kommen rein -> mit Run-Daten mergen und SOFORT senden.
func deliver_manual_times(run_id: String, page_times: Dictionary) -> void:
	if _pending_run.get("run_id", "") != run_id:
		push_warning("Manual-Zeiten fuer unbekannten/veralteten Run: " + run_id)
		return

	for tab_name in page_times:
		_pending_run["manual_time_%s_s" % tab_name] = page_times[tab_name]

	_send_to_sheet(_pending_run)
	print("=== Run+Manual-Zeile fuer %s gesendet ===" % run_id)
	_pending_run = {}

## Fragebogen fertig: eigene Zeile, unabhaengig vom Run+Manual-Timing.
func _on_questionnaire_submitted(answers: Array) -> void:
	var payload := {
		"type": "questionnaire",
		"run_id": GameState.get_current_run_id(),
		"participant_id": GameState.participant_id,
	}
	for entry in answers:
		payload[entry["name"]] = entry["selected"]

	_send_to_sheet(payload)
	print("=== Fragebogen fuer %s gesendet (%d Antworten) ===" % [
		GameState.get_current_run_id(), answers.size()])

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
