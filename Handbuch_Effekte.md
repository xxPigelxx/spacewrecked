# Handbuch-Effekte — Auswahlregel, Vorgehen, Belegbarkeit

Stand 31.07.2026. Drei Teile: nach welcher Regel Effekte eingesetzt werden
duerfen, nach welchem Schema die Seiten bestueckt sind, und was sich zu welchem
Effekt belegen laesst.

Schwesterdokumente: [Fragebogen_Uebersicht.md](Fragebogen_Uebersicht.md),
[Fragebogen_Auswertung.md](Fragebogen_Auswertung.md).

---

## 1. Die Auswahlregel

> **Effekte duerfen Zeichen bewegen, stauchen, drehen, ausblenden und anfressen.
> Auf exakten Werten duerfen sie nicht ersetzen, welches Zeichen dasteht.**

Im Fliesstext ist auch Ersetzen unbedenklich, weil der Kontext es zurueckholt —
„Dordcomputer" liest man trotzdem. Bei `385197` gibt es nichts, was es
zurueckholt: Eine falsch gelesene Ziffer ist nicht muehsam, sondern still
falsch, und der Spieler kann es nicht bemerken.

Die Regel ist die Anwendung eines Prinzips, das im Projekt schon steht — in der
Begruendung zu `MISSING_MAX`: *muehsam ja, unlesbar nein.*

**Praktisch heisst das nur eine Einschraenkung:** kein `swap` auf Werte-Labels
(er ersetzt mit 6↔9 und 2↔5 genau dort Ziffern, wo es keine Redundanz gibt).
Alles andere ist ueberall erlaubt, solange die Zeichen beim Hinsehen
unterscheidbar bleiben.

Ein Detail, das dabei hilft: **`phonetic` fasst Ziffern nie an.** Die
`PHON_RULES` greifen nur auf Buchstaben. Auf der Codes-Seite werden also die
Beschriftungen umgeschrieben, die Codes selbst bleiben unberuehrt — das ist
automatischer Schutz, kein Zufall, den man absichern muesste.

**Was sich durch Warten aufloest und was nicht:**

| | Verhalten |
|---|---|
| `tornado`, `shake`, `drift`, `vanish`, `pulse` | Animiert — die Zeichen kehren periodisch an ihren Platz zurueck. Kostet Zeit und Arbeitsgedaechtnis, zerstoert aber nichts |
| `crowd`, `char_size`, `size_variation`, `rotate`, `missing`, `font`, `river_spacing` | Statisch — der Versatz haengt nur an Index und Seed, kein Zeitanteil. Was hier zusammenlaeuft, laeuft dauerhaft zusammen |

Auf Werte-Labels ist deshalb nicht der Bewegungseffekt der kritische, sondern
die Hoehe der **statischen** Effekte. `crowd 80` auf einer sechsstelligen Zahl
ist der Wert, den man sich ansieht — nicht `tornado`.

---

## 2. Das Vorgehen

**Jede Seite folgt demselben Bauplan:**

```
phonetic (Konstante)  +  mindestens ein Effekt je Kanal
```

„Mindestens", weil zwei Seiten einen zweiten Decodiereffekt bekommen haben —
jeweils mit Begruendung in der Bestueckungstabelle. Der Bauplan bleibt
derselbe, nur die Besetzung variiert.

Begruendung der drei Rollen:

- **`phonetic` als Konstante**, weil es der einzige Effekt mit direkter
  Verankerung in der Dyslexieforschung ist (Abschnitt 3). Er traegt die
  inhaltliche Aussage der Arbeit und soll deshalb ueberall wirken — auch auf
  den Seiten, die jeder Teilnehmer lesen muss.
  **Wert: 40.** Bei Stress 100 verdoppelt sich das auf 80 %; die restlichen
  20 % bleiben als unveraenderte Ankerwoerter stehen. Die braucht der Leser,
  um die Umschriftregeln ueberhaupt zu erschliessen.
- **Ein Effekt aus dem Decodierkanal** variiert, welcher Aspekt der
  Worterkennung teuer wird: Buchstabenidentitaet, Glyphenform, Wortgrenzen.
- **Ein Effekt aus dem Aufmerksamkeitskanal** erzeugt die extrinsische Last,
  die neben dem Lesen bedient werden muss.

Damit hat jede Seite dieselbe **Struktur** und eine andere **Auspraegung** —
das ist in einem Satz erklaerbar und sampelt gleichzeitig den Gestaltungsraum.

### Zweites Auswahlkriterium: Plausibilitaet als Wahrnehmungsbericht

Innerhalb der Belastungseffekte wurden solche ausgeschlossen, die sich als
Wahrnehmungsbericht lesen lassen. Ein Effekt soll Last erzeugen, nicht
nahelegen, wie Betroffene Text sehen.

| Effekt | Plausibel als Wahrnehmung? | Einsatz |
|---|---|---|
| `drift` | **Ja** — langsames Wogen; „die Buchstaben schwimmen" ist eine der haeufigsten Laienbeschreibungen von Dyslexie | **nein** |
| `vanish` | Grenzfall — bildet aber keine Wahrnehmung nach, sondern eine **Verfuegbarkeitsluecke**: Information ist zeitweise nicht abrufbar und muss im Arbeitsgedaechtnis gehalten werden (transient information effect). Der Effekt sagt nicht, wie Text aussieht, sondern wann er da ist | ja |
| `shake` | Nein — bei `SHAKE_RATE 20` zu schnell und regelmaessig; liest sich als Geraetestoerung | ja |
| `tornado` | Nein — niemand glaubt, dass Buchstaben kreisen. Am eindeutigsten kuenstlich | ja |

### Verfuegbare Effekte pro Slot

| Slot | Effekte |
|---|---|
| Decodierkanal | `crowd`, `missing`, `font`, `char_size`, `river_spacing`, `rotate`, `size_variation` |
| Aufmerksamkeitskanal | `tornado`, `shake`, `vanish` |

### Bestueckung (Stand im Projekt)

Auf **jeder** Seite `phonetic_percent = 42`.

| Seite | Decodierkanal | Aufmerksamkeit |
|---|---|---|
| **Home** | `char_size_percent 40` | `tornado_radius 5` · `tornado_frequency 2.0` |
| **Energie** | `missing_percent 25` | `shake_amplitude 3` |
| **Navigation** | `crowd_percent 40` · `font_percent 60` | `vanish_percent 25` |
| **Treibstoff** | `river_spacing 6` | `shake_amplitude 4` |
| **Schild** | `rotate_percent 35` | `vanish_percent 25` |
| **Codes** | `font_percent 60` · `crowd_percent 80` | `tornado_radius 5` · `tornado_frequency 2.0` |

**Alle uebrigen Parameter auf 0.**

Die Werte sind Ruhewerte und auf Stress 100 ausgelegt — der Boost verdoppelt
jeden davon.

**Warum die Verteilung so aussieht:**

- **Abwechslung statt Systematik in der Reihenfolge.** Bei sechs Seiten und
  drei Aufmerksamkeitseffekten wuerde eine streng schematische Zuordnung
  paarweise wirken (shake-shake-vanish-vanish-tornado-tornado). Die
  Aufteilung streut sie stattdessen ueber die Seiten.
- **Codes: `crowd` + `tornado` bewusst zusammen.** `crowd` zieht die Glyphen
  statisch zur Wortmitte, `tornado` bewegt sie zeitabhaengig um ihren
  Ursprung. Weil beide auf `char_fx.offset` addieren, kreisen die Buchstaben
  um ein gestauchtes Zentrum — die Woerter ziehen sich sichtbar auseinander
  und wieder zusammen. Ein emergenter Ziehharmonika-Effekt, der aus keinem
  der beiden allein entsteht.
- **Navigation: zweiter Decodiereffekt** (`font 60` neben `crowd 40`), weil
  die Seite den laengsten Fliesstext traegt.
- **`shake` auf Energie**, weil die Seite vier Fehlercodes traegt: Zittern
  laesst sie stehen, Verschwinden naehme sie periodisch weg.

`size_variation` bleibt ungenutzt — schwaechste Befundlage und der einzige
Effekt, der ins Layout eingreift statt nur in die Darstellung.
`pulse` bleibt ungenutzt wegen Anfallsrisiko (Abschnitt 3).
`drift` bleibt ungenutzt als Wahrnehmungsbericht (siehe oben).

### Ausnahmen per `override_page`

`override_page` ist Alles-oder-nichts: In `apply_effects()` steigt das Label
sofort aus und rendert ueber `_render_own()` **ausschliesslich** aus seinen
eigenen Exportwerten. Es muessen also alle Werte am Label stehen, nicht nur der
abweichende. Und: Override-Labels folgen spaeteren Seitenaenderungen nicht mehr.

**Home — Statusanzeige laeuft bewusst mit.** Die Seite mischt zwei Dinge:
Willkommenstext (Handbuch) und Live-Statusanzeige (Spielzustand, von
`HomePanel.gd` im Sekundentakt neu gesetzt — Uhr, AKTIV/OFFLINE,
Schiffshuelle, geloeste Stoerungen). Erwogen wurde, die acht Statuslabels per
`override_page` auszunehmen, weil eine unlesbare Uhr kaputtes Spielfeedback
waere und kein Leseerlebnis.

**Entscheidung: nicht ausgenommen.** Bei den eingestellten Werten bleiben die
Statuswerte entzifferbar, und damit greift dasselbe Kriterium wie ueberall
sonst — teuer ja, unlesbar nein. Bei einer spaeteren Erhoehung der Home-Werte
waere der Punkt neu zu pruefen.

**Energie — Fehlercodes gedaempft.** Ziffern haben keine Redundanz: Mit
angefressener Flaeche wird aus einer 3 eine 8, aus einer 6 eine 8. Auf den vier
`ListTitle`-Labels deshalb `missing` auf 10 statt 25 — der Effekt kommt erst
spaet dazu und bleibt bei Stress 100 bei 0.20 statt 0.50.

| Node (unter dem `Energie`-Tab) | Code |
|---|---|
| `VBox/ScrollContainer/VBoxContainer/StepList/ListTitle` | 1281 |
| `VBox/ScrollContainer/VBoxContainer/StepList2/ListTitle` | 3854 |
| `VBox/ScrollContainer/VBoxContainer/StepList3/ListTitle` | 9418 |
| `VBox/ScrollContainer/VBoxContainer/StepList4/ListTitle` | 2458 |

Werte auf allen vier:

```
override_page     = true
phonetic_percent  = 42
missing_percent   = 10
shake_amplitude   = 3
rng_seed          = 1000 / 1001 / 1002 / 1003
```

Unterschiedliche Seeds, weil `_render_own()` den Label-eigenen `rng_seed`
benutzt statt des von `PageEffects` verteilten `base_seed + i * 97` — sonst
werden alle vier identisch ausgewuerfelt. (`StepList` laeuft ueber den
Default 1000, die anderen drei sind explizit gesetzt.)

Die Schritt-Labels `S1`–`S5` brauchen keinen Override: „Blau <-> Lila" ist
Text mit Kontext und bei `missing 25` rekonstruierbar.

---

## 3. Was sich belegen laesst

> ⚠️ **Die Literaturhinweise unten sind Ansatzpunkte fuer die Suche, keine
> gepruefte Bibliografie.** Vor dem Zitieren jede Quelle selbst nachschlagen und
> die Aussage gegen das Original pruefen. Titel und Jahreszahlen aus zweiter
> Hand zu uebernehmen ist der schnellste Weg zu einer angreifbaren Arbeit.

### 3.1 Belegbar als Befund ueber Dyslexie

Diese Effekte bilden etwas ab, das ueber dyslektisches Lesen dokumentiert ist.

| Effekt | Was belegt ist | Suchrichtung |
|---|---|---|
| `phonetic` | Die phonologische Defizithypothese ist das dominante Erklaerungsmodell: Kern des Problems ist die Zuordnung von Graphem zu Phonem, nicht die Wahrnehmung. Der Effekt erzwingt genau die langsame serielle Route | Snowling, Hulme — „Dyslexia: a cognitive developmental perspective"; Ramus zu phonologischen Repraesentationen |
| `crowd` | Zu Buchstabenabstand und Lesegeschwindigkeit bei Dyslexie gibt es direkte Evidenz — vergroesserter Abstand verbessert das Lesen betroffener Kinder. Der Effekt kehrt das um | Zorzi et al., PNAS 2012, „Extra-large letter spacing improves reading in dyslexia"; Martelli u. a. zu Crowding |

**Nur diese zwei.** Das ist wenig, aber es ist ehrlich — und `phonetic` traegt
als Konstante ohnehin die inhaltliche Hauptlast.

### 3.2 Belegbar als allgemeine Lesekosten (nicht dyslexiespezifisch)

Diese Effekte erhoehen den Leseaufwand nachweisbar, aber bei allen Lesern. Sie
modellieren keinen dyslexietypischen Befund — sie erzeugen Last mit bekannter
Wirkrichtung.

| Effekt | Was belegt ist |
|---|---|
| `rotate` | Lesekosten als Funktion des Orientierungsbereichs sind psychophysisch gut untersucht (mentale Rotation, Corballis). Gilt fuer alle Leser |
| `font` | Schriftvertrautheit und -konsistenz beeinflussen Lesegeschwindigkeit; ein Wechsel pro Wort verhindert perzeptuelles Tuning |
| `missing` | Degradierte Reize erhoehen den Erkennungsaufwand. Zusaetzlich als **Gestaltungspraezedenz** belegbar: Daniel Brittons Dyslexia-Typeface — ein Designprojekt, kein Forschungsbefund. Als solches zitieren |
| `river_spacing` | Unregelmaessige Wortabstaende stoeren die Sakkadenplanung |
| `char_size`, `size_variation` | Typografische Inkonsistenz erhoeht Verarbeitungsaufwand; schwaechere Befundlage als die uebrigen |

### 3.3 Theoretisch begruendet ueber Cognitive Load Theory

Diese Effekte haben keinen dyslexiespezifischen Anker, sind aber **nicht
unbegruendet**: Sie erzeugen extrinsische Belastung im Sinne Swellers — Last,
die aus der Darbietung entsteht und nichts zur Aufgabe beitraegt. Genau die
Kategorie, die Gestaltungsrichtlinien minimieren sollen und die das Handbuch
systematisch maximiert.

| Effekt | Verankerung | Umgekehrtes Kriterium |
|---|---|---|
| `vanish` | **Transient information effect** — ein benannter CLT-Effekt: Information verschwindet, bevor sie verarbeitet ist, und muss im Arbeitsgedaechtnis gehalten werden (Leahy & Sweller; Ayres) | WCAG 2.2.2 „Pause, Stop, Hide" |
| `tornado`, `shake` | Extraneous processing / Coherence-Prinzip: nicht aufgabenrelevante Reize binden Aufmerksamkeit und verschlechtern die Verarbeitung (Mayer; seductive details) | WCAG 2.2.2 „Pause, Stop, Hide" |
| `drift` | Dieselbe Verankerung, aber **nicht eingesetzt** — als Wahrnehmungsbericht zu plausibel (Abschnitt 2) | WCAG 2.2.2 |

Die Verankerung traegt auf **Kategorieebene**, nicht pro Parameter — es gibt
keine Studie zu kreisendem Text bei 9.5 px Radius. Fuer eine
gestaltungsorientierte Arbeit ist das die richtige Ebene: zitiert wird die
Theorie, die die Klasse der Manipulation rechtfertigt.

**Der uebergreifende Bogen:** Bei geuebten Lesern ist das Decodieren
automatisiert und kostet nahezu nichts. Alle Effekte des Handbuchs
de-automatisieren es — ein zuvor kostenloser Vorgang verbraucht damit
Arbeitsgedaechtnis, das dem Textverstaendnis fehlt. Das ist die
kognitionspsychologische Erklaerung fuer die Kernthese (Last statt
Wahrnehmung) und zugleich die Vorhersage, die `q05_kopf_frei` misst: „weniger
Kopf frei fuer den Inhalt". Theorie, Umsetzung und Messung haengen an einem
Strang.

**Was CLT nicht belegt:** dass diese Last der bei Dyslexie *aehnelt*.
`phonetic` und `crowd` haben zusaetzlich einen dyslexiespezifischen Anker
(3.1), die Effekte hier nicht. Deshalb bleiben sie getrennt gefuehrt — kein
Argument gegen ihren Einsatz, nur gegen eine Gleichsetzung.

**Zur Ehrlichkeit im Methodikteil:** Diese Effekte sind zuerst explorativ
eingesetzt und danach theoretisch eingeordnet worden — sie waren als
Godot-BBCode verfuegbar. Nachtraegliche Systematisierung ist legitim, sollte
aber nicht als Ausgangspunkt dargestellt werden. „Zunaechst explorativ,
anschliessend ueber CLT und das jeweils umgekehrte Kriterium geordnet" ist die
belastbarere Formulierung.

`pulse` gehoert der Sache nach hierher, wird aber **nicht eingesetzt**: Starke
Helligkeitswechsel zwischen etwa 3 und 50 Hz sind ein Risiko fuer
photosensitive Anfaelle (WCAG 2.3.1), und der Parameter reicht bis 5 Hz. Das
ist die eine Richtlinie, die nicht umgekehrt wird.

### 3.4 Sachlich falsch

Diese vier behaupten etwas ueber Dyslexie, das dem Forschungsstand
widerspricht. Sie erzeugen zwar Last wie alle anderen, transportieren aber
zusaetzlich eine Aussage, die die Arbeit gerade widerlegen will.

| Effekt | Warum falsch |
|---|---|
| `swap` (b↔d, p↔q) | Buchstabenverwechslungen sind bei Leseanfaengern allgemein verbreitet und **kein diagnostisches Merkmal** von Dyslexie. Die Vorstellung einer perzeptuellen Umkehrung ist widerlegt — und `q01_verdreht` fragt woertlich danach |
| `mirror` | Dieselbe Aussage, staerker |
| `scramble` | Die Vorstellung, Betroffene naehmen Buchstaben in falscher Reihenfolge wahr, ist nicht gestuetzt. Der bekannte „Cambridge"-Buchstabensalat ist Folklore und mehrfach widerlegt |
| `transpose` | Wie `scramble`, auf Silbenebene |

**Einsatz:** nicht. Implementiert lassen und in der Arbeit als bewusst nicht
eingesetzt dokumentieren — das ist selbst ein Ergebnis: Es zeigt, wie nah eine
Dyslexie-Simulation am verbreiteten Mythos gebaut ist und wie leicht sie ihn
reproduziert.

**Wichtig:** Das ist kein Sicherheitsargument, sondern ein Wahrheitsargument.
Alle vier bleiben nach der Auswahlregel aus Abschnitt 1 im Fliesstext
entzifferbar. Sie fliegen nicht raus, weil sie zu hart waeren, sondern weil sie
etwas Unzutreffendes aussagen.

---

## 4. Wie das System aufgebaut ist

```
PageEffects (pro Handbuchseite, Inspector-Werte)
        ↓ apply_effects(...)
DyslexiaLabel (pro Textfeld, kann per override_page abweichen)
        ↓ process_text(...)
DyslexiaManager (Autoload) → fertiger BBCode
        ↓
RichTextLabel + eigene RichTextEffects + Shader
```

- **`PageEffects.gd`** haengt an einer Seite und reicht dieselben Werte an alle
  `DyslexiaLabel` darunter durch (`base_seed + i * 97` pro Label).
- **`DyslexiaLabel.gd`** kann die Seitenwerte per `override_page` ueberstimmen.
  Derzeit ungenutzt — der Weg, einzelne Werte-Labels abweichend einzustellen,
  falls die statischen Effekte dort zu hoch werden.
- **`DyslexiaManager.gd`** baut den BBCode und haelt `stress`, `accessibility`
  und die gemeinsame Konfiguration.

| Globaler Schalter | Wirkung |
|---|---|
| `accessibility` | `true` = alle Effekte aus, reiner Text. Aus `dyslexia_enabled` (invertiert) |
| `stress` (0–100) | `_boost() = 1.0 + stress/100` — bei Stress 100 wirkt jeder Prozentwert doppelt |

**Stress-Kopplung** (`GameManager._apply_stress_from_health()`):

```
stress = (1 - health / max_health) * 100,  gerundet auf Stufen von 5
```

Nur waehrend `Phase.JOURNEY` und nur wenn `stress_from_health` **und**
`dyslexia_enabled` gesetzt sind. Zum Ansehen aller Stufen ohne Schaden:
`debug_stress_slider.gd` an einen Node in `MainGame.tscn` haengen.

---

## 5. Folgen fuer die Auswertung

1. **Seitenzeiten sind nicht poolbar.** Jede Seite traegt eine andere
   Kombination, anderen Text und andere Laenge (Body-Woerter: Navigation 65,
   Energie 63, Treibstoff 54, Codes 49, Schild 32).
2. **`phonetic` nutzt sich ab.** Die Umschrift ist regelbasiert und damit
   lernbar — nach zwei Seiten sind die Regeln internalisiert und die Kosten
   sinken. Inhaltlich stimmig (Betroffene entwickeln Strategien), fuer die
   Messung ein Lerngefaelle. Verstaerkt dadurch, dass die **Seitenreihenfolge
   nicht kontrolliert** ist: der Spieler oeffnet den Tab, den die aktive
   Stoerung verlangt. Seitenzeiten deshalb deskriptiv berichten.
3. **`text_schwierigstes_post` trennt die Lesarten:**
   - „konnte mich nicht konzentrieren", „musste immer wieder von vorn
     anfangen" → die Last kam als **Last** an, wie beabsichtigt
   - „die Buchstaben haben sich bewegt", „war verschwommen" → sie kam als
     **Abbildung** an
4. **`q01`/`q02` bleiben Kontrollindikator**, nicht Zielgroesse (siehe
   [Fragebogen_Auswertung.md](Fragebogen_Auswertung.md), Abschnitt 5).

---

## 6. Offene Punkte

1. **Bestueckung nach Abschnitt 2 umsetzen** und jede Seite einmal **bei Stress
   100** ansehen, nicht bei 0. Der `MISSING_MAX`-Gedanke gilt bisher nur fuer
   einen einzelnen Effekt; bei drei gleichzeitigen und doppeltem Boost liegt
   die Grenze woanders.
2. **Werte-Labels pruefen:** Codes, Mischverhaeltnisse, Frequenzwerte. Falls
   die statischen Effekte dort zu hoch stehen, per `override_page` einzeln
   herunterregeln statt die ganze Seite abzuschwaechen.
3. **Literaturhinweise aus Abschnitt 3 verifizieren**, bevor etwas davon in die
   Arbeit wandert.
4. **Begruendung in den Code nachtragen** — bei `tornado`, `shake`, `drift`
   steht bisher nur, was sie tun, nicht welches Kriterium sie umkehren.
5. **Baseline unveraendert lassen.** Der Einleitungstext im Story-Intro ist ein
   normales `RichTextLabel` ohne `PageEffects` und damit die
   Vergleichsgrundlage fuer den Prae-TLX.
