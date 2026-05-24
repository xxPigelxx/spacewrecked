## PageEffects.gd
## An eine Page (z.B. Page_Strom) hängen.
## Steuert alle DyslexiaLabel Kinder dieser Seite gleichzeitig.
## Werte im Inspector einstellen — alle Labels der Seite übernehmen sie.

extends Control

@export_group("Dyslexie Effekte")
## Wörter verschwinden. 0 = aus, 100 = alle weg.
@export_range(0, 100, 1, "suffix:%") var vanish_percent: float = 0.0
## Buchstaben tauschen: b↔d, p↔q, n↔u. 0 = nie, 100 = immer.
@export_range(0, 100, 1, "suffix:%") var swap_percent: float = 0.0
## Wörter schwingen auf/ab. 0 = aus.
@export_range(0.0, 20.0, 0.5) var drift_amplitude: float = 0.0
## Wellengeschwindigkeit.
@export_range(0.1, 5.0, 0.1) var drift_frequency: float = 1.0
## Wortgröße variiert. 0 = aus.
@export_range(0.0, 10.0, 0.5) var size_variation: float = 0.0
## Extra Lücken zwischen Wörtern. 0 = aus.
@export_range(0.0, 20.0, 1.0) var river_spacing: float = 0.0
## Wörter gespiegelt. 0 = nie, 100 = immer.
@export_range(0, 100, 1, "suffix:%") var mirror_percent: float = 0.0
## Basis-Seed — jedes Label bekommt einen leicht anderen Seed.
@export var base_seed: int = 1000

func _ready() -> void:
	DyslexiaManager.stress_changed.connect(_on_stress_changed)
	# Einen Frame warten damit alle DyslexiaLabel _ready() fertig haben
	await get_tree().process_frame
	_apply()

func _apply() -> void:
	var labels := _get_all_dyslexia_labels(self)
	for i in labels.size():
		labels[i].apply_effects(
			vanish_percent, swap_percent,
			drift_amplitude, drift_frequency,
			size_variation, river_spacing,
			mirror_percent, base_seed + i * 97
		)

func _get_all_dyslexia_labels(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		if child is DyslexiaLabel:
			result.append(child)
		result.append_array(_get_all_dyslexia_labels(child))
	return result

func _on_stress_changed(_val: float) -> void:
	_apply()
