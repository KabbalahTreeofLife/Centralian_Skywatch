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

