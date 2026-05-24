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
@export var rng_seed: int = 1000

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
var _s: int = 1000

func _ready() -> void:
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_theme_color_override("default_color", Color.BLACK)
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
func apply_effects(v: float, sw: float, da: float, df: float, sv: float, rs: float, mp: float, s: int) -> void:
	if override_page or not _ready_done:
		return
	if _source_text.is_empty():
		_source_text = text
	_v = v; _sw = sw; _da = da; _df = df; _sv = sv; _rs = rs; _mp = mp; _s = s
	_render()

func refresh() -> void:
	if override_page:
		_render_own()
	else:
		_render()

func _render() -> void:
	if _source_text.is_empty():
		return
	text = DyslexiaManager.process_text(_source_text, _s, _v, _sw, _da, _df, _sv, _rs, _mp)

func _render_own() -> void:
	if _source_text.is_empty():
		_source_text = text
	text = DyslexiaManager.process_text(_source_text, rng_seed,
		vanish_percent, swap_percent, drift_amplitude, drift_frequency,
		size_variation, river_spacing, mirror_percent)

func _on_stress_changed(_val: float) -> void:
	# Immer neu rendern — stress wird in process_text automatisch einbezogen
	if override_page:
		_render_own()
	else:
		_render()
