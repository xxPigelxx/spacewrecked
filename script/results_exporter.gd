extends Node
## ResultsExporter (Autoload) — Datenerhebung der Studie.
##
## Sammelt alles, was waehrend eines Durchlaufs anfaellt, in EINER Zeile
## und schickt sie genau einmal ab: wenn der Post-Fragebogen abgeschickt wird.
##
## Reihenfolge egal — Fragebogen, Spielende und Manual-Zeiten koennen in
## beliebiger Folge eintreffen, sie landen alle im selben Dictionary.

const SHEET_URL := "https://script.google.com/macros/s/AKfycbxcDLo86UI7y4sMGBlWF7Yi14kRsgg0IvaS9zZYo0vtrKvRathwdnkuXtjmQmZGs7zuMg/exec"

## Die Zeile, die am Ende ins Sheet geht. Wird ueber den ganzen Durchlauf gefuellt.
var _row: Dictionary = {}
var _uploading := false
var _quitting := false


func _ready() -> void:
	reset()
	GameState.run_finished.connect(_on_run_finished)
	# Fenster-X soll nicht mitten im Upload beenden.
	get_tree().set_auto_accept_quit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_when_upload_done()


## Setzt die Zeile zurueck. Beim Start und vor einem neuen Durchlauf aufrufen.
func reset() -> void:
	_row = {"type": "run"}
	_row["timestamp_start"] = Time.get_datetime_string_from_system(true)
	_uploading = false


# --------------------------------------------------------------------------
#  Sammeln
# --------------------------------------------------------------------------

## Einzelwert ablegen, z. B. store("alter", 22).
func store(key: String, value) -> void:
	_row[key] = value


## Fragebogen-Antworten ablegen. block ist "pre" oder "post".
## Aus der Frage "q01" wird so die Spalte "q01_pre" bzw. "q01_post".
## answers ist das Array aus questionear.gd: [{ "name": ..., "selected": ... }, ...]
func store_answers(block: String, answers: Array) -> void:
	for entry in answers:
		_row["%s_%s" % [entry["name"], block]] = entry["selected"]


## Lesezeiten pro Handbuch-Tab. Kommt aus ManualPage.gd.
func deliver_manual_times(page_times: Dictionary) -> void:
	for tab_name in page_times:
		_row["manual_time_%s_s" % tab_name] = _round2(page_times[tab_name])


## Spielende: Kennzahlen des Durchlaufs uebernehmen.
func _on_run_finished(results: Dictionary) -> void:
	_row["run_id"] = results.get("run_id", "")
	_row["participant_id"] = results.get("participant_id", "")
	_row["dyslexia_enabled"] = results.get("dyslexia_enabled", false)
	_row["stress_from_health"] = results.get("stress_from_health", false)
	_row["run_duration_s"] = _round2(results.get("run_duration", 0.0))
	_row["malfunctions_solved"] = results.get("malfunctions_solved", 0)
	_row["died_early"] = results.get("died_early", false)


# --------------------------------------------------------------------------
#  Abschicken
# --------------------------------------------------------------------------

## Schickt die gesammelte Zeile ans Sheet und wartet auf die Antwort.
## Gibt true zurueck, wenn sie angekommen ist.
func submit() -> bool:
	if _uploading:
		return false
	_uploading = true
	_row["timestamp_end"] = Time.get_datetime_string_from_system(true)

	var http := HTTPRequest.new()
	# Apps Script antwortet auf einen erfolgreichen POST mit einem 302-Redirect.
	# Godot wuerde dem Redirect wieder als POST folgen -> Google lehnt mit 400 ab.
	# Also: nicht folgen, den 302 selbst als Erfolg werten.
	http.max_redirects = 0
	# Ohne Timeout haengt ein Upload ohne Internet ewig — und mit ihm der
	# Fragebogen, der auf die Bestaetigung wartet.
	http.timeout = 15.0
	add_child(http)

	# Content-Type text/plain vermeidet einen CORS-Preflight im HTML5-Export
	# (Apps Script setzt keine CORS-Header fuer OPTIONS).
	var err := http.request(
		SHEET_URL,
		["Content-Type: text/plain"],
		HTTPClient.METHOD_POST,
		JSON.stringify(_row)
	)
	if err != OK:
		push_error("Upload konnte nicht gestartet werden: " + str(err))
		http.queue_free()
		_uploading = false
		return false

	var response: Array = await http.request_completed
	var code: int = response[1]
	var body: String = (response[3] as PackedByteArray).get_string_from_utf8()
	http.queue_free()
	_uploading = false

	var ok := code == 302 or (code == 200 and body.begins_with("OK"))
	if ok:
		print("=== Durchlauf %s gesendet (%d Spalten) ===" % [
			_row.get("run_id", "?"), _row.size()])
	else:
		push_warning("Upload fehlgeschlagen (HTTP %d): %s" % [code, body])
	return ok


# --------------------------------------------------------------------------
#  Hilfsfunktionen
# --------------------------------------------------------------------------

## Rundet Sekundenwerte auf 2 Nachkommastellen — sonst wird die Tabelle unlesbar.
func _round2(value: float) -> float:
	return snappedf(value, 0.01)


## Wartet, bis ein laufender Upload durch ist. Vor get_tree().quit() aufrufen.
func await_pending_uploads(timeout_s := 15.0) -> void:
	var waited := 0.0
	while _uploading and waited < timeout_s:
		await get_tree().create_timer(0.05).timeout
		waited += 0.05


func _quit_when_upload_done() -> void:
	if _quitting:
		return
	_quitting = true
	await await_pending_uploads()
	get_tree().quit()
