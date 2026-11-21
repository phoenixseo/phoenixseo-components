---
owner: phoenixseo
typ: intern
status: planung
stand: 2026-11-21
live: — (geplant: https://components.phoenixseo.de)
repo: — (geplant: phoenixseo/phoenixseo-components)
quelle: plugin/schemas/ im Repo phoenixseo/sdc-page-builder
---

# AGENTS.md — PhoenixSEO Components

## Projektwissen (WICHTIG)

Die Quelle der Wahrheit für den **Katalog** ist das Plugin-Repo, nicht diese Seite:
`workspaces/sdc-page-builder/plugin/schemas/<type>/`. Was hier liegt, ist der Generator und
die Hülle — nichts, was dort schon steht, wird hier nachgepflegt.

Projektwissen (Entscheidungen, Begründungen) liegt im Vault unter
`vault/vault_agency/projects/sdc-page-builder/`. Das Spec zu dieser Seite:
`docs/specs/2026-11-21_components-site-design.md`.

## Projekt-Kontext

Statische, englischsprachige Komponenten-Bibliothek zum PhoenixSEO Page Builder.
Zweck: frei verfügbare Komponenten zum Stöbern, Ansehen, Herunterladen — als ZIP pro
Komponente, Installation durch Entpacken nach `sdc-components/`.

Entscheidungen (2026-11-21):

| Frage | Entscheidung |
|---|---|
| Hauptaufgabe | Komponenten-Bibliothek, nicht Produktseite, kein Community-Hub |
| Installation | ZIP pro Komponente + drei Zeilen Anleitung. Kein Remote-Install. |
| Startumfang | Die 10 mitgelieferten Komponenten, danach wachsen |
| Sprache | Nur Englisch (Seite), Beispielinhalte ebenfalls englisch |
| Ort | `components.phoenixseo.de`, Astro, statisch auf dem VPS |

## Regeln

- **Eine Quelle:** Der Katalog wird aus `plugin/schemas/` erzeugt. Keine Komponente, keine
  Feldliste, kein Vorschau-HTML wird hier von Hand geschrieben.
- **Vorschau ist gerendertes Plugin-Output**, kein Nachbau in HTML. Der Export läuft dort, wo
  WordPress läuft (wp-env), und friert das HTML ein.
- Neue Komponente = neues Verzeichnis im Plugin + Build. Keine Liste, die jemand pflegt.
- Client-Artefakte interaktiv, Kundentexte nie Text über Text — hier nicht relevant, aber
  gilt weiter für alles, was auf phoenixseo.de verlinkt.

## Aufbau (geplant)

```
phoenixseo-components/
├── src/            Astro-Seite: Seiten, Layout, Styles
├── scripts/        Export: schemas/ → previews/ + catalog.json
├── previews/       erzeugt, nicht von Hand ändern
└── docs/specs/     Design-Entscheidungen
```

## Nicht vorgesehen

Einreichungen Dritter, Bewertungen, Editor im Browser, Accounts. Bewusst weggelassen, damit
der Katalog ohne Moderation wachsen kann.
