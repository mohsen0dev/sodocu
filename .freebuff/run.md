# Run Doc

## Reproduce artifacts

No `.env` or generated config files needed. Dependencies:

```powershell
flutter pub get
```

## Run the server

Serve the Flutter web app on port 8080:

```powershell
flutter run -d web-server --web-port 8080
```

URL: http://localhost:8080

- Framework: Flutter 3.38.5 (stable)
- Dev server: `flutter run -d web-server` (Dart DevTools / VM web server)
- Port: 8080 (default; override with `--web-port` if occupied)
