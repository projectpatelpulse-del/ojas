#!/usr/bin/env bash
# Run on the VPS (Ubuntu/Debian) after cloning this repo, e.g. to /root/ojas_project
set -euo pipefail

OJAS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_ROOT="${WEB_ROOT:-/var/www/ojas}"

echo "Ojas root: $OJAS_ROOT"
echo "Web root:  $WEB_ROOT"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo) so nginx paths and apt work."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx curl git
command -v ufw >/dev/null 2>&1 && ufw allow 'Nginx HTTP' 2>/dev/null || true

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi

npm install -g pm2

BACKEND="$OJAS_ROOT/ojas_backend"
if [[ ! -f "$BACKEND/package.json" ]]; then
  echo "Missing $BACKEND — clone the full repo first."
  exit 1
fi

cd "$BACKEND"
npm ci --omit=dev

if [[ ! -f "$BACKEND/.env" ]]; then
  echo ""
  echo ">>> Create $BACKEND/.env with at least:"
  echo "    MONGO_URI=..."
  echo "    JWT_SECRET=..."
  echo "    PORT=5001"
  echo "    IMAGEKIT_PUBLIC_KEY=..."
  echo "    IMAGEKIT_PRIVATE_KEY=..."
  echo "    IMAGEKIT_URL_ENDPOINT=..."
  echo ""
  exit 1
fi

pm2 delete ojas-api 2>/dev/null || true
pm2 start "$OJAS_ROOT/deploy/ecosystem.config.cjs"
pm2 save

install -d -m 0755 "$WEB_ROOT/ecom" "$WEB_ROOT/admin" "$WEB_ROOT/vendor"

cp "$OJAS_ROOT/deploy/nginx-ojas-ip.conf" /etc/nginx/sites-available/ojas
ln -sf /etc/nginx/sites-available/ojas /etc/nginx/sites-enabled/ojas
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx

echo ""
echo "Nginx + PM2 configured. Copy Flutter web builds:"
echo "  $WEB_ROOT/ecom/    <- ojas-ecom/build/web/*"
echo "  $WEB_ROOT/admin/   <- ojas-admin/build/web/*"
echo "  $WEB_ROOT/vendor/  <- ojas-vendor/build/web/*"
echo "Or run ./deploy/build-web.sh on your dev machine and rsync deploy/www/ to $WEB_ROOT/"
echo ""
