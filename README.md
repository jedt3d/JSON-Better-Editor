# JSON Better Editor

A Flutter desktop app (macOS only) for editing JSON in two switchable modes, **Text** and **Node**.
Requirements, mockups and the decision log live in [`docs/`](docs/).

## Run

Needs the Flutter SDK (stable) and Xcode.

```bash
flutter run -d macos
```

```bash
flutter analyze && flutter test
```

## Folder structure

| Path | What goes there |
|---|---|
| `lib/main.dart` | Entry point only. |
| `lib/app/` | App root widget and app-wide setup (theme, localization). |
| `lib/document/` | Pure-Dart JSON document model, no Flutter imports. |
| `lib/ui/` | Windows, toolbar, Text pane and Node pane widgets. |
| `test/` | Unit and widget tests, mirroring `lib/`. |
| `macos/` | macOS runner (Xcode project, entitlements). The only platform target. |

Folders appear when the first file for them lands.
