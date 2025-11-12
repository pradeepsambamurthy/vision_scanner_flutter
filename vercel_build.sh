#!/usr/bin/env bash
set -euo pipefail

# Pin version (optional)
FLUTTER_VERSION=${FLUTTER_VERSION:-3.24.3}
FLUTTER_HOME="$HOME/flutter-$FLUTTER_VERSION"
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release

