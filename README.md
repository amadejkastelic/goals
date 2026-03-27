# Goals

A privacy-first Flutter app for tracking personal goals with daily journal entries. All data is stored locally on your device using SQLite -- no account or internet connection required.

## Features

- **Goal tracking** -- Create goals with a title, description, category, and set duration (in days). Track status: active, paused, completed, or abandoned.
- **Daily journal** -- Log daily progress with text, an emoji mood, and media attachments (images, audio, video).
- **Categories** -- Organize goals with predefined and custom categories.
- **Custom fields** -- Add your own structured fields to journal entries.
- **Fasting tracker** -- Built-in intermittent fasting timer with configurable protocols.
- **Health integration** -- Import health data from connected sources.
- **MyFitnessPal import** -- Fetch and view nutrition data from MyFitnessPal.
- **Reminders** -- Local notifications to keep you on track with your goals.
- **Theming** -- Material You dynamic colors, light/dark mode, with manual theme selection.
- **Offline-first** -- Everything works without an internet connection. No sign-up required.

## Screenshots

TODO

## Tech Stack

- **Flutter** 3.11+ (Dart SDK ^3.11.0)
- **SQLite** via [sqflite](https://pub.dev/packages/sqflite) / [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) (desktop)
- **Provider** for state management
- **Material 3** with [dynamic_color](https://pub.dev/packages/dynamic_color)
- Local notifications via [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

## Getting Started

### Prerequisites

- Flutter SDK 3.11 or newer
- A connected device or emulator (Android, iOS, Linux, macOS, Windows, or Web)

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Run tests

```bash
flutter test
```

### Analyze code

```bash
flutter analyze
```

### Build APK

```bash
flutter build apk
```

## Project Structure

```
lib/
  main.dart                  # App entry point, providers setup
  models/                    # Data models
    category.dart
    custom_field_definition.dart
    custom_field_value.dart
    fasting_protocol.dart
    fasting_session.dart
    goal.dart
    health_data.dart
    journal_entry.dart
    media_attachment.dart
    mfp_nutrition.dart
  db/                        # SQLite database helper
  data/                      # Data layer
  providers/                 # Provider state management
    categories_provider.dart
    custom_fields_provider.dart
    fasting_provider.dart
    goals_provider.dart
    journal_provider.dart
    notification_provider.dart
    theme_provider.dart
  screens/                   # App screens
    categories_screen.dart
    goal_detail_screen.dart
    goal_form_screen.dart
    health_import_screen.dart
    home_screen.dart
    journal_entry_screen.dart
    settings_screen.dart
  services/                  # Platform services
    health_service.dart
    notification_service.dart
  theme/
    app_theme.dart
  utils/                     # Utility functions
  widgets/                   # Reusable UI components
    custom_field_editor.dart
    custom_field_input.dart
    fasting_summary_card.dart
    goal_card.dart
    health_data_tile.dart
    journal_day_tile.dart
    media_gallery.dart
    mfp_nutrition_tile.dart
    status_widgets.dart
```

## Data Storage

All data is stored locally in a SQLite database file (`goals.db`) located in the app's documents directory. Media attachments are stored as BLOBs. No data leaves your device.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
