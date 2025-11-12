#!/usr/bin/env bash
set -euo pipefail

echo "=== Flutter version ==="
flutter --version

echo "=== Enable web target ==="
flutter config --enable-web

echo "=== Pub get ==="
flutter pub get

echo "=== Build web (release) ==="
# IMPORTANT: no --web-renderer flag here
flutter build web --release

echo "=== Verify output ==="
test -d build/web || { echo "❌ build/web missing"; exit 2; }
ls -la build/web | head -50
echo "✔ Build complete -> build/web"


