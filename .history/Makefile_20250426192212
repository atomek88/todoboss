.PHONY: clean build-ios build-android deploy-ios deploy-android bump-version

clean:
	flutter clean

build-ios:
	flutter build ios --release

build-android:
	flutter build appbundle --release

deploy-ios: build-ios
	cd ios && fastlane release

deploy-android: build-android
	cd android && fastlane release

bump-version:
	./scripts/version_increment.sh

release: bump-version
	git add pubspec.yaml android/app/build.gradle ios/Runner/Info.plist
	git commit -m "Bump version to $$(grep 'version:' pubspec.yaml | sed 's/version: //')"
	git tag -a "v$$(grep 'version:' pubspec.yaml | sed 's/version: //')" -m "Release v$$(grep 'version:' pubspec.yaml | sed 's/version: //')"
	git push origin main --tags