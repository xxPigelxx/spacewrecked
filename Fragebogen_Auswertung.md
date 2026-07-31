# Fragebogen — Konstrukte und Auswertungsplan

Stand 31.07.2026, gegliedert nach den zwei Haelften der Forschungsfrage.
Exakte Wortlaute und Antwortoptionen: [Fragebogen_Uebersicht.md](Fragebogen_Uebersicht.md).

> **Forschungsfrage:** „Wie kann Dyslexie durch ein Spiel erfahrbar gemacht
> werden, um Verstaendnis und Empathie bei Personen ohne Dyslexie zu foerdern?"

Die Frage hat zwei Haelften, und die Daten teilen sich entlang derselben Naht:

| Teil der FF | Was beantwortet wird | Datenbasis |
|---|---|---|
| „Wie kann Dyslexie **erfahrbar gemacht** werden" | Gestaltungsfrage — beantwortet durch das Artefakt (systematische WCAG-Umkehrung) und den Nachweis, dass die beabsichtigte Erfahrung entstanden ist | TLX-Differenz, `q10_handbuch`, Lesezeiten, `text_schwierigstes` |
| „um **Verstaendnis und Empathie** zu foerdern" | Wirkungsfrage | q03, q04, q05, q06, q07, q11, retro-Items |

Eine „Wie kann"-Frage wird durch den Entwurf und den Nachweis der erzeugten
Erfahrung beantwortet, nicht durch signifikante Einstellungsaenderungen. Der
Gestaltungsbeitrag traegt auch dann, wenn die Likert-Differenzen klein bleiben.

**Begriffsklaerung fuer den Theorieteil:** Erhoben wird selbstberichtetes
Verstaendnis und Perspektivuebernahme, nicht Empathie im engeren
psychologischen Sinn (geteiltes affektives Miterleben). In der Auswertung
durchgaengig „Verstaendnis und Perspektivuebernahme" schreiben und einmal
begruenden, warum das die zugaengliche Operationalisierung des
Empathie-Begriffs der FF ist.

---

## 1. Erhebungslogik

Ein Durchlauf = eine Zeile im Blatt "Runs" (plus optional eine Zeile in
"ManualTimes"). Gesendet wird einmal, am Ende des Post-Fragebogens. Alle
Fragebogen-Items bekommen automatisch das Suffix `_pre` bzw. `_post` — auch
Demografie und Story-Fragen, die nur einmal vorkommen. Die Spalte heisst also
`demo_alter_pre`, nicht `demo_alter`.

| Fragetyp | Gespeichert als |
|---|---|
| Likert (5 Checkboxen) | Ganzzahl 1–5 |
| TLX-Slider | Ganzzahl 1–20 |
| Auswahl (Dropdown) | **Antworttext als String**, z. B. `"18 - 24"` — vor der Auswertung umkodieren |
| Freitext | String (kann bei `text_veraenderung` leer sein) |

---

## 2. Studiendesign — gehoert an den Anfang des Auswertungskapitels

**Ein-Gruppen-Prae-Post-Design ohne Kontrollgruppe.** Alle Teilnehmer spielen
mit `dyslexia_enabled = true`; es gibt keine Bedingung ohne Texteffekte.
Bewusste Entscheidung (Absprache mit dem Betreuer), aber sie begrenzt die
Reichweite der Aussagen:

- Verschiebungen koennen auch Testwiederholung, Reifung oder Regression zur
  Mitte sein.
- Demand-Effekte sind nicht kontrolliert — die Teilnehmer ahnen die
  erwuenschte Antwortrichtung.
- Es fehlt der Vergleichswert, wie viel sich ohne Intervention veraendert haette.

Das offen zu benennen ist staerker, als es zu umgehen. Die Validitaetschecks in
Abschnitt 3 und 7 sind der Ersatz, den das Design zulaesst.

---

## 3. Teil 1 der FF — wurde Dyslexie erfahrbar?

Hier entscheidet sich, ob die Gestaltung getan hat, was sie sollte. Ohne einen
Nachweis an dieser Stelle ist Teil 2 nicht interpretierbar: Bleiben die
Einstellungen unveraendert, weil die Erfahrung ausblieb, oder weil die
Erfahrung nicht wirkt? Das laesst sich nur hier trennen.

### 3.1 NASA-TLX (Slider 1–20, Prae und Post)

Endpunkte "sehr gering" / "sehr hoch". Bezug: Prae = Lesen des
**Einleitungstextes** (unveraendert, Baseline), Post = Lesen des
**Handbuchtextes** (mit Effekten).

| Spalte | Dimension | Rolle |
|---|---|---|
| `tlx_geistig` | Geistige Anforderung | Kernindikator — wirkt die Manipulation hier nicht, traegt nichts anderes |
| `tlx_koerperlich` | Koerperliche Anforderung | Validitaetskontrolle, siehe unten |
| `tlx_zeitlich` | Zeitliche Anforderung | Steigt vermutlich, ist aber durch den Journey-Timer konfundiert — kein sauberer Textindikator |
| `tlx_leistung` | Leistung | Endpunkte "Gut" (1) / "Schlecht" (20): hoeher = schlechter = mehr Belastung, also **gleichgerichtet mit den uebrigen Skalen. Nicht umkodieren.** |
| `tlx_anstrengung` | Anstrengung | Kernindikator |
| `tlx_frustration` | Frustration | Kernindikator; gegen `q09_frust_post` halten (Konvergenz) |

**Index:** Raw TLX (RTLX) als ungewichteter Mittelwert der sechs Dimensionen.
Gewichtung ist nicht moeglich, weil keine Paarvergleiche erhoben werden — das
so benennen ("Raw TLX, ungewichtet"), sonst wird danach gefragt.

**Validitaetscheck ueber die koerperliche Anforderung:** Die motorische
Anforderung ist in beiden Messungen praktisch gleich (lesen, klicken). Bleibt
`tlx_koerperlich` konstant, waehrend geistige Anforderung, Anstrengung und
Frustration steigen, spricht das fuer eine spezifische Wirkung der
Textmanipulation. Steigen alle sechs Dimensionen gleichmaessig, ist eher eine
allgemeine Antworttendenz am Werk. Billiger Check, aber er ersetzt ein Stueck
der fehlenden Kontrollgruppe.

**Einschraenkung:** Der Post-TLX wird nach dem Spiel erhoben. Die Instruktion
grenzt auf das Lesen des Handbuchtextes ein, aber Zeitdruck, Puzzles und
Schiffsschaden faerben ab. Die Differenz ist damit nicht rein der Texteffekt —
bei `tlx_zeitlich` am deutlichsten.

### 3.2 Manipulationscheck und Prozessdaten

| Spalte | Rolle |
|---|---|
| `q10_handbuch_post` | „Das Lesen des Handbuchs hat mich ueberfordert." — **der entscheidende Wert fuer die Interpretation eines Nullbefunds.** Niedrige Werte hier bei ausbleibender Einstellungsaenderung heissen: die Manipulation war zu schwach, nicht die Idee falsch |
| `manual_time_<tab>_s` (Blatt "ManualTimes") | Lesezeit pro Handbuchseite — **das einzige nicht selbstberichtete Mass fuer Leseaufwand.** Korreliert es mit dem TLX-Anstieg, ist das das staerkste Argument der Arbeit |
| `text_schwierigstes_post` | Qualitative Beschreibung der Erfahrung. Besonders achten auf Beschreibungen, die auf **Decodierungsaufwand** deuten ("musste jedes Wort einzeln") gegenueber solchen, die **visuelle Verzerrung** nahelegen ("verschwommen", "verschoben") — Letzteres waere ein Warnsignal fuer die Kernthese |
| `text_beeinflusst_post` | Selbstbeschreibung der Lesestrategie unter Effekt |

---

## 4. Teil 2 der FF — Verstaendnis und Perspektivuebernahme

Likert 1–5, AGREEMENT, Prae und Post wortgleich. Spalten `<name>_pre` /
`<name>_post`, ausgewertet wird die Differenz.

| Spalte | Item | Konstrukt | Erwartung | Hinweis |
|---|---|---|---|---|
| `q04_kraft` | Lesen kostet Menschen mit Legasthenie mehr Kraft als mich. | Anerkennung des erhoehten Ressourcenaufwands (Aufwandsdimension kognitiver Last) | ↑ | Zentrale Bestaetigung der Kernthese. Gegen `retro_kraft_post` halten |
| `q05_kopf_frei` | Wer mit Legasthenie liest, hat weniger Kopf frei fuer den Inhalt. | Anerkennung, dass Decodierung Kapazitaet bindet, die dem Verstaendnis fehlt (Verdraengungsdimension) | ↑ | Theoretisch das praeziseste Item der Arbeit — hier zeigt sich, ob „kognitive Last statt visueller Verzerrung" angekommen ist |
| `q03_uebung` | Mit genug Uebung waere Lesen mit Legasthenie kein Problem mehr. | **Zuschreibung an mangelnde Anstrengung** — „er strengt sich nicht genug an" ist die Gegenposition zu Verstaendnis, keine Wissensfrage | ↓ | Eines der wenigen Items, bei denen das Spiel plausibel wirken kann: man merkt am eigenen Leib, dass Anstrengung das Problem nicht loest. Umgekehrt gepolt → einzeln berichten oder vor Indexbildung umkodieren (6 − x) |
| `q06_zeit_verstaendnis` | Wenn jemand mit Legasthenie fuer einen Text laenger braucht, kann ich nachvollziehen, warum. | Nachvollziehbarkeit erhoehter Lesezeit | ↑ | **Deckeneffekt pruefen, bevor eine Nullverschiebung gedeutet wird.** Prae-Mittelwert ≥ 4,5 heisst: das Item kann die Bewegung nicht abbilden — untaugliches Item, kein ausbleibender Effekt. Wortlaut aktuell noch nicht Prae/Post-identisch, siehe Abschnitt 9 |
| `q07_vorlesen_verstaendnis` | Wenn jemand in einer Gruppe nicht laut vorlesen moechte, kann ich die Gruende nachvollziehen. | Transfer auf eine soziale Alltagssituation, **ohne Nennung der Diagnose** | ↑ | Misst, ob Verstaendnis auch ohne Label greift. Bewegt sich q06, aber nicht q07, bleibt der Effekt an die explizite Nennung gebunden |
| `q11_vorstellen` | Ich kann mir vorstellen, wie es ist, mit Legasthenie zu lesen. | Perspektivuebernahme — subjektiv verfuegbares Vorstellungsbild | ↑↑ | Erwartungsgemaess die staerkste Verschiebung, weil der Prae-Wert nicht an der Decke liegt. **Nur im Verbund deuten:** steigt es allein, waehrend q03/q06/q07 stehen bleiben, spricht das fuer gefuehltes statt begruendetes Verstehen — die Standardkritik an Behinderungssimulationen. Das ist ein eigener Befund, kein Misserfolg |

### Indexbildung

| Index | Items | Richtung |
|---|---|---|
| Verstaendnis fuer kognitive Last | q04, q05 | ↑ |
| Perspektivuebernahme | q06, q07, q11 | ↑ |
| Zuschreibung an Anstrengung | q03 (einzeln) | ↓ |

Bei zwei bis drei Items ist Cronbachs α wenig aussagekraeftig — fuer die
zweistellige Skala stattdessen die Inter-Item-Korrelation berichten.
Einzelitems **und** Indizes ausweisen: die Indizes fuer die Hypothesentests,
die Einzelitems in einer Tabelle fuer die Nachvollziehbarkeit.

---

## 5. Nebenbedingung — keine neuen Fehlvorstellungen

Diese beiden Items sind **kein Wirkungsmass.** Das Spiel belehrt nicht, es
macht Lesen anstrengend; eine Verschiebung deklarativer Ueberzeugungen in
zwanzig Minuten waere ueberraschend und schwer zu erklaeren. Erhoben werden sie
als Kontrollindikator — Simulationen von Beeintraechtigungen koennen
verbreitete Fehlvorstellungen verstaerken, und die Kernthese der Arbeit
verbietet das ausdruecklich.

| Spalte | Item | Erwartung |
|---|---|---|
| `q01_verdreht` | Menschen mit Legasthenie sehen Buchstaben verdreht. | **Konstanz.** Ein Anstieg hiesse, die Umsetzung unterlaeuft ihre eigene Kernthese — das waere der wichtigste Negativbefund der Arbeit |
| `q02_augen` | Legasthenie ist vor allem ein Problem der Augen. | Konstanz; zweiter Indikator derselben Fehlvorstellungsfamilie |

Formulierungsvorschlag fuer die Methodik:

> Da Simulationen von Beeintraechtigungen die Gefahr bergen, verbreitete
> Fehlvorstellungen zu verstaerken, wurden q01 und q02 nicht als Wirkungsmass,
> sondern als Kontrollindikator erhoben. Erwartet wird kein Rueckgang, sondern
> Konstanz; ein Anstieg waere ein Hinweis darauf, dass die Umsetzung die
> Kernthese der Arbeit unterlaeuft.

Damit ist ein Nullergebnis hier das **erwartete** Ergebnis statt eines
ausgebliebenen Effekts — und ein Anstieg bleibt trotzdem sichtbar.

---

## 6. Retrospektive Selbstauskunft (nur Post, Likert 1–5)

| Spalte | Konstrukt | Auswertung |
|---|---|---|
| `retro_nachvollziehen_post` | Selbstberichtete Veraenderung im Verstaendnis fuer erhoehte Lesezeit | Gegen die gemessene Differenz Δ`q06` halten |
| `retro_kraft_post` | Selbstberichtete Veraenderung im Bewusstsein fuer den Kraftaufwand | Gegen die gemessene Differenz Δ`q04` halten |

Menschen ueberschaetzen ihre eigene Veraenderung im Rueckblick zuverlaessig.
Hohe retrospektive Werte bei kleinen gemessenen Differenzen sind kein
Widerspruch in den Daten, sondern ein eigener, gut diskutierbarer Befund.

---

## 7. Spielerleben (nur Post, Likert 1–5)

| Spalte | Konstrukt | Auswertung |
|---|---|---|
| `q08_spass_post` | Akzeptanz / Motivation | Ein Serious Game, das keinen Spass macht, wird nicht zu Ende gespielt — relevant fuer die Uebertragbarkeit, nicht fuer die Wirkung |
| `q09_frust_post` | Frustration als Kosten der Intervention | Gegen `tlx_frustration_post` halten (Konvergenzcheck); hohe Werte relativieren einen Erfolg |

`q10_handbuch_post` steht in Abschnitt 3.2, weil es als Manipulationscheck zu
Teil 1 der FF gehoert.

`text_veraenderung_post` („Hat sich deine Vorstellung von Dyslexie durch das
Spiel veraendert?") ist **optional beantwortbar** → Selbstselektion beachten,
nur zitieren, nicht auszaehlen.

---

## 8. Stichprobe, Kontrollvariablen, Aufmerksamkeitspruefung (nur Prae)

| Spalte | Rolle |
|---|---|
| `demo_alter_pre`, `demo_geschlecht_pre` | Stichprobenbeschreibung |
| `demo_deutsch_l1_pre` | Kontrollvariable — Nicht-Muttersprachler haben unabhaengig von der Manipulation erhoehte Lesezeiten und TLX-Werte. Vorab festlegen: Kovariate oder Ausschluss |
| `demo_dyslexie_selbst_pre` | **Wichtigster Moderator.** Betroffene erleben die Simulation grundsaetzlich anders — sie brauchen keine Sensibilisierung und koennen die Darstellung als unzutreffend empfinden. Die FF adressiert ausdruecklich „Personen ohne Dyslexie", das ist also zugleich das Kriterium fuer die Zielgruppe |
| `demo_dyslexie_umfeld_pre` | Vorkontakt — bekannter Praediktor fuer Einstellungen. Wer Betroffene kennt, startet vermutlich hoeher und hat weniger Spielraum nach oben |

**Story-Kontrollfragen** `story_material_pre`, `story_planet_pre`,
`story_ausfall_pre` (richtig: Stratium, Veridian VII, Der Bordcomputer):

Sie beziehen sich auf den **Einleitungstext**, der noch unveraendert ist — also
kein Mass fuer Textverstaendnis unter Effekt, sondern eine Aufmerksamkeits- und
Lesekontrolle fuer die Baseline. Wer hier 0 von 3 richtig hat, hat den
Einleitungstext vermutlich weggeklickt; dann ist auch der Prae-TLX-Wert
wertlos und mit ihm die ganze Differenz. **Ausschlusskriterium vorab
festlegen** (Vorschlag: Ausschluss bei 0 von 3, Vermerk bei 1 von 3) und in der
Methodik nennen — nachtraeglich festgelegte Ausschluesse sind angreifbar.

---

## 9. Weitere Prozessdaten

| Spalte | Bedeutung |
|---|---|
| `journey_time_s`, `journey_limit_s` | Verbrauchte vs. verfuegbare Reisezeit |
| `total_play_time_s` | Gesamtspielzeit |
| `malfunctions_solved` | Geloeste Stoerungen — Leistungsmass |
| `died_early` | Abbruch durch Schiffsverlust; getrennt betrachten, diese Durchlaeufe haben ein anderes Erleben |
| `dyslexia_enabled`, `stress_from_health` | Konfigurationsflags. `dyslexia_enabled` ist bei allen `true` → keine Vergleichsgruppe (Abschnitt 2) |
| `timestamp_start`, `timestamp_end` | Bearbeitungsdauer, Plausibilitaetspruefung |
| `run_id`, `participant_id` | Verknuepfung der beiden Blaetter |

---

## 10. Statistischer Vorschlag

Bei einem BA-typischen N von etwa 20–40:

- **Einzelitems (ordinal):** Wilcoxon-Vorzeichen-Rang-Test fuer abhaengige
  Stichproben, Effektstaerke r = Z/√N.
- **Indizes und RTLX (Mittelwerte):** abhaengiger t-Test bei annaehernder
  Normalverteilung der Differenzen, sonst Wilcoxon. Effektstaerke Cohens d_z.
- **Primaere Hypothesen vorab festlegen**, passend zu den zwei Haelften der FF:
  - **H1 (erfahrbar gemacht):** RTLX steigt vom Einleitungstext zum
    Handbuchtext.
  - **H2 (Verstaendnis/Perspektive):** Der Index Perspektivuebernahme
    (q06, q07, q11) steigt.

  Alles Weitere ausdruecklich als explorativ berichten. Bei sechs
  Einstellungsitems plus sechs TLX-Dimensionen ist sonst mindestens ein
  „signifikantes" Ergebnis Zufall; zwei vorab festgelegte Hypothesen sind
  ehrlicher und leichter zu verteidigen als eine Alpha-Korrektur ueber ein
  Dutzend Tests.
- **Effektstaerken immer mitberichten**, nicht nur p-Werte. Bei kleinem N ist
  ein nicht signifikanter mittlerer Effekt aussagekraeftiger als ein
  signifikanter kleiner.

---

## 11. Offene Punkte

1. **`q06_zeit_verstaendnis` ist noch nicht Prae/Post-identisch.**
   `pre_flow.tscn`: „Wenn jemand **mit Legasthenie** fuer einen Text laenger
   braucht ...", `questionear.tscn`: „Wenn jemand fuer einen Text laenger
   braucht ...". Das ist der letzte offene Punkt aus der Item-Durchsicht —
   ohne Angleichung ist das Item als Prae-Post-Vergleich nicht verwertbar und
   faellt aus dem Index Perspektivuebernahme heraus.
2. **Begriff in `text_veraenderung`:** sagt „Dyslexie", der uebrige Fragebogen
   sagt durchgaengig „Legasthenie".
3. **Tippfehler in `retro_nachvollziehen`:** „laenger" statt „länger" — steht
   so im Teilnehmertext.
4. **Ausschlusskriterien vorab festlegen** (Story-Kontrollfragen,
   Muttersprache, Selbstbetroffenheit) und in der Methodik dokumentieren.
5. **Spaltennamen einfrieren.** Das Apps Script legt fehlende Spalten an,
   entfernt aber keine. Ab dem ersten echten Teilnehmer wird jede Umbenennung
   zu einer halb gefuellten Zusatzspalte.
