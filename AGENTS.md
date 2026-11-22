---
owner: phoenixseo
typ: intern
status: live
stand: 2026-11-22
live: https://components.phoenixseo.de
repo: phoenixseo/phoenixseo-components
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
| Ort | Astro, statisch, `https://components.phoenixseo.de` |

## Deployment (2026-11-22)

Wie phoenixseo.de: **Push auf `main` → GitHub Action baut und schiebt hoch.**
Kein Handdeploy mehr, kein Zwischenrechner.

- Workflow: `.github/workflows/deploy.yml`, Job „Deploy components site to Hostinger".
- Transport: rsync über SSH (nicht FTP) — Port 65002, User `u206548916`,
  Ziel `/home/u206548916/domains/phoenixseo.de/public_html/subdomain/components.phoenixseo.de/`,
  `--delete`, ausgenommen `default.php*` und `.htaccess`.
- Secret: `SSH_KEY` (eigener Deploy-Key, lokal `~/.ssh/components-deploy`,
  Pubkey in `~/.ssh/authorized_keys` auf Hostinger). Der Key darf nur dieses Verzeichnis.
- Vor dem Upload prüft der Job den Build (Seitenzahl, `catalog.json`, ZIPs) — ein
  unvollständiger Build wird rot statt still kleiner live zu gehen.
- Nach dem Upload prüft der Job **auf dem Server** (Datei vorhanden, `index.html` enthält den
  Titel). Die HTTP-Probe läuft zusätzlich, akzeptiert aber 403: der hcdn-Bot-Filter vor der
  Subdomain beantwortet alles ohne Browser mit 403 — das ist kein Seitenfehler.
- `generated/`, `public/img/`, `public/download/` **sind committet**. Die Action kann die
  Komponenten nicht rendern (dafür braucht es WordPress), also reist das Export-Ergebnis mit.
  `dist/` bleibt ungetrackt.

Rebuild mit geänderten Komponenten: `npm run export` (lokal, wp-env) → `git commit` → `git push`.

## Regeln

- **Eine Quelle:** Der Katalog wird aus `plugin/schemas/` erzeugt. Keine Komponente, keine
  Feldliste, kein Vorschau-HTML wird hier von Hand geschrieben.
- **Vorschau ist gerendertes Plugin-Output**, kein Nachbau in HTML. Der Export läuft dort, wo
  WordPress läuft (wp-env), und friert das HTML ein.
- Neue Komponente = neues Verzeichnis im Plugin + Export + Push. Keine Liste, die jemand pflegt.
- `generated/` nie von Hand ändern — immer über `npm run export`.
- Client-Artefakte interaktiv, Kundentexte nie Text über Text — hier nicht relevant, aber
  gilt weiter für alles, was auf phoenixseo.de verlinkt.

## Aufbau

```
phoenixseo-components/
├── src/            Astro-Seite: Seiten, Layout, Styles
├── scripts/        Export: schemas/ → generated/ (preview, src, catalog.json, ZIPs)
├── examples/       Beispielinhalte pro Komponente (englisch)
├── generated/      erzeugt, committet — nicht von Hand ändern
├── public/         img/ + download/ (aus dem Export), alles andere handgepflegt
├── .github/        Deploy-Workflow
└── docs/specs/     Design-Entscheidungen
```

## Nicht vorgesehen

Einreichungen Dritter, Bewertungen, Editor im Browser, Accounts. Bewusst weggelassen, damit
der Katalog ohne Moderation wachsen kann.
