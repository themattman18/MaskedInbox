# Masked Inbox

Masked Inbox is a Flutter app for managing Firefox Relay email masks.

## Features

- First-run API key setup with a visual guide.
- Secure API key storage.
- List Firefox Relay random and custom masks.
- Copy mask addresses from each row.
- Sort by date created or alphabetically.
- Create random masks.
- Create custom masks when the connected Relay account has premium access.
- Change the saved API key from settings.

## Firefox Relay API

The app uses the API shape from `C:\Users\thema\Downloads\openapi.json`:

- `GET /api/v1/profiles/` for account capabilities.
- `GET /api/v1/relayaddresses/` for random masks.
- `POST /api/v1/relayaddresses/` to create a random mask.
- `GET /api/v1/domainaddresses/` for custom masks.
- `POST /api/v1/domainaddresses/` to create a custom mask.

Authentication is sent as:

```http
Authorization: Token <api-key>
```

## Run

Install Flutter, then run:

```powershell
flutter pub get
flutter run
```

If you want generated platform folders, run `flutter create .` from this directory before `flutter run`.

## Run In Chrome

Firefox Relay does not send browser CORS headers for local Flutter web apps. Start the local development proxy in one terminal:

```powershell
cd C:\GitHub\MaskedInbox
dart run tool/relay_proxy.dart
```

Then start the Flutter web app in another terminal:

```powershell
cd C:\GitHub\MaskedInbox
flutter run -d chrome
```

Native Windows, Android, and iOS builds call Firefox Relay directly and do not need the proxy.