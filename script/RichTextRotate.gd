# RichTextRotate.gd — Custom RichTextEffect: [rot pct=0.3 deg=60 seed=123]Wort[/rot]
# Rotation nach dem Corballis-Paradigma: jeder Buchstabe wird um einen ZUFÄLLIGEN
# Winkel innerhalb ±deg gedreht (deg = Orientierungsbereich θ der Studie).
# Winkel und Auswahl sind deterministisch (Hash aus seed + Glyphen-Index) —
# kein Flackern, obwohl der Effekt jeden Frame läuft. Siehe TextEffectHelper.
@tool
class_name RichTextRotate
extends RichTextEffect

var bbcode := "rot"

var _ts: TextServer = TextServerManager.get_primary_interface()

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var pct: float = TextEffectHelper.env_float(char_fx, "pct", 0.0)
	if pct <= 0.0:
		return true
	var seed_val: int = TextEffectHelper.env_int(char_fx, "seed", 0)
	if TextEffectHelper.hash01(seed_val, char_fx.relative_index) >= pct:
		return true
	var theta: float = TextEffectHelper.env_float(char_fx, "deg", 180.0)
	# seed + 7919: zweiter Hash-Griff aus demselben seed, sonst waeren Auswahl
	# und Winkel derselben Glyphe aneinander gekoppelt.
	var angle: float = deg_to_rad(TextEffectHelper.hash_signed(seed_val + 7919, char_fx.relative_index) * theta)
	# Um die Glyphenmitte drehen, damit die Buchstaben auf der Zeile bleiben:
	# x aus der echten Glyphenbreite, y ≈ halbe x-Höhe über der Baseline.
	# fs kommt aus dem Tag, weil CharFXTransform die Schriftgroesse nicht kennt —
	# mit einer fest verdrahteten Groesse saesse der Drehpunkt neben der Mitte,
	# sobald das Label in einer anderen Groesse rendert.
	var fs: int = TextEffectHelper.env_int(char_fx, "fs", 16)
	var adv: Vector2 = _ts.font_get_glyph_advance(char_fx.font, fs, char_fx.glyph_index)
	var pivot := Vector2(maxf(adv.x * 0.5, 2.0), -float(fs) * 0.33)
	char_fx.transform = char_fx.transform \
		.translated_local(pivot) \
		.rotated_local(angle) \
		.translated_local(-pivot)
	return true
