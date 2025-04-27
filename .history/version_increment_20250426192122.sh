#!/bin/bash
# version_increment.sh

# Get current version
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //')

# Increment patch version
NEW_VERSION=$(echo $VERSION | awk -F. '{$NF = $NF + 1;} 1' OFS=.)

# Update pubspec.yaml
sed -i '' "s/version: $VERSION/version: $NEW_VERSION/" pubspec.yaml

# Update build.gradle
ANDROID_VERSION_CODE=$(grep 'versionCode ' android/app/build.gradle | sed 's/.*versionCode //' | sed 's/$//')
NEW_ANDROID_VERSION_CODE=$((ANDROID_VERSION_CODE + 1))
sed -i '' "s/versionCode $ANDROID_VERSION_CODE/versionCode $NEW_ANDROID_VERSION_CODE/" android/app/build.gradle
sed -i '' "s/versionName \"$VERSION\"/versionName \"$NEW_VERSION\"/" android/app/build.gradle

echo "Updated version from $VERSION to $NEW_VERSION"