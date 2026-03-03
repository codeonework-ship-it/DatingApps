# SUPABASE MIGRATION CHECKLIST & EXECUTION GUIDE
## Step-by-Step Database Deployment

**Project URL**: https://ufrmtgriqpyzqaewvtgn.supabase.co  
**Status**: Ready for Execution  
**Date**: February 21, 2026

---

## 🎯 OBJECTIVES

1. ✅ Deploy complete SQL schema (35+ tables, 8 schemas)
2. ✅ Configure Supabase for real-time features
3. ✅ Set up authentication (Phone OTP)
4. ✅ Prepare Flutter app for integration
5. ✅ Verify all systems operational

---

## 📋 PHASE 1: PRE-MIGRATION (Verify Everything)

### ✅ Verify Local Files

- [ ] SQL schema exists: `/scripts/complete_database_schema_all_phases.sql`
- [ ] All Dart models created in `/app/lib/features/*/models/`
- [ ] Models:
  - [x] profile_models.dart (5 classes)
  - [x] swipe_models.dart (2 classes)
  - [x] messaging_models.dart (1 class)
  - [x] verification_models.dart (3 classes)
  - [x] payment_models.dart (3 classes)
  - [x] admin_models.dart (4 classes)

### ✅ Verify Supabase Project

- [ ] Project created at: https://ufrmtgriqpyzqaewvtgn.supabase.co
- [ ] Can login to dashboard
- [ ] PostgreSQL database accessible
- [ ] Credentials saved:
  - Project URL: https://ufrmtgriqpyzqaewvtgn.supabase.co
  - Publishable Key: sb_publishable_fdrhcB-7-G9yh6RJmqe4mw_acCVKC9_

### ✅ Environment Setup

- [ ] `.env.local` created: `/app/.env.local`
- [ ] Service role key obtained from dashboard
- [ ] Credentials NOT committed to git

---

## 📋 PHASE 2: SQL EXECUTION (30 minutes)

### Step 1: Open Supabase SQL Editor

```
1. Go to: https://ufrmtgriqpyzqaewvtgn.supabase.co
2. Login with Supabase account
3. Click: "SQL Editor" (left sidebar)
4. Click: "New query"
```

✅ **Checkpoint**: SQL Editor open, blank query ready

---

### Step 2: Copy Database Schema

**Location**: `/scripts/complete_database_schema_all_phases.sql`

```bash
# Terminal command to copy file content
cat "/Users/anandsadasivan/Documents/Workspaces/Development/GitHub/Dating apps/scripts/complete_database_schema_all_phases.sql"
```

**Copy**:
- Open the SQL file
- Select all content (Cmd+A)
- Copy (Cmd+C)

✅ **Checkpoint**: SQL schema copied to clipboard

---

### Step 3: Execute Schema in Supabase

```
1. Click in SQL Editor (paste area)
2. Paste SQL (Cmd+V)
3. Click "Run" button (or Cmd+Enter)
4. Wait for execution (should take 10-30 seconds)
```

**Expected Output**:
```
✓ Query executed successfully
```

❌ **If Error Occurs**:
- Check for "already exists" errors → Schemas/tables may exist
- Check for syntax errors → Use `\l` to list databases
- For foreign key errors → Run tables in order (dependencies)

✅ **Checkpoint**: SQL executed without errors

---

### Step 4: Verify Schema Creation

Run these verification queries in Supabase SQL Editor:

**Query 1: Check all schemas**
```sql
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name IN ('user_management', 'matching', 'safety', 'monetization', 'admin_panel', 'analytics', 'advanced_features', 'growth')
ORDER BY schema_name;
```

**Expected Result**: 8 rows (all schemas listed)

**Query 2: Count tables**
```sql
SELECT COUNT(*) as total_tables
FROM information_schema.tables 
WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
```

**Expected Result**: 35+ tables

**Query 3: List all tables by schema**
```sql
SELECT table_schema, table_name
FROM information_schema.tables 
WHERE table_schema IN ('user_management', 'matching', 'safety', 'monetization', 'admin_panel', 'analytics', 'advanced_features', 'growth')
ORDER BY table_schema, table_name;
```

**Expected Result**: All 35+ tables listed

✅ **Checkpoint**: All schemas and tables verified

---

## 📋 PHASE 3: REALTIME CONFIGURATION (15 minutes)

### Step 5: Enable Real-time on Critical Tables

Navigate to: **Dashboard → Database → Replication**

**Enable Realtime for**:

1. **matching.messages**
   - [ ] Select table
   - [ ] Toggle "Realtime" ON
   - [ ] Save

2. **matching.matches**
   - [ ] Toggle "Realtime" ON
   - [ ] Save

3. **admin_panel.notifications**
   - [ ] Toggle "Realtime" ON
   - [ ] Save

4. **user_management.users** (optional, for profile updates)
   - [ ] Toggle "Realtime" ON
   - [ ] Save

✅ **Checkpoint**: Real-time enabled for messaging

---

## 📋 PHASE 4: AUTHENTICATION SETUP (10 minutes)

### Step 6: Configure Phone OTP

Navigate to: **Dashboard → Authentication → Providers**

**Click "Phone"**:
- [ ] Toggle "Enable Phone Auth" → ON
- [ ] Keep "Auto-confirm" → OFF (for security)
- [ ] Save changes

✅ **Checkpoint**: Phone OTP authentication enabled

---

### Step 7: Get Service Role Key

Navigate to: **Dashboard → Settings → API**

**Copy Service Role Key**:
- [ ] Find "Service Role Key"
- [ ] Click "Show" or eye icon
- [ ] Copy the key
- [ ] Paste into `.env.local` as `SUPABASE_SERVICE_ROLE`

✅ **Checkpoint**: Service role key saved in .env.local

---

## 📋 PHASE 5: FLUTTER SETUP (15 minutes)

### Step 8: Update Environment Variables

**File**: `/app/.env.local`

```env
SUPABASE_URL=https://ufrmtgriqpyzqaewvtgn.supabase.co
SUPABASE_ANON_KEY=sb_publishable_fdrhcB-7-G9yh6RJmqe4mw_acCVKC9_
SUPABASE_SERVICE_ROLE=<YOUR_SERVICE_ROLE_KEY>
```

Verify:
- [ ] `.env.local` exists in `/app/`
- [ ] Contains all 3 keys
- [ ] File is NOT in git (check .gitignore)

✅ **Checkpoint**: Environment variables configured

---

### Step 9: Generate Freezed Models

```bash
cd "/Users/anandsadasivan/Documents/Workspaces/Development/GitHub/Dating apps/app"

# Get dependencies
flutter pub get

# Generate models
flutter pub run build_runner build
```

**Expected Output**:
```
Building with .../build_runner/build.dart
Building with sound null safety
............................
✓ Built instance of build app
Generated 6 files
```

**Verify Generated Files**:
```bash
# Check for generated files
find . -name "*.freezed.dart" | head -10
find . -name "*.g.dart" | head -10
```

✅ **Checkpoint**: All models generated successfully

---

### Step 10: Test Database Connection

**Create test file**: `/app/test_supabase_connection.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testConnection() async {
  try {
    final supabase = Supabase.instance.client;
    
    // Test read
    final users = await supabase
      .from('user_management.users')
      .select()
      .limit(1);
    
    print('✅ Connection successful!');
    print('Database responsive: ${users.isNotEmpty || users.isEmpty}');
    
  } catch (e) {
    print('❌ Connection failed: $e');
  }
}

void main() async {
  await Supabase.initialize(
    url: 'https://ufrmtgriqpyzqaewvtgn.supabase.co',
    anonKey: 'sb_publishable_fdrhcB-7-G9yh6RJmqe4mw_acCVKC9_',
  );
  
  await testConnection();
}
```

**Run test**:
```bash
dart test_supabase_connection.dart
```

✅ **Checkpoint**: Database connection verified

---

## ✅ FINAL VERIFICATION CHECKLIST

### Database
- [ ] 8 schemas created
- [ ] 35+ tables present
- [ ] All indexes created
- [ ] Foreign key relationships intact
- [ ] RLS policies configurable

### Real-time
- [ ] Realtime enabled for messages
- [ ] Realtime enabled for matches
- [ ] Realtime enabled for notifications
- [ ] Subscriptions working in tests

### Authentication
- [ ] Phone OTP enabled
- [ ] Service role key obtained
- [ ] Anon key in .env.local
- [ ] JWT tokens working

### Flutter App
- [ ] `.env.local` configured
- [ ] Freezed models generated
- [ ] No build errors
- [ ] Supabase connection tested
- [ ] Can query tables successfully

---

## 🎯 MIGRATION STATUS TRACKER

**Phase 1: Pre-Migration**
- [ ] Files verified
- [ ] Supabase project ready
- [ ] Credentials saved

**Phase 2: SQL Execution** ← START HERE
- [ ] [ ] Run SQL script
- [ ] [ ] Verify schemas
- [ ] [ ] Verify tables

**Phase 3: Configuration** ← PHASE 2 DONE
- [ ] [ ] Enable realtime
- [ ] [ ] Setup authentication
- [ ] [ ] Get service role key

**Phase 4: Flutter Setup** ← PHASE 3 DONE
- [ ] [ ] Update .env.local
- [ ] [ ] Generate models
- [ ] [ ] Test connection

**Phase 5: Launch** ← WHEN PHASE 4 DONE
- [ ] [ ] Run full test suite
- [ ] [ ] Deploy to emulator
- [ ] [ ] Test all features
- [ ] [ ] Create backup

---

## 🚨 COMMON ISSUES & FIXES

| Issue | Cause | Fix |
|-------|-------|-----|
| "Schema already exists" | Schema created before | Drop schema and re-run, OR update script to use `IF NOT EXISTS` |
| "Table not found" | SQL not executed fully | Run full SQL script again, check for errors |
| Realtime not working | Table doesn't have replication | Enable realtime in Dashboard → Database → Replication |
| Connection refused | Wrong URL or network issue | Verify SUPABASE_URL is correct, check internet |
| "Role postgres cannot..." | Permission issue | Use service role key for backend operations |
| Models not generating | Missing dependencies | Run `flutter pub get && flutter pub run build_runner clean` |

---

## 📊 EXPECTED RESULTS

**After Completion**:
- ✅ Live PostgreSQL database (35+ tables ready)
- ✅ Real-time messaging infrastructure
- ✅ Phone OTP authentication ready
- ✅ Flutter app can query data
- ✅ All models type-safe and generated
- ✅ <300ms query performance on indexed columns
- ✅ Zero-downtime deployment ready

**Time Estimate**: 1-2 hours total
- Phase 1: 10 min
- Phase 2: 30 min
- Phase 3: 15 min
- Phase 4: 20 min
- Testing: 10-15 min

---

## 📞 NEXT STEPS

1. ✅ **Complete migration** → Follow this checklist
2. 🔨 **Build repositories** → Connect models to Supabase
3. 🎨 **Build UI screens** → Create user-facing features
4. 🧪 **Test thoroughly** → All flows end-to-end
5. 🚀 **Deploy to production** → Go live!

---

## 💾 BACKUP STRATEGY

**After deployment, immediately**:
```sql
-- Backup schema
pg_dump -h ufrmtgriqpyzqaewvtgn.supabase.co -U postgres -d postgres > backup.sql

-- Backup anonymously via Supabase dashboard
Settings → Database → Backups → Create backup
```

---

## 📌 IMPORTANT

- ✅ Keep `.env.local` secure (never commit to git)
- ✅ Rotate credentials monthly
- ✅ Monitor database usage (Settings → Billing)
- ✅ Test RLS policies with actual user data
- ✅ Keep Supabase SDK updated (`flutter pub upgrade`)
- ✅ Document any custom SQL modifications

---

**Status**: ✅ READY FOR EXECUTION  
**Last Updated**: February 21, 2026  
**Next Review**: After Phase 2 completion

---

## 🟢 YOU'RE NOW READY!

Follow the phases above in order for a smooth migration.

**Estimated time to live database**: 2 hours

**Questions?** Refer to SUPABASE_MIGRATION_GUIDE.md for detailed instructions

Let's deploy! 🚀
