# DyslexiaManager.gd — Autoload, Name: DyslexiaManager
extends Node

signal stress_changed(val: float)

## Stress 0–100: verstärkt alle per-Label eingestellten Effekte.
## Beeinflusst NICHT das Verschwinden — das ist global_vanish.
var stress: float = 0.0:
	set(v):
		stress = clampf(v, 0.0, 100.0)
		stress_changed.emit(stress)

## Globales Verschwinden 0–100: lässt Wörter bei ALLEN Labels verschwinden.
## Unabhängig von stress und den per-Label Einstellungen.
var global_vanish: float = 0.0:
	set(v):
		global_vanish = clampf(v, 0.0, 100.0)
		stress_changed.emit(stress)

## true = alle Effekte aus, reiner Text.
var accessibility: bool = false:
	set(v):
		accessibility = v
		stress_changed.emit(stress)

var _labels: Array = []
var _rng := RandomNumberGenerator.new()  # reuse — no GC pressure

## Farben der Effekte — frei einstellbar
var color_swap       := Color("#8b0000")
var color_scramble   := Color("#4a0e8f")
var color_transpose  := Color("#005f5f")
var color_pulse      := Color("#ffffff88")

## Orientierungsbereich ±θ der Buchstaben-Rotation (Grad), wie im
## Corballis-Lesexperiment: jeder Buchstabe bekommt einen zufälligen
## Winkel innerhalb ±θ. Studienstufen: 20, 40, 60, 90, 120, 180.
var rotate_deg: float = 60.0

const SWAP_PAIRS: Dictionary = {
	"b": "d", "d": "b",
	"p": "q", "q": "p",
	"n": "u", "u": "n",
	"m": "w", "w": "m",
	"6": "9", "9": "6",
	"2": "5", "5": "2",
}

func register(lbl: RichTextLabel) -> void:
	if lbl not in _labels:
		_labels.append(lbl)

func unregister(lbl: RichTextLabel) -> void:
	_labels.erase(lbl)

func refresh_all() -> void:
	stress_changed.emit(stress)

## Verarbeitet Text mit den gegebenen Effekten.
##
## stress    → multipliziert swap, drift, size, river, mirror
## global_vanish → wird ZUSÄTZLICH zu vanish_pct angewendet
##
## vanish_pct: per-Label Einstellung (0–100)
## swap_pct, drift_amp, etc.: per-Label Einstellungen, werden durch stress verstärkt
func process_text(
	raw: String,
	rng_seed: int,
	vanish_pct: float,
	swap_pct: float,
	drift_amp: float,
	drift_freq: float,
	size_var: float,
	river_gap: float,
	mirror_pct: float,
	scramble_pct: float = 0.0,
	crowd_pct: float = 0.0,
	transpose_pct: float = 0.0,
	shake_amp: float = 0.0,
	tornado_radius: float = 0.0,
	tornado_freq: float = 1.0,
	pulse_freq: float = 0.0,
	rotate_pct: float = 0.0
) -> String:
	if accessibility or raw.is_empty():
		return raw

	# stress boost: 0% stress = 1.0x, 100% stress = 2.0x
	var boost: float = 1.0 + (stress / 100.0)

	var rng := _rng
	rng.seed = rng_seed

	# BBCode aus dem Rohtext entfernen damit generierte Tags nicht verschachteln
	var clean_raw := _strip_bbcode(raw)
	var words := clean_raw.split(" ", false)
	var out: PackedStringArray = []

	for i in words.size():
		var w: String = words[i]

		# Verschwinden = max(per-Label, global_vanish) — stress beeinflusst das NICHT
		var v: float = clampf(maxf(vanish_pct, global_vanish) / 100.0, 0.0, 1.0)
		if rng.randf() < v:
			out.append("[color=#00000000]%s[/color]" % " ".repeat(w.length()))
			continue

		# Spiegeln — Satzzeichen am Ende bleiben stehen
		var mp: float = clampf((mirror_pct / 100.0) * boost, 0.0, 1.0)
		if rng.randf() < mp:
			w = _mirror_word(w)

		# Buchstaben tauschen — durch stress verstärkt
		var sp: float = clampf((swap_pct / 100.0) * boost, 0.0, 1.0)
		if sp > 0.0:
			w = _swap_letters(w, sp, rng)

		# Größen-Variation — durch stress verstärkt
		var sv: float = size_var * boost
		if sv > 0.5:
			var delta: int = int(rng.randf_range(-sv, sv))
			var sz: int = clampi(15 + delta, 8, 40)
			w = "[font_size=%d]%s[/font_size]" % [sz, w]

		# Buchstaben-Scramble (Wortmitte mischen) — durch stress verstärkt
		var sc: float = clampf((scramble_pct / 100.0) * boost, 0.0, 1.0)
		if sc > 0.0:
			w = _scramble_middle(w, sc, rng)

		# Silben-Transposition — durch stress verstärkt
		var tp: float = clampf((transpose_pct / 100.0) * boost, 0.0, 1.0)
		if rng.randf() < tp and w.length() >= 4:
			w = _transpose_syllable(w, rng)

		# Visuelles Crowding (Buchstaben zusammenrücken) — durch stress verstärkt
		var cp: float = clampf((crowd_pct / 100.0) * boost, 0.0, 1.0)
		if cp > 0.0:
			w = _apply_crowding(w, cp, rng)

		# Buchstaben-Rotation — durch stress verstärkt.
		# Welche Buchstaben sich drehen entscheidet der RichTextRotate-Effekt
		# deterministisch aus dem seed (siehe RichTextRotate.gd).
		var rp: float = clampf((rotate_pct / 100.0) * boost, 0.0, 1.0)
		if rp > 0.0:
			w = "[rot pct=%.2f deg=%.0f seed=%d]%s[/rot]" % [rp, rotate_deg, rng.randi_range(0, 999999), w]

		# Drift / Welle — durch stress verstärkt
		var da: float = drift_amp * boost
		if da > 0.5:
			var phase: float = fmod(float(i) * 0.41, 1.0)
			w = "[wave amp=%.1f freq=%.2f]%s[/wave]" % [da, drift_freq + phase, w]

		# Shake — durch stress verstärkt
		var sa: float = shake_amp * boost
		if sa > 0.5:
			w = "[shake rate=20 level=%.1f]%s[/shake]" % [sa, w]

		# Tornado — durch stress verstärkt
		var torn_r: float = tornado_radius * boost
		if torn_r > 0.5:
			w = "[tornado radius=%.1f freq=%.2f]%s[/tornado]" % [torn_r, tornado_freq, w]

		# Pulse — durch stress verstärkt
		var pf: float = pulse_freq * boost
		if pf > 0.1:
			w = "[pulse freq=%.2f color=%s]%s[/pulse]" % [pf, color_pulse.to_html(), w]

		out.append(w)

	# River Spacing — durch stress verstärkt
	var rs: float = river_gap * boost
	if rs > 0.5:
		var parts: PackedStringArray = []
		for i in out.size():
			parts.append(out[i])
			if i < out.size() - 1:
				var extra: int = int(rng.randf() * rs)
				if extra > 0:
					parts.append(" ".repeat(extra))
		return "".join(parts)

	return " ".join(out)


## Effektive Stärke (0–1) des Fehlende-Teile-Shaders (glyph_missing.gdshader).
## Kein BBCode-Effekt — DyslexiaLabel setzt damit sein ShaderMaterial.
## Stress-verstärkt wie die anderen Effekte, gedeckelt bei 0.9 damit
## Buchstaben nie komplett verschwinden.
func effective_missing(missing_pct: float) -> float:
	if accessibility:
		return 0.0
	var boost: float = 1.0 + (stress / 100.0)
	return clampf((missing_pct / 100.0) * boost, 0.0, 0.9)


func _swap_letters(word: String, chance: float, rng: RandomNumberGenerator) -> String:
	var result := ""
	for i in word.length():
		var ch: String = word[i]
		var lo: String = ch.to_lower()
		if lo in SWAP_PAIRS and rng.randf() < chance:
			var swapped: String = SWAP_PAIRS[lo]
			if ch == ch.to_upper() and ch != ch.to_lower():
				swapped = swapped.to_upper()
			result += "[color=%s]%s[/color]" % [color_swap.to_html(), swapped]
		else:
			result += ch
	return result


## Spiegelt ein Wort, lässt Satzzeichen (.,!?-:;) am Anfang/Ende in Ruhe.
func _mirror_word(word: String) -> String:
	const PUNCT := ".,-!?:;…„“"
	var start := 0
	var end := word.length() - 1
	while start < word.length() and PUNCT.contains(word[start]):
		start += 1
	while end >= 0 and PUNCT.contains(word[end]):
		end -= 1
	if end <= start:
		return word
	var prefix := word.substr(0, start)
	var suffix := word.substr(end + 1)
	var middle := word.substr(start, end - start + 1)
	return prefix + middle.reverse() + suffix


## Mitte des Wortes zufällig durchmischen, Anfang+Ende bleiben.
func _scramble_middle(word: String, chance: float, rng: RandomNumberGenerator) -> String:
	if word.length() < 4 or rng.randf() >= chance:
		return word
	var first := word[0]
	var last  := word[word.length() - 1]
	var middle_chars: Array = []
	for i in range(1, word.length() - 1):
		middle_chars.append(word[i])
	for i in range(middle_chars.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = middle_chars[i]
		middle_chars[i] = middle_chars[j]
		middle_chars[j] = tmp
	var scrambled := first + "".join(middle_chars) + last
	return "[color=%s]%s[/color]" % [color_scramble.to_html(), scrambled]


## Verschiebt zwei Zeichenblöcke (Pseudo-Silben) im Wort.
func _transpose_syllable(word: String, rng: RandomNumberGenerator) -> String:
	var n := word.length()
	var cut: int = rng.randi_range(1, n - 2)
	var part_a := word.substr(0, cut)
	var part_b := word.substr(cut)
	return "[color=%s]%s%s[/color]" % [color_transpose.to_html(), part_b, part_a]


## Visuelles Crowding: negativer Buchstabenabstand via font_spacing.
func _apply_crowding(word: String, chance: float, rng: RandomNumberGenerator) -> String:
	if rng.randf() >= chance * 0.6:
		return word
	var spacing: int = rng.randi_range(-4, -1)
	return "[font_size=15][outline_size=0]%s[/outline_size][/font_size]" % word if spacing == 0 else \
		"[p spacing_character=%d]%s[/p]" % [spacing, word]


## Entfernt BBCode-Tags aus einem String.
func _strip_bbcode(text: String) -> String:
	var result := ""
	var inside := false
	for i in text.length():
		var c := text[i]
		if c == "[":
			inside = true
		elif c == "]":
			inside = false
		elif not inside:
			result += c
	return result
