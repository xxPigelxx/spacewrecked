shader_type canvas_item;

// Energieschild ueber der Schiffssilhouette.
// Nutzt den Alphakanal der Textur als Maske: innen ein wanderndes
// Energiemuster, an der Kante ein heller Saum, dazu ein langsames Pulsieren.

uniform vec4 shield_color : source_color = vec4(0.30, 0.62, 1.0, 1.0);

// Grundsichtbarkeit des Schilds.
uniform float base_alpha : hint_range(0.0, 1.0) = 0.35;

// Langsames Atmen der gesamten Flaeche.
uniform float pulse_speed : hint_range(0.0, 4.0) = 0.35;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.25;

// Diagonal wandernde Energiebaender.
uniform float band_scale : hint_range(1.0, 60.0) = 14.0;
uniform float band_speed : hint_range(0.0, 4.0) = 0.5;
uniform float band_strength : hint_range(0.0, 1.0) = 0.30;

// Heller Saum an der Silhouettenkante.
uniform float rim_width : hint_range(0.5, 12.0) = 4.0;
uniform float rim_strength : hint_range(0.0, 6.0) = 2.2;

void fragment() {
	float a = texture(TEXTURE, UV).a;
	if (a <= 0.003) {
		discard;
	}

	// Kante = eigenes Alpha minus Mittelwert der Nachbarn. Innen ~0, am Rand ~1.
	vec2 px = TEXTURE_PIXEL_SIZE * rim_width;
	float neighbours = texture(TEXTURE, UV + vec2(px.x, 0.0)).a
		+ texture(TEXTURE, UV - vec2(px.x, 0.0)).a
		+ texture(TEXTURE, UV + vec2(0.0, px.y)).a
		+ texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float rim = clamp(a - neighbours * 0.25, 0.0, 1.0);

	float bands = sin((UV.x + UV.y) * band_scale - TIME * band_speed * TAU) * 0.5 + 0.5;
	float pulse = 1.0 + sin(TIME * pulse_speed * TAU) * pulse_strength;
	float glow = rim * rim_strength;

	vec4 col = shield_color;
	col.rgb *= 1.0 + glow;
	col.a = a * base_alpha * pulse * (1.0 + bands * band_strength + glow);

	// Mit COLOR multiplizieren, damit modulate/self_modulate weiter greifen.
	COLOR *= col;
}
