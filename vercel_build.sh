#!/usr/bin/env bash
set -euxo pipefail

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release
test -d build/web




