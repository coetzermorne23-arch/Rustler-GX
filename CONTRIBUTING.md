# Contributing to Rustler GX

Thanks for your interest in Rustler GX.

The project is under active development and parts of the architecture may change quickly.

## Useful contributions

Contributions are especially useful in these areas:

- Flutter/Dart
- Android/Kotlin
- Bluetooth Low Energy
- OBD-II and CAN research
- Victron protocol research
- Offline maps/navigation
- ESP32 integrations
- Testing on different Android head units
- Testing with real camping/off-grid hardware
- Documentation

## Before opening a pull request

1. Open or reference an issue describing the problem or feature.
2. Keep changes focused.
3. Do not invent undocumented protocol values or vehicle thresholds.
4. Preserve local-first operation where practical.
5. Run formatting and analysis.

```bash
dart format lib
flutter analyze
```

For Android changes, build/test the Android target when possible.

## Vehicle and protocol data

Do not submit guessed manufacturer-specific PIDs, warning thresholds, register meanings or protocol fields as facts.

Where possible, include a source, hardware observation or reproducible test procedure.

## Safety-critical changes

Changes affecting vehicle warnings, navigation, relays or other potentially safety-relevant behaviour require extra care.

Rustler GX must fail clearly when data is unavailable rather than displaying invented or stale values as live data.

## Code style

Prefer:

- Complete, readable implementations
- Small services with clear responsibilities
- Shared device/entity models
- Null/unavailable values instead of fake defaults
- Local operation over unnecessary cloud dependencies

## License

By contributing code to this repository, you agree that your contribution may be distributed under the repository's GNU GPL v3.0 license.
