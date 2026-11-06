# native_nourish

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Browser database

Chrome and Edge require the SQLite runtime files in `web/sqlite3.wasm` and
`web/sqflite_sw.js`. Both files are included in this project and must be
served alongside the Flutter web build.

If the SQLite packages are upgraded, regenerate them with:

```sh
dart run sqflite_common_ffi_web:setup --force --no-sqlite3-wasm
```

The checked-in worker was built with sqlite3 3.9.0 and uses the matching
[official sqlite3.wasm binary](https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.9.0/sqlite3.wasm).
After regenerating the worker, check its sqlite3 version in
`.dart_tool/sqflite_common_ffi_web/setup/0.4.5+4/pubspec.lock` and download
the matching binary into `web/sqlite3.wasm`. The setup utility's default
WebAssembly download is older and incompatible with this worker.

Use a stable port during development to keep the same browser database:

```sh
flutter run -d chrome --web-port 8765
```

After adding or regenerating these runtime files, stop the running app, start
it again, and reload the browser. A hot reload alone does not restart a failed
database worker.
