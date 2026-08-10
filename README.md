# hepatovita_app

A new Flutter project.

## Local AI Key Setup

Create a local file at:

config/dart_defines.local.json

Example content:

{
	"GROK_API_KEY": "your_grok_key_here"
}

Run app with local key file:

flutter run --dart-define-from-file=config/dart_defines.local.json

Build APK with local key file:

flutter build apk --dart-define-from-file=config/dart_defines.local.json

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
