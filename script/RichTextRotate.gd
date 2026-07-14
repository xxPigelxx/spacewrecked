# RichTextRotate.gd — Custom RichTextEffect: [rot pct=0.3 deg=60 seed=123]Wort[/rot]
# Rotation nach dem Corballis-Paradigma: jeder Buchstabe wird um einen ZUFÄLLIGEN
# Winkel innerhalb ±deg gedreht (deg = Orientierungsbereich θ der Studie).
# Winkel und Auswahl sind deterministisch (Hash aus seed + Glyphen-Index) —
# kein Flackern, obwohl der Effekt jeden Frame läuft.
@tool
class_name RichTextRotate
extends RichTextEffect

var bbcode := "rot"

var _ts: TextServer = TextServerManager.get_primary_interface()

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var pct: float = float(char_fx.env.get("pct", 0.0))
	if pct <= 0.0:
		return true
	var seed_val: int = int(char_fx.env.get("seed", 0))
	if _hash01(seed_val, char_fx.relative_index) >= pct:
		return true
	var theta: float = float(char_fx.env.get("deg", 180.0))
	var angle: float = deg_to_rad((_hash01(seed_val + 7919, char_fx.relative_index) * 2.0 - 1.0) * theta)
	# Um die Glyphenmitte drehen, damit die Buchstaben auf der Zeile bleiben:
	# x aus der echten Glyphenbreite, y ≈ halbe x-Höhe über der Baseline.
	var adv: Vector2 = _ts.font_get_glyph_advance(char_fx.font, 15, char_fx.glyph_index)
	var pivot := Vector2(maxf(adv.x * 0.5, 2.0), -5.0)
	char_fx.transform = char_fx.transform \
		.translated_local(pivot) \
		.rotated_local(angle) \
		.translated_local(-pivot)
	return true


static func _hash01(s: int, i: int) -> float:
	var x: int = (s * 73856093) ^ ((i + 1) * 19349663)
	x = (x ^ (x >> 13)) * 1274126177
	return float(absi(x) % 100000) / 100000.0
