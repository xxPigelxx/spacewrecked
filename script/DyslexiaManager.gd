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
	mirror_pct: float
) -> String:
	if accessibility or raw.is_empty():
		return raw

	# stress boost: 0% stress = 1.0x, 100% stress = 2.0x
	var boost: float = 1.0 + (stress / 100.0)

	var rng := _rng
	rng.seed = rng_seed

	var words := raw.split(" ", false)
	var out: PackedStringArray = []

	for i in words.size():
		var w: String = words[i]

		# Verschwinden = max(per-Label, global_vanish) — stress beeinflusst das NICHT
		var v: float = clampf(maxf(vanish_pct, global_vanish) / 100.0, 0.0, 1.0)
		if rng.randf() < v:
			out.append("[color=#00000000]%s[/color]" % " ".repeat(w.length()))
			continue

		# Spiegeln — durch stress verstärkt
		var mp: float = clampf((mirror_pct / 100.0) * boost, 0.0, 1.0)
		if rng.randf() < mp:
			w = w.reverse()

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

		# Drift / Welle — durch stress verstärkt
		var da: float = drift_amp * boost
		if da > 0.5:
			var phase: float = fmod(float(i) * 0.41, 1.0)
			w = "[wave amp=%.1f freq=%.2f]%s[/wave]" % [da, drift_freq + phase, w]

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


func _swap_letters(word: String, chance: float, rng: RandomNumberGenerator) -> String:
	var result := ""
	for i in word.length():
		var ch: String = word[i]
		var lo: String = ch.to_lower()
		if lo in SWAP_PAIRS and rng.randf() < chance:
			var swapped: String = SWAP_PAIRS[lo]
			if ch == ch.to_upper() and ch != ch.to_lower():
				swapped = swapped.to_upper()
			result += "[color=#8b0000]%s[/color]" % swapped
		else:
			result += ch
	return result
