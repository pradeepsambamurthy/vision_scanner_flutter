#!/usr/bin/env bash
set -euxo pipefail
echo "=== CI MARKER: USING ci_build.sh ==="

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release

echo "=== CI MARKER: BUILD DONE, LISTING build/web ==="
ls -la build/web | head -50





