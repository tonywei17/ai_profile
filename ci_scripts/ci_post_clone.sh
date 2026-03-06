#!/bin/bash
set -e

echo "==> Installing XcodeGen via Homebrew..."
brew install xcodegen

echo "==> Generating Xcode project..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "==> Resolving SPM dependencies..."
xcodebuild -resolvePackageDependencies -project AIIDPhoto.xcodeproj -scheme AIIDPhoto

echo "==> Done."
