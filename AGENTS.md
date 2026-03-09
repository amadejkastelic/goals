# AGENTS.md

## Project Overview
A Flutter mobile app for tracking personal goals with daily journal entries. Users can create goals with a set duration, log daily progress with text, mood (emoji), and media attachments (images, audio, video). Data is stored locally in SQLite without requiring login.

## Tech Stack
- Flutter 3.11+
- SQLite (sqflite package)
- Provider (state management)
- image_picker, file_picker (media handling)

## Project Structure
```
lib/
  main.dart              # App entry point, providers setup
  models/
    goal.dart            # Goal data model
    category.dart        # Category data model
    journal_entry.dart   # Journal entry model
    media_attachment.dart # Media attachment model
  db/
    database_helper.dart # SQLite database operations
  providers/
    goals_provider.dart  # Goals state management
    categories_provider.dart # Categories state management
    journal_provider.dart # Journal entries state management
  screens/
    home_screen.dart     # Goals list, filtering
    goal_detail_screen.dart # Goal progress, day tiles
    journal_entry_screen.dart # Daily journal entry form
    categories_screen.dart # Manage categories
  widgets/
    goal_card.dart       # Goal list item widget
    journal_day_tile.dart # Day tile in goal detail
    media_gallery.dart   # Display attached media
```

## Key Features
- Goals: title, description, category, duration (days), start date, status
- Statuses: active, paused, completed, abandoned
- Journal: text content, emoji mood (😞😟😐🙂😊), media attachments
- Media: stored as BLOB in SQLite
- Categories: predefined defaults + custom user-created

## Commands

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

## Database Notes
- Database file: `goals.db`
- Stored in app's documents directory
- Default categories inserted on first launch
- Media stored as BLOB (consider size limits for video)

## Naming Conventions
- Files: snake_case
- Classes: PascalCase
- Variables/functions: camelCase
- Constants: camelCase or SCREAMING_SNAKE_CASE

## Before Committing
1. Run `flutter analyze` - no warnings/errors
2. Run `flutter test` - all tests pass
3. Test on at least one platform (Android/Linux)
