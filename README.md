# Media AI (Flutter)
1. `flutter create --platforms=android --org com.example .`  (generates the android/ folder; keeps lib/ and pubspec.yaml)
2. Add to android/app/src/main/AndroidManifest.xml if picking photos fails: `<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>`
3. Run the SQL in supabase/schema.sql in your Supabase project (Free tier).
4. `flutter pub get`
5. Run: `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
   Without the defines the app runs in offline demo mode (admin: admin@rvce.edu.in / admin123).
6. Build: `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
Set a user's `profiles.role` to `admin` in Supabase to grant admin access.
