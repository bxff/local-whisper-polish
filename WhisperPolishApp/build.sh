#!/bin/bash
# Build WhisperPolish.app bundle

set -e
cd "$(dirname "$0")"

APP_NAME="WhisperPolish"
APP_BUNDLE="$APP_NAME.app"

# Clean previous build
rm -rf "$APP_BUNDLE"

# Create app bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Compile Swift
swiftc -O -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" main.swift -framework Cocoa

# Copy Info.plist
cp Info.plist "$APP_BUNDLE/Contents/"

echo "Built: $APP_BUNDLE"
echo ""
echo "To install:"
echo "  cp -r $APP_BUNDLE /Applications/"
echo ""
echo "To run:"
echo "  open $APP_BUNDLE"
