#!/usr/bin/env bash
# Build all Flutter web targets into deploy/www/ for rsync to the VPS.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/deploy/www"
mkdir -p "$OUT/ecom" "$OUT/admin" "$OUT/vendor"

build_one() {
  local dir="$1"
  local href="$2"
  local dest="$3"
  echo "=== Building $dir (base-href $href) ==="
  (cd "$ROOT/$dir" && flutter build web --release --base-href "$href")
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -R "$ROOT/$dir/build/web/." "$dest/"
}

build_one "ojas-ecom" "/" "$OUT/ecom"
build_one "ojas-admin" "/admin/" "$OUT/admin"
build_one "ojas-vendor" "/vendor/" "$OUT/vendor"

echo ""
echo "Built to: $OUT"
echo "Rsync example:"
echo "  rsync -avz $OUT/ecom/   root@72.61.172.182:/var/www/ojas/ecom/"
echo "  rsync -avz $OUT/admin/  root@72.61.172.182:/var/www/ojas/admin/"
echo "  rsync -avz $OUT/vendor/ root@72.61.172.182:/var/www/ojas/vendor/"
