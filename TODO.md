# Goals App - Development Plan

## Tech Stack
- Flutter (mobile app)
- SQLite via `sqflite` package
- Provider for state management
- Media: `image_picker`, `file_picker`

## Database Schema

```sql
-- Categories (predefined + custom)
CREATE TABLE categories (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  emoji TEXT,
  is_default INTEGER DEFAULT 0
);

-- Goals
CREATE TABLE goals (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  category_id INTEGER REFERENCES categories(id),
  duration_days INTEGER NOT NULL,
  start_date TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active'
);

-- Journal entries (one per day per goal)
CREATE TABLE journal_entries (
  id INTEGER PRIMARY KEY,
  goal_id INTEGER REFERENCES goals(id),
  day_number INTEGER NOT NULL,
  date TEXT NOT NULL,
  content TEXT,
  mood_emoji TEXT,
  UNIQUE(goal_id, day_number)
);

-- Media attachments
CREATE TABLE media_attachments (
  id INTEGER PRIMARY KEY,
  journal_entry_id INTEGER REFERENCES journal_entries(id),
  type TEXT NOT NULL,
  data BLOB NOT NULL,
  created_at TEXT NOT NULL
);
```

## Default Categories
- 🏃 Health & Fitness
- 💼 Work & Career
- 📚 Learning
- 🧘 Mental Wellness
- 💰 Finance
- 🎨 Hobbies & Creativity

## Mood Emojis
😞 😟 😐 🙂 😊 (5-level scale)

## Goal Statuses
- active
- paused
- completed
- abandoned

---

## TODO

### Phase 1: Foundation
- [ ] Add dependencies to pubspec.yaml (sqflite, path, provider, image_picker, file_picker, intl, flutter_slidable)
- [ ] Create folder structure (models/, db/, providers/, screens/, widgets/)

### Phase 2: Database Layer
- [ ] Implement DatabaseHelper singleton
- [ ] Create database init with default categories
- [ ] CRUD for goals
- [ ] CRUD for categories
- [ ] CRUD for journal entries
- [ ] CRUD for media attachments

### Phase 3: Models
- [ ] Goal model (toMap/fromMap)
- [ ] Category model
- [ ] JournalEntry model
- [ ] MediaAttachment model

### Phase 4: State Management
- [ ] GoalsProvider
- [ ] CategoriesProvider
- [ ] Wire providers in main.dart

### Phase 5: UI - Home Screen
- [ ] Goals list with status filtering
- [ ] FAB for new goal
- [ ] Goal creation screen/dialog
- [ ] Category filter chips
- [ ] Progress indicator on goal cards

### Phase 6: UI - Goal Detail Screen
- [ ] Goal info header
- [ ] Day tiles grid/list
- [ ] Color-coded days (empty, filled, today)
- [ ] Status change actions
- [ ] Delete goal option

### Phase 7: UI - Journal Entry Screen
- [ ] Day/date display
- [ ] Text input
- [ ] Emoji mood selector
- [ ] Media capture buttons (camera, gallery, audio, video)
- [ ] Media gallery with delete
- [ ] Save/cancel

### Phase 8: UI - Categories Management
- [ ] List categories
- [ ] Add custom category
- [ ] Edit category
- [ ] Delete custom categories

### Phase 9: Polish
- [ ] App icon
- [ ] Theme configuration
- [ ] Empty states
- [ ] Loading indicators
- [ ] Error handling (snackbars)
- [ ] Date formatting
