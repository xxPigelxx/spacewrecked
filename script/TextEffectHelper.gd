# TextEffectHelper.gd — Gemeinsame Bausteine der RichTextEffect-Skripte
# (RichTextRotate, RichTextCrowd, spaetere).
#
# Alles hier ist static: die Datei wird nie instanziiert, sondern direkt ueber
# den Klassennamen aufgerufen — TextEffectHelper.hash01(seed, index).
#
# Warum es die Hash-Funktionen ueberhaupt braucht:
# _process_custom_fx() laeuft pro Glyphe pro FRAME. Ein RandomNumberGenerator
# wuerde dort in jedem Frame einen neuen Wert liefern und die Buchstaben zittern
# lassen. Deshalb kommt jede "Zufallszahl" aus einem Hash ueber (seed, index) —
# gleiche Eingabe, gleiches Ergebnis, also ein stehendes Bild trotz Zufallslook.
@tool
class_name TextEffectHelper
extends RefCounted


## Stabile Pseudozufallszahl 0.0 … 1.0 fuer eine einzelne Glyphe.
static func hash01(hash_seed: int, index: int) -> float:
	# index + 1, sonst faellt der Index bei 0 komplett aus dem XOR heraus.
	var x: int = (hash_seed * 73856093) ^ ((index + 1) * 19349663)
	# Avalanche-Schritt: benachbarte Indizes bekommen dadurch weit auseinander
	# liegende Ergebnisse. Ohne ihn waere der "Zufall" sichtbar gleichmaessig.
	x = (x ^ (x >> 13)) * 1274126177
	return float(absi(x) % 100000) / 100000.0


## Wie hash01(), aber symmetrisch um Null: -1.0 … +1.0.
## Fuer Effekte, die in beide Richtungen ausschlagen (Winkel, Versatz) — sonst
## wuerde der Effekt alle Glyphen systematisch in dieselbe Richtung schieben.
static func hash_signed(hash_seed: int, index: int) -> float:
	return hash01(hash_seed, index) * 2.0 - 1.0


## Tag-Attribut als float lesen, mit Fallback wenn es im BBCode fehlt.
static func env_float(char_fx: CharFXTransform, key: String, fallback: float) -> float:
	return float(char_fx.env.get(key, fallback))


## Tag-Attribut als int lesen, mit Fallback wenn es im BBCode fehlt.
static func env_int(char_fx: CharFXTransform, key: String, fallback: int) -> int:
	return int(char_fx.env.get(key, fallback))
