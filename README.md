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
| Automated tests | 225 tests across 27 files. |
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
used for the release icon and splash.

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

225 tests across 27 files. `flutter test`.

Unit tests cover models and JSON parsing, `ApiClient` retry and error mapping,
and each provider's load, retry and caching behaviour. Widget tests cover every
screen's loading, error, empty and offline states. A navigation test walks the
tabs and confirms tab state is preserved.

## Continuous integration

Every pull request and every push to `main` runs three gates:

```yaml
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

`main` is protected: the check must pass before a pull request can merge.

## Debugging case

<!-- Screenshot is added in #16:
![Console after repeated hot restarts](docs/screenshots/debugging-context-lost.png)
-->

After a long session of hot restarts in Chrome the app stopped rendering and
the console showed `Too many active WebGL contexts`, followed by
`Uncaught DartError: LateInitializationError: Field '_handledContextLostEvent'
has not been initialized`. The stack trace pointed into Flutter's CanvasKit
engine rather than app code, so I read the engine source in the SDK cache and
found the field is only ever assigned by the test-only `triggerContextLoss()`
hook — meaning a real WebGL context loss throws. The fault was in the engine,
not the app: the context churn came from accumulated hot restarts, a full page
reload cleared it, and the release build is unaffected because it does not
restart contexts that way. The working practice became hot reload (`r`) instead
of hot restart (`R`) during UI work.

## Release build

Debug and release APKs share the same entry point; only signing and
optimisation differ.

```powershell
# Debug — debuggable, unoptimised, signed with the debug key
flutter build apk --debug
# build/app/outputs/flutter-apk/app-debug.apk

# Release — optimised and signed, for the demo build
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

Install on a connected device with `flutter install`, or copy the release APK to
the device and open it.

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
