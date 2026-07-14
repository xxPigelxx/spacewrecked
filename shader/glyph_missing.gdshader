// glyph_missing.gdshader — Fehlende-Teile-Effekt nach dem Dyslexia-Typeface
// von Daniel Britton: pro Zelle (~Buchstabengröße) fehlt EIN zusammenhängendes
// Band mit gerader Kante — kein Streumuster aus kleinen Blöcken.
// Das Muster liegt im Font-Atlas-Raum: es klebt fest am Buchstaben
// (jedes "a" fehlt an derselben Stelle), egal wie der Text sich bewegt.
shader_type canvas_item;

// Anteil der fehlenden Fläche pro Zelle, 0.0 = nichts fehlt, 1.0 = alles weg.
uniform float missing_amount : hint_range(0.0, 1.0) = 0.0;
// Zellgröße in Atlas-Pixeln — sollte ungefähr der Buchstabengröße entsprechen.
uniform float cell_size : hint_range(4.0, 64.0) = 12.0;
// Verschiebt das Muster — pro Label anders, damit nicht alles identisch aussieht.
uniform float pattern_seed = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	if (missing_amount > 0.0) {
		vec2 px = UV / TEXTURE_PIXEL_SIZE;
		vec2 cell = floor(px / cell_size);
		vec2 f = fract(px / cell_size);
		// Pro Zelle: horizontales oder vertikales Band, Startposition zufällig —
		// so entstehen Schnitte wie H→II (Querbalken weg) oder E→Ǝ (Stamm weg).
		float axis = hash21(cell + pattern_seed + 17.0);
		float pos = (axis < 0.5) ? f.x : f.y;
		float start = hash21(cell + pattern_seed + 53.0) * (1.0 - missing_amount);
		if (pos >= start && pos < start + missing_amount) {
			COLOR.a = 0.0;
		}
	}
}
