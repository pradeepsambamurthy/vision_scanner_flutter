#!/usr/bin/env bash
set -euxo pipefail
echo "=== CI MARKER: USING vercel_build.sh ==="

# 0) Ensure we’re in the dir that has pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
  # Try to locate the first pubspec.yaml in the repo and cd into it
  APP_DIR="$(git ls-files | grep -E '(^|/)(pubspec\.yaml)$' | head -n1 | xargs -r dirname)"
  if [ -z "${APP_DIR:-}" ] || [ ! -f "$APP_DIR/pubspec.yaml" ]; then
    echo "❌ Could not find pubspec.yaml. Set Vercel Root Directory to the folder with pubspec.yaml." >&2
    exit 2
  fi
  cd "$APP_DIR"
  echo "=== Changed directory to: $(pwd) ==="
fi

# 1) Bootstrap Flutter (pin or set FLUTTER_VERSION in Vercel env)
FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.3}"
FLUTTER_HOME="/vercel/flutter-${FLUTTER_VERSION}"
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
export PUB_CACHE="/vercel/.pub-cache"
mkdir -p "$PUB_CACHE"

# 2) Tooling & web target
echo "=== Flutter version ==="
flutter --version
echo "=== Precache web artifacts ==="
flutter precache --web
echo "=== Enable web target ==="
flutter config --enable-web

# 3) Dependencies + build
echo "=== Pub get ==="
flutter pub get

echo "=== Build web (release) ==="
# IMPORTANT: no --web-renderer used anywhere
flutter build web --release

# 4) Verify artifact for Vercel
echo "=== build/web (top 50) ==="
ls -la build/web | head -50
echo "✔ Build complete -> build/web"







