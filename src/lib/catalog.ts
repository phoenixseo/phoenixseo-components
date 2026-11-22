import fs from 'node:fs';
import path from 'node:path';

/**
 * The catalog is generated, never written by hand — see scripts/export.sh.
 * Every read goes through this module so a missing export fails in one place
 * with an instruction instead of rendering an empty page that looks finished.
 */

const GENERATED = path.join(process.cwd(), 'generated');

export interface FieldRow {
  name: string;
  label: string;
  type: string;
  required: boolean;
  level: number;
  instructions: string;
}

export interface ComponentEntry {
  type: string;
  title: string;
  description: string;
  icon: string;
  version: number;
  note: string;
  capabilities: string[];
  files: string[];
  depth: number;
  fields: FieldRow[];
  size: number;
}

export interface Catalog {
  generated: string;
  plugin: { name: string; version: string; repo: string; license: string };
  components: ComponentEntry[];
}

function read(relative: string): string {
  const file = path.join(GENERATED, relative);

  if (!fs.existsSync(file)) {
    throw new Error(
      `generated/${relative} is missing. Run "npm run export" — it renders the components inside WordPress.`
    );
  }

  return fs.readFileSync(file, 'utf8');
}

let cached: Catalog | null = null;

export function catalog(): Catalog {
  if (!cached) {
    cached = JSON.parse(read('catalog.json')) as Catalog;
  }

  return cached;
}

export function component(type: string): ComponentEntry | undefined {
  return catalog().components.find((entry) => entry.type === type);
}

/** The component's real output, exactly as the frontend prints it. */
export function preview(type: string): string {
  return read(path.join('preview', `${type}.html`));
}

/** The component's own stylesheet, empty when it ships without one. */
export function componentCss(type: string): string {
  const file = path.join(GENERATED, 'src', type, 'component.css');

  return fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
}

/** The component's source files, for the code panes. */
export function sources(type: string): { name: string; code: string }[] {
  const entry = component(type);

  if (!entry) {
    return [];
  }

  return entry.files.map((name) => ({
    name,
    code: fs.readFileSync(path.join(GENERATED, 'src', type, name), 'utf8'),
  }));
}

/**
 * Capabilities are declared in examples/<type>.json rather than derived, so a
 * component has to say what it demonstrates instead of having tags guessed
 * from its field types.
 */
export function capabilities(): { name: string; count: number }[] {
  const counts = new Map<string, number>();

  for (const entry of catalog().components) {
    for (const capability of entry.capabilities) {
      counts.set(capability, (counts.get(capability) ?? 0) + 1);
    }
  }

  return [...counts.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));
}

/** "nested-repeater" -> "Nested repeater" */
export function label(capability: string): string {
  const words = capability.replace(/-/g, ' ');

  return words.charAt(0).toUpperCase() + words.slice(1);
}
