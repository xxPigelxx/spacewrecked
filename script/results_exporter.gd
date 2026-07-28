extends Node
## ResultsExporter (Autoload) — Datenerhebung der Studie.
##
## Sammelt alles, was waehrend eines Durchlaufs anfaellt, in EINER Zeile
## und schickt sie genau einmal ab: wenn der Post-Fragebogen abgeschickt wird.
##
## Reihenfolge egal — Fragebogen, Spielende und Manual-Zeiten koennen in
## beliebiger Folge eintreffen, sie landen alle im selben Dictionary.

const SHEET_URL := "https://script.google.com/macros/s/AKfycbxcDLo86UI7y4sMGBlWF7Yi14kRsgg0IvaS9zZYo0vtrKvRathwdnkuXtjmQmZGs7zuMg/exec"

## Die Zeile, die am Ende ins Blatt "Runs" geht. Wird ueber den ganzen
## Durchlauf gefuellt.
var _row: Dictionary = {}
## Zweite Zeile, Blatt "ManualTimes": die Lesezeiten pro Handbuch-Tab. Getrennt,
## weil sonst jeder Tab eine eigene Spalte in der ohnehin breiten Run-Zeile waere.
var _manual: Dictionary = {}
var _uploading := false
var _quitting := false
## Ist die Run-Zeile schon durch? Verhindert Dubletten beim zweiten Sendeversuch.
var _row_sent := false


func _ready() -> void:
	reset()
	GameState.run_finished.connect(_on_run_finished)
	# Fenster-X soll nicht mitten im Upload beenden.
	get_tree().set_auto_accept_quit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_when_upload_done()


## Setzt beide Zeilen zurueck. Beim Start und vor einem neuen Durchlauf aufrufen.
func reset() -> void:
	_row = {"type": "run"}
	_row["timestamp_start"] = Time.get_datetime_string_from_system(true)
	_manual = {"type": "manual"}
	_uploading = false
	_row_sent = false


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
		_manual["manual_time_%s_s" % tab_name] = _round2(page_times[tab_name])


## Spielende: Kennzahlen des Durchlaufs uebernehmen.
func _on_run_finished(results: Dictionary) -> void:
	_row["run_id"] = results.get("run_id", "")
	_row["participant_id"] = results.get("participant_id", "")
	_row["dyslexia_enabled"] = results.get("dyslexia_enabled", false)
	# Ohne diese Spalte ist dyslexia_enabled=false nicht deutbar: Kontrollgruppe
	# oder betroffene Person, bei der die Simulation abgeschaltet wurde?
	_row["has_dyslexia"] = results.get("has_dyslexia", false)
	_row["stress_from_health"] = results.get("stress_from_health", false)
	_row["journey_limit_s"] = _round2(results.get("journey_limit", 0.0))
	_row["journey_time_s"] = _round2(results.get("journey_time", 0.0))
	_row["total_play_time_s"] = _round2(results.get("total_play_time", 0.0))
	_row["malfunctions_solved"] = results.get("malfunctions_solved", 0)
	_row["died_early"] = results.get("died_early", false)


# --------------------------------------------------------------------------
#  Abschicken
# --------------------------------------------------------------------------

## Schickt den Durchlauf ans Sheet: die Run-Zeile und, falls das Handbuch
## geoeffnet wurde, die Lesezeiten als zweite Zeile. Wartet auf beide Antworten
## und gibt true zurueck, wenn alles angekommen ist.
func submit() -> bool:
	if _uploading:
		return false
	_uploading = true
	_row["timestamp_end"] = Time.get_datetime_string_from_system(true)

	# Nach einem Fehlschlag darf der Nochmal-senden-Button nur nachholen, was
	# fehlt — sonst steht der Lauf zweimal im Blatt.
	if not _row_sent:
		_row_sent = await _send(_row)
	var ok := _row_sent

	# Verknuepfung zum Lauf. Erst hier gesetzt, damit die Reihenfolge egal ist,
	# in der Exporter und ManualPage auf run_finished reagieren.
	if ok and _manual.size() > 1:
		_manual["run_id"] = _row.get("run_id", "")
		_manual["participant_id"] = _row.get("participant_id", "")
		ok = await _send(_manual)

	_uploading = false
	if ok:
		print("=== Durchlauf %s gesendet (%d Spalten) ===" % [
			_row.get("run_id", "?"), _row.size()])
	return ok


## Schickt ein Dictionary als eine Zeile ans Sheet und wartet auf die Antwort.
func _send(data: Dictionary) -> bool:
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
		JSON.stringify(data)
	)
	if err != OK:
		push_error("Upload konnte nicht gestartet werden: " + str(err))
		http.queue_free()
		return false

	var response: Array = await http.request_completed
	var code: int = response[1]
	var body: String = (response[3] as PackedByteArray).get_string_from_utf8()
	http.queue_free()

	var ok := code == 302 or (code == 200 and body.begins_with("OK"))
	if not ok:
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
