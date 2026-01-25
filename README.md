# flashlight

A new Flutter project.

## Release builds (smaller + smoother)

- Smaller APKs (one per CPU architecture):
	- `flutter build apk --release --split-per-abi`
- Recommended for store releases (Google Play will split per device automatically):
	- `flutter build appbundle --release`

Extra size hardening (optional, but common in production):

- Obfuscate Dart code (keeps stack traces via split debug info):
	- `flutter build apk --release --obfuscate --split-debug-info=build/symbols`
	- `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
