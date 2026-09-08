# SnowTracker

A native iOS app (SwiftUI) for checking ski conditions: search any resort or
mountain worldwide, see current conditions and a 7-day forecast with expected
snowfall, and pull up nearby webcams — all in-app.

## Features

- **Search any resort/mountain** by name (not limited to a fixed list), plus
  a curated "Popular Resorts" shortcut list.
- **Resort detail** — current temp/wind/snowfall and a 7-day forecast with
  daily snowfall totals. From here, tap **Live Cameras** (card or toolbar
  icon) to browse that resort's public webcams. Tap a camera to view its
  live snapshot, or open the live page in an embedded in-app web view (no
  need to leave the app).
- **Favorites** — star a resort to pin it to the top of the list; persisted
  on-device.
- **Units** — toggle between Metric (°C, cm, km/h) and Imperial (°F, in, mph)
  from the toolbar.

## Data sources

- **Weather & snowfall**: [Open-Meteo](https://open-meteo.com) — free,
  no API key required. Elevation is passed per-resort so the forecast model
  corrects for the resort's actual altitude.
- **Resort search**: Open-Meteo's free
  [Geocoding API](https://open-meteo.com/en/docs/geocoding-api), so you can
  search literally any named place worldwide.
- **Webcams**: [Windy Webcams API](https://api.windy.com/webcams/dev) —
  requires a free API key (see setup below). Not every resort has a public
  webcam nearby; the Cameras tab handles that gracefully.

## Setup

1. Open `SnowTracker.xcodeproj` in Xcode 15+.
2. To enable the Cameras tab, sign up for a free key at
   https://api.windy.com/webcams/dev and paste it into
   `SnowTracker/Services/WebcamAPIConfig.swift`:
   ```swift
   static let apiKey = "YOUR_KEY_HERE"
   ```
   Without a key, the cameras screen still works but shows a message asking
   you to configure one.
3. Build & run on iOS 16+ (simulator or device) — no other setup needed.

## Project structure

```
SnowTracker/
  SnowTrackerApp.swift        App entry point
  ContentView.swift           Root screen: search/browse resorts
  Models/                     Resort, weather, and webcam data types
  Services/                   Networking (Open-Meteo, Windy), persistence
  Views/                      SwiftUI screens and components
  Resources/resorts.json      Curated "Popular Resorts" catalog
```

## Notes

- The Windy Webcams API's exact JSON shape can change between plan tiers;
  `WebcamService`/`Webcam` decode defensively (optional fields) so a schema
  tweak degrades to "no image" instead of crashing.
- No backend required — the app talks directly to Open-Meteo and Windy.
