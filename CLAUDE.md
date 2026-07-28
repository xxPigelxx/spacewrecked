# Space Wrecked

Serious Game zur Sensibilisierung fuer Dyslexie (Bachelorarbeit, HAW Hamburg,
Medieninformatik). Godot 4, 2D top-down. Distribution als HTML5 ueber itch.io.
Abgabe: 21.08.2026.

Kernthese des Projekts: Dyslexie ist ein Problem kognitiver Last und des
Decodierens, **keine visuelle Verzerrung**. Effekte im Spiel duerfen nie
suggerieren, dass sich Buchstaben "bewegen" oder "verschwimmen".

## Code-Stil: einfach vor clever

Das hier ist eine Bachelorarbeit, kein Produktionssystem. Der Code muss von
einer Person lesbar sein, die ihn in sechs Monaten wieder aufmacht.

- Direkte, offensichtliche Loesungen. Kein Muster einbauen, das erst ab
  mehreren Anwendungsfaellen Sinn ergibt.
- Keine Abstraktionsschicht "fuer spaeter". Es gibt kein spaeter.
- Keine Retry-Logik, Queues oder State-Machines, wo ein einzelner Aufruf reicht.
- Lieber drei Zeilen, die man sofort versteht, als eine elegante.
- Wenn eine Funktion laenger als ein Bildschirm wird, ist meistens etwas
  zu viel drin.
- Kommentare erklaeren das **Warum**, nicht das Was. Was der Code tut, steht
  im Code.

Vor einem Umbau: erst lesen, dann Varianten vorschlagen. Nicht direkt
umschreiben.

## Konventionen

- GDScript mit statischen Typen (`var x: int`, `-> void`), snake_case
- Kommentare auf Deutsch, ohne Umlaute (ae/oe/ue/ss)
- Docstrings mit `##` ueber der Deklaration
- Autoloads: `GameState`, `ResultsExporter`, `DyslexiaManager`, `SceneSwitcher`
- Szenen (`.tscn`) und UI-Aufbau mache ich selbst im Editor — bitte nur
  `.gd`-Dateien anfassen

## Datenerhebung der Studie

Eine Zeile pro Durchlauf. Der `ResultsExporter` sammelt alles im Dictionary
`_row` und sendet **genau einmal** am Ende, ausgeloest vom Post-Fragebogen.
Vorher verlaesst nichts das Spiel.

- `store(key, value)` — Einzelwert, `key` wird 1:1 zum Spaltennamen
- `store_answers(block, answers)` — `block` ist "pre" oder "post",
  haengt das Suffix selbst an (`q01` -> `q01_pre`)
- `deliver_manual_times(page_times)` — Lesezeiten pro Handbuch-Tab
- `submit()` — der einzige Sende-Punkt, gibt `bool` zurueck

Ablauf: Demografie + 5 Items + 6 TLX-Slider (Baseline auf einer intakten
Handbuchseite) -> Spiel -> dieselben 5 Items + 6 TLX-Slider + Freitext ->
`submit()`.

### Nicht anfassen ohne Grund

- `max_redirects = 0` im `HTTPRequest`. Apps Script antwortet auf einen
  erfolgreichen POST mit 302. Ohne diese Zeile folgt Godot dem Redirect
  erneut als POST, und Google lehnt mit 400 ab. Der 302 gilt als Erfolg.
- `Content-Type: text/plain` statt `application/json`. Vermeidet den
  CORS-Preflight im HTML5-Export — Apps Script setzt keine CORS-Header
  fuer OPTIONS.
- `_timed_tab` in der Manual-Zeitmessung. Merkt sich den Tab beim Start des
  Timers. Ohne das wird die Lesezeit beim Blaettern der falschen Seite
  gutgeschrieben, weil `current_tab` beim Stoppen schon der neue ist.

Backend ist ein Google Apps Script (`appendByHeader`, Blatt "Runs"). Legt
fehlende Spalten automatisch an. Wird aktuell nicht geaendert.

## Bekannte Baustellen

- `GameState.unlock_door()` feuert `door_locked` statt `door_unlocked`
- `participant_has_dyslexia` wird doppelt erhoben (Startup-Popup und
  Fragebogen-Item) — eine Quelle muss weg
- Offen: TLX-Slider-Szene, Text der intakten Baseline-Handbuchseite

## Umgebungs-Eigenheiten

- Vorbestehende Fehler in `door.gd`, `camera_controller.gd`, `socket.gd`
  ignorieren — nicht durch neue Aenderungen verursacht
- `validate_script` meldet bei Skripten mit Autoload-Referenzen falsche
  "cannot be instantiated"-Fehler. Kein echtes Problem.
- Nach jeder Aenderung am Apps Script: Bereitstellen -> Bereitstellungen
  verwalten -> **Neue Version**. Nur speichern reicht nicht.
