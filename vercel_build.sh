#!/usr/bin/env bash
set -euxo pipefail
echo "=== CI MARKER: USING vercel_build.sh ==="

# Use a known Flutter channel or tag. 'stable' is safest in CI.
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_HOME="$HOME/flutter-${FLUTTER_VERSION}"
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
export PUB_CACHE="$HOME/.pub-cache"
mkdir -p "$PUB_CACHE"

flutter --version
flutter precache --web
flutter config --enable-web
flutter pub get

# Build web
flutter build web --release --pwa-strategy=none --no-tree-shake-icons

# Include legal pages in the final artifact
cp -f web/terms.html   build/web/
cp -f web/privacy.html build/web/
# (Optional) If you want a copy of vercel.json inside output:
# cp -f vercel.json build/web/

ls -lah build/web | head -n 50
echo "✔ Build complete -> build/web"