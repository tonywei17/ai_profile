#!/bin/bash
set -e

echo "==> Installing XcodeGen via Homebrew..."
# Retry up to 3 times to handle transient network failures on Xcode Cloud
for i in 1 2 3; do
    brew install xcodegen && break
    echo "==> Retry $i: brew install xcodegen failed, retrying in 5s..."
    sleep 5
done

echo "==> Generating Xcode project..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "==> Copying Package.resolved into generated xcodeproj..."
mkdir -p AIIDPhoto.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
cp Package.resolved AIIDPhoto.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

echo "==> Done."
