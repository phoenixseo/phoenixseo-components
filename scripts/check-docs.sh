#!/usr/bin/env bash
#
# Quality gate for the documentation section.
#
# Exit 0 only when the docs actually exist in the built site: the build ran,
# every chapter page is there with its own marker, the main navigation links
# to it, and every screenshot a page references is present in dist/.
#
# Runs the build itself, so a stale dist/ cannot pass. Intended as a /goal
# gate: `bash scripts/check-docs.sh` from the repository root.
#
set -euo pipefail

cd "$(dirname "$0")/.."

SITE_URL="${SITE_URL:-https://components.phoenixseo.de}"
fail=0
ok() { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "build"
if SITE_URL="$SITE_URL" npx astro build >/tmp/check-docs-build.log 2>&1; then
  ok "astro build"
else
  bad "astro build — see /tmp/check-docs-build.log"
  tail -20 /tmp/check-docs-build.log
  exit 1
fi

echo "chapters"
# data-doc marks the article on each page; the gate does not care what the
# page is titled, only that the chapter exists and is rendered.
for doc in index install use build reference; do
  if [ "$doc" = "index" ]; then
    page="dist/docs/index.html"
  else
    page="dist/docs/$doc/index.html"
  fi
  if [ ! -f "$page" ]; then
    bad "missing $page"
    continue
  fi
  if grep -q "data-doc=\"$doc\"" "$page"; then
    ok "$page"
  else
    bad "$page has no data-doc=\"$doc\""
  fi
done

echo "navigation"
missing_nav=0
while IFS= read -r page; do
  if ! grep -q 'href="/docs/"' "$page"; then
    bad "no Docs link in $page"
    missing_nav=1
  fi
done < <(find dist -name 'index.html' -o -name '*.html' -maxdepth 3 | sort -u)
if [ "$missing_nav" -eq 0 ]; then
  ok "every page links to /docs/"
fi

echo "images"
while IFS= read -r src; do
  if [ -f "dist${src#/}" ] || [ -f "dist${src}" ]; then
    ok "image ${src}"
  else
    bad "image ${src} referenced but not in dist/"
  fi
done < <(grep -rho 'src="/docs/[^"]*"' dist/docs | sed 's/^src="//; s/"$//' | sort -u)

if [ "$fail" -ne 0 ]; then
  echo "gate: FAILED"
  exit 1
fi

echo "gate: passed"
