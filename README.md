# Centralian Skywatch

[![CI](https://github.com/KabbalahTreeofLife/Centralian_Skywatch/actions/workflows/ci.yml/badge.svg)](https://github.com/KabbalahTreeofLife/Centralian_Skywatch/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart&logoColor=white)

Centralian Skywatch brings today's astronomy picture, upcoming rocket launches
and live ISS tracking together in one Flutter app, with a favourites list that
survives a restart.

Built for **SE2142 — Software Engineering**, Final Project.

## Requirements at a glance

| Requirement | How it is met |
| --- | --- |
| At least 4 screens | 5 content screens plus a 404 route: Home, Launches, Launch detail, ISS, Favorites, NotFound. |
| Screenshots | Main screens and key UI states, plus the GitHub Issues page: [Screens](#screens). |
| Navigation, with data passed between screens | Named routes. The selected `Launch` is passed as route arguments and read back from `ModalRoute.settings.arguments`. |
| State management | `provider`, one `ChangeNotifier` per data source, over a shared `LoadableProvider` holding an explicit `LoadStatus`. |
| CRUD | Favorites: create (save), read (list), update (note), delete (remove). |
| Local persistence | `shared_preferences`; favourites survive a restart. |
| Form validation | Note form rejects an empty note and caps input at 200 characters. |
| REST API integration | Three live APIs: NASA APOD, Launch Library 2, Where the ISS at? See [Data sources](#data-sources). |
| Loading, error and empty handling | Three shared widgets used on three screens each. Offline is named separately from a generic failure. |
| Reusable widgets on more than one screen | `LoadingView`, `ErrorRetryView` and `EmptyStateView` — three, each on Home, Launches and ISS or Favorites. `LaunchImage` is also shared by the launch card and the detail header. |
| Themed, custom UI | Material 3, fidelity scheme, bundled Inter and Space Grotesk variable fonts. |
| Automated tests | 227 tests across 27 files. |
| Static analysis and formatting | `flutter analyze --fatal-infos` clean; `dart format` clean. |
| Continuous integration | Three gates on every pull request; `main` is protected. |
| Version control workflow | Feature branches merged through pull requests: 27 merged, 4 carrying review comments. |
| Issue tracking | GitHub Issues, each branch and pull request linked to the issue it closes. |
| DevTools / stack-trace debugging | Documented below: [Debugging case](#debugging-case). |
| Release preparation | Release APK build steps: [Release build](#release-build). |

## Features

- **Today's picture** — NASA's Astronomy Picture of the Day, with title, date,
  explanation and credit. Video entries degrade to a link rather than a broken
  image.
- **Launch countdowns** — upcoming launches with a live `T-HH:MM:SS` countdown
  that ticks to T-0, then switches to the scheduled time.
- **Launch detail** — agency, pad, mission type and status in one view.
- **ISS tracker** — the station's position on a map with latitude, longitude,
  altitude and velocity, auto-refreshing every 15 seconds.
- **Favorites** — save any picture or launch, attach a note of up to 200
  characters, persisted across restarts.
- **Failure states that name the cause** — offline, timeout, rate limit and
  server errors each show a readable message and a way to retry.

## Screens

| Home | Launches | Launch detail |
| :---: | :---: | :---: |
| <img src="docs/screenshots/01-home.png" width="240" alt="Home screen showing the astronomy picture of the day"> | <img src="docs/screenshots/02-launches.png" width="240" alt="Launches list with countdowns"> | <img src="docs/screenshots/03-launch-detail.png" width="240" alt="Launch detail with agency, pad and status"> |

| ISS tracker | Favorites |
| :---: | :---: |
| <img src="docs/screenshots/04-iss.png" width="240" alt="ISS position on a map with live readouts"> | <img src="docs/screenshots/05-favorites.png" width="240" alt="Saved pictures and launches"> |

### Key states and project tracking

| Home loading | Home error | Empty favorites |
| :---: | :---: | :---: |
| <img src="docs/screenshots/06-home-loading.png" width="240" alt="Home screen while the astronomy picture is loading"> | <img src="docs/screenshots/07-home-error.png" width="240" alt="Home screen showing a timeout error and Retry button"> | <img src="docs/screenshots/08-favorites-empty.png" width="240" alt="Favorites screen empty state"> |

| Favorite note dialog | GitHub Issues |
| :---: | :---: |
| <img src="docs/screenshots/09-note-dialog.png" width="240" alt="Dialog for adding a note to a favorite"> | <img src="docs/screenshots/10-github-issues.png" width="800" alt="GitHub Issues page showing open and closed project issues"> |

## Getting started

**Requirements:** Flutter 3.44.9 (stable) or later, and Dart 3.12.2.

```powershell
git clone https://github.com/KabbalahTreeofLife/Centralian_Skywatch.git
cd Centralian_Skywatch
Copy-Item .env.example .env     # required: pubspec.yaml bundles it as an asset
flutter pub get
flutter run
```

`.env` is gitignored, so no key is committed. The file has to exist or the
build fails on the missing asset, but what is in it is optional: the copied
placeholder uses NASA's `DEMO_KEY`, and the app also falls back to that key if
the value is blank. Anything in `.env` is bundled into the app, so a key placed
there can be extracted from a build you share.

| Variable | Required | Purpose |
| --- | --- | --- |
| `NASA_API_KEY` | No | Key for the NASA APOD API. Falls back to `DEMO_KEY`. |

`DEMO_KEY` works without signing up but is heavily rate-limited (30 requests per
hour, 50 per day per IP), so a personal key from
<https://api.nasa.gov/> is recommended for demos. A free key is available at the
same address.

## Packages used

| Package | Version | Used for |
| --- | --- | --- |
| `provider` | ^6.1.5+1 | ChangeNotifier state, injected above the route stack |
| `http` | ^1.6.0 | All REST calls, through a single `ApiClient` |
| `flutter_dotenv` | ^6.0.1 | Reading `NASA_API_KEY` from the untracked `.env` |
| `shared_preferences` | ^2.5.6 | Persisting favourites and their notes |
| `cached_network_image` | ^3.4.1 | APOD and launch images, with disk cache |
| `flutter_map` | ^8.3.2 | The ISS map |
| `latlong2` | ^0.10.1 | `LatLng` values for `flutter_map` |
| `url_launcher` | ^6.3.3 | Opening APOD video entries and source links |

Dev tooling: `flutter_lints`, `flutter_launcher_icons` and `flutter_native_splash`,
configured to generate the Android and iOS launcher icons and Android splash from
`assets/icon/app_icon.png`.

## Architecture

```
screens/     one screen per route, owns layout only
widgets/     reusable UI, including the three shared state views
providers/   ChangeNotifier state, one per data source
services/    HTTP and JSON, one per API
models/      immutable value types with fromJson/toJson
theme/       Material 3 theme and type scale
routes/      route names and the router
```

### State, in one arc

```
ApiClient -> Service -> Provider -> Screen -> shared state widgets
```

`ApiClient` owns retries and error mapping. Each service turns one API's JSON
into a model and nothing else. Each provider is a `ChangeNotifier` holding a
`LoadStatus` (`idle`, `loading`, `success`, `error`) plus either data or an
`ApiException`. Screens only choose which widget to show for a status, which is
why loading, error and empty look the same everywhere.

### Networking

Three attempts for timeouts and 5xx, `Retry-After` honoured on 429, and no retry
for 4xx — a bad request fails the same way twice. Every failure becomes a case
of a sealed `ApiException`, so no screen ever renders a raw exception string.

### Design system

Material 3 with a fidelity scheme seeded from `#5B6CFF`, a 20px card radius, and
component themes so screens do not restyle controls individually. Inter for body
text and Space Grotesk for display, both bundled as variable fonts so every
weight comes from a single asset and nothing is fetched at runtime.

## Testing

227 tests across 27 files. `flutter test`.

Unit tests cover models and JSON parsing, `ApiClient` retry and error mapping,
and each provider's load, retry and caching behaviour. HTTP tests use
`MockClient` to cover success, non-retried 4xx responses, retried 5xx
responses, request timeouts, and `SocketException` mapping without live network
calls. Home widget tests cover the pending-request loading indicator, loaded
APOD content, and error/retry behavior. Widget tests also cover the other
screens' loading, error, empty, and offline states. A navigation test walks the
tabs and confirms tab state is preserved.

Latest verification for issue #13: `flutter test` passed all 227 tests;
`flutter analyze --fatal-infos` reported no issues; and
`dart format --output=none --set-exit-if-changed .` completed with no files
changed.

## Continuous integration

Every pull request and every push to `main` runs three gates:

```yaml
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

`main` is protected: the check must pass before a pull request can merge.

## Debugging case

![Chrome DevTools showing the ISS map camera-constraint assertion](docs/screenshots/debugging-iss-camera-constraint.png)

While testing the ISS tracker in Chrome's mobile device emulation, the console
reported `MapCamera is no longer within the cameraConstraint after an option
change.` The stack led from `IssMap` in `iss_screen.dart` into
`flutter_map`'s map-controller options setter. The map used
`CameraConstraint.contain` to keep the entire viewport inside longitude bounds
of -180° to 180°. On a narrow portrait viewport, that also restricted the
camera center; at the station's reported position of 21.85° N, 148.62° E, the
map could not follow the ISS to its actual longitude. A later position update
rebuilt the map options while the camera was at that constrained edge, causing
the assertion.

I changed the constraint to `CameraConstraint.containCenter`, which keeps the
camera center within the world bounds without requiring the entire viewport to
fit inside them. This lets the map center on the ISS near the edge of the map,
including on narrow screens.

## Release build

Generate the launcher icons and Android splash after changing their source
image or configuration:

```powershell
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Debug and release APKs share the same entry point; the release build is
optimised. Release signing uses the private keystore configured in
`android/key.properties` when present. Without that file, Gradle uses the
debug key so a local demo build can still be produced; do not distribute that
APK as a store release.

```powershell
# Debug — debuggable, unoptimised, signed with the debug key
flutter build apk --debug
# build/app/outputs/flutter-apk/app-debug.apk

# Release — optimised; signed with your private key if configured
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

To configure a private Android release key, create a keystore locally and keep
it backed up securely:

```powershell
keytool -genkeypair -v -keystore android/upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` with the values for that key. `storeFile` is
relative to the `android` directory:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=upload-keystore.jks
```

Both `android/key.properties` and keystore files are ignored by Git. Never
commit or share them; losing the keystore can prevent future updates signed
with that key.

Install on a connected device with `flutter install`, or copy the release APK to
the device and open it. The release APK was manually verified on an Android
device: it installed with the configured signing, showed the custom launcher
icon, and loaded Home, Launches and ISS data from their APIs.

For iOS, run the **iOS-ipa-build** workflow from the updated `main` branch in
GitHub Actions, then install that newly built IPA. Existing iPhone installs do
not update when the source icon or display name changes; install the new build
over the old one using the same signing method.

## Data sources

| Source | Used for |
| --- | --- |
| [NASA APOD](https://api.nasa.gov/) | Astronomy picture of the day |
| [Launch Library 2](https://thespacedevs.com/llapi) | Upcoming launches |
| [Where the ISS at?](https://wheretheiss.at/) | ISS position |

Map tiles © [OpenStreetMap](https://www.openstreetmap.org/copyright)
contributors, used under the
[tile usage policy](https://operations.osmfoundation.org/policies/tiles/).

## Member and role

**Marco Daniel S. Castillo** — all roles (individual project):
[github.com/KabbalahTreeOfLife](https://github.com/KabbalahTreeOfLife)