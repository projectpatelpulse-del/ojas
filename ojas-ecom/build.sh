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

# 5. Build the web app
flutter build web --release --base-href /
