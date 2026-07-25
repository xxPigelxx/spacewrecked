# RichTextCrowd.gd — Custom RichTextEffect: [crowd amt=1.5 len=7 seed=123]Wort[/crowd]
# Visuelles Crowding: die Buchstaben eines Wortes ruecken zusammen, sodass sie
# sich beim Lesen gegenseitig verdecken/stoeren (Crowding-Effekt).
#
# Bewusst ein Glyphen-Versatz und kein Layout-Eingriff: RichTextLabel bricht
# Zeilen nach dem Layout um, ein Effekt aendert nur die Zeichenposition. Damit
# bleibt der Zeilenfluss intakt (der frueher benutzte [p]-Tag ist ein ABSATZ-Tag
# und hat jedes gecrowdete Wort in eine eigene Zeile gezwungen).
#
# Die Buchstaben werden zur WORTMITTE gezogen, nicht kumulativ nach links: so
# verteilt sich der frei werdende Raum symmetrisch auf beide Wortseiten statt
# als eine grosse Luecke dahinter zu landen.
@tool
class_name RichTextCrowd
extends RichTextEffect

var bbcode := "crowd"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var amt: float = TextEffectHelper.env_float(char_fx, "amt", 0.0)
	if amt <= 0.0:
		return true
	var glyphs: float = TextEffectHelper.env_float(char_fx, "len", 0.0)
	if glyphs < 2.0:
		return true
	var seed_val: int = TextEffectHelper.env_int(char_fx, "seed", 0)
	# Zug zur Wortmitte: Buchstabe 0 nach rechts, letzter nach links.
	var center: float = (glyphs - 1.0) * 0.5
	var pull: float = (center - float(char_fx.relative_index)) * amt
	# Ungleichmaessig — echtes Crowding klumpt, es staucht nicht linear.
	# hash_signed liefert -1…+1, halbiert ergibt das den Ausschlag ±0.5 * amt.
	var jitter: float = TextEffectHelper.hash_signed(seed_val, char_fx.relative_index) * amt * 0.5
	char_fx.offset.x += pull + jitter
	return true
