# Spacewrecked 🚀

A 2D top-down serious game about dyslexia, made for my Bachelor's thesis at HAW Hamburg.

You play Astro, an astronaut on the way home with a resource that could save your planet. A meteor shower damages your ship, and now you have to repair it, using the ship's manual. The catch: the text you rely on is altered by visual effects inspired by dyslexia, so reading becomes real work.

**▶ Play in your browser:** [pigel.itch.io/spacewrecked](https://pigel.itch.io/spacewrecked)

*The game is currently in German. Playtime is about 15–20 minutes.*

## About the project

The thesis *"Dyslexie erfahrbar machen: Entwicklung eines Serious Games zur Sensibilisierung nicht-betroffener Personen"* looks at whether a game can make the cognitive load of dyslexia tangible for people who don't have it.

The game does **not** claim to show how people with dyslexia actually see text. The effects are meant to make reading harder in a way players can feel, as a starting point for understanding and empathy.

## Features

- **Repair gameplay**: walk around the ship, find malfunctions and fix them with the help of an in-game manual
- **Dyslexia-inspired text effects**:
  - per-character rotation of letters
  - a shader based on Daniel Britton's "Dyslexia" typeface, which erases random parts of each glyph
- **Slide-in manual**: an in-game handbook with tabs, which players need to solve the repairs
- **Built-in study**: after the game, players fill out a questionnaire (NASA-TLX plus custom questions)
- **Telemetry**: task times, manual reading times and questionnaire answers are sent anonymously to a Google Sheet via Google Apps Script

## Demovideo

[![Watch the video](https://img.youtube.com/vi/8DfruPnB4s8/maxresdefault.jpg)](https://www.youtube.com/watch?v=8DfruPnB4s8)

## Screenshots

<table>
  <tr>
    <td align="center" width="50%">
      <img src="https://github.com/user-attachments/assets/7a8f03e7-fc0b-4e27-ab50-fcfdb6d53da3" alt="Treibstoff" width="100%"><br>
      <sub><b>Treibstoff</b></sub>
    </td>
    <td align="center" width="50%">
      <img src="https://github.com/user-attachments/assets/34fc5c13-7199-4978-a6ec-5fe375df91e8" alt="Schild" width="100%"><br>
      <sub><b>Schild</b></sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/8fcbf435-7497-4455-a94b-b157460e4cb9" alt="UI in der Reisephase" width="100%"><br>
      <sub><b>Reisephase</b></sub>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/2e2359e3-172e-4ca2-bdab-eaaa319cdfc7" alt="Gameplay" width="100%"><br>
      <sub><b>Gameplay</b></sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/604f1a4b-ddc6-4daa-99bc-4f2cbf8ef0a3" alt="Sicherungskasten" width="100%"><br>
      <sub><b>Sicherungskasten</b></sub>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/213b3414-c111-43bd-a309-862ecc21e0f6" alt="Navigation" width="100%"><br>
      <sub><b>Navigation</b></sub>
    </td>
  </tr>
</table>

### Effekte

<p align="center">
  <img src="https://github.com/user-attachments/assets/f4b9708e-8828-4699-bd85-941f7d2f278a" alt="Übersicht der Effekte" width="600">
</p>
## Tech stack

| Part      | Tech |
|-----------|------|
| Engine    | Godot 4.6, GDScript |
| Effects   | canvas_item shader, RichTextLabel per-character transforms |
| Data      | Google Apps Script → Google Sheets (tabs: Runs, Tasks, Questionnaire) |
| Platforms | Web (HTML5, hosted on itch.io), Windows |

## Architecture

Core systems are Godot autoloads:

| Autoload           | Purpose |
|--------------------|---------|
| `GameState`        | Global game and run state |
| `DyslexiaManager`  | Controls the text effects |
| `ResultsExporter`  | Collects telemetry and questionnaire data and sends it to the backend |
| `SceneSwitcher`    | Scene transitions |

The questionnaire uses a `Question` base class with subclasses for rating, checkbox, text and multiple-choice questions.

## Getting started

### Requirements

- [Godot 4.6](https://godotengine.org/download)

### Run the game

1. Clone the repo
2. Open `project.godot` in Godot
3. Press **F5**

<!-- If the Apps Script URL is set somewhere specific (e.g. in ResultsExporter), mention it here, so people running their own copy don't send data to your sheet -->

## Data & privacy

All data is collected anonymously. Only gameplay telemetry and questionnaire answers are sent; no personal data is stored. The study for the thesis ran until 14 August 2026.

## Credits

Developed by [Nikolai](https://github.com/xxPigelxx) as part of a Bachelor's thesis in Media Systems at HAW Hamburg.

Sound and asset licenses are listed in the in-game credits.
