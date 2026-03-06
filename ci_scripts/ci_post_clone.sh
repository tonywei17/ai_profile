#!/bin/bash
set -e

echo "==> Installing XcodeGen via Homebrew..."
brew install xcodegen

echo "==> Generating Xcode project..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "==> Copying Package.resolved into generated xcodeproj..."
mkdir -p AIIDPhoto.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
cp Package.resolved AIIDPhoto.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

echo "==> Done."
