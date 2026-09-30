# ElliMate

> **Live together. Communicate better.**

ElliMate is a Flutter mobile application for apartment and roommate management. It helps people living together manage laundry schedules, apartment communication, announcements, notifications, and more.

---

## 📱 Features

- **Authentication** — Register, login, forgot password via Supabase Auth
- **Apartment Management** — Create or join an apartment with a unique invite code
- **Real-time Chat** — Group chat powered by Supabase Realtime
- **Laundry Scheduling** — Book time slots with race-condition-safe conflict prevention
- **Apartment Updates** — Admin-posted announcements with categories
- **Roommates** — View all apartment members
- **Profile** — Edit name and avatar (stored in Supabase Storage)
- **Notification Preferences** — Toggle push notification categories
- **Push Notifications** — Firebase Cloud Messaging (FCM)
- **Offline Handling** — Friendly messages when connectivity is lost

---

## 🛠 Technology Stack

| Layer | Technology |
|---|---|
| Mobile Framework | Flutter / Dart |
| Backend / Database | Supabase (PostgreSQL) |
| Auth | Supabase Auth |
| Realtime | Supabase Realtime |
| File Storage | Supabase Storage |
| Push Notifications | Firebase Cloud Messaging |
| Local Notifications | flutter_local_notifications |
| State Management | Riverpod |
| Navigation | go_router |

---

## ⚙️ Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable, ≥ 3.22)
- [Android Studio](https://developer.android.com/studio) + Android SDK
- [Supabase account](https://supabase.com)
- [Firebase project](https://console.firebase.google.com) (for push notifications)
- Java 17+ (for Android build)

---

## 🚀 Setup

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd ellimate
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

1. Create a new project at [supabase.com](https://supabase.com).
2. In the Supabase SQL editor, run **all SQL** from:
   ```
   supabase/migrations/001_initial_schema.sql
   ```
3. Create a `profile-images` storage bucket in Supabase Dashboard → Storage:
   - Set it to **Public**.
   - Add storage policies (see the SQL migration comments at the bottom of the file).
4. Copy your **Project URL** and **anon key** from Settings → API.

### 4. Set environment variables

You can pass Supabase credentials at build time using `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Or create a `.env.sh` helper (do NOT commit this):

```bash
export SUPABASE_URL=https://your-project.supabase.co
export SUPABASE_ANON_KEY=your-anon-key
```

### 5. Configure Firebase (optional — for push notifications)

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Add an Android app with package name `com.ellimate.ellimate`.
3. Download `google-services.json` and place it at:
   ```
   android/app/google-services.json
   ```
4. Follow the [FlutterFire setup guide](https://firebase.flutter.dev/docs/overview).

> ⚠️ Do NOT commit `google-services.json` to version control.

---

## 🏃 Running the App

### Development mode

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Run static analysis

```bash
flutter analyze
```

### Run tests

```bash
flutter test
```

---

## 📦 Building for Android

### Debug APK

```bash
flutter build apk --debug \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Release APK

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🗄 Database Migrations

All schema is in `supabase/migrations/001_initial_schema.sql`.

Run via Supabase SQL editor, or with the Supabase CLI:

```bash
supabase db push
```

---

## 🔐 Security Notes

- Row Level Security (RLS) is enabled on all tables.
- Users can only read/write data belonging to their apartment.
- Laundry slot conflicts are prevented at the database level using a `UNIQUE` constraint and a transactional RPC function.
- The Supabase service-role key is **never** used in the Flutter client.
- Secrets are passed via `--dart-define` at build time, not hard-coded.

---

## 🧪 Test Checklist

- [ ] Register new account
- [ ] Login / logout
- [ ] Forgot password email
- [ ] Create apartment
- [ ] Join apartment with invite code
- [ ] Invalid invite code
- [ ] Duplicate join
- [ ] Send and receive chat messages in real time
- [ ] Book laundry slot
- [ ] Conflict booking (two users, same slot)
- [ ] Post apartment update (admin only)
- [ ] View roommates
- [ ] Edit profile + upload avatar
- [ ] Toggle notification preferences
- [ ] Session persistence (close & reopen app)
- [ ] Offline behavior

---

## 📁 Project Structure

```
lib/
  main.dart              # App entry point
  app/
    app.dart             # Root widget
    router.dart          # go_router configuration
    theme/               # Colors, typography, theme
  core/
    constants/           # App-wide constants
    errors/              # Exception classes
    services/            # Riverpod providers
    utils/               # Helper utilities
  features/
    auth/                # Auth screens, repository, providers
    apartment/           # Apartment creation/joining
    home/                # Home dashboard + shell
    laundry/             # Laundry scheduling
    chat/                # Real-time group chat
    updates/             # Apartment announcements
    roommates/           # Member list
    profile/             # Profile management
    settings/            # All settings screens
    notifications/       # Notification list
  shared/
    models/              # Freezed data models
    widgets/             # Reusable UI components
supabase/
  migrations/
    001_initial_schema.sql
```

---

## 📞 Support

Contact: support@ellimate.app
