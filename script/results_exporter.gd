extends Node
## ResultsExporter (Autoload) — Datenerhebung der Studie.
##
## Lauscht auf GameState.run_finished und haengt die Ergebnisse an zwei
## dauerhafte CSVs an — NIEMALS ueberschreiben:
##   runs.csv  — eine Zeile pro Lauf (Bedingungen + Gesamtergebnis)
##   tasks.csv — eine Zeile pro geloester Stoerung (Auswertung pro Aufgabe)
## Verknuepft ueber run_id. GameManager weiss nichts vom Export — er baut nur
## das results-Dictionary und feuert run_finished.
## Ergebnis-Ordner: einfach "results/" im Projektordner.
## (Hinweis: falls das Spiel mal exportiert wird, ist res:// schreibgeschuetzt —
## dann hier auf user:// umstellen.)
##
## Zusaetzlich: sendet die gleichen Daten per HTTP (fire-and-forget) an ein
## Google Sheet via Apps Script Web-App. Rein additiv — CSV wird immer
## geschrieben, unabhaengig davon ob der Sheet-Upload klappt (z.B. offline).
const RESULTS_DIR := "res://results"
const RUNS_HEADER := "run_id,timestamp,participant_id,dyslexia_enabled,stress_from_health,run_duration_s,time_used_s,malfunctions_solved,died_early"
const TASKS_HEADER := "run_id,participant_id,task_no,category,solved_at_s,time_left_s"

## Apps Script Web-App URL — nach dem Deployment hier eintragen.
const SHEET_URL := "https://script.google.com/macros/s/AKfycbxcDLo86UI7y4sMGBlWF7Yi14kRsgg0IvaS9zZYo0vtrKvRathwdnkuXtjmQmZGs7zuMg/exec"
func _ready() -> void:
	GameState.run_finished.connect(deliver_results)

func deliver_results(results: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(RESULTS_DIR)
	# .gdignore: Editor soll den Ordner ignorieren — sonst importiert Godot die
	# CSVs als "Translation" (erzeugt Muelldateien und stoert das Anhaengen).
	if not FileAccess.file_exists(RESULTS_DIR + "/.gdignore"):
		var g := FileAccess.open(RESULTS_DIR + "/.gdignore", FileAccess.WRITE)
		if g:
			g.close()

	var run_row := "%s,%s,%s,%s,%s,%.0f,%.1f,%d,%s" % [
		results.get("run_id", ""),
		results.get("timestamp", ""),
		results.get("participant_id", ""),
		str(results.get("dyslexia_enabled", false)),
		str(results.get("stress_from_health", false)),
		results.get("run_duration", 0.0),
		results.get("time_used", 0.0),
		results.get("malfunctions_solved", 0),
		str(results.get("died_early", false)),
	]
	_append_csv_line(RESULTS_DIR + "/runs.csv", RUNS_HEADER, run_row)

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
		var task_row := "%s,%s,%d,%s,%.1f,%.1f" % [
			results.get("run_id", ""),
			results.get("participant_id", ""),
			i + 1,
			str(entry.get("puzzle_id", "?")),
			entry.get("elapsed", 0.0),
			entry.get("time_left", 0.0),
		]
		_append_csv_line(RESULTS_DIR + "/tasks.csv", TASKS_HEADER, task_row)

		_send_to_sheet({
			"type": "task",
			"run_id": results.get("run_id", ""),
			"participant_id": results.get("participant_id", ""),
			"task_no": i + 1,
			"category": str(entry.get("puzzle_id", "?")),
			"solved_at_s": entry.get("elapsed", 0.0),
			"time_left_s": entry.get("time_left", 0.0),
		})

	print("=== Run %s exportiert (%d Task-Zeilen) -> %s ===" % [
		results.get("run_id", "?"), task_log.size(), ProjectSettings.globalize_path(RESULTS_DIR)])

## Eine Zeile an eine CSV anhaengen; Datei + Header werden bei Bedarf angelegt.
func _append_csv_line(path: String, header: String, row: String) -> void:
	var f: FileAccess
	if FileAccess.file_exists(path):
		f = FileAccess.open(path, FileAccess.READ_WRITE)
		if f:
			f.seek_end()
	else:
		f = FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_line(header)
	if f == null:
		# Datei gesperrt (z. B. gerade in Excel geoeffnet)? Daten NIEMALS verlieren —
		# stattdessen in eine Ausweichdatei daneben schreiben.
		var rescue := path.get_basename() + "_recovery_%d.csv" % Time.get_ticks_usec()
		push_error("CSV gesperrt (%s, Fehler %d) — Zeile landet in %s" % [path, FileAccess.get_open_error(), rescue])
		f = FileAccess.open(rescue, FileAccess.WRITE)
		if f == null:
			push_error("Auch Ausweichdatei fehlgeschlagen — Datenzeile verloren: " + row)
			return
		f.store_line(header)
	f.store_line(row)
	f.close()

## Sendet ein Ergebnis-Dictionary per POST ans Google-Sheet-Backend.
## Fire-and-forget: CSV ist immer die verlaessliche Quelle, das hier ist nur
## der Live-Sync. Content-Type text/plain vermeidet einen CORS-Preflight im
## HTML5-Export (Apps Script setzt selbst keine CORS-Header fuer OPTIONS).
func _send_to_sheet(payload: Dictionary) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result, _code, _headers, _body): http.queue_free())
	var json := JSON.stringify(payload)
	var headers := ["Content-Type: text/plain"]
	var err := http.request(SHEET_URL, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		push_error("Sheet-Upload fehlgeschlagen (lokale CSV bleibt trotzdem erhalten): " + str(err))
		http.queue_free()
