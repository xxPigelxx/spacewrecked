# RichTextVanishPulse.gd — Custom RichTextEffect:
# [vanish pct=0.40 period=6.0 hide=0.18 fade=0.12 seed=1234]Wort[/vanish]
#
# Das ganze Wort blendet aus, bleibt kurz weg und kommt wieder. Ersetzt das
# frueher statische Verschwinden: dort war ein Wort bis zum naechsten Render
# endgueltig fort, was eine Handbuchseite unloesbar machen konnte. Hier ist jedes
# Wort irgendwann wieder lesbar, der Text bleibt trotzdem unruhig.
#
# Den Tag bekommt JEDES Wort — welche Woerter tatsaechlich verschwinden, wird
# hier pro Zyklus neu ausgewuerfelt (pct = Anteil). Die Auswahl im DyslexiaManager
# zu treffen wuerde bedeuten, dass bis zum naechsten Re-Render immer dieselben
# Woerter blinken; ein Re-Render nur zum Neuwuerfeln wiederum wuerde alle
# laufenden Animationen auf Phase 0 zuruecksetzen und den Text zucken lassen.
#
# Alle Glyphen eines Wortes teilen sich dieselbe Phase — im Term steht bewusst
# KEIN Zeichenindex, sonst liefe eine Welle durch das Wort und es verschwaende
# buchstabenweise. Der Versatz zwischen den Woertern kommt aus dem seed.
@tool
class_name RichTextVanishPulse
extends RichTextEffect

var bbcode := "vanish"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var pct: float = TextEffectHelper.env_float(char_fx, "pct", 0.0)
	if pct <= 0.0:
		return true
	var period: float = TextEffectHelper.env_float(char_fx, "period", 6.0)
	if period <= 0.0:
		return true
	var hide: float = TextEffectHelper.env_float(char_fx, "hide", 0.18)
	var fade: float = TextEffectHelper.env_float(char_fx, "fade", 0.12)
	var seed_val: int = TextEffectHelper.env_int(char_fx, "seed", 0)

	# Index 0 ist fuer den Phasenversatz reserviert, die Zyklen zaehlen ab 1 —
	# so kann die Auswahl nie denselben Hash-Wert wie die Phase ziehen.
	var phase: float = TextEffectHelper.hash01(seed_val, 0)
	var x: float = char_fx.elapsed_time / period + phase
	var cycle: int = floori(x)

	# Pro Zyklus neu wuerfeln, ob dieses Wort diesmal drankommt. Dadurch rotiert
	# die Auswahl von selbst weiter, ohne dass der Text neu gerendert werden muss.
	if TextEffectHelper.hash01(seed_val, cycle + 1) >= pct:
		return true

	# Position im aktuellen Zyklus, 0…1.
	var u: float = x - float(cycle)
	# Abstand zur Zyklusmitte. Das Loch sitzt bei u = 0.5, damit der Sprung ueber
	# die Zyklusgrenze (u = 1 → 0) immer im voll sichtbaren Teil liegt.
	var d: float = absf(u - 0.5)
	var alpha: float = smoothstep(hide * 0.5, hide * 0.5 + fade, d)

	# Multiplizieren statt setzen: eine Farbe aus [color] (z.B. Swap-Rot) bleibt
	# so erhalten, nur die Deckkraft wird moduliert.
	var col: Color = char_fx.color
	col.a *= alpha
	char_fx.color = col
	# Sicherheitsnetz: im ganz unsichtbaren Fenster die Glyphe auch wirklich
	# abschalten, damit ein anderer farbaendernder Effekt sie nicht zurueckholt.
	if alpha <= 0.01:
		char_fx.visible = false
	return true
