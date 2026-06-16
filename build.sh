#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable

# Add flutter to path
export PATH="$PATH:`pwd`/flutter/bin"

# Get dependencies
flutter/bin/flutter pub get

# Build the web app
flutter/bin/flutter build web --release
