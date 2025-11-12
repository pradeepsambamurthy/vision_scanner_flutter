#!/usr/bin/env bash
set -euo pipefail

# Pin (or use 'stable')
FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.3}"
FLUTTER_HOME="$HOME/flutter-$FLUTTER_VERSION"

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -d "$FLUTTER_HOME" ]; then
    git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

echo "=== Flutter version ==="
flutter --version

echo "=== Enable web target ==="
flutter config --enable-web

echo "=== Pub get ==="
flutter pub get

echo "=== Build web (release) ==="
flutter build web --release

echo "=== Verify output ==="
test -d build/web
ls -la build/web | head -50
echo "✔ Build complete -> build/web"



