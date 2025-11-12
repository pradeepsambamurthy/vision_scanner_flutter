#!/usr/bin/env bash
set -euo pipefail

# Pin a known-good Flutter version for consistent CI builds
FLUTTER_VERSION=${FLUTTER_VERSION:-3.24.3}
FLUTTER_HOME="$HOME/flutter-$FLUTTER_VERSION"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

echo "Using Flutter $(flutter --version)"
flutter config --enable-web

# Dependencies & build
flutter pub get
# NOTE: do NOT pass --web-renderer; some toolchains in CI don't recognize it
flutter build web --release

echo "Build complete -> build/web"
