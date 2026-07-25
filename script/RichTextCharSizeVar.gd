# RichTextCharSizeVar.gd — Custom RichTextEffect:
# [charsize amt=1.00 fs=18 seed=1234]Wort[/charsize]
#
# Jeder Buchstabe bekommt eine eigene, zufaellige Groesse. Der Wert ist fest —
# er kommt aus einem Hash ueber (seed, Zeichenposition), nicht aus der Zeit.
# Deshalb steht das Bild still, obwohl der Effekt jeden Frame neu laeuft.
#
# Der Zufall kommt aus einem Hash und nicht aus einem RandomNumberGenerator: die
# Funktion laeuft pro Glyphe pro Frame, ein RNG wuerde in jedem Frame andere
# Werte liefern und die Buchstaben flackern lassen.
#
# Abgrenzung zu size_variation im DyslexiaManager: das setzt pro WORT ein
# [font_size]-Tag und aendert damit das Layout. Dieser Effekt ist rein visuell,
# die Vorschubbreite der Glyphe bleibt gleich. Deswegen skaliert er auch nur nach
# unten — ueber 1.0 hinaus wuerde der Buchstabe in seine Nachbarn ragen.
@tool
class_name RichTextCharSizeVar
extends RichTextEffect

var bbcode := "charsize"

## Staerkste Verkleinerung bei amt = 1.0 (0.5 = halbe Groesse).
## Fuer eine symmetrische Streuung (mal groesser, mal kleiner) muesste hier
## hash_signed() statt hash01() ran — dann ueberlappen die grossen Buchstaben
## aber ihre Nachbarn, weil der Vorschub unveraendert bleibt.
const MAX_SHRINK := 0.5

var _ts: TextServer = TextServerManager.get_primary_interface()

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var amt: float = TextEffectHelper.env_float(char_fx, "amt", 0.0)
	if amt <= 0.0:
		return true
	var seed_val: int = TextEffectHelper.env_int(char_fx, "seed", 0)
	var scale: float = 1.0 - MAX_SHRINK * amt * TextEffectHelper.hash01(seed_val, char_fx.relative_index)

	# Um die Glyphenmitte skalieren. scaled_local() geht sonst vom Ursprung links
	# auf der Grundlinie aus — kleinere Buchstaben wuerden nach unten links
	# wegrutschen statt an ihrem Platz zu schrumpfen.
	var fs: int = TextEffectHelper.env_int(char_fx, "fs", 16)
	var adv: Vector2 = _ts.font_get_glyph_advance(char_fx.font, fs, char_fx.glyph_index)
	var pivot := Vector2(maxf(adv.x * 0.5, 2.0), -float(fs) * 0.33)
	char_fx.transform = char_fx.transform \
		.translated_local(pivot) \
		.scaled_local(Vector2.ONE * scale) \
		.translated_local(-pivot)
	return true
