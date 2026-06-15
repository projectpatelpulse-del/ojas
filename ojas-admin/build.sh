#!/bin/bash

# Download Flutter
git clone https://github.com/flutter/flutter.git -b stable

# Add Flutter to path
export PATH="$PATH:`pwd`/flutter/bin"

# Check Flutter version
flutter --version

# Enable Web
flutter config --enable-web

# Get dependencies
flutter pub get

# Build Web
flutter build web --release
