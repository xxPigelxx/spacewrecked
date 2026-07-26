// glyph_missing.gdshader — Fehlende-Teile-Effekt nach dem Dyslexia-Typeface
// von Daniel Britton: pro Zelle (~Buchstabengröße) fehlt EIN zusammenhängendes
// Band mit gerader Kante — kein Streumuster aus kleinen Blöcken.
// Das Muster liegt im Font-Atlas-Raum: es klebt fest am Buchstaben
// (jedes "a" fehlt an derselben Stelle), egal wie der Text sich bewegt.
//
// missing_amount zählt den Anteil der TINTE, nicht der Fläche: pro Zelle wird
// die Deckung entlang der Schnittachse aufsummiert und das Band dort gelegt, wo
// genau dieser Anteil der wirklich schwarzen Pixel liegt. So verliert ein dünnes
// "l" denselben Anteil seiner Substanz wie ein fettes "m" — nicht denselben
// Anteil der leeren Zelle drumherum.
shader_type canvas_item;

// Anteil der fehlenden Tinte pro Zelle, 0.0 = nichts fehlt, 1.0 = alles weg.
uniform float missing_amount : hint_range(0.0, 1.0) = 0.0;
// Zellgröße in Atlas-Pixeln — sollte ungefähr der Buchstabengröße entsprechen.
uniform float cell_size : hint_range(4.0, 64.0) = 12.0;
// Verschiebt das Muster — pro Label anders, damit nicht alles identisch aussieht.
uniform float pattern_seed = 0.0;

// Abtastungen beim Aufsummieren der Tinte einer Zelle:
// SLICES entlang der Schnittachse, CROSS quer dazu.
const int SLICES = 16;
const int CROSS = 6;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	// Nur echte Tinte behandeln: leere Pixel sind ohnehin transparent, und das
	// spart die teure Abtast-Schleife auf dem Großteil des Labels.
	if (missing_amount > 0.0 && COLOR.a > 0.0) {
		vec2 px = UV / TEXTURE_PIXEL_SIZE;
		vec2 cell = floor(px / cell_size);
		vec2 f = fract(px / cell_size);

		// Pro Zelle: horizontales oder vertikales Band, Richtung zufällig —
		// so entstehen Schnitte wie H→II (Querbalken weg) oder E→Ǝ (Stamm weg).
		float axis = hash21(cell + pattern_seed + 17.0);
		vec2 axis_dir = (axis < 0.5) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
		vec2 cross_dir = (axis < 0.5) ? vec2(0.0, 1.0) : vec2(1.0, 0.0);
		float pos = dot(f, axis_dir);

		// Tinte der Zelle entlang der Schnittachse aufsummieren: pro Scheibe die
		// Deckung quer zur Achse messen. total = gesamte Tinte der Zelle,
		// below = Tinte VOR der aktuellen Stelle. So zählt nur, was wirklich
		// schwarz ist — nicht die leere Fläche um den Buchstaben.
		float total = 0.0;
		float below = 0.0;
		for (int i = 0; i < SLICES; i++) {
			float t = (float(i) + 0.5) / float(SLICES);
			float w = 0.0;
			for (int j = 0; j < CROSS; j++) {
				float s = (float(j) + 0.5) / float(CROSS);
				vec2 sample_px = (cell + t * axis_dir + s * cross_dir) * cell_size;
				w += texture(TEXTURE, sample_px * TEXTURE_PIXEL_SIZE).a;
			}
			total += w;
			if (t < pos) {
				below += w;
			}
		}

		if (total > 0.0) {
			// frac = Anteil der Tinte vor dieser Stelle. Das Band deckt
			// missing_amount der Tinte ab, ab einem zufälligen Tinten-Startpunkt.
			float frac = below / total;
			float start = hash21(cell + pattern_seed + 53.0) * (1.0 - missing_amount);
			if (frac >= start && frac < start + missing_amount) {
				COLOR.a = 0.0;
			}
		}
	}
}
