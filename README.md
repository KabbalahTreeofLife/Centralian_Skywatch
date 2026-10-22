# Centralian Skywatch

Centralian Skywatch brings today's space picture, launch countdowns, and live ISS tracking together in a single Flutter app.

## Member
* [**Marco Daniel S. Castillo**](https://github.com/KabbalahTreeofLife)

## Setup

1. Copy the example environment file:

   ```powershell
   Copy-Item .env.example .env
   ```

2. (Optional) Put a free NASA API key in `.env`:

   ```
   NASA_API_KEY=your_key_here
   ```

   Get one at <https://api.nasa.gov/>. If the key is missing, the app falls
   back to `DEMO_KEY`, which works but is heavily rate-limited.

3. Install dependencies and run:

   ```powershell
   flutter pub get
   flutter run
   ```

## Environment variables

| Variable | Required | Purpose |
| --- | --- | --- |
| `NASA_API_KEY` | No | Key for the NASA APOD API. Falls back to `DEMO_KEY` when unset. |

`.env` is gitignored, so it never reaches the repository. Copy `.env.example`
to `.env` and fill in the key. A free key is available at
<https://api.nasa.gov/>.

`DEMO_KEY` works without signing up, but it is heavily rate-limited (30
requests per hour and 50 per day per IP), so a personal key is recommended for
demos. The app starts normally when `.env` is missing and simply uses
`DEMO_KEY`.

