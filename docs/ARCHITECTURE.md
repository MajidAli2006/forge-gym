# Forge Gym — Architecture

> Working title: **Forge Gym** (placeholder — confirm real gym name, bundle identifiers,
> and backend URLs before store submission).
> Package: `com.forgegym` (placeholder) · Dart/Flutter: latest stable · Null safety everywhere.

This document is the single source of truth for how the app is structured and why.
It is written for the engineers who will maintain and extend this codebase.

---

## 1. Architectural style

**Feature-first Clean Architecture + Cubit (MVVM-style).**

- Each feature owns its code vertically: `data / domain / presentation`.
- Shared, feature-independent code lives in `app/`, `core/`, and `design_system/`.
- Dependency rule: **dependencies point inward** — presentation → domain ← data.
  The domain layer has zero Flutter, Dio, or Firebase imports.
- State management: **Cubit/BLoC** (`flutter_bloc`). No GetX. One focused Cubit per
  screen/feature — never one global Cubit for the whole app.
- Pragmatism over ceremony: we do not add layers for the sake of architecture.
  If a feature is simple, its use case may be a single function; wrappers that only
  forward calls are not created.

### Data flow (every feature follows this)

```
Server / Mock JSON
        ↓
DataSource          (knows Dio / JSON / local storage — data layer only)
        ↓  DTO
Mapper              (DTO → domain entity; UI never sees a DTO)
        ↓  Entity
Repository impl     (implements the domain repository interface)
        ↓
Repository interface (lives in domain/ — the contract the app depends on)
        ↓
UseCase             (one job, e.g. GetExercisesUseCase)
        ↓
Cubit               (holds immutable UI state, exposes intents)
        ↓
UI                  (screens + widgets — no business logic)
```

Swapping `MockExerciseRepository` for `ApiExerciseRepository` changes only the
data layer registration in `dependency_injection/`. Presentation code is untouched.

### Key decisions

| Decision | Rationale |
|---|---|
| Repository interfaces in `domain/` | Lets us replace mock ↔ API without touching UI or use cases |
| `equatable` for states/entities now; `freezed` later if needed | Dart 3 sealed classes + equatable cover current needs; freezed + build_runner is added when union types get complex |
| `AnalyticsService` / `ErrorReporter` abstractions in `core/` | Presentation never calls Firebase directly; implementations are swapped per environment |
| `DioException` → `Failure` mapping in `core/network/` | UI receives user-friendly messages (`NetworkFailure`, `UnauthorizedFailure`, `ServerFailure`, `UnknownFailure`), never raw exceptions |
| Constructor injection everywhere | Explicit dependencies; `get_it` is only touched at composition roots and in DI modules — never deep inside domain classes |

---

## 2. Folder structure

```
lib/
  main.dart                  → delegates to main_development.dart (flutter run default)
  main_development.dart      → bootstrap(AppEnvironment.development)
  main_staging.dart          → bootstrap(AppEnvironment.staging)
  main_production.dart       → bootstrap(AppEnvironment.production)

  app/
    app.dart                 → GymApp (MaterialApp.router, themes, routerConfig)
    bootstrap/
      bootstrap.dart         → one entry: binding → config → DI → error hooks → runApp
      app_environment.dart   → AppEnvironment enum + EnvConfig (apiBaseUrl, flags)
    routing/
      app_routes.dart        → typed route constants (no raw strings in widgets)
      app_router.dart        → GoRouter + StatefulShellRoute (bottom nav)
      scaffold_with_nav_bar.dart
    dependency_injection/
      injection.dart         → getIt + configureDependencies(); feature modules hook in here

  core/
    analytics/               → AnalyticsService abstraction + event name constants
    constants/               → app-wide defaults (page size, timeouts, weekly goal), AppInfo
    errors/                  → Failure taxonomy + ErrorReporter abstraction
    media/                   → MediaCache: on-demand download + on-device cache for demo clips
    network/                 → shared Dio client + DioException→Failure mapper
    notifications/           → NotificationService (local reminders + rest-over alarm)
    utils/                   → Formatters (dates, kg, durations)

  design_system/
    design_system.dart       → barrel export
    theme/                   → AppColors (tokens), AppTheme (light/dark ThemeData)
    typography/              → AppTextStyles
    spacing/                 → AppSpacing, AppRadius
    components/              → AppButton, AppCard, AppChip, AppTextField,
                               AppSectionHeader, AppStateViews (loading/error/empty)

  features/
    <feature>/
      data/        → models/ (DTOs), datasources/, repositories/ (impls), mappers/
      domain/      → entities/, repositories/ (interfaces), usecases/
      presentation/→ cubit/, screens/, widgets/   (feature-local composition only)

  assets/mock/               → exercises.json, workouts.json, announcements.json,
                               challenges.json (dev data behind repository interfaces)
  assets/exercises/<id>/thumb.jpg → thumbnails only; demo.mp4 lives in ../media_upload
```

### Cross-feature data flow

Features never import each other's data layer. Where one feature reacts to
another's writes it does so through a **domain contract that exposes a
change stream**: `WorkoutHistoryRepository.changes`, `WeightRepository.changes`,
`ChallengeEnrollmentRepository.changes`, `CustomWorkoutRepository.changes`.
Home, Progress, Challenges and Workouts cubits subscribe and reload in
place, so finishing a workout or saving a routine updates every tab without
the screens being rebuilt. Cubits cancel these subscriptions in `close()`.

### Personal routines

`CustomWorkoutRepository` (domain) holds member-built routines;
`PrefsCustomWorkoutRepository` (data) persists them as JSON under
`forge.custom_workouts`. `CompositeWorkoutRepository` implements the
existing `WorkoutRepository` by listing routines first and the bundled
plans second, so the session, history, home and challenge code needs no
notion of "custom" — `Workout.isCustom` only drives the Edit / Delete
affordances. `SaveCustomWorkoutUseCase` owns validation (name ≤ 40 chars,
1–15 exercises, sets 1–10, reps 1–600, rest 0–600 s) and derives difficulty,
target muscles and estimated duration from the chosen exercises;
`RoutineEditorCubit` only holds the draft.

### Quick log

`QuickLogSetUseCase` turns a single logged set on an exercise page into a
`CompletedWorkout` with id `quick-log-YYYY-MM-DD`, merging same-day sets
through `WorkoutHistoryRepository.upsertCompleted`, so ad-hoc training
feeds the same stats, streak and challenge pipeline as a guided session.

### Media

Demo clips are not bundled. `MediaCache` (core/media) resolves a relative
path such as `exercises/plank/demo.mp4` to `<EnvConfig.mediaBaseUrl>/<path>`
remotely and `<app support dir>/media/<path>` locally, downloads to a `.part`
file, renames on success, de-duplicates concurrent requests and exposes a
progress `ValueListenable`. `ExerciseVideo` (exercises/presentation/widgets)
shows the poster, progress, retry, then plays the cached file. The base URL
is set per environment and overridable with `--dart-define=MEDIA_BASE_URL`.

### Firebase

`FirebaseBootstrap.initialize()` runs before DI and records whether Firebase
came up. `configureDependencies` then registers either the Firebase-backed
implementation or the local one for each seam:

| Seam | Firebase | Local |
|---|---|---|
| `AuthRepository` | `FirebaseAuthRepository` (identity in Firebase Auth, training profile in the local session store keyed by uid) | `MockAuthRepository` |
| `PushService` | `FirebasePushService` (topic `announcements`; foreground messages re-shown via `NotificationService.showNow`) | `NoopPushService` |
| `MediaCache` URL resolver | Storage `getDownloadURL` when `mediaBaseUrl == 'firebase'` | `<mediaBaseUrl>/<path>` |

`BackendInfo` (core/constants) tells presentation which mode is active so
mock-only affordances (the demo-credentials shortcut) can hide themselves.
Widget tests never initialise Firebase and therefore always exercise the
local implementations.

### Notifications

`NotificationService` (core/notifications) is a small abstraction over
`flutter_local_notifications`; `NoopNotificationService` is the default in
tests and for cubits constructed without one. Two producers:

- `SyncWorkoutReminderUseCase` (profile/domain) schedules or cancels the daily
  reminder from `NotificationPreferences`. It is run at app start **without**
  prompting and from the Profile toggle **with** the OS permission prompt.
- `WorkoutSessionCubit` schedules a "rest over" alarm when a rest starts and
  cancels it on every in-app path that ends the rest, so it only fires when
  the app is in the background.

Android needs the receivers/permissions declared in `AndroidManifest.xml`
and core-library desugaring (both in place); ProGuard keep rules live in
`android/app/proguard-rules.pro`.

Rules:

- Reusable UI lives in `design_system/` with **generic, feature-independent names**
  (`AppButton`, not `WorkoutBlueButton`). Check for an existing component before creating one.
- Feature-specific composition stays inside the feature's `presentation/widgets/`.
- No `models/` dumping ground: DTOs live with their feature's `data/`, entities with `domain/`.

---

## 3. Packages

### Foundation (added now)

| Package | Why |
|---|---|
| `flutter_bloc` | Cubit/BLoC state management — immutable states, testable with `bloc_test` |
| `get_it` | Service location at composition roots; constructor injection everywhere else |
| `go_router` | Declarative routing + `StatefulShellRoute` so bottom-nav tabs keep their state; deep-link ready |
| `dio` | HTTP client; single shared instance with base URL from `EnvConfig`, timeouts, dev logging |
| `equatable` | Value equality for states/entities/failures without boilerplate |
| `shared_preferences` | Non-sensitive local prefs (onboarding seen, theme choice) |
| `flutter_secure_storage` | Sensitive local data (auth tokens) — never `shared_preferences` |

### Added with their features (documented here so the plan is complete)

| Package | Why | Lands with |
|---|---|---|
| `cached_network_image` | Image caching for exercise thumbnails; offline-friendly | Exercise library |
| `video_player` | Short exercise demos; one controller per detail screen, disposed correctly, never one per list row | ✅ Exercise details |
| `path_provider` | Locates the app support directory for the media cache | ✅ Media cache |
| `flutter_local_notifications` + `timezone` | Daily reminder and rest-over alarm, scheduled on the device | ✅ Notifications |
| `package_info_plus` | Version / build number for the profile footer and bug reports | ✅ Profile |
| `firebase_core` + `firebase_analytics` | Behind `AnalyticsService`; needs platform config first | Analytics phase |
| `firebase_crashlytics` | Behind `ErrorReporter`; needs platform config first | Stability phase |
| `firebase_messaging` | Workout reminders, gym announcements; permission only when needed | Notifications phase |
| `freezed` / `json_serializable` + `build_runner` | Codegen for DTOs/unions when hand-written models get noisy | First API-backed feature |
| `qr_flutter` (+ camera perms) | Future "My Gym Pass" QR | Phase 3 |

Dev: `flutter_lints` (analysis), `bloc_test` + `mocktail` (tests).

Firebase packages are intentionally **not** added until the Firebase project exists
(`google-services.json` / `GoogleService-Info.plist`), because adding them without
platform configuration crashes the app on startup.

---

## 4. Navigation

`go_router` with `StatefulShellRoute.indexedStack`: five branches (Home, Workouts,
Exercises, Progress, Profile). Each tab keeps its own navigation stack — switching
tabs never loses scroll position or state.

Route table (implemented → planned):

```
/home                         → HomeScreen            ✅ now
/workouts                     → WorkoutsScreen        ✅ now (placeholder)
/exercises                    → ExercisesScreen       ✅ now (placeholder)
/progress                     → ProgressScreen        ✅ now (placeholder)
/profile                      → ProfileScreen         ✅ now (placeholder)

/splash                       → decides auth vs home            (auth feature)
/onboarding                   → first-run onboarding            (auth feature)
/login  /register  /forgot-password                            (auth feature)
/exercises/:exerciseId        → ExerciseDetailScreen            ✅
/exercises/videos             → VideoLibraryScreen              ✅ (static route before :exerciseId)
/workouts/:workoutId          → WorkoutDetailScreen             ✅
/workouts/:workoutId/active   → ActiveWorkoutScreen             ✅ (root navigator: no tab bar)
/workouts/:workoutId/edit     → RoutineEditorScreen (edit)      ✅ (root navigator)
/workouts/new                 → RoutineEditorScreen (create)    ✅ (static route before :workoutId, root navigator)
/workouts/active/resume       → resumes the persisted session    ✅
/home/challenges              → ChallengesScreen                ✅
```

Conventions:

- Widgets reference `AppRoutes.*` constants — never raw strings.
- Focused tasks (live workout, routine editor) pass `parentNavigatorKey`
  so they open above the shell: the whole screen is theirs and a stray tab
  tap can't interrupt a set. Everything else stays inside its tab branch.
- The auth gate (redirect in `GoRouter`) lands with the authentication feature;
  until then `initialLocation` is `/home`.
- Route names are set for deep linking and analytics screen tracking.

---

## 5. Dependency injection

`get_it` (`lib/app/dependency_injection/injection.dart`):

```dart
await configureDependencies(EnvConfig.forEnvironment(AppEnvironment.development));
```

Registration order: `EnvConfig` → core services (`AnalyticsService`, `ErrorReporter`,
`Dio`) → `AppRouter` → feature modules. Each feature exposes
`registerXxxDependencies()` (e.g. `registerExerciseDependencies()`) and it is called
from `configureDependencies()` — one place to see the whole object graph.

Rules:

- **Constructor injection.** `ExerciseListCubit(getExercisesUseCase)`,
  `GetExercisesUseCase(exerciseRepository)`,
  `ApiExerciseRepository(exerciseRemoteDataSource)`.
- `get_it` is read at composition roots (bootstrap, `BlocProvider` creation, `GymApp`).
  Domain/data classes never import it.
- Cubits are created per screen via `BlocProvider(create: (_) => getIt<...>())`
  or a feature DI module — never as app-wide singletons holding screen state.

---

## 6. Design system

```
design_system/
  theme/       AppColors  → raw tokens (brand "Ember", neutrals, semantic)
               AppTheme   → ThemeData.light() / .dark() built from tokens
  typography/  AppTextStyles → display/headline/title/subtitle/body/caption/button
  spacing/     AppSpacing (4–32), AppRadius (8–full)
  components/  AppButton (primary/secondary/outline/text; large 56dp / medium 48dp;
                         loading + disabled states)
               AppCard, AppChip, AppTextField, AppSectionHeader,
               AppLoadingView / AppErrorView / AppEmptyView
```

Principles:

- **Dark theme is first-class** — most gym usage happens in dark environments.
- **Large touch targets**: minimum 48dp everywhere (buttons default 56dp) for use mid-workout.
- **Composition over configuration**: small components combined in features, not one
  mega-widget with 30 parameters.
- **Accessibility from day one**: semantic labels on interactive components, scalable
  text (no fixed pixel heights that clip), sufficient contrast in both themes,
  videos always paired with written instructions.
- **Consistent states**: loading / refreshing / empty / error / loaded are handled by
  the shared state views — no ad-hoc `CircularProgressIndicator`s scattered in screens.

---

## Environments & running

| Entry | Flavor | Analytics | Network logging |
|---|---|---|---|
| `lib/main_development.dart` | dev | off | on |
| `lib/main_staging.dart` | staging | on | on |
| `lib/main_production.dart` | production | on | off |

```bash
flutter run --target lib/main_development.dart   # default via lib/main.dart
flutter run --target lib/main_staging.dart
flutter run --target lib/main_production.dart
```

Backend URLs in `EnvConfig` are placeholders — no backend exists yet. Repositories
currently resolve to local mock JSON (`assets/mock/`), behind the same interfaces
the API implementations will satisfy.

## Placeholders to confirm before store submission

- Gym name: **"Forge Gym"** (working title)
- Org / bundle id: **`com.forgegym`** → iOS bundle id + Android applicationId
- Backend base URLs per environment
- App icon, splash screen, privacy policy URL
