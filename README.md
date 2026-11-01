# Duet

**Different goals. One journey.**

Duet is a Flutter habit tracker for two people pursuing independent goals together. Each habit is normalized to completion percentage so studying, running, reading, and any other goal can share one progress language.

## Security boundary

This repository is a local UI prototype, not a production authentication or
accountability service. Authentication, admin authorization, buddy invites,
and TOTP verification are enabled only in debug builds and use local Hive
storage. Local flags and browser storage are user-controlled and must never be
trusted for authorization or sensitive data protection.

Before any release, replace the prototype flows with a backend that provides
server-side authentication, role checks, single-use expiring invite records,
rate limiting, relationship ownership, and atomic invite consumption. Deploy
only over HTTPS and do not ship the demo admin credentials.

## Current build

This first demo implements the Phase 1–2 experience with a polished local state layer:

- Five-tab mobile shell: Home, Progress, Buddy, Challenges, Settings
- Universal habit model for boolean, quantity, duration, distance, and count goals
- Type-agnostic completion percentage: `min(value / target, 1) * 100`
- Daily check-ins and personal streak calculation
- Add-habit flow and a shared progress chart
- Mock buddy summary, sync streak, activity, and notification preference UI
- Riverpod state management and GoRouter navigation
- Hive local database for habits, logs, sessions, and notification preferences
- Unit coverage for normalization rules

Supabase authentication, realtime sync, offline queueing, FCM, and Edge Functions are intentionally deferred until backend credentials and schema migrations are available. The current local database is implemented with Hive so web reloads and app restarts retain the demo state.

## Run

Install Flutter 3.22 or later, then run:

```text
flutter pub get
flutter test
flutter run
```

The current local store starts with a sample habit and sample history so the core journey is immediately demo-able. Data is stored through `lib/services/local_database.dart`; replace that repository with Supabase repositories in the backend phase.

## Local super-admin testing (debug builds only)

For local UI testing only, use the Login screen's **Use super-admin demo account** button, or enter:

- Email: `admin@duet.local`
- Password: `DuetAdmin123!`

Super-admin mode exposes a confirmation-protected local data reset in Settings. This is not production authentication and must be replaced by server-side roles before deployment.

Buddy testing supports both sides of the local flow: one user can generate a code such as `DUET-ABC123`, and another user can enter it in the **Have an invite code?** field on the Buddy screen to become active immediately.

## Structure

- `lib/models/` — universal domain models
- `lib/services/habit_engine.dart` — pure completion, average, streak, and daily-threshold logic
- `lib/services/local_database.dart` — Hive persistence boundary
- `lib/features/` — reserved feature boundaries from the PRD
- `lib/services/` — reserved backend service boundaries
- `lib/main.dart` — app shell and Phase 1–2 demo screens
