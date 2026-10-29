# 🌱 EcoTask (Flutter + SQLite)

EcoTask is a personal carbon-footprint tracker. You log everyday activities (transport, food, energy, shopping, waste, water, other), the app converts them into kg CO₂e with the same emission factors as the original web app, and shows your eco score, level, streak, badges, weekly trend, category breakdown and tailored suggestions.

This repository is the **Flutter / Dart mobile port** of the original React + Express + Sequelize web application. It is **offline-first**: everything is stored in a local SQLite database on the device. There is no server, no REST API and no network permission in release builds.

---

## Features

| Area | What you get |
| --- | --- |
| **Auth** | Register, login, logout, persistent session (7 days like the original JWT), duplicate e-mail detection, validation, salted PBKDF2 password hashes. |
| **Dashboard** | Eco score ring (animated), eco level, day streak, today / week / month emissions, week-over-week insight banner, 7-day trend chart, category donut chart, smart suggestions, badge collection, five most recent activities, pull-to-refresh. |
| **Activities** | Create, edit, delete, complete / un-complete, filter by category and date, search by title, summary of emitted / saved / net carbon, live "estimated impact" while filling the form. |
| **Demo account** | `demo@ecotask.com` / `demo123` is created on first launch (same data as the original `seed.js`) and the **Use Demo Account** button fills it in. |

### Screens (all screens that exist in the original app)

The original web app has exactly four routes. All are migrated:

| Original route | Flutter |
| --- | --- |
| `/login` | `LoginScreen` |
| `/register` | `RegisterScreen` |
| `/dashboard` | `DashboardScreen` |
| `/tasks` (+ create/edit **modal**) | `TasksScreen` (+ create/edit **bottom sheet**) |

Plus a `SplashScreen` shown while the saved session is restored (needed by Flutter's async start-up; the web app read `localStorage` synchronously).

> The original has **no** statistics, profile, settings, about, task-details or separate carbon-tracking pages, so none were invented. Statistics/carbon tracking live on the dashboard exactly as before.

---

## Tech stack

| Concern | Package |
| --- | --- |
| UI | Flutter (Material 3), Dart ≥ 3.5 |
| State | `provider` |
| Navigation | `go_router` (auth-guarded routes, shell route with bottom navigation) |
| Database | `sqflite` (+ `path`) |
| Charts | `fl_chart` |
| Dates / formatting | `intl` |
| IDs | `uuid` |
| Session (non-sensitive) | `shared_preferences` |
| Session token | `flutter_secure_storage` |
| Password hashing | `crypto` (PBKDF2-HMAC-SHA256, replaces bcrypt) |
| Dev only | `flutter_test`, `flutter_lints`, `sqflite_common_ffi` (runs SQLite in unit tests) |

`crypto` is the only package beyond your suggested list; it is required for salted password hashing and is a first-party Dart package.

### Fonts / assets

The original loaded Playfair Display, DM Sans and JetBrains Mono from Google Fonts. They are **bundled** in `assets/fonts/` (static weights, SIL OFL licences included) so typography is identical offline. The original uses emoji instead of image assets, so there are no images to migrate. The Android launcher icon is a new seedling icon in the app's green.

---

## Architecture

```
Flutter UI (screens / widgets)
        │  context.watch / context.read
        ▼
Provider (AuthProvider, TaskProvider, DashboardProvider)   ← UI state only
        ▼
Repositories (User, Task, Stats, Dashboard, Seed)          ← all SQL lives here
        ▼
DatabaseHelper → SQLite (sqflite)

Services (pure Dart): CarbonEngine, PasswordService, AuthService, SessionStore
```

Old → new:

```
React → Axios → Express → Sequelize → SQLite     (removed)
Flutter → Provider → Repository → SQLite         (new)
```

Rules followed: screens never run SQL; business rules (carbon factors, eco score, level, streak, badges, suggestions) live in `services/carbon_engine.dart`, which has no Flutter imports so it is testable on a plain Dart VM.

### Folder structure

```
lib/
  main.dart                 entry point
  app.dart                  providers + router + theme
  app_dependencies.dart     composition root (DB → repos → services)
  core/                     constants, dates, validators, errors, number helpers, chart scale
  database/                 DatabaseHelper (open/create/migrate/close), schema.dart
  models/                   AppUser, Task, CarbonLog, EcoLevel, EarnedBadge, Suggestion, DashboardData, ...
  repositories/             user_, task_, stats_, dashboard_, seed_repository (+ error guard)
  services/                 carbon_engine, password_service, auth_service, session_store
  providers/                auth_, task_, dashboard_provider, op_result
  router/                   go_router config with auth redirects
  screens/                  splash, login, register, dashboard, tasks
  widgets/                  glass_card, eco_score_ring, stat_card, badge_grid, charts, task_card, task_form_sheet, ...
  theme/                    colors, text styles, spacing/radii, ThemeData + decoration builders
assets/fonts/               bundled fonts
android/                    Android project (Kotlin DSL)
test/                       unit, database, repository, widget tests (+ JS-derived fixtures)
```

---

## Database

SQLite file `ecotask.db`, schema version 1 (`lib/database/schema.dart`). Table and column names are identical to what Sequelize generated for the original models. Foreign keys are enabled (`PRAGMA foreign_keys = ON`).

```sql
users (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,                       -- pbkdf2_sha256$iters$salt$hash
  totalEcoScore REAL NOT NULL DEFAULT 100, streak INTEGER NOT NULL DEFAULT 0,
  lastActiveDate TEXT,                          -- yyyy-MM-dd
  badges TEXT NOT NULL DEFAULT '[]',            -- JSON array
  level TEXT NOT NULL DEFAULT 'Seedling',
  createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
)

tasks (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (length(title) BETWEEN 1 AND 200),
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL CHECK (category IN ('transport','food','energy','shopping','waste','water','other')),
  subcategory TEXT NOT NULL DEFAULT '', carbonValue REAL NOT NULL,
  quantity REAL NOT NULL DEFAULT 1, unit TEXT NOT NULL DEFAULT 'unit',
  date TEXT NOT NULL, completed INTEGER NOT NULL DEFAULT 0, isRecurring INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
)

carbon_logs (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  taskId TEXT REFERENCES tasks(id) ON DELETE SET NULL,
  date TEXT NOT NULL, category TEXT NOT NULL, carbonAmount REAL NOT NULL,
  description TEXT NOT NULL DEFAULT '', createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
)

-- indexes
idx_tasks_user_date (userId, date DESC, createdAt DESC)   idx_tasks_user_category (userId, category)
idx_logs_user_date  (userId, date)                         idx_logs_task (taskId)
```

Migrations: add a script to `Schema.migrations[<newVersion>]` and bump `Schema.version`; `DatabaseHelper._onUpgrade` applies pending scripts in one transaction. Task mutations (insert/update/delete + carbon log + user-stats refresh) run in a single transaction.

---

## Business logic (ported 1:1)

Everything below comes from `backend/utils/carbonEngine.js` and the controllers; see `lib/services/carbon_engine.dart` and `lib/repositories/`.

* **Carbon value** = `factor[category][subcategory] × quantity`, rounded to 3 decimals; unknown category/type → `0`.
* **Eco score** = `clamp(100 − (totalLast30Days / 30 / 13) × 50, 0, 100)`, 1 decimal (13 kg/day = global average).
* **Levels** (inclusive, first match): Seedling 0–30 · Sprout 30–50 · Leaf 50–65 · Tree 65–80 · Forest 80–90 · Earth Guardian 90–100.
* **Streak**: unchanged if no previous activity or already active today; `+1` if last active yesterday; otherwise reset to `1`.
* **Badges**: eight are displayed; the original source only ever **awards** `first_task`, `week_streak` and `earth_guardian` (checked with the *pre-update* streak). This is preserved.
* **Suggestions**: transport > 5 kg, food > 8 kg, energy > 3 kg, waste logged < 3 times, a "plant a tree" filler when fewer than 2, max 3.
* **Dashboard**: today / 7-day / 30-day / previous-week windows, 7-point trend, category breakdown sorted by total with % of the 30-day total, 5 most recent tasks.
* **After every task create / update / toggle / delete** the user's score, level, streak, last-active date and badges are recomputed (`refreshUserStats`).

### Behaviour intentionally preserved (looks odd, but is what the original does)

* A brand-new user shows score **100 / Earth Guardian** until the first activity is logged.
* On the sign-up day the streak stays `0` (last-active date defaults to today).
* Editing a task does not change `isRecurring`, and does not rename the carbon-log description.
* Completed tasks still count towards carbon totals.
* Dashboard stat cards: the "tone" (forest/earth/sage) only changes the text colour, because the original CSS `.glass-card` rule overrode the tinted backgrounds.

---

## Verification performed

No Flutter SDK or pub.dev access was available in the environment this was written in, so **`flutter pub get`, `flutter test` and `flutter build apk` were NOT executed**. What *was* done, and how:

1. **Static analysis against real sources.** The Flutter framework (stable branch, Flutter 3.47 / Dart 3.13) and the pinned package versions (`fl_chart 0.69.2`, `go_router 16.2.x`, `provider 6.1.5`, `sqflite 2.4.2`, `flutter_secure_storage 9.2.4`, `shared_preferences 2.5.x`, `uuid 4.5.1`, …) were assembled from GitHub and `dart analyze` was run with the `flutter_lints` rule set on `lib/` **and** `test/`: **0 errors, warnings, or infos**. `dart format` reports no changes.
2. **Tests executed on a Dart VM against real SQLite** (via `sqflite_common_ffi`, with `sqflite` swapped for the same-API `sqflite_common`, and a tiny stand-in test runner because `flutter_test` needs the Flutter engine): **95 tests passed** (engine, validators, password hashing, database, repositories, auth/session). A deliberate-failure check confirmed the runner detects failures, including async `throwsA`.
3. **Parity against the original app.** The original Express backend was installed and run; two randomized scenarios (57 and 75 operations: creates, edits, toggles, deletes, forced streak states) were replayed against both the original API and the Dart repositories. Per-step user state, returned stats, the full dashboard payload and the final task list matched with **0 differences**. The carbon engine was additionally diffed on 9,000+ random inputs.
4. **Not run here:** widget tests (`test/widget_*_test.dart`, which need the Flutter engine), UI rendering on a device/emulator, and the Android build. They compile and are analysed, but please run them yourself (below). Visual fidelity was implemented from the original markup/Tailwind config but has not been compared pixel-by-pixel.

---

## Getting started

### 1. Install Flutter

Follow <https://docs.flutter.dev/get-started/install> for your OS, install Android Studio (or the Android SDK command-line tools), accept licences, and check:

```bash
flutter doctor
```

### 2. Install dependencies

```bash
cd ecotask_flutter
flutter pub get
```

### 3. Run

**On Windows desktop (quickest way to try it):**

```bash
flutter create --platforms=windows .
del test\widget_test.dart          # the template adds a sample test that does not apply to this app
flutter pub get
flutter run -d windows
```

You need *Visual Studio 2022 with the "Desktop development with C++" workload* (`flutter doctor` tells you), and Windows **Developer Mode** turned on (Settings → System → For developers) because Flutter plugins use symlinks. The desktop database is stored in `%APPDATA%\EcoTask\ecotask.db`. If `flutter pub get` complains about `sqlite3_flutter_libs`, delete that one line from `pubspec.yaml` and retry. Same idea for Linux/macOS (`--platforms=linux` / `macos`).

**On Android:**

```bash
flutter devices          # pick an emulator or a USB-connected phone
flutter run
```

Sign in with the demo account (`demo@ecotask.com` / `demo123`) or register a new one.

### 4. Test, analyse, format

```bash
flutter analyze
dart format .
flutter test
```

`flutter test` needs the host's SQLite shared library for the database tests (`libsqlite3` on Linux, built in on macOS; on Windows place `sqlite3.dll` on the PATH).

### 5. Build an APK

```bash
flutter build apk --debug      # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release    # signed with the debug key until you add your own
```

### Android project note

The `android/` folder was written by hand for current Flutter templates (AGP 8.11 / Kotlin 2.2 / Gradle 8.14, `minSdk 24`, package `com.ecotask.app`). Flutter injects `gradlew` automatically on first build. If your Flutter version complains about Gradle/AGP versions, run `flutter create --platforms=android .` once in this folder (it only fills in missing files) and re-apply `minSdk = 24` in `android/app/build.gradle.kts`.

---

## Migration notes

### What was removed / replaced

| Original | Now |
| --- | --- |
| React 18 | Flutter + Dart |
| JavaScript | Dart |
| JSX / HTML | Flutter widgets |
| CSS / Tailwind | `ThemeData` + `lib/theme` tokens |
| React Hooks / Context | Provider (`ChangeNotifier`) |
| React Router | GoRouter |
| Framer Motion | `TweenAnimationBuilder`, `AnimationController` (`Entrance`, `FloatingEmoji`), `AnimatedContainer`, page fades |
| Recharts | `fl_chart` |
| react-hot-toast | `SnackBar` styled like the toasts |
| Axios, REST API | **removed** |
| Node.js, Express | **removed** |
| Sequelize | **removed** (repositories + `sqflite`) |
| `sqlite3` (Node) | `sqflite` |
| JWT | random session token in secure storage + user id / expiry in SharedPreferences (7 days) |
| bcryptjs (cost 12) | PBKDF2-HMAC-SHA256, 50 000 iterations, random 16-byte salt, hashed off the UI thread |
| localStorage | SharedPreferences / flutter_secure_storage |
| npm | pub (`pubspec.yaml`) |

### Mobile adaptations

Sidebar → top bar + bottom navigation; the account menu (name, level, streak, logout) is a bottom sheet; task modal → bottom sheet that resizes with the keyboard; native date picker instead of `<input type="date">`; `window.confirm` → dialog; hover tooltips on badges → tap tooltips; pull-to-refresh on dashboard and tasks; wide layouts (≥ 768 / 1024 dp) reuse the original multi-column grids.

### Deliberate deviations (small, all documented)

1. **"Today" uses the device's local date** instead of the UTC date the web app used (`toISOString()`), so the day rolls over at local midnight. One-line revert in `lib/core/app_date.dart`.
2. **E-mails are trimmed and lower-cased** at registration/login (a phone keyboard auto-capitalises).
3. **Unit field** is synced when the *category/type* changes, not on every quantity edit (the original overwrote a typed unit whenever quantity changed).
4. **Pie chart** slices are sized by absolute value so a net-negative category (saving) still renders.
5. **Task mutations are transactional** (the original issued separate queries).
6. Extra validation messages (name 2–50 characters, e-mail format, title ≤ 200) are shown inline instead of surfacing a raw 500 error.

The login page's "2.4M kg CO₂ saved / 12k+ users / 98% eco score" tiles are static marketing copy from the original and are kept as-is.

### Known limitations

* Not yet built/run on a device by the author (see *Verification*).
* The original `isRecurring` field is stored but has no UI (the original had none either).
* Five of the eight badges (`carbon_saver`, `green_commuter`, `plant_power`, `energy_saver`, `recycler`) can never be unlocked — the original source has no award logic for them and none was invented.
* Task cards have no exit animation on delete (the original used AnimatePresence).
* No cloud sync / multi-device support (by design: offline-first).
