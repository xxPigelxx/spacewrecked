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
@export_range(0, 100, 1, "suffix:%") var rotate_percent: float = 0.0
@export_range(0, 100, 1, "suffix:%") var char_size_percent: float = 0.0
@export_range(0, 100, 1, "suffix:%") var missing_percent: float = 0.0
@export var rng_seed: int = 1000


@export var text_color: Color = Color.BLACK

var _source_text: String = ""
var _ready_done: bool = false
## Zuletzt gesetzter, fertig verarbeiteter String. Nur bei Aenderung wird .text
## neu zugewiesen — sonst wuerde RichTextLabel neu parsen und die zeitbasierten
## Effekte (wave/shake/tornado/pulse) auf Phase 0 zuruecksetzen (sichtbares Springen).
var _last_rendered: String = ""

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
var _rp: float = 0.0
var _cs: float = 0.0
var _mi: float = 0.0
var _s: int = 1000

const MISSING_SHADER := preload("res://shader/glyph_missing.gdshader")
const CROWD_EFFECT := preload("res://script/RichTextCrowd.gd")
const CHAR_SIZE_EFFECT := preload("res://script/RichTextCharSizeVar.gd")
const VANISH_EFFECT := preload("res://script/RichTextVanishPulse.gd")
var _missing_mat: ShaderMaterial
## Schrift OHNE Zusatzabstand. Muss vor dem ersten Theme-Override gemerkt werden,
## sonst wuerde get_theme_font() spaeter die FontVariation zurueckgeben und sich
## bei jedem Render selbst verschachteln.
var _base_font: Font = null
var _spacing_font: FontVariation = null

func _ready() -> void:
	bbcode_enabled = true
	# Reine Anzeige — darf niemals Klicks abfangen. Godot gibt der GUI Vorrang vor
	# dem Physics-Picking: ein Label mit MOUSE_FILTER_STOP verschluckt den Klick,
	# bevor die Area2D darunter ihr input_event bekommt. Zusammen mit fit_content
	# waechst so ein Label unter Stress ueber die halbe Spalte und macht die
	# Kabelstecker/Flaschen ungreifbar.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	install_effect(RichTextRotate.new())
	install_effect(CROWD_EFFECT.new())
	install_effect(CHAR_SIZE_EFFECT.new())
	install_effect(VANISH_EFFECT.new())
	fit_content = true
	scroll_active = false
	add_theme_color_override("default_color", text_color)
	_base_font = get_theme_font("normal_font")
	_source_text = text
	_ready_done = true
	DyslexiaManager.stress_changed.connect(_on_stress_changed)
	if override_page:
		_render_own()

func _exit_tree() -> void:
	if DyslexiaManager.stress_changed.is_connected(_on_stress_changed):
		DyslexiaManager.stress_changed.disconnect(_on_stress_changed)

## Von PageEffects aufgerufen — speichert Werte und rendert.
func apply_effects(v: float, sw: float, da: float, df: float, sv: float, rs: float, mp: float, s: int, sc: float = 0.0, cp: float = 0.0, tp: float = 0.0, sa: float = 0.0, tr: float = 0.0, tf: float = 1.0, pf: float = 0.0, rp: float = 0.0, mi: float = 0.0, cs: float = 0.0) -> void:
	if override_page or not _ready_done:
		return
	if _source_text.is_empty():
		_source_text = text
	_v = v; _sw = sw; _da = da; _df = df; _sv = sv; _rs = rs; _mp = mp; _s = s
	_sc = sc; _cp = cp; _tp = tp; _sa = sa; _tr = tr; _tf = tf; _pf = pf
	_rp = rp; _mi = mi; _cs = cs
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
	_set_rendered(DyslexiaManager.process_text(_source_text, _s, _v, _sw, _da, _df, _sv, _rs, _mp, _sc, _cp, _tp, _sa, _tr, _tf, _pf, _rp, _cs,
		get_theme_font_size("normal_font_size")))
	_update_rotation_spacing(_rp)
	_update_missing_shader(_mi, _s)

func _render_own() -> void:
	if _source_text.is_empty():
		_source_text = text
	_set_rendered(DyslexiaManager.process_text(_source_text, rng_seed,
		vanish_percent, swap_percent, drift_amplitude, drift_frequency,
		size_variation, river_spacing, mirror_percent,
		scramble_percent, crowd_percent, transpose_percent,
		shake_amplitude, tornado_radius, tornado_frequency, pulse_frequency,
		rotate_percent, char_size_percent, get_theme_font_size("normal_font_size")))
	_update_rotation_spacing(rotate_percent)
	_update_missing_shader(missing_percent, rng_seed)

## Weist .text nur zu, wenn sich der verarbeitete String geaendert hat — sonst
## bliebe die laufende Animation erhalten (kein Neu-Parsen, kein Zuruecksetzen).
func _set_rendered(rendered: String) -> void:
	if rendered == _last_rendered:
		return
	_last_rendered = rendered
	text = rendered

## Gibt jeder Glyphe zusaetzlichen Vorschub, solange Rotation aktiv ist — sonst
## ueberlappen gedrehte Buchstaben ihre Nachbarn und die Leseschwierigkeit kaeme
## aus der Ueberlappung statt aus der Orientierung.
##
## Laeuft ueber einen Theme-Override auf dem ganzen Label, nicht per BBCode: der
## Abstand soll fuer ALLE Buchstaben gleich sein, auch die ungedrehten. Sonst
## haetten gedrehte und ungedrehte Buchstaben unterschiedliche Laufweiten — der
## Abstand wuerde mit der Rotation kovariieren und waere ein zweiter Störfaktor.
func _update_rotation_spacing(rotate_pct: float) -> void:
	var fs := get_theme_font_size("normal_font_size")
	var extra := DyslexiaManager.rotation_glyph_spacing(_base_font, fs, rotate_pct)
	if extra <= 0:
		if _spacing_font != null:
			remove_theme_font_override("normal_font")
			_spacing_font = null
		return
	if _spacing_font == null:
		_spacing_font = FontVariation.new()
		_spacing_font.base_font = _base_font
	elif _spacing_font.spacing_glyph == extra:
		return  # unveraendert — ein erneutes Override wuerde nur Neu-Layout kosten
	_spacing_font.spacing_glyph = extra
	add_theme_font_override("normal_font", _spacing_font)


## Fehlende-Teile-Effekt läuft als ShaderMaterial über das ganze Label,
## nicht als BBCode — deshalb hier statt in process_text.
func _update_missing_shader(pct: float, seed_val: int) -> void:
	var amount := DyslexiaManager.effective_missing(pct)
	if amount <= 0.0:
		if material != null and material == _missing_mat:
			material = null
		return
	if _missing_mat == null:
		_missing_mat = ShaderMaterial.new()
		_missing_mat.shader = MISSING_SHADER
	_missing_mat.set_shader_parameter("missing_amount", amount)
	_missing_mat.set_shader_parameter("pattern_seed", float(seed_val % 997))
	# Zellgröße an die Schriftgröße koppeln → pro Buchstabe fehlt EIN
	# zusammenhängendes Stück, egal wie groß das Label rendert.
	var fs := get_theme_font_size("normal_font_size")
	_missing_mat.set_shader_parameter("cell_size", maxf(float(fs) * 0.8, 4.0))
	material = _missing_mat

func _on_stress_changed(_val: float) -> void:
	# Immer neu rendern — stress wird in process_text automatisch einbezogen
	if override_page:
		_render_own()
	else:
		_render()
