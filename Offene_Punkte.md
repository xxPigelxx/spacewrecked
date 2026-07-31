# Offene Punkte — Gesamtstand

Stand 31.07.2026, gegen den Code geprueft. Zusammenzug aus
[Fragebogen_Uebersicht.md](Fragebogen_Uebersicht.md),
[Fragebogen_Auswertung.md](Fragebogen_Auswertung.md) und
[Handbuch_Effekte.md](Handbuch_Effekte.md).

Sortiert nach den zwei Stichtagen: was die Erhebung blockiert, und was bis zur
Abgabe fertig sein muss. Abgabe ist der **20.08.2026**.

---

## A — Vor dem ersten echten Teilnehmer

Danach sind Spaltennamen und Konfiguration eingefroren.

### A1 · Kleinigkeit: `phonetic` einmal auf 40 statt 42

Auf dem `StepList/ListTitle` der Energie-Seite (Fehlercode 1281) steht
`phonetic_percent = 40`, ueberall sonst 42. Angleichen.

### A2 · Jede Seite bei Stress 100 ansehen

Mit `debug_stress_slider` (haengt bereits in `Manual_NEU.tscn`): Regler auf
100, „Stress festhalten", jede Seite durchgehen. Der Boost verdoppelt jeden
Wert — die Auslegung zielt auf diesen Zustand, nicht auf den Ruhezustand.

Der `MISSING_MAX`-Gedanke (muehsam ja, unlesbar nein) gilt bisher nur pro
Effekt. Bei drei gleichzeitigen und doppeltem Boost liegt die Grenze woanders.

**Besonders ansehen:** die vier Fehlercodes auf Energie (landen bei 0.20
Abtrag) und die vier Codes auf der Codes-Seite. `crowd 80` ist dort der
statische Anteil, der sich nicht durch Warten aufloest — bei Stress 100 zieht
er die aeusserste Ziffer einer sechsstelligen Zahl knapp 9 px nach innen.
Laufen die Ziffern zusammen, nicht die Seite abschwaechen, sondern `V1`–`V4`
per `override_page` mit niedrigerem `crowd` versehen (gleiches Muster wie bei
den Energie-Fehlercodes).

### A3 · Zwei Textkorrekturen im Fragebogen

In `Scenes/questionear.tscn`:

| Zeile | Ist | Soll |
|---|---|---|
| 130 | `retro_nachvollziehen`: „für einen Text **laenger** braucht" | „länger" |
| 184 | `text_veraenderung`: „Vorstellung von **Dyslexie**" | „Legasthenie" — der uebrige Fragebogen sagt durchgehend Legasthenie |

### A4 · Ausschlusskriterien vorab festlegen

Nachtraeglich festgelegte Ausschluesse sind angreifbar. Vor der Erhebung
entscheiden und in der Methodik dokumentieren:

- **Story-Kontrollfragen:** Vorschlag Ausschluss bei 0 von 3 richtig, Vermerk
  bei 1 von 3
- **`demo_deutsch_l1`:** Nicht-Muttersprachler als Kovariate mitfuehren oder
  ausschliessen
- **`demo_dyslexie_selbst`:** Die FF adressiert „Personen ohne Dyslexie" —
  Betroffene getrennt berichten oder ausschliessen

### A5 · Entscheidung: Stress beim Lesen mitschreiben?

`deliver_manual_times()` sendet nur `manual_time_<tab>_s`. Der Stresswert beim
Lesen wird nirgends festgehalten — zwei Teilnehmer mit derselben Zeit auf
derselben Seite koennen sehr unterschiedlich starke Effekte gesehen haben.

Eine Zeile in der Manual-Zeitmessung macht daraus eine Kovariate. Geringes
Risiko, aber eine Aenderung an der Erhebung: **jetzt entscheiden oder gar
nicht.**

### A6 · Keypad-Rueckmeldung pruefen

Was passiert bei einem falschen Code? Gibt es eine klare Rueckmeldung, weiss
der Spieler, dass er nochmal lesen muss, und die Kosten bleiben Zeit. Passiert
nichts, kann er „ich habe mich verlesen" nicht von „falsche Tuer"
unterscheiden — dann wird aus Belastung Verwirrung.

---

## B — Vor der Abgabe

### B1 · Literaturhinweise verifizieren

Die Angaben in [Handbuch_Effekte.md](Handbuch_Effekte.md) Abschnitt 3 sind
Suchrichtungen, keine geprueften Quellen. Selbst nachschlagen, bevor etwas
davon zitiert wird. Am wichtigsten die zwei aus Kategorie 3.1
(`phonetic` → Snowling/Hulme, `crowd` → Zorzi et al. zum Buchstabenabstand),
weil die Arbeit inhaltlich darauf steht.

### B2 · Begruendung in den Code nachtragen

Bei `phonetic`, `missing`, `rotate` und `font` steht im Code, was sie
modellieren. Bei `tornado`, `shake` und `vanish` steht nur, was sie tun. Die
CLT-Verankerung und das jeweils umgekehrte WCAG-Kriterium gehoeren dorthin —
und in den Methodikteil, damit die Sammlung als System lesbar ist.

### B3 · CLAUDE.md aktualisieren

Zeile 50–51 beschreibt den Ablauf noch als „Demografie + 5 Items + 6
TLX-Slider". Es sind inzwischen **8** wiederholte Items plus 3
Story-Kontrollfragen. Zeile 74 fuehrt die TLX-Slider-Szene als offen — die
steht laengst.

### B4 · `pre_questionear` loeschen

`Scenes/pre_questionear.tscn` und `pre_questionear.gd` sind tot: `skip := true`
ueberspringt die Szene sofort, und keine andere Szene laedt sie. Der aktive
Pre-Fragebogen sitzt in `pre_flow.tscn`.

### B5 · Startup-Popup entscheiden

Die Frage „Wurde bei Ihnen Dyslexie/Legasthenie festgestellt?" im Hauptmenue
landet nur in `GameState.participant_has_dyslexia` und wird **nicht gesendet**.
Inhaltlich doppelt zu `demo_dyslexie_selbst`. Entweder raus oder in der Arbeit
als bewusst redundant erklaeren.

---

## C — Erledigt

- `q06_zeit_verstaendnis` in Pre und Post wortgleich ✓
- `q02_augen` auf AGREEMENT umgestellt ✓
- `q03_uebung` in beiden Bloecken angeglichen ✓
- `q11_vorstellen` in beide Bloecke aufgenommen ✓
- `demo_dyslexie_umfeld` auf „Legasthenie" ✓
- TLX-Node `tlx_geistig2` → `tlx_koerperlich` ✓
- Codes-Seite: Handbuchtext korrigiert ✓
- Fullscreen-Schalter im Optionen-Panel ✓
- `debug_stress_slider` gebaut und eingehaengt ✓
- Effektbestueckung vollstaendig eingetragen ✓
- Fehlercode-Overrides auf Energie gesetzt, mit verschiedenen Seeds ✓
- Home-Statusanzeige geprueft — bleibt bewusst mit Effekten, Werte sind
  entzifferbar ✓
- Alles committet ✓
