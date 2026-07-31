# Fragebogen-Uebersicht (Stand 31.07.2026)

Alle Fragen, die im Spiel gestellt werden, in der Reihenfolge des Durchlaufs.
Der Node-Name in Klammern ist gleichzeitig der Spaltenname im Google Sheet —
`store_answers` haengt `_pre` bzw. `_post` an, auch bei Demografie und
Story-Fragen.

Was die Items messen sollen und wie sie ausgewertet werden:
[Fragebogen_Auswertung.md](Fragebogen_Auswertung.md).

Antwortformate:
- **Likert (5)** — 5 Checkboxen, Endpunkte je nach `scale_type`:
  AGREEMENT „stimme gar nicht zu" ... „stimme voll zu" (alle Items nutzen das)
- **Auswahl** — Dropdown, startet ohne Vorauswahl, speichert den Antworttext
- **TLX-Slider** — 1 bis 20, „sehr gering" ... „sehr hoch", startet unbeantwortet („?")
- **Freitext** — TextEdit

---

## 0. Startbildschirm (MainMenu.tscn, Popup)

| Frage | Antworten |
|---|---|
| Wurde bei Ihnen Dyslexie/Legasthenie festgestellt? | Ja / Nein |

Landet in `GameState.participant_has_dyslexia` und wird **nicht gesendet**.
Inhaltlich doppelt zu `demo_dyslexie_selbst`.

---

## 1. Pre-Block (Scenes/Menu/pre_flow.tscn)

Ablauf: Story-Intro (nur Text) → TLX → Fragebogen → MainGame

### 1.1 TLX — Bezug: „Lesen des **Einleitungstextes**"

Instruktion: „Klicken Sie in jeder Skala auf den Punkt, der Ihre Erfahrung im
Hinblick auf das Lesen des Einleitungstextes am besten verdeutlicht."

| # | Dimension | Node | Erklaerungstext |
|---|---|---|---|
| 1 | Geistige Anforderung | `tlx_geistig` | Wie viel geistige Anforderung war bei der Informationsaufnahme und bei der Informationsverarbeitung erforderlich (z.B. Denken, Entscheiden, Rechnen, Erinnern, Hinsehen, Suchen ...)? War die Aufgabe leicht oder anspruchsvoll, einfach oder komplex, erfordert sie hohe Genauigkeit oder ist sie fehlertolerant? |
| 2 | Koerperliche Anforderung | `tlx_koerperlich` | Wie viel koerperliche Aktivitaet war erforderlich (z.B. ziehen, druecken, drehen, steuern, aktivieren ...)? War die Aufgabe leicht oder schwer, einfach oder anstrengend, erholsam oder muehselig? |
| 3 | Zeitliche Anforderung | `tlx_zeitlich` | Wie viel Zeitdruck empfanden Sie hinsichtlich der Haeufigkeit oder dem Takt mit dem die Aufgaben oder Aufgabenelemente auftraten? War die Aufgabe langsam und geruhsam oder schnell und hektisch? |
| 4 | Leistung | `tlx_leistung` | Wie erfolgreich haben Sie Ihrer Meinung nach die vom Versuchsleiter (oder Ihnen selbst) gesetzten Ziele erreicht? Wie zufrieden waren Sie mit Ihrer Leistung bei der Verfolgung dieser Ziele? — **Endpunkte hier „Gut" / „Schlecht"** |
| 5 | Anstrengung | `tlx_anstrengung` | Wie hart mussten Sie arbeiten, um Ihren Grad an Aufgabenerfuellung zu erreichen? |
| 6 | Frustration | `tlx_frustration` | Wie unsicher, entmutigt, irritiert, gestresst und veraergert (versus sicher, bestaetigt, zufrieden, entspannt und zufrieden mit sich selbst) fuehlten Sie sich waehrend der Aufgabe? |

### 1.2 Angaben zu deiner Person

| Frage | Node | Antworten |
|---|---|---|
| Alter | `demo_alter` | unter 18 / 18 - 24 / 25 - 34 / 35 - 49 / ueber 50 |
| Geschlecht | `demo_geschlecht` | Weiblich / Maennlich / Divers / Keine Angabe |
| Ist Deutsch deine Muttersprache? | `demo_deutsch_l1` | Ja / Nein |
| Hast du selbst Legasthenie? | `demo_dyslexie_selbst` | Ja, diagnostiziert / Ja, vermute ich / Nein / Keine Angabe |
| Kennst du persoenlich jemanden mit Legasthenie? | `demo_dyslexie_umfeld` | Ja / Nein / Weiss nicht / Keine Angabe |

### 1.3 Kurze Kontrollfragen zur Geschichte

| Frage | Node | Antworten (richtig **fett**) |
|---|---|---|
| Wie heisst das Material, das du geborgen hast? | `story_material` | Veridium / **Stratium** / Astralit / Weiss ich nicht mehr |
| Auf welchem Planeten hast du es gefunden? | `story_planet` | Kaldris IV / **Veridian VII** / Erebus-3 / Weiss ich nicht mehr |
| Welches System ist beim Meteoritenschauer ausgefallen? | `story_ausfall` | Der Antrieb / Der Frachtraum / **Der Bordcomputer** / Weiss ich nicht mehr |

### 1.4 Angaben zu deinen Einschaetzungen (Likert 5, alle AGREEMENT)

| # | Frage | Node |
|---|---|---|
| 1 | Menschen mit Legasthenie sehen Buchstaben verdreht. | `q01_verdreht` |
| 2 | Legasthenie ist vor allem ein Problem der Augen. | `q02_augen` |
| 3 | Mit genug Uebung waere Lesen mit Legasthenie kein Problem mehr. | `q03_uebung` |
| 4 | Lesen kostet Menschen mit Legasthenie mehr Kraft als mich. | `q04_kraft` |
| 5 | Wer mit Legasthenie liest, hat weniger Kopf frei fuer den Inhalt. | `q05_kopf_frei` |
| 6 | Wenn jemand **mit Legasthenie** fuer einen Text laenger braucht, kann ich nachvollziehen, warum. | `q06_zeit_verstaendnis` |
| 7 | Ich kann mir vorstellen, wie es ist, mit Legasthenie zu lesen. | `q11_vorstellen` |
| 8 | Wenn jemand in einer Gruppe nicht laut vorlesen moechte, kann ich die Gruende nachvollziehen. | `q07_vorlesen_verstaendnis` |

---

## 2. Post-Block (Scenes/Menu/post_flow.tscn)

Ablauf: TLX → Fragebogen → `submit()` → EndScreen

### 2.1 TLX — Bezug: „Lesen des **Handbuchtextes**"

Dieselben 6 Dimensionen und Erklaerungstexte, nur die Instruktion
unterscheidet sich.

### 2.2 Wiederholte Items (Likert 5)

| # | Frage | Node |
|---|---|---|
| 1 | Menschen mit Legasthenie sehen Buchstaben verdreht. | `q01_verdreht` |
| 2 | Legasthenie ist vor allem ein Problem der Augen. | `q02_augen` |
| 3 | Mit genug Uebung waere Lesen mit Legasthenie kein Problem mehr. | `q03_uebung` |
| 4 | Lesen kostet Menschen mit Legasthenie mehr Kraft als mich. | `q04_kraft` |
| 5 | Wer mit Legasthenie liest, hat weniger Kopf frei fuer den Inhalt. | `q05_kopf_frei` |
| 6 | Wenn jemand **mit Legasthenie** fuer einen Text laenger braucht, kann ich nachvollziehen, warum. | `q06_zeit_verstaendnis` |
| 7 | Ich kann mir vorstellen, wie es ist, mit Legasthenie zu lesen. | `q11_vorstellen` |
| 8 | Wenn jemand in einer Gruppe nicht laut vorlesen moechte, kann ich die Gruende nachvollziehen. | `q07_vorlesen_verstaendnis` |

Alle acht Items sind wortgleich zum Pre-Block.

### 2.3 Retrospektive Items (Likert 5, nur Post)

| Frage | Node |
|---|---|
| Durch das Spiel kann ich besser nachvollziehen, warum jemand mit Legasthenie fuer einen Text laenger braucht. | `retro_nachvollziehen` |
| Durch das Spiel ist mir klarer geworden, wie viel Kraft das Lesen mit Legasthenie kosten kann. | `retro_kraft` |

### 2.4 Erleben des Spiels (Likert 5, nur Post)

| Frage | Node |
|---|---|
| Das Spiel hat mir Spass gemacht. | `q08_spass` |
| Das Spiel hat mich frustriert. | `q09_frust` |
| Das Lesen des Handbuchs hat mich ueberfordert. | `q10_handbuch` |

### 2.5 Freitext

| Frage | Node | Pflicht |
|---|---|---|
| Was hat sich beim Lesen des Handbuchs am schwierigsten angefuehlt? | `text_schwierigstes` | ja |
| Haben die Veraenderungen im Handbuch dein Lesen beeinflusst? wenn Ja wie? | `text_beeinflusst` | ja |
| Hat sich deine Vorstellung von Dyslexie durch das Spiel veraendert? Wenn ja, wie? | `text_veraenderung` | nein |

---

## Zaehlung

| Block | TLX | Auswahl | Likert | Freitext | Summe |
|---|---|---|---|---|---|
| Pre | 6 | 8 | 8 | 0 | 22 |
| Post | 6 | 0 | 13 | 3 | 22 |

Plus 1 Ja/Nein im Startup-Popup (wird nicht gesendet).

---

## Offene Punkte

Gesamtstand aller Punkte: [Offene_Punkte.md](Offene_Punkte.md).

1. **`text_veraenderung` sagt „Dyslexie"**, der uebrige Fragebogen sagt
   durchgaengig „Legasthenie".
3. **Tippfehler in `retro_nachvollziehen`:** „laenger" statt „länger", steht so
   im Teilnehmertext.
4. **Startup-Popup und `demo_dyslexie_selbst` erheben dasselbe** (bekannte
   Baustelle in CLAUDE.md). Das Popup landet nur in `GameState` und wird nicht
   gesendet — die Fragebogen-Variante ist die verwertbare.
5. **CLAUDE.md ist veraltet:** dort steht „Demografie + 5 Items + 6
   TLX-Slider". Es sind inzwischen 8 wiederholte Items plus 3
   Story-Kontrollfragen.
6. **`pre_questionear.tscn` / `pre_questionear.gd` sind tot.** `skip := true`
   ueberspringt die Szene sofort, und keine andere Szene laedt sie. Der aktive
   Pre-Fragebogen sitzt in `pre_flow.tscn`.
