#!/usr/bin/env bash
set -euo pipefail

# Use the flutter that Vercel just cloned (/vercel/flutter/bin on PATH)
flutter --version
flutter config --enable-web

flutter pub get
flutter build web --release

echo "✔ Build complete -> build/web"
