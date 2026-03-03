# 🚀 QUICK START GUIDE
## Get Your Dating App Database Live in 20 Minutes

---

## WHAT YOU HAVE

✅ **Complete SQL Database** (35+ tables, 8 schemas)  
✅ **All Dart Models** (18 Freezed classes, production-ready)  
✅ **Setup Guides** (Step-by-step instructions)  
✅ **Documentation** (Reference & examples)  

**Total Time to Launch**: ~20 minutes + 5 minutes for code generation

---

## THE 3-STEP SETUP

### STEP 1️⃣: CREATE SUPABASE ACCOUNT (5 minutes)

```
1. Open: https://supabase.com
2. Click "Start your project" 
3. Sign up with email/GitHub
4. Create new project:
   - Name: "dating_apps"
   - Password: Save securely
   - Region: Choose closest to users
5. Wait for provisioning (~2 min)
```

**You'll get**:
- Project URL: `https://[id].supabase.co`
- Anon Key: `eyJ...`
- Service Role: `eyJ...` (keep secret)

---

### STEP 2️⃣: DEPLOY DATABASE SCHEMA (5 minutes)

**In Supabase Dashboard**:

1. Click **SQL Editor** (left sidebar)
2. Click **New Query**
3. **Copy entire content** from:  
   `/scripts/complete_database_schema_all_phases.sql`
4. **Paste** into the editor
5. Click **Run** (blue button, top-right)
6. Wait for completion (you'll see ✅ pass all 35+ tables created)

**Verify Success**:
- Check **Database** → **Schemas** (see 8 schemas)
- Check **Tables** (see 35+ tables)
- No red error messages

---

### STEP 3️⃣: INITIALIZE MODELS (5 minutes)

**In terminal** (from project root):

```bash
# Navigate to app
cd app

# Get dependencies
flutter pub get

# Generate Freezed models
flutter pub run build_runner build

# Wait for completion...
# You'll see: ✅ Succeeded after X.XXs
```

**If you see errors**:
```bash
# Clean and try again
flutter pub run build_runner clean
flutter pub run build_runner build
```

**Success = No red errors + Generated files appear**:
- `profile_models.freezed.dart`
- `swipe_models.freezed.dart`
- `messaging_models.freezed.dart`
- `verification_models.freezed.dart`
- `payment_models.freezed.dart`
- `admin_models.freezed.dart`

---

## WHAT'S NEXT (OPTIONAL SETUP - 15 min)

**Follow**: `/scripts/SUPABASE_SETUP_GUIDE.md` (Steps 4-10)

This enables:
- ✅ Real-time messaging (WebSocket)
- ✅ Phone OTP authentication
- ✅ Photo storage (cloud)
- ✅ Row Level Security (RLS)

**Not blocking**: You can start building UI without these

---

## VERIFY IT WORKS

### Test 1: Database Connection
```bash
# In Flutter terminal
flutter pub add supabase_flutter

# Create a simple test:
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://[your-project-id].supabase.co',
    anonKey: '[your-anon-key]',
  );
  print('✅ Connected to Supabase!');
}
```

### Test 2: Query a Table
```dart
final response = await Supabase.instance.client
  .from('user_management.users')
  .select('count', const FetchOptions(count: CountOption.exact))
  .execute();

print('✅ Users table exists: ${response.data}');
```

---

## FILE LOCATIONS

```
📁 Project Root
├── 📁 scripts/
│   ├── complete_database_schema_all_phases.sql  ← Copy-paste to Supabase
│   ├── SUPABASE_SETUP_GUIDE.md                  ← Full setup instructions
│   ├── DART_MODELS_REFERENCE.md                 ← Model details & examples
│   ├── DEVELOPMENT_ROADMAP.md                   ← Timeline & checklist
│   └── COMPLETION_SUMMARY.md                    ← What you got
│
└── 📁 app/lib/features/
    ├── profile/models/profile_models.dart       ← User, Preferences, Photo
    ├── swipe/models/swipe_models.dart           ← Swipe, Match
    ├── messaging/models/messaging_models.dart   ← Message
    ├── verification/models/verification_models.dart ← Verification, Report
    ├── payment/models/payment_models.dart       ← Plans, Subscription, Payment
    └── admin/models/admin_models.dart           ← AdminUser, Notification, etc
```

---

## ENVIRONMENT SETUP

### Create `app/.env.local`:
```
SUPABASE_URL=https://[your-project-id].supabase.co
SUPABASE_ANON_KEY=[your-anon-key]
SUPABASE_SERVICE_ROLE=[your-service-role-key]
```

### Load in `app/lib/main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(const MyApp());
}
```

---

## QUICK TROUBLESHOOTING

| Problem | Fix |
|---------|-----|
| "SQL syntax error" | Make sure you copied the ENTIRE file (all 35+ tables) |
| "Models not generating" | Run: `flutter pub run build_runner clean && flutter pub run build_runner build` |
| "Supabase connection fails" | Check keys in .env match Supabase dashboard |
| "Can't find module" | Run: `flutter pub get` in app/ folder |
| "Models compile errors" | Update to latest pubspec.yaml (run `flutter pub upgrade`) |

---

## WHAT YOU CAN DO NOW

✅ **Immediately**:
- Execute SQL queries in Supabase
- Build repository classes
- Create Riverpod providers
- Build UI screens

✅ **Next**:
- Implement authentication
- Build matching algorithm
- Create messaging interface
- Setup subscriptions

✅ **Later**:
- Video calling (Jitsi)
- Advanced features (Phase 2)
- Growth features (Phase 3)

---

## DATABASE QUICK REFERENCE

### 8 Schemas Available:

| Schema | Tables | Purpose |
|--------|--------|---------|
| `user_management` | 5 | Profiles, preferences, photos |
| `matching` | 3 | Swipes, matches, messages |
| `safety` | 3 | Verification, reports, flags |
| `monetization` | 3 | Plans, subscriptions, payments |
| `admin_panel` | 2 | Admin users, notifications |
| `analytics` | 2 | Activity logs, metrics |
| `advanced_features` | 7 | Phase 2: Video, liveness, SOS |
| `growth` | 9 | Phase 3: AI, events, referrals |

### Most Used Tables:

```sql
-- Get all users
SELECT * FROM user_management.users;

-- Get a user's preferences
SELECT * FROM user_management.user_preferences WHERE user_id = 'xxx';

-- Get matches for a user
SELECT * FROM matching.matches 
WHERE user_id_1 = 'xxx' OR user_id_2 = 'xxx';

-- Get active subscriptions
SELECT * FROM monetization.subscriptions 
WHERE status = 'active' AND user_id = 'xxx';
```

---

## MODELS QUICK REFERENCE

### Profile Management
```dart
User           // {id, name, gender, dateOfBirth, ...}
Preferences    // {userId, seekingGenders, minAge, maxAge, ...}
Photo          // {userId, photoUrl, ordering, isModerated, ...}
UserSettings   // {userId, showAge, notifyNewMatch, theme, ...}
```

### Matching
```dart
Swipe          // {userId, targetUserId, isLike, createdAt}
Match          // {userId1, userId2, status, lastMessageAt, ...}
Message        // {matchId, senderId, text, deliveredAt, readAt, ...}
```

### Safety & Verification
```dart
Verification   // {userId, status, idPhoto, selfiePhoto, ...}
Report         // {reporterId, reportedUserId, reason, status, ...}
SafetyFlag     // {userId, flagType, severity, isResolved, ...}
```

### Monetization
```dart
SubscriptionPlan   // {name, monthlyPrice, features, ...}
Subscription       // {userId, planId, startDate, autoRenew, ...}
Payment            // {userId, amount, method, razorpayId, ...}
```

### Admin & Analytics
```dart
AdminUser          // {userId, role, permissions, ...}
Notification       // {userId, type, title, body, ...}
ActivityLog        // {userId, action, resourceType, ...}
AnalyticsMetrics   // {metricDate, totalUsers, activeUsers, ...}
```

---

## SUPPORT & RESOURCES

- **Supabase Docs**: https://supabase.com/docs
- **Flutter Docs**: https://flutter.dev
- **Freezed Docs**: https://pub.dev/packages/freezed
- **Riverpod Docs**: https://riverpod.dev

**Documentation Files**:
- Setup Guide: `/scripts/SUPABASE_SETUP_GUIDE.md`
- Models Ref: `/scripts/DART_MODELS_REFERENCE.md`
- Roadmap: `/scripts/DEVELOPMENT_ROADMAP.md`
- Summary: `/scripts/COMPLETION_SUMMARY.md`

---

## NEXT STEPS

1. ✅ **RIGHT NOW** (5 min): Create Supabase account
2. ✅ **THEN** (5 min): Execute SQL schema
3. ✅ **THEN** (5 min): Run model code generation
4. ✅ **NEXT** (30 min): Create repository classes
5. ✅ **THEN** (2-3 hrs): Build first UI screen
6. ✅ **FINALLY** (1-2 weeks): Complete Phase 1 features

---

## YOU'RE READY! 🎉

Everything is prepared. Database schema is copy-paste ready. Models are written. You just need to:

1. Paste SQL into Supabase → Done!
2. Run `flutter pub run build_runner build` → Done!
3. Start building features! 🚀

**Total setup time: 20 minutes**  
**Cost: $0/month free tier**  
**Result: Production-ready database**

---

**Document Version**: 1.0  
**Status**: ✅ READY TO USE  
**Last Updated**: February 21, 2026
