class_name DyslexiaLabel
extends RichTextLabel

@export_group("Effekte Override")
## true = benutze die Werte hier unten statt die von PageEffects.
@export var override_page: bool = false
@export_range(0, 100, 1, "suffix:%") var vanish_percent: float = 0.0
@export_range(0, 100, 1, "suffix:%") var swap_percent: float = 0.0
@export_range(0.0, 20.0, 0.5) var drift_amplitude: float = 0.0
@export_range(0.1, 5.0, 0.1) var drift_frequency: float = 1.0
@export_range(0.0, 10.0, 0.5) var size_variation: float = 0.0
@export_range(0.0, 20.0, 1.0) var river_spacing: float = 0.0
@export_range(0, 100, 1, "suffix:%") var mirror_percent: float = 0.0
@export_range(0, 100, 1, "suffix:%") var scramble_percent: float = 0.0
@export_range(0, 100, 1, "suffix:%") var crowd_percent: float = 0.0
@export_range(0, 100, 1, "suffix:%") var transpose_percent: float = 0.0
@export_range(0.0, 20.0, 0.5) var shake_amplitude: float = 0.0
@export_range(0.0, 20.0, 0.5) var tornado_radius: float = 0.0
@export_range(0.1, 5.0, 0.1) var tornado_frequency: float = 1.0
@export_range(0.0, 5.0, 0.1) var pulse_frequency: float = 0.0
@export var rng_seed: int = 1000


@export var text_color: Color = Color.BLACK

var _source_text: String = ""
var _ready_done: bool = false

# Gespeicherte Werte von PageEffects — damit Stress-Änderung neu rendern kann
var _v: float = 0.0
var _sw: float = 0.0
var _da: float = 0.0
var _df: float = 1.0
var _sv: float = 0.0
var _rs: float = 0.0
var _mp: float = 0.0
var _sc: float = 0.0
var _cp: float = 0.0
var _tp: float = 0.0
var _sa: float = 0.0
var _tr: float = 0.0
var _tf: float = 1.0
var _pf: float = 0.0
var _s: int = 1000

func _ready() -> void:
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	add_theme_color_override("default_color", text_color)
	_source_text = text
	_ready_done = true
	DyslexiaManager.register(self)
	DyslexiaManager.stress_changed.connect(_on_stress_changed)
	if override_page:
		_render_own()

func _exit_tree() -> void:
	DyslexiaManager.unregister(self)
	if DyslexiaManager.stress_changed.is_connected(_on_stress_changed):
		DyslexiaManager.stress_changed.disconnect(_on_stress_changed)

## Von PageEffects aufgerufen — speichert Werte und rendert.
func apply_effects(v: float, sw: float, da: float, df: float, sv: float, rs: float, mp: float, s: int, sc: float = 0.0, cp: float = 0.0, tp: float = 0.0, sa: float = 0.0, tr: float = 0.0, tf: float = 1.0, pf: float = 0.0) -> void:
	if override_page or not _ready_done:
		return
	if _source_text.is_empty():
		_source_text = text
	_v = v; _sw = sw; _da = da; _df = df; _sv = sv; _rs = rs; _mp = mp; _s = s
	_sc = sc; _cp = cp; _tp = tp; _sa = sa; _tr = tr; _tf = tf; _pf = pf
	_render()

func refresh() -> void:
	if override_page:
		_render_own()
	else:
		_render()

## Neuen Quelltext setzen (per Skript). Aktualisiert die gespeicherte Kopie
## und rendert neu — sonst würde der alte Text beim nächsten Render zurückkommen.
func set_source_text(new_text: String) -> void:
	_source_text = new_text
	if not _ready_done:
		text = new_text
		return
	refresh()

func _render() -> void:
	if _source_text.is_empty():
		return
	text = DyslexiaManager.process_text(_source_text, _s, _v, _sw, _da, _df, _sv, _rs, _mp, _sc, _cp, _tp, _sa, _tr, _tf, _pf)

func _render_own() -> void:
	if _source_text.is_empty():
		_source_text = text
	text = DyslexiaManager.process_text(_source_text, rng_seed,
		vanish_percent, swap_percent, drift_amplitude, drift_frequency,
		size_variation, river_spacing, mirror_percent,
		scramble_percent, crowd_percent, transpose_percent,
		shake_amplitude, tornado_radius, tornado_frequency, pulse_frequency)

func _on_stress_changed(_val: float) -> void:
	# Immer neu rendern — stress wird in process_text automatisch einbezogen
	if override_page:
		_render_own()
	else:
		_render()
