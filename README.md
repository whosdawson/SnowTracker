# SnowTracker

A native iOS app (SwiftUI) for checking ski conditions: search any resort or
mountain worldwide, see current conditions and a 7-day forecast with expected
snowfall, check whether it's open for the season, and pull up its webcams —
all in-app.

## Features

- **Search any resort/mountain** by name (not limited to a fixed list), plus
  a curated "Popular Resorts" shortcut list.
- **Resort detail** — current temp/wind/snowfall and a 7-day forecast with
  daily snowfall totals. A season-status badge shows **Open Now**, **Opens
  &lt;date&gt;**, or **Season Closed** for resorts with curated dates.
- **Cameras** — tap **Live Cameras** (card or toolbar icon) on a resort to
  browse up to three sources: a curated **official webcam page**, live
  **YouTube streams**, and nearby **Windy webcams** (sorted by real distance
  from the resort). Tap any camera to view its snapshot, or watch live in an
  embedded in-app web view — no need to leave the app.
- **Favorites** — star a resort to pin it to the top of the list; persisted
  on-device.
- **Snow alert notifications** — favorited resorts are checked for notable
  snow (≥2cm) in the next 2 days whenever the app is opened; posts one local
  notification per resort per day.
- **Units** — toggle between Metric (°C, cm, km/h) and Imperial (°F, in, mph)
  from the toolbar.

## Data sources

- **Weather & snowfall**: [Open-Meteo](https://open-meteo.com) — free,
  no API key required. Elevation is passed per-resort so the forecast model
  corrects for the resort's actual altitude.
- **Resort search**: Open-Meteo's free
  [Geocoding API](https://open-meteo.com/en/docs/geocoding-api), so you can
  search literally any named place worldwide.
- **Nearby webcams**: [Windy Webcams API](https://api.windy.com/webcams/dev)
  — requires a free API key (see setup below).
- **Live streams**: [YouTube Data API v3](https://console.cloud.google.com/apis/credentials)
  — requires a free API key (see setup below).
- **Official webcam links & season dates**: hand-curated in
  `Resources/resorts.json` for a subset of the bundled Popular Resorts (see
  Notes below) — not every resort has these.

Any of these sources can be missing for a given resort or unconfigured
entirely; the app degrades gracefully (a section or badge just doesn't show)
rather than erroring out.

## Setup

1. Open `SnowTracker.xcodeproj` in Xcode 15+.
2. To enable nearby webcams, sign up for a free key at
   https://api.windy.com/webcams/dev and paste it into
   `SnowTracker/Services/WebcamAPIConfig.swift`.
3. To enable live YouTube streams, create a free API key at
   https://console.cloud.google.com/apis/credentials (enable "YouTube Data
   API v3" on the project first) and paste it into
   `SnowTracker/Services/YouTubeAPIConfig.swift`.
   Without either key, that source's section just doesn't appear — the rest
   of the app (forecasts, official links, season status) still works.
4. Build & run on iOS 16+ (simulator or device) — no other setup needed.

## Project structure

```
SnowTracker/
  SnowTrackerApp.swift        App entry point
  ContentView.swift           Root screen: search/browse resorts
  Models/                     Resort, weather, and webcam data types
  Services/                   Networking (Open-Meteo, Windy, YouTube), persistence
  Views/                      SwiftUI screens and components
  Resources/resorts.json      Curated "Popular Resorts" catalog
```

## Notes

- The Windy Webcams API's exact JSON shape can change between plan tiers;
  `WebcamService`/`Webcam` decode defensively (optional fields) so a schema
  tweak degrades to "no image" instead of crashing.
- Nearby webcams are fetched from a wider radius and sorted client-side by
  real distance from the resort, since Windy's own ordering isn't
  distance-based and can otherwise surface a nearby town's webcams ahead of
  the resort's own.
- `officialWebcamURL`, `plannedOpeningDate`, and `plannedClosingDate` in
  `resorts.json` are curated by hand and only present for a subset of
  resorts (10 official links; 8 with real 2026-27 season dates as of this
  writing). A resort without these just shows no badge/section rather than
  a guess — dates especially need refreshing each season since resorts
  announce them a few months ahead and can adjust for conditions.
- No backend required — the app talks directly to Open-Meteo, Windy, and
  YouTube.
