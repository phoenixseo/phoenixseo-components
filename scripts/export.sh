#!/usr/bin/env bash
# Build the catalog data from the plugin's own components.
#
# Runs the components inside wp-env, because the previews must be the real
# frontend output. The result lands in generated/ and is not committed: it is
# derived data, and a committed copy would keep looking plausible long after
# the plugin had moved on.
#
# Usage:  scripts/export.sh
#
# Environment:
#   PLUGIN_REPO   path to the sdc-page-builder checkout (default: sibling dir)
#   WP_ENV_CLI    wp-env CLI container (default: discovered by image label)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_REPO="${PLUGIN_REPO:-$ROOT/../sdc-page-builder}"

if [ ! -d "$PLUGIN_REPO/plugin/schemas" ]; then
	echo "Kein Plugin-Checkout unter $PLUGIN_REPO — PLUGIN_REPO setzen." >&2
	exit 2
fi

CLI="${WP_ENV_CLI:-$(docker ps --format '{{.Names}}' | grep -E 'wp-env.*-cli-1$' | head -1)}"

if [ -z "$CLI" ]; then
	echo "Kein laufender wp-env-Container gefunden. Zuerst 'npx wp-env start' im Plugin-Repo." >&2
	exit 2
fi

echo "Container: $CLI"

# The previews come from the plugin that WordPress has loaded. If that copy
# differs from the checkout, the catalog would describe a component nobody
# ships — the most expensive kind of wrong, because it looks fine.
STAGE=/tmp/sdc-catalog-export
DEST=/var/www/html/wp-content/plugins

# Ask WordPress which plugin is active instead of globbing the plugin folder:
# the test environments keep several copies of the same plugin around (baseline,
# package check), and the alphabetically first one is not the one that runs.
loaded=""
for name in $(docker exec "$CLI" wp plugin list --status=active --field=name --path=/var/www/html --allow-root); do
	candidate="$DEST/$name/includes/class-sdc-frontend.php"
	if docker exec "$CLI" test -f "$candidate"; then
		loaded="$candidate"
		break
	fi
done

if [ -z "$loaded" ]; then
	echo "Im Container ist kein Page Builder aktiv." >&2
	exit 3
fi

echo "Gerendert mit: ${loaded%%/includes/*}"

stale=0
while IFS= read -r file; do
	rel="${file#"$PLUGIN_REPO"/plugin/}"
	host_sum="$(md5sum "$file" | cut -d' ' -f1)"
	cont_sum="$(docker exec "$CLI" md5sum "${loaded%%/includes/*}/$rel" 2>/dev/null | cut -d' ' -f1 || true)"

	if [ -z "$cont_sum" ]; then
		echo "FEHLT im Container: $rel" >&2
		stale=1
	elif [ "$host_sum" != "$cont_sum" ]; then
		echo "ABWEICHUNG: $rel" >&2
		stale=1
	fi
done < <(find "$PLUGIN_REPO/plugin" -type f \( -name '*.php' -o -name '*.css' -o -name 'definition.json' \) \
	-not -path '*/node_modules/*' -not -path '*/tests/*' -not -path '*/vendor/*')

if [ "$stale" -ne 0 ]; then
	echo "Die Container-Kopie ist nicht der Checkout. test-scf/sync-dev-site.sh im Plugin-Repo laufen lassen." >&2
	exit 4
fi

# Stage: this repo's examples and the exporter, so the container needs no
# knowledge of this checkout.
docker exec "$CLI" sh -lc "rm -rf $STAGE && mkdir -p $STAGE/out"
tar -C "$ROOT" -cf - examples scripts/export-catalog.php | docker exec -i "$CLI" sh -lc "tar -C $STAGE -xf -"

docker exec "$CLI" wp eval-file \
	"$STAGE/scripts/export-catalog.php" "$STAGE/examples" "$STAGE/out" \
	--path=/var/www/html --allow-root

# Collect: replace generated/ wholesale, so a removed component leaves no
# orphaned preview behind.
rm -rf "$ROOT/generated"
docker exec "$CLI" tar -C /tmp -cf - "$(basename "$STAGE")/out" | tar -C "$ROOT" -xf -
mv "$ROOT/sdc-catalog-export/out" "$ROOT/generated"
rmdir "$ROOT/sdc-catalog-export"

# Example images stay in the plugin repo (they are the demo page's photographs)
# and are served from the site root, so the previews' paths work unchanged.
mkdir -p "$ROOT/generated/img"
cp "$PLUGIN_REPO"/preview/img/*.jpg "$ROOT/generated/img/"

# Static assets Astro serves verbatim: the images the previews reference, and
# one ZIP per component. Zip names are the component type, so the install
# instruction on every page can be the same three lines.
mkdir -p "$ROOT/public/img" "$ROOT/public/download"
cp "$ROOT"/generated/img/*.jpg "$ROOT/public/img/"

python3 - "$ROOT" <<'PY'
import json, os, sys, zipfile

root = sys.argv[1]
catalog = json.load(open(os.path.join(root, 'generated', 'catalog.json'), encoding='utf-8'))
out = os.path.join(root, 'public', 'download')

# Deterministic archives: fixed timestamps and sorted entries, so a rebuild that
# changed nothing produces a byte-identical ZIP instead of a new hash.
for entry in catalog['components']:
    src = os.path.join(root, 'generated', 'src', entry['type'])
    target = os.path.join(out, f"{entry['type']}.zip")
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in sorted(os.listdir(src)):
            info = zipfile.ZipInfo(f"{entry['type']}/{name}", date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            with open(os.path.join(src, name), 'rb') as handle:
                archive.writestr(info, handle.read())
print(f"  {len(catalog['components'])} ZIPs -> public/download/")
PY

echo
echo "generated/: $(find "$ROOT/generated" -type f | wc -l) Dateien"
