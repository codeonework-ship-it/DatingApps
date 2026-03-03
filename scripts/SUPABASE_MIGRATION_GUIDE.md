# SUPABASE MIGRATION GUIDE
## Database Deployment Instructions

**Date**: February 21, 2026  
**Status**: Ready for Deployment  
**Supabase Project**: https://ufrmtgriqpyzqaewvtgn.supabase.co

---

## ✅ CREDENTIALS PROVIDED

```
Project URL   : https://ufrmtgriqpyzqaewvtgn.supabase.co
Publishable Key: sb_publishable_fdrhcB-7-G9yh6RJmqe4mw_acCVKC9_
```

**⚠️ IMPORTANT**: 
- Keep these credentials secure
- Add to .env.local (never commit to git)
- Use service role key for backend operations
- Use publishable key for frontend/client

---

## 🚀 STEP 1: REVIEW SUPABASE PROJECT

### Dashboard Checklist
- [ ] Login to https://ufrmtgriqpyzqaewvtgn.supabase.co
- [ ] Navigate to Project Settings
- [ ] Copy Service Role Key (needed for backend)
- [ ] Verify database is accessible
- [ ] Check PostgreSQL version (should be 15.1+)

---

## 🚀 STEP 2: DEPLOY DATABASE SCHEMA

### Execute SQL Script

1. **Open SQL Editor**
   - Dashboard → SQL Editor
   - Click "New Query"

2. **Import Schema**
   - Open: `/scripts/complete_database_schema_all_phases.sql`
   - Copy entire content
   - Paste into SQL Editor
   - Click "Run"

3. **Verify Execution**
   - Check console for "Query executed successfully"
   - No errors should appear
   - Status should show green checkmark

### After SQL Execution

```sql
-- Verify all schemas created
SELECT schema_name FROM information_schema.schemata 
WHERE schema_name IN ('user_management', 'matching', 'safety', 'monetization', 'admin_panel', 'analytics', 'advanced_features', 'growth');

-- Verify table count (should be 35+)
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
```

---

## 🚀 STEP 3: ENABLE REALTIME

Navigate to **Database → Replication** and enable for:
- `matching.messages` (real-time messaging)
- `matching.matches` (live match updates)
- `user_management.users` (profile updates)
- `admin_panel.notifications` (push notifications)

### Steps:
1. Dashboard → Database → Replication
2. For each table above:
   - Click the table
   - Toggle "Enable Realtime" ON
   - Click "Save"

---

## 🚀 STEP 4: CREATE SERVICE ROLE KEY

1. **Settings → API**
2. Under "Auth tokens":
   - Find "Service Role Key"
   - Click show/copy
   - Save for backend operations

---

## 🚀 STEP 5: CONFIGURE AUTHENTICATION

### Enable Phone OTP

1. **Authentication → Providers**
2. **Phone tab**:
   - Toggle "Enable Phone Auth"
   - Keep "Auto-confirm" OFF for security

### Test Phone OTP
```bash
# Use Supabase CLI or dashboard to test
supabase functions invoke send-otp --body '{"phone": "+919999999999"}'
```

---

## 🚀 STEP 6: STORAGE SETUP

### Create Photo Upload Bucket

1. **Storage → New Bucket**
2. **Name**: `profile-photos`
3. **Access**: Private (for safety)
4. Click "Create"

### Configure RLS Policies

```sql
-- Allow users to upload their own photos
CREATE POLICY "Users can upload their own photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to read their own photos
CREATE POLICY "Users can read their own photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'profile-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

---

## 🚀 STEP 7: ROW LEVEL SECURITY (RLS)

### Enable RLS for Critical Tables

```sql
-- Enable RLS
ALTER TABLE user_management.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE matching.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE matching.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_management.user_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only see their own profile
CREATE POLICY "Users can view own profile"
ON user_management.users
FOR SELECT
TO authenticated
USING (auth.uid()::text = id);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
ON user_management.users
FOR UPDATE
TO authenticated
USING (auth.uid()::text = id);

-- Users can only see messages they're part of
CREATE POLICY "Users can view their messages"
ON matching.messages
FOR SELECT
TO authenticated
USING (
  auth.uid()::text = sender_id OR
  EXISTS (
    SELECT 1 FROM matching.matches m
    WHERE m.id = match_id
    AND (m.user_id_1 = auth.uid()::text OR m.user_id_2 = auth.uid()::text)
  )
);
```

---

## 🚀 STEP 8: ENVIRONMENT VARIABLES

### Create `app/.env.local`

```env
# Supabase Configuration
SUPABASE_URL=https://ufrmtgriqpyzqaewvtgn.supabase.co
SUPABASE_ANON_KEY=sb_publishable_fdrhcB-7-G9yh6RJmqe4mw_acCVKC9_
SUPABASE_SERVICE_ROLE=<paste-service-role-key-from-dashboard>

# API Configuration
API_TIMEOUT=30000
LOG_LEVEL=info

# Feature Flags
ENABLE_VIDEO_CALLS=true
ENABLE_VERIFICATION=true
ENABLE_PAYMENTS=true
```

### Add to `.gitignore`
```
.env.local
.env.*.local
*.key
*.secret
```

---

## 🚀 STEP 9: TEST CONNECTION

### Test Supabase Connection

```bash
cd app

# Install dependencies
flutter pub get

# Test connection
flutter run -v

# Check logs for "Supabase connected successfully"
```

### Manual Connection Test

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testSupabaseConnection() async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase
      .from('user_management.users')
      .select()
      .limit(1);
    
    print('✅ Supabase connection successful!');
    print('Response: $response');
  } catch (e) {
    print('❌ Connection failed: $e');
  }
}
```

---

## 🚀 STEP 10: VERIFY ALL TABLES

### Quick Table Verification

Run these queries in Supabase SQL Editor:

```sql
-- List all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema IN ('user_management', 'matching', 'safety', 'monetization', 'admin_panel', 'analytics', 'advanced_features', 'growth')
ORDER BY table_schema, table_name;

-- Check indexes
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname IN ('user_management', 'matching', 'safety', 'monetization', 'admin_panel', 'analytics', 'advanced_features', 'growth')
ORDER BY tablename;

-- Verify foreign keys
SELECT constraint_name, table_name, column_name, foreign_table_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('user_management', 'matching', 'safety', 'monetization', 'admin_panel', 'analytics', 'advanced_features', 'growth')
AND foreign_table_name IS NOT NULL;
```

---

## ✅ MIGRATION CHECKLIST

### Pre-Migration
- [ ] Supabase project created
- [ ] Credentials saved securely
- [ ] Service role key obtained

### SQL Deployment
- [ ] SQL script reviewed
- [ ] Schema executed successfully
- [ ] All 8 schemas created (verified with query)
- [ ] All 35+ tables created (verified with query)

### Configuration
- [ ] Realtime enabled for: messages, matches, notifications
- [ ] Phone OTP configured
- [ ] Storage bucket created
- [ ] RLS policies set up
- [ ] Service role key saved

### Environment Setup
- [ ] `.env.local` created with credentials
- [ ] `.gitignore` updated to exclude `.env.local`
- [ ] Pubspec.yaml has all dependencies
- [ ] `flutter pub get` executed successfully

### Testing
- [ ] Connection test passed
- [ ] Can query user_management.users
- [ ] Can insert test data
- [ ] Real-time subscriptions working
- [ ] Phone OTP functional

### Documentation
- [ ] Supabase credentials secured
- [ ] Migration notes recorded
- [ ] Team notified of deployment
- [ ] Backup of schema created

---

## 🔒 SECURITY CHECKLIST

- [ ] Service Role Key stored securely (not in git)
- [ ] Anon Key used only in frontend
- [ ] RLS enabled on all user-specific tables
- [ ] Policies restrict data by user ID
- [ ] Storage bucket set to private
- [ ] No sensitive data in logs
- [ ] Rate limiting configured (if available)

---

## 📊 POST-MIGRATION VERIFICATION

### Database Health Check

```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity WHERE state = 'active';

-- Check table sizes
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname IN ('user_management', 'matching', 'safety', 'monetization', 'admin_panel', 'analytics', 'advanced_features', 'growth')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check for any errors in logs
SELECT * FROM pg_stat_database ORDER BY stats_reset DESC LIMIT 10;
```

---

## 🐛 TROUBLESHOOTING

| Problem | Solution |
|---------|----------|
| "Schema does not exist" error | Run the complete SQL script again, ensure no copy-paste errors |
| RLS policies not working | Verify `auth.uid()` returns correct user ID, check policy conditions |
| Real-time not live | Ensure table has replication enabled in Supabase console |
| Connection timeout | Check internet connection, verify SUPABASE_URL is correct |
| "Table not found" | Run schema verification queries to check table existence |
| Foreign key constraint errors | Verify parent tables exist before inserting into child tables |

---

## 📞 NEXT STEPS

1. **Complete SQL Deployment** → Database live
2. **Run Model Code Generation** → `flutter pub run build_runner build`
3. **Create Repositories** → Connect models to Supabase
4. **Build Features** → Use repositories in business logic
5. **Test Thoroughly** → All flows working end-to-end

---

## 📌 IMPORTANT NOTES

- ✅ **Do NOT share credentials** with anyone outside your team
- ✅ **Backup Supabase database** regularly (Settings → Database → Backups)
- ✅ **Monitor usage** against free tier limits (Settings → Billing)
- ✅ **Keep SDK updated** (`flutter pub upgrade`)
- ✅ **Test all flows** before going to production
- ✅ **Enable backups** immediately after setup

---

## 📋 USEFUL COMMANDS

```bash
# Test Supabase CLI
supabase status

# Generate models from schema
flutter pub run build_runner build

# Watch for model changes
flutter pub run build_runner watch

# Run app with verbose logging
flutter run -v

# Format code
dart format

# Run linter
flutter analyze
```

---

**Document Version**: 1.0  
**Status**: Ready to Deploy  
**Created**: February 21, 2026

---

## ✨ You're Ready!

Your database is fully designed and prepared. Follow these 10 steps to go live.

**Estimated time**: 30-45 minutes for complete setup

**Result**: Production-ready PostgreSQL database with 35+ tables, ready for Flutter app integration

Let's build! 🚀
