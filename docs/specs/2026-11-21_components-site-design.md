# PhoenixSEO Components — Entwurf

Stand: 2026-11-21 · Status: vom Nutzer freigegeben (Gespräch vom 2026-11-21)

## Zweck

Eine frei verfügbare Komponenten-Bibliothek für den PhoenixSEO Page Builder. Besucher stöbern,
sehen die echte Ausgabe einer Komponente, laden sie als ZIP und entpacken sie nach
`sdc-components/`. Das Plugin ist die Laufzeit, die Seite ist der Katalog.

Nicht Teil davon: Produktseite mit Verkaufsabsicht, Community-Einreichungen, Bewertungen.

## Entscheidungen

| Frage | Entscheidung | Warum |
|---|---|---|
| Hauptaufgabe | Komponenten-Bibliothek | Katalog ist das Produkt; bestimmt Aufbau und Pflegeaufwand |
| Installation | ZIP pro Komponente + drei Zeilen Anleitung | Funktioniert mit dem Plugin heute, kein Remote-Install; hält den WordPress.org-Review sauber |
| Startumfang | 10 mitgelieferte Komponenten, danach wachsen | Schnell live; Zuwachs muss auf der Seite sichtbar sein, sonst wirkt sie leer |
| Sprache | Nur Englisch | Reichweite; deckt sich mit Repo-Beschreibung und readme.txt |
| Ort | Astro, statisch — **Host offen, keine Subdomain** (Nutzerentscheidung 2026-11-21) | Build erzeugt reines `dist/`, Ablage später ohne Umbau |

## Seiten

| Pfad | Inhalt |
|---|---|
| `/` | Was die Bibliothek ist, was SDC heißt, Einstieg: 10 Komponenten, Plugin installieren |
| `/components/` | Raster mit Mini-Vorschau, Filter nach Fähigkeit (Repeater, verschachtelt, berechnete Werte, nur CSS), Suche |
| `/components/<type>/` | Echte Vorschau, ZIP-Download, drei Zeilen Installation, Feldtabelle aus `definition.json`, die drei Dateien zum Lesen und Kopieren, Lizenzhinweis GPLv2+ |
| `/format/` | Wie man eine eigene Komponente schreibt: Verzeichnis, `definition.json`-Schlüssel, `render.php`, Fallback-Markup |
| `/catalog.json` | Maschinenlesbarer Index aller Komponenten; Anschluss für einen späteren Ein-Klick-Install im WP-Admin |

## Wie der Katalog entsteht

```
plugin/schemas/<type>/  →  Export (auf dem Dev-WP)  →  previews/<type>.html + .css + meta.json
                                                    →  Astro-Build  →  statisch
```

- **Eine Quelle:** nur `plugin/schemas/` im Plugin-Repo. Keine Feldliste, kein Vorschau-HTML
  von Hand auf der Seite — sonst veralten Downloads unbemerkt.
- **Echte Vorschau:** `render.php` läuft in wp-env, der Export schreibt das gerenderte HTML
  mit der Komponenten-CSS heraus. Die Seite bettet nur ein.
- **Anschluss:** `test-scf/screenshots.py` fotografiert die Komponenten bereits über stabile
  Klassen (`sdc-hero`, `sdc-vinyl`, …). Dieses Skript wird um eine HTML-Ausgabe erweitert,
  nicht ersetzt.
- **Zwei Repos im CI ausgecheckt:** `phoenixseo/phoenixseo-components` (Seite) und
  `phoenixseo/sdc-page-builder` (Quelle). Kein Submodule, damit das Plugin-Repo schlank bleibt.
- Neue Komponente = ein Verzeichnis im Plugin + Build. Keine Liste, die jemand pflegt.

## Reihenfolge

1. Export-Skript erweitern: Vorschau-HTML, Komponenten-CSS, `catalog.json`
2. Englische Beispielinhalte für die zehn Komponenten (die Demo-Seed-Daten sind heute deutsch)
3. Astro-Seite: drei Templates, Design, Build
4. VPS-Deploy, Rebuild bei Plugin-Release

## Offen

- Host offen — keine eigene Subdomain. `dist/` ist statisch und überall ablegbar.
- Ob die Startseite auf die Bibliothek oder auf das Plugin verlinkt, sobald ein Komponenten-
  Detail-Link geteilt wird (Canonical, siehe `seo-canonical-anticannibalization`)
- Rebuild-Trigger: manuell zum Release oder per CI auf Tag im Plugin-Repo
