# HealthMate

Personal health and wellness tracker for Mobile Application Development Coursework 1.

## Features

- Today's aggregated steps, calories burned and water intake.
- Add, edit and delete dated entries; multiple entries per date are summed.
- Journal with date filtering and deletion confirmation.
- SQLite persistence using sqflite with the required health_records table.
- Integer input validation and save/load error handling.
- Persistent Light, Dark and System appearance modes.
- Daily activity summary.
- Add your own sample entries using Add Record for initial testing.

Activity is manually entered using Add Record. This project targets Android; it is not configured as a Windows desktop app. The requested Desktop folder is the project location.

## Open and run in VS Code

1. Install/enable the Flutter and Dart extensions in VS Code.
2. Open this folder. The installed Flutter SDK path is configured in .vscode/settings.json.
3. Start an Android emulator or connect an Android phone with USB debugging.
4. Select the Android device in VS Code and press F5.

From a terminal:

```powershell
$env:PUB_CACHE = 'C:\Users\Asus\AppData\Local\Pub\Cache'
flutter pub get
flutter analyze
flutter test
flutter run
```

## Architecture

The application uses MVVM with Provider (ChangeNotifier).

```text
views/home_screen.dart       Screens, forms and user actions
          |
viewmodels/health_view_model.dart    State, totals, preferences, mutations
          |
data/health_repository.dart         SQLite and parameterized CRUD
          |
healthmate.db / health_records
```

- models/health_record.dart: immutable record, database mapping, date keys and validation.
- main.dart: startup, dependency injection and shared Material 3 themes.
- SharedPreferences: theme preference.
- intl: readable dates and numbers.
- path: database file path construction.

## Database

health_records: id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL (YYYY-MM-DD), steps INTEGER, calories INTEGER, water INTEGER (ml). Nonnegative checks are enforced on activity columns. The date index supports future SQL date queries; the current journal filters already loaded records in memory.

Deleting an entry is permanent after confirmation. Uninstalling or clearing app data removes local data.

## Verification

Five automated tests cover invalid input, multiple-entry daily aggregation and date isolation, update/delete state refresh, theme preference persistence, and the add-record form flow. Repository operations are replaced by an in-memory fake in these tests. SQLite persistence across real device restarts and APK installation still require Android device testing.

## Coursework submission work

Prepare the technical PDF report, architecture and database diagrams, wireframes and screenshots, test evidence, Harvard references, and appendix links. Record the demonstration with your own voice (maximum 25 MB). Publish the source in your own public repository and maintain meaningful commits during your remaining development.

Build a release APK with `flutter build apk --release`. The generated Android configuration uses a debug signing key for local coursework builds; configure a private release signing key before store distribution. Upload the APK and demonstration video to Google Drive with viewer link access.

Acknowledge AI assistance according to the assessment brief and be able to explain and demonstrate your implementation.

## Local verification status

- Dart analysis: no issues found.
- Automated unit/widget tests: all 5 passed.
- Android plugin registration verified for shared_preferences_android and sqflite_android.
- Android device/emulator testing remains pending: the installed emulator could not start because hardware acceleration was unavailable in this environment.
- Minimum supported Android version: Android 7.0 (API 24).

- Android release APK built successfully: HealthMate.apk in the project root (local debug signing key).

## Building from a OneDrive Desktop folder

The Android Flutter compilation tasks defer incremental tracking to Flutter itself, because Gradle cannot snapshot OneDrive reparse-point marker files reliably. This is configured in android/app/build.gradle.kts.

- Final Android debug and release rebuilds both passed after the OneDrive cache adjustment.



Settings contains persistent Light / Dark / System themes and an About HealthMate section with the app purpose and version.

