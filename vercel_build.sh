#!/usr/bin/env bash
set -euo pipefail

flutter --version
flutter config --enable-web

flutter pub get
# IMPORTANT: no --web-renderer flag here
flutter build web --release

echo "✔ Build complete -> build/web"

