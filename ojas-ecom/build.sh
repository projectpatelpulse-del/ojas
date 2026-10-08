#!/bin/bash

# 1. Clone Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Enable Web support
flutter config --enable-web

# 4. Get dependencies
flutter pub get

# 5. Generate fresh sitemap with dynamic products
if command -v node >/dev/null 2>&1; then
  node scripts/generate-sitemap.js || true
fi

# 6. Build the web app
flutter build web --release --base-href /

# Ensure static sitemap and robots are present in build output
cp web/robots.txt build/web/robots.txt 2>/dev/null || true
cp web/sitemap.xml build/web/sitemap.xml 2>/dev/null || true

