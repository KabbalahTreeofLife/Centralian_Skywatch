<p align="center">
  <img src="assets/icon/app_icon.png" alt="Centralian Skywatch app icon" width="160">
</p>

# Centralian Skywatch [![CI](https://github.com/KabbalahTreeofLife/Centralian_Skywatch/actions/workflows/ci.yml/badge.svg)](https://github.com/KabbalahTreeofLife/Centralian_Skywatch/actions/workflows/ci.yml) ![Flutter](https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart&logoColor=white)

Centralian Skywatch brings NASA's Astronomy Picture of the Day, upcoming
rocket launches, and live ISS tracking together in one Flutter app. Save
favorite pictures and launches, with notes that persist across restarts.

Built for **SE2142 — Software Engineering**, Final Project. See the
[project documentation](docs/PROJECT_DOCUMENTATION.md) for screenshots,
architecture, debugging notes, tests, APIs, and release instructions.

## Installation

Requirements: Flutter 3.44.9 (stable) or later and Dart 3.12.2.

```powershell
git clone https://github.com/KabbalahTreeofLife/Centralian_Skywatch.git
cd Centralian_Skywatch
Copy-Item .env.example .env
flutter pub get
```

The `.env` file is required as a bundled asset. `NASA_API_KEY` is optional; the
app uses NASA's rate-limited `DEMO_KEY` if no key is provided. See the
[NASA API](https://api.nasa.gov/) for a personal key. Values in `.env` are
bundled into the app and can be extracted, so do not put secrets in builds you
share.

## Usage

Run the app on a connected device or emulator:

```powershell
flutter run
```

Run the automated tests:

```powershell
flutter test
```

## Contributing

This is an individual course project. Bug reports and suggestions are welcome
through [GitHub Issues](https://github.com/KabbalahTreeofLife/Centralian_Skywatch/issues).
For code changes, open an issue first, then submit a pull request with relevant
tests passing.

## License

No license is currently included in this repository. Contact the maintainer
before reusing or redistributing the project.

## Contact

For questions or support, open a
[GitHub Issue](https://github.com/KabbalahTreeofLife/Centralian_Skywatch/issues)
or contact the maintainer through
[GitHub](https://github.com/KabbalahTreeOfLife).
