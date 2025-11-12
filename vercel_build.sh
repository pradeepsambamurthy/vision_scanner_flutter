#!/usr/bin/env bash
set -euxo pipefail
echo "=== CI MARKER: USING vercel_build.sh ==="

# Pin Flutter (or set FLUTTER_VERSION in Vercel env)
FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.3}"
FLUTTER_HOME="$HOME/flutter-$FLUTTER_VERSION"
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release

echo "=== build/web ==="
ls -la build/web | head -50





