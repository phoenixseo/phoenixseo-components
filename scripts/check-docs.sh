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

echo "home page"
# The start page has to answer the cost question itself, not only the docs.
# These are literal checks on purpose: the gate fails when the sentence is
# removed, it does not try to judge prose.
home="dist/index.html"
if [ ! -f "$home" ]; then
  bad "missing $home"
else
  ok "$home"
  if grep -q 'id="free"' "$home"; then
    ok 'section #free'
  else
    bad 'no section id="free" on the start page'
  fi
  if grep -q 'href="#free"' "$home"; then
    ok 'a link jumps to #free'
  else
    bad 'nothing on the start page links to #free'
  fi
  if grep -q 'GPL-2.0-or-later' "$home"; then
    ok 'licence named'
  else
    bad 'licence GPL-2.0-or-later not named on the start page'
  fi
  # "free edition is enough" is the claim the page makes about ACF; both
  # halves have to survive an edit.
  if grep -qi 'free edition is enough' "$home"; then
    ok 'free edition of the field plugin named as sufficient'
  else
    bad 'start page does not say that the free edition of the field plugin is enough'
  fi
  if grep -qi 'no account' "$home"; then
    ok 'no account'
  else
    bad 'start page does not say there is no account'
  fi
  # The size of the library is not an argument: it grows, and anyone can add
  # to it. A count in the hero reads as a limit, so the page must not make one.
  if grep -qE '[0-9]+ (page )?components' "$home"; then
    bad "start page states a component count: $(grep -oE '[0-9]+ (page )?components' "$home" | head -1)"
  else
    ok 'no component count on the start page'
  fi
fi

echo "docs: no bare 'ACF or SCF'"
# A chapter that offers the two hosts as a choice has to say that the free
# edition is enough, otherwise the start page and the manual contradict each
# other. Pages that name ACF only in passing (field types, JSON output) are
# not part of that rule, so the trigger is the pair ACF + Secure Custom Fields.
docs_pair=0
while IFS= read -r page; do
  if ! grep -qi 'ACF' "$page" || ! grep -qi 'Secure Custom Fields' "$page"; then
    continue
  fi
  docs_pair=$((docs_pair + 1))
  if grep -qiE 'free edition|free version|free for this|free of charge' "$page"; then
    ok "$page names the free edition"
  else
    bad "$page offers ACF and Secure Custom Fields without saying that the free edition is enough"
  fi
done < <(find dist/docs -name 'index.html' | sort)
if [ "$docs_pair" -lt 2 ]; then
  bad "only $docs_pair chapter(s) offer both hosts — expected the install page and the overview"
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
