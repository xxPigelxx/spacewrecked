# DyslexiaManager.gd — Autoload, Name: DyslexiaManager
extends Node

signal stress_changed(val: float)

## Stress 0–100: verstärkt alle per-Label eingestellten Effekte.
var stress: float = 0.0:
	set(v):
		var nv := clampf(v, 0.0, 100.0)
		if nv == stress:
			return  # kein Re-Render bei unveraendertem Wert (spart Neu-Parsen)
		stress = nv
		stress_changed.emit(stress)

## true = alle Effekte aus, reiner Text.
var accessibility: bool = false:
	set(v):
		if v == accessibility:
			return
		accessibility = v
		stress_changed.emit(stress)

## true = manipulierte Woerter/Buchstaben werden farblich markiert (Swap,
## Scramble, Transposition). false = dieselben Verzerrungen wirken unmarkiert im
## Fliesstext. Schaltet NUR die Farbe, nicht WELCHE Zeichen getroffen werden —
## der RNG-Verbrauch bleibt gleich, damit "mit" und "ohne" Farbe A/B-vergleichbar
## sind. Test-Schalter fuer die Frage, ob die Markierung "zu eindeutig" macht.
var mark_effects: bool = false:
	set(v):	
		if v == mark_effects:
			return
		mark_effects = v
		stress_changed.emit(stress)

var _rng := RandomNumberGenerator.new()  # reuse — no GC pressure
var _font_rng := RandomNumberGenerator.new()  # eigener Strom fuer die Font-Wahl

## Farben der Effekte — frei einstellbar
var color_swap       := Color("#8b0000")
var color_scramble   := Color("#4a0e8f")
var color_transpose  := Color("#005f5f")
var color_pulse      := Color("#ffffff88")

## Font-pro-Wort-Effekt (Anti-WCAG: Konsistenz / WCAG 3.2 "Predictable").
## Simuliert Instabilitaet der Buchstaben-Identitaet (perzeptuelles Font-Tuning
## wird staendig zurueckgeworfen). Die STAERKE ist per-Label (font_percent, wie
## rotate_percent & Co.) — hier steht nur die gemeinsame Config:
## FONT_POOL[0] = Anker (Theme-Font Share Tech) und wird nie als Wrapper gesetzt;
## font_size_scale normalisiert die x-Hoehe pro Font (visuell in der Testszene
## feinjustieren) — 1.0 = keine Skalierung.
const FONT_POOL: Array[String] = [
	"res://resources/fonts/Share_Tech/ShareTech-Regular.ttf",              # 0 Anker
	"res://resources/fonts/Source_Sans_3/SourceSans3-VariableFont_wght.ttf",
	"res://resources/fonts/Nunito/Nunito-VariableFont_wght.ttf",
	"res://resources/fonts/PT_Serif/PTSerif-Regular.ttf",
	"res://resources/fonts/Bitter/Bitter-VariableFont_wght.ttf",
	"res://resources/fonts/Work_Sans/WorkSans-VariableFont_wght.ttf",
]
var font_size_scale: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

## Orientierungsbereich ±θ der Buchstaben-Rotation (Grad), wie im
## Corballis-Lesexperiment: jeder Buchstabe bekommt einen zufälligen
## Winkel innerhalb ±θ. Studienstufen: 20, 40, 60, 90, 120, 180.
var rotate_deg: float = 60.0

## true = gedrehte Buchstaben bekommen zusaetzlichen Vorschub, damit sie einander
## nicht ueberlappen. Wichtig fuer die Studienvalidität: ohne den Platz misst man
## nicht mehr den Orientierungsbereich θ, sondern die Überlappung (Crowding).
var rotate_spacing: bool = true:
	set(v):
		if v == rotate_spacing:
			return
		rotate_spacing = v
		stress_changed.emit(stress)

## Maximaler Buchstaben-Versatz beim Crowding in Pixeln (bei crowd_percent = 100
## und stress = 100). Der aeusserste Buchstabe eines Wortes wandert um bis zu
## len/2 * diesen Wert nach innen — 1.5 staucht ein 8-Zeichen-Wort um ~12 px.
var crowd_max_shift: float = 3.5

## Pulsierendes Verschwinden (siehe RichTextVanishPulse.gd).
## period: Laenge eines vollen Zyklus in Sekunden.
## hide/fade: Anteil des Zyklus, in dem das Wort ganz weg ist bzw. blendet.
## Default 6.0 / 0.18 / 0.12 → pro Zyklus ~1.1 s unsichtbar, ~1.4 s im Uebergang,
## der Rest lesbar. Bewusst deutlich langsamer als der [pulse]-Effekt: das Wort
## soll lange genug stehen, um es tatsaechlich lesen zu koennen.
var vanish_period: float = 6.0
var vanish_hide: float = 0.18
var vanish_fade: float = 0.12

## Bezugs-Schriftgroesse, falls ein Aufrufer keine eigene durchreicht.
const DEFAULT_FONT_SIZE := 18
## Kuerzeste Wortlaenge fuer Scramble/Transposition — darunter gibt es keine
## Wortmitte, die sich mischen liesse.
const MIN_SCRAMBLE_LEN := 4
## Unterhalb dieser Staerke lohnt sich kein Animations-Tag: der Effekt waere
## unsichtbar und wuerde den BBCode nur aufblaehen.
const ANIM_THRESHOLD := 0.5
## Pulse rechnet in Hz statt in Pixeln und braucht deshalb eine eigene Schwelle.
const PULSE_THRESHOLD := 0.1
## Phasenversatz pro Wort, damit die Welle nicht ueber die ganze Zeile synchron laeuft.
const WAVE_PHASE_STEP := 0.41
## Zittergeschwindigkeit des Shake-Tags.
const SHAKE_RATE := 20
## Grenzen der Groessen-Varianz.
const SIZE_MIN := 6
const SIZE_MAX := 68
## Deckel fuer den Fehlende-Teile-Shader: mehr als dieser Anteil der Tinte darf
## nie fehlen, egal wie hoch der Stress steigt. Darueber kippt ein Wort von
## muehsam nach unlesbar — und muehsam ist das, was gezeigt werden soll.
const MISSING_MAX := 0.5

const SWAP_PAIRS: Dictionary = {
	"b": "d", "d": "b",
	"p": "q", "q": "p",
	"n": "u", "u": "n",
	"m": "w", "w": "m",
	"6": "9", "9": "6",
	"2": "5", "5": "2",
}

## Regeln der lautbasierten Umschrift (_phoneticize). Reihenfolge zählt:
## Mehrzeichen-/Digraphen zuerst, dann Doppelkonsonanten, dann Einzellaute.
## Alle Regeln sind lauttreu (w=/v/, v=/f/, z=/ts/ …), damit das Wort durch
## Vorsprechen recoverbar bleibt.
const PHON_RULES: Array = [
	["chs", "x"], ["ph", "f"], ["qu", "kw"], ["ck", "k"],
	["äu", "oi"], ["eu", "oi"], ["ei", "ai"], ["ie", "i"],
	["tz", "ts"], ["ß", "s"],
	["mm", "m"], ["nn", "n"], ["ss", "s"], ["ll", "l"], ["tt", "t"],
	["ff", "f"], ["pp", "p"], ["rr", "r"], ["dd", "d"], ["bb", "b"], ["gg", "g"],
	["v", "f"], ["w", "v"], ["z", "ts"],
]

## Loest bei allen Labels ein Neu-Rendern aus. Die Labels haengen selbst am
## stress_changed-Signal — es braucht deshalb keine Registry auf dieser Seite.
func refresh_all() -> void:
	stress_changed.emit(stress)


## Stress-Verstaerker: 0 % Stress = 1.0x, 100 % Stress = 2.0x.
func _boost() -> float:
	return 1.0 + (stress / 100.0)


## Deterministische Font-Wahl fuer ein Wort. Liefert den Pool-Index; 0 = Anker
## (kein Wechsel). Eigener RNG-Seed pro Wort, unabhaengig von _rng.
func _pick_font(fseed: int, chance: float) -> int:
	_font_rng.seed = fseed
	if _font_rng.randf() >= chance:
		return 0
	return _font_rng.randi_range(1, FONT_POOL.size() - 1)


## Lautbasierte Umschrift eines Wortes (siehe PHON_RULES). Regelbasiert und damit
## deterministisch: dasselbe Wort wird immer gleich umgeschrieben, innerhalb einer
## Seite also konsistent (lesbar-lernbar). Grossschreibung des ersten Buchstabens
## bleibt erhalten, Satzzeichen laufen unveraendert durch.
func _phoneticize(word: String) -> String:
	if word.strip_edges().is_empty():
		return word
	var first := word[0]
	var had_upper := first != first.to_lower() and first == first.to_upper()
	var s := word.to_lower()
	# Wortanfang: st-/sp- werden gesprochen wie scht-/schp-.
	if s.begins_with("st"):
		s = "scht" + s.substr(2)
	elif s.begins_with("sp"):
		s = "schp" + s.substr(2)
	for rule in PHON_RULES:
		s = s.replace(rule[0], rule[1])
	if had_upper:
		s = s.substr(0, 1).to_upper() + s.substr(1)
	return s


## Prozentwert (0–100) als stress-verstaerkte Wahrscheinlichkeit (0.0–1.0).
func _pct(value: float, boost: float) -> float:
	return clampf((value / 100.0) * boost, 0.0, 1.0)

## Verarbeitet Text mit den gegebenen Effekten und liefert fertigen BBCode.
##
## stress verstaerkt alle Effekte, inklusive des Verschwindens.
##
## vanish_pct, swap_pct, drift_amp usw.: per-Label Einstellungen (0–100 bzw. Pixel)
## base_font_size: Bezugsgroesse der Groessen-Varianz. Die Labels reichen ihre
##   echte Theme-Schriftgroesse durch, damit die Varianz um die tatsaechliche
##   Groesse streut statt um einen fest verdrahteten Wert.
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
	rotate_pct: float = 0.0,
	char_size_pct: float = 0.0,
	font_pct: float = 0.0,
	phonetic_pct: float = 0.0,
	base_font_size: int = DEFAULT_FONT_SIZE
) -> String:
	if accessibility or raw.is_empty():
		return raw

	var boost := _boost()
	_rng.seed = rng_seed

	# BBCode aus dem Rohtext entfernen damit generierte Tags nicht verschachteln
	var clean_raw := _strip_bbcode(raw)
	var words := clean_raw.split(" ", false)
	var out: PackedStringArray = []

	for i in words.size():
		var w: String = words[i]

		# Lautbasierte Umschrift (phonologischer Effekt) — ganz am Anfang auf reinem
		# Text. Blockiert die Ganzwort-Erkennung und zwingt den Leser auf die
		# langsame, serielle Laut-für-Laut-Route: das Erleben des dyslektischen
		# Dekodierens (Snowling/Hulme), NICHT dessen Mechanismus.
		if phonetic_pct > 0.0 and _rng.randf() < _pct(phonetic_pct, boost):
			w = _phoneticize(w)

		# Sichtbare Zeichenzahl. Keine der Zeichen-Operationen unten aendert sie:
		# Spiegeln, Scramble und Transposition sind Permutationen, und Swap ersetzt
		# ein Zeichen durch genau eines. Sie steht damit hier schon fest und muss
		# spaeter nicht muehsam aus dem erzeugten BBCode zurueckgerechnet werden.
		var glyph_count: int = w.length()

		# Verschwinden — stress-verstaerkt: mehr Stress = mehr Woerter gleichzeitig weg.
		#
		# Hier wird NICHT ausgewuerfelt, WELCHE Woerter es trifft — nur der Anteil.
		# Die Auswahl faellt pro Zyklus im Effekt (RichTextVanishPulse), damit nicht
		# bis zum naechsten Re-Render immer dieselben Woerter blinken.
		var v := _pct(vanish_pct, boost)

		# ---- Zeichen-Ebene ----------------------------------------------------
		# Diese Effekte spiegeln/mischen/zerschneiden den String zeichenweise und
		# muessen deshalb auf REINEM Text laufen. Kaeme hier schon BBCode vor,
		# wuerden sie die Tags selbst mitmischen und als Klartext sichtbar machen.
		# Farbe wird gemerkt und erst unten als Wrapper gesetzt.
		var word_color := Color(0, 0, 0, 0)

		# Spiegeln — Satzzeichen am Ende bleiben stehen
		if _rng.randf() < _pct(mirror_pct, boost):
			w = _mirror_word(w)

		# Buchstaben-Scramble (Wortmitte mischen) — durch stress verstärkt
		var sc := _pct(scramble_pct, boost)
		if sc > 0.0 and glyph_count >= MIN_SCRAMBLE_LEN and _rng.randf() < sc:
			w = _scramble_middle(w, _rng)
			if mark_effects:
				word_color = color_scramble

		# Silben-Transposition — durch stress verstärkt
		if _rng.randf() < _pct(transpose_pct, boost) and glyph_count >= MIN_SCRAMBLE_LEN:
			w = _transpose_syllable(w, _rng)
			if mark_effects:
				word_color = color_transpose

		# Buchstaben tauschen — durch stress verstärkt.
		# LETZTE Zeichen-Operation: faerbt einzelne Buchstaben inline ein und
		# hinterlaesst damit BBCode, an dem Scramble/Transposition scheitern wuerden.
		var sp := _pct(swap_pct, boost)
		if sp > 0.0:
			w = _swap_letters(w, sp, _rng)

		# ---- Ab hier nur noch umschliessende Tags ------------------------------
		if word_color.a > 0.0:
			w = "[color=%s]%s[/color]" % [word_color.to_html(), w]

		# Font-Wechsel pro Wort (Anti-WCAG: Konsistenz) — durch stress verstärkt.
		# Waehlt deterministisch aus rng_seed + i einen Font aus dem Pool; Index 0
		# (Share Tech) ist der Anker und bleibt ohne Wrapper. Eigener Seed statt
		# _rng, damit das An/Aus-Schalten die RNG-Folge der anderen Effekte NICHT
		# verschiebt — "mit" und "ohne" Font-Wechsel bleiben so vergleichbar.
		if font_pct > 0.0:
			var fi := _pick_font(rng_seed + i, _pct(font_pct, boost))
			if fi > 0:
				var scale: float = font_size_scale[fi]
				if scale != 1.0:
					w = "[font=%s][font_size=%d]%s[/font_size][/font]" % [
						FONT_POOL[fi], int(round(base_font_size * scale)), w]
				else:
					w = "[font=%s]%s[/font]" % [FONT_POOL[fi], w]

		# Größen-Variation — durch stress verstärkt
		var sv: float = size_var * boost
		if sv > ANIM_THRESHOLD:
			var delta: int = int(_rng.randf_range(-sv, sv))
			var sz: int = clampi(base_font_size + delta, SIZE_MIN, SIZE_MAX)
			w = "[font_size=%d]%s[/font_size]" % [sz, w]

		# Zufaellige Groesse pro Buchstabe — durch stress verstärkt. Anders als die
		# Groessen-Variation darueber aendert das nur die Darstellung, nicht das
		# Layout; welcher Buchstabe wie klein wird, entscheidet der Effekt
		# deterministisch aus dem seed (siehe RichTextCharSizeVar.gd).
		var cs := _pct(char_size_pct, boost)
		if cs > 0.0:
			w = "[charsize amt=%.2f fs=%d seed=%d]%s[/charsize]" % [cs, base_font_size, _rng.randi_range(0, 999999), w]

		# Visuelles Crowding (Buchstaben zusammenrücken) — durch stress verstärkt
		var cp := _pct(crowd_pct, boost)
		if cp > 0.0:
			w = _apply_crowding(w, cp, _rng, glyph_count)

		# Buchstaben-Rotation — durch stress verstärkt.
		# Welche Buchstaben sich drehen entscheidet der RichTextRotate-Effekt
		# deterministisch aus dem seed (siehe RichTextRotate.gd). fs reicht die
		# Schriftgroesse durch, weil CharFXTransform sie selbst nicht kennt.
		var rp := _pct(rotate_pct, boost)
		if rp > 0.0:
			w = "[rot pct=%.2f deg=%.0f fs=%d seed=%d]%s[/rot]" % [rp, rotate_deg, base_font_size, _rng.randi_range(0, 999999), w]

		# Drift / Welle — durch stress verstärkt
		var da: float = drift_amp * boost
		if da > ANIM_THRESHOLD:
			var phase: float = fmod(float(i) * WAVE_PHASE_STEP, 1.0)
			w = "[wave amp=%.1f freq=%.2f]%s[/wave]" % [da, drift_freq + phase, w]

		# Shake — durch stress verstärkt
		var sa: float = shake_amp * boost
		if sa > ANIM_THRESHOLD:
			w = "[shake rate=%d level=%.1f]%s[/shake]" % [SHAKE_RATE, sa, w]

		# Tornado — durch stress verstärkt
		var torn_r: float = tornado_radius * boost
		if torn_r > ANIM_THRESHOLD:
			w = "[tornado radius=%.1f freq=%.2f]%s[/tornado]" % [torn_r, tornado_freq, w]

		# Pulse — durch stress verstärkt
		var pf: float = pulse_freq * boost
		if pf > PULSE_THRESHOLD:
			w = "[pulse freq=%.2f color=%s]%s[/pulse]" % [pf, color_pulse.to_html(), w]

		# Pulsierendes Verschwinden ganz aussen, damit es die Deckkraft aller
		# inneren Effekte moduliert. Der seed kommt deterministisch aus rng_seed +
		# Wortindex statt aus _rng: so bleibt der erzeugte String ueber Re-Renders
		# identisch und die laufende Animation springt nicht auf Phase 0 zurueck
		# (siehe _set_rendered in DyslexiaLabel).
		if v > 0.0:
			w = "[vanish pct=%.2f period=%.2f hide=%.2f fade=%.2f seed=%d]%s[/vanish]" % [
				v, vanish_period, vanish_hide, vanish_fade, rng_seed + i * 7919, w]

		out.append(w)

	# River Spacing — durch stress verstärkt
	var rs: float = river_gap * boost
	if rs > ANIM_THRESHOLD:
		var parts: PackedStringArray = []
		for i in out.size():
			parts.append(out[i])
			if i < out.size() - 1:
				var extra: int = int(_rng.randf() * rs)
				if extra > 0:
					parts.append(" ".repeat(extra))
		return "".join(parts)

	return " ".join(out)


## Effektive Stärke (0–1) des Fehlende-Teile-Shaders (glyph_missing.gdshader).
## Kein BBCode-Effekt — DyslexiaLabel setzt damit sein ShaderMaterial.
## Stress-verstärkt wie die anderen Effekte, gedeckelt bei MISSING_MAX.
func effective_missing(missing_pct: float) -> float:
	if accessibility:
		return 0.0
	# Kein _pct(): der Deckel liegt hier bei MISSING_MAX statt bei 1.0.
	return clampf((missing_pct / 100.0) * _boost(), 0.0, MISSING_MAX)


## Zusaetzlicher Vorschub pro Glyphe (in Pixeln), damit gedrehte Buchstaben
## einander nicht ueberlappen. Kein BBCode — DyslexiaLabel setzt damit eine
## FontVariation als Theme-Override, denn nur das Layout kann Platz schaffen;
## ein RichTextEffect verschiebt Glyphen, ohne ihre Breite zu aendern.
##
## Der Wert haengt bewusst NUR an rotate_deg, nicht an rotate_pct: sobald ein
## einziger Buchstabe gedreht werden kann, braucht er den vollen Platz. Und ein
## gleichmaessiger Abstand haelt die Laufweite ueber alle Stufen konstant —
## sonst wuerde der Abstand mit θ mitwandern und waere ein zweiter Störfaktor.
func rotation_glyph_spacing(font: Font, font_size: int, rotate_pct: float) -> int:
	if accessibility or not rotate_spacing or rotate_pct <= 0.0 or font == null:
		return 0
	var w: float = font.get_string_size("m", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var h: float = font.get_ascent(font_size)
	if w <= 0.0:
		return 0
	# Breite einer um t gedrehten Box: w*cos(t) + h*sin(t). Das Maximum liegt bei
	# atan(h/w) — daraeber wird die Box wieder schmaler (bei 90° ist sie nur h breit).
	var worst: float = atan2(h, w)
	var t: float = minf(deg_to_rad(rotate_deg), worst)
	var needed: float = w * cos(t) + h * sin(t)
	return int(ceil(maxf(needed - w, 0.0)))


func _swap_letters(word: String, chance: float, rng: RandomNumberGenerator) -> String:
	var result := ""
	for i in word.length():
		var ch: String = word[i]
		var lo: String = ch.to_lower()
		if lo in SWAP_PAIRS and rng.randf() < chance:
			var swapped: String = SWAP_PAIRS[lo]
			if ch == ch.to_upper() and ch != ch.to_lower():
				swapped = swapped.to_upper()
			if mark_effects:
				result += "[color=%s]%s[/color]" % [color_swap.to_html(), swapped]
			else:
				result += swapped
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
## Erwartet reinen Text und liefert reinen Text — die Einfaerbung setzt
## process_text() als Wrapper, damit hier keine BBCode-Tags mitgemischt werden.
func _scramble_middle(word: String, rng: RandomNumberGenerator) -> String:
	var first := word[0]
	var last  := word[word.length() - 1]
	var middle_chars: Array = []
	for i in range(1, word.length() - 1):
		middle_chars.append(word[i])
	for i in range(middle_chars.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = middle_chars[i]
		middle_chars[i] = middle_chars[j]
		middle_chars[j] = tmp
	return first + "".join(middle_chars) + last


## Verschiebt zwei Zeichenblöcke (Pseudo-Silben) im Wort.
## Reiner Text rein, reiner Text raus — siehe _scramble_middle().
func _transpose_syllable(word: String, rng: RandomNumberGenerator) -> String:
	var n := word.length()
	var cut: int = rng.randi_range(1, n - 2)
	var part_a := word.substr(0, cut)
	var part_b := word.substr(cut)
	return part_b + part_a


## Visuelles Crowding: Buchstaben ruecken zur Wortmitte zusammen.
## Wie stark verschoben wird entscheidet der RichTextCrowd-Effekt aus amt/len/seed
## (siehe RichTextCrowd.gd) — hier wird nur ausgewuerfelt, WELCHE Woerter es trifft.
##
## glyph_count kommt von aussen: word enthaelt hier schon BBCode aus Swap/Size,
## seine .length() waere also nicht die sichtbare Zeichenzahl.
func _apply_crowding(word: String, chance: float, rng: RandomNumberGenerator, glyph_count: int) -> String:
	if rng.randf() >= chance or glyph_count < 2:
		return word
	var amt: float = chance * crowd_max_shift
	return "[crowd amt=%.2f len=%d seed=%d]%s[/crowd]" % [amt, glyph_count, rng.randi_range(0, 999999), word]


## Entfernt BBCode-Tags aus einem String.
func _strip_bbcode(text: String) -> String:
	var parts: PackedStringArray = []
	var inside := false
	for i in text.length():
		var c := text[i]
		if c == "[":
			inside = true
		elif c == "]":
			inside = false
		elif not inside:
			parts.append(c)
	return "".join(parts)
