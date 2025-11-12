#!/usr/bin/env bash
set -e

# Cache dir between builds
export FLUTTER_HOME="$HOME/flutter"
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

# Warm up toolchain
flutter --version
flutter config --enable-web

# Fetch deps and build
flutter pub get
flutter build web --release --web-renderer auto

# Vercel expects the output dir to exist after build
echo "Build complete -> build/web"
