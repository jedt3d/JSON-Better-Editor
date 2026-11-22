# JSON Better Editor

A Flutter desktop app (macOS only) for editing JSON in two switchable modes, **Text** and **Node**.
Requirements, mockups and the decision log live in [`docs/`](docs/).

## Run

Needs Flutter 3.50.1 or later (stable) and Xcode 27. Flutter 3.41 cannot make Release builds with Xcode 27.

```bash
flutter run -d macos
```

```bash
flutter analyze && flutter test
```

## Check everything

```bash
./scripts/check.sh
```

Runs, in order, and stops at the first failure with a non-zero exit: `flutter pub get`,
`flutter analyze`, `flutter test`, `flutter build macos --debug`, then the launch smoke test
`flutter test integration_test -d macos` (starts the real app). Prints `PASS` or `FAIL: <step>`.

Needs a Mac with the Flutter SDK (stable), Xcode, and CocoaPods (`integration_test` is a
native plugin). There is no GitHub Actions CI; this script is the build check (decision #34).

## Folder structure

| Path | What goes there |
|---|---|
| `lib/main.dart` | Entry point only. |
| `lib/app/` | App root widget and app-wide setup (theme, localization). |
| `lib/document/` | Pure-Dart JSON document model, no Flutter imports. |
| `lib/ui/` | Windows, toolbar, Text pane and Node pane widgets. |
| `test/` | Unit and widget tests, mirroring `lib/`. |
| `integration_test/` | Tests that launch the real macOS app. |
| `scripts/` | Local build-and-test scripts. |
| `macos/` | macOS runner (Xcode project, entitlements). The only platform target. |

Folders appear when the first file for them lands.
