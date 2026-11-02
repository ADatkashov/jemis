#!/usr/bin/env bash
# Build command of the Render static site `jemis-admin` (render.yaml): Render's static build image has no Flutter,
# so the SDK is fetched once and reused from the build cache. The result is build/web (staticPublishPath).
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.8}"   # keep in sync with .github/workflows/ci.yml
SDK="${XDG_CACHE_HOME:-$HOME/.cache}/flutter-${FLUTTER_VERSION}"

if [ ! -x "$SDK/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK"
fi
export PATH="$SDK/bin:$PATH"

flutter config --no-analytics --enable-web >/dev/null
flutter pub get
flutter build web --release
