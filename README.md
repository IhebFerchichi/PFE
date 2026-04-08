# Battery Pack Mobile

Flutter mobile client for the BatteryPack backend.

## What is included

- Email/password sign-in against the Spring backend.
- Dashboard with approved pack selection, live status, and compact trend cards.
- Pack detail screen for LFP and Supercap telemetry, including cell drill-down.
- Alerts screen with search, severity filters, acknowledge, and resolve actions.
- Profile screen with backend connection guidance.

## Backend target

The app chooses a default backend URL based on platform:

- Android emulator: `http://10.0.2.2:8080`
- iOS simulator, desktop, web: `http://localhost:8080`

Override it when needed:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080
```

Use your machine IP when testing on a physical device.

## Notes

- The mobile experience is inspired by the existing web frontend, but rebuilt for phone-sized navigation and quick actions.
- The current scope covers the strongest shared flows first: auth, overview, telemetry, cells, and alerts.
