# SUPABASE SETUP GUIDE
# Complete Database Initialization

**Date**: February 21, 2026  
**Database Name**: dating_apps  
**Status**: Ready to Deploy

---

## STEP 1: CREATE SUPABASE PROJECT

### 1.1 Sign Up/Login
```
Go to: https://supabase.com
Sign up or login to your account
```

### 1.2 Create New Project
```
Click: "New Project"
Name: dating_apps
Database Password: [Create strong password - save it!]
Region: Choose nearest to your users
Plan: Free (suitable for Phase 1+1.5)
```

### 1.3 Wait for Initialization
```
Database initializes (~30 seconds)
You'll receive:
  - Project URL
  - Anon Key
  - Service Role Key
  - Database credentials
```

---

## STEP 2: GET CONNECTION CREDENTIALS

### 2.1 Get Project URL
```
Dashboard → Settings → API
Copy: Project URL
Example: https://xxxxx.supabase.co
```

### 2.2 Get API Keys
```
Dashboard → Settings → API
Copy: Anon Key (public key)
Copy: Service Role Key (private key)
```

### 2.3 Get Database Connection String
```
Dashboard → Settings → Database
Copy: Connection string (use for direct database access)
Format: postgresql://postgres:[PASSWORD]@...
```

---

## STEP 3: CREATE DATABASE TABLES

### 3.1 Import SQL Schema
```
1. Open Supabase Dashboard
2. Click: SQL Editor
3. Click: New Query
4. Paste entire content of: scripts/complete_database_schema_all_phases.sql
5. Click: Run (or Ctrl+Enter)
```

### 3.2 What Gets Created
```
Schemas (8):
  ✅ user_management (users, preferences, photos)
  ✅ matching (swipes, matches, messages)
  ✅ safety (verifications, reports, flags)
  ✅ monetization (subscriptions, payments)
  ✅ admin_panel (admin users, notifications)
  ✅ analytics (logs, metrics)
  ✅ advanced_features (video calls, liveness, SOS)
  ✅ growth (AI, events, referrals, partnerships)

Tables (35+):
  ✅ All Phase 1, 1.5, 2, 3 tables
  ✅ Indexes optimized for performance
  ✅ Foreign key constraints
  ✅ Check constraints for validation
```

### 3.3 Verify Tables Created
```
Dashboard → Database → Tables
You should see 35+ tables organized by schema
Each table has green checkmark ✅
```

---

## STEP 4: ENABLE REAL-TIME

### 4.1 Enable Realtime on Core Tables
```
Dashboard → Database → Tables

For these tables, toggle "Realtime" ON:
  ✅ matching.messages
  ✅ matching.matches
  ✅ user_management.users (online status)
  ✅ admin_panel.notifications
  ✅ advanced_features.sosAlerts
```

### 4.2 What This Does
```
Enables WebSocket subscriptions
Real-time updates for messaging
Live presence indicators
Instant notifications
```

---

## STEP 5: SETUP AUTHENTICATION

### 5.1 Enable Email/Password Auth
```
Dashboard → Authentication → Providers
Click: Email/Password toggle ON
Configure:
  ✅ Email confirmation (optional)
  ✅ Double confirm change (optional)
```

### 5.2 Enable Phone OTP (for login)
```
Dashboard → Authentication → Providers
Click: Phone toggle ON
Configure:
  Option 1: Use Twilio (recommended for production)
    - Add Twilio Account SID
    - Add Twilio Auth Token
    - Add Twilio Phone Number
  
  Option 2: Use Supabase test credentials (for development)
    - Default test mode
```

### 5.3 Configure Auth Settings
```
Dashboard → Authentication → Settings
Set:
  ✅ Site URL: http://localhost:3000 (for testing)
  ✅ Redirect URLs: 
      - http://localhost:3000/auth/callback
      - https://yourapp.com/auth/callback (production)
  ✅ JWT expiry: 3600 seconds (1 hour)
  ✅ Refresh token rotation: enabled
```

---

## STEP 6: SETUP STORAGE (FOR PHOTOS)

### 6.1 Create Storage Buckets
```
Dashboard → Storage → Buckets
Click: New Bucket

Create bucket: "photos"
  Public: No (for privacy)
  Allowed file types: image/jpeg, image/png, image/webp

Create bucket: "verifications"
  Public: No (sensitive data)
  Allowed file types: image/jpeg, image/png, image/webp
```

### 6.2 Configure Storage Policies
```
Dashboard → Storage → Policies

For photos bucket:
  ✅ Users can read own photos
  ✅ Users can upload own photos
  ✅ Users can delete own photos

For verifications bucket:
  ✅ Admin can read all
  ✅ Users can upload own
  ✅ Users can't delete after verification
```

---

## STEP 7: CONFIGURE ROW LEVEL SECURITY (Optional)

### 7.1 Enable RLS
```
Dashboard → Database → Tables

For each table:
  Click table → RLS toggle ON
  
Tables to protect:
  ✅ user_management.users (privacy)
  ✅ matching.messages (chat privacy)
  ✅ monetization.subscriptions (payment privacy)
  ✅ admin_panel.adminUsers (security)
```

### 7.2 Create Security Policies
```
Example: Users can only read own profile

Dashboard → Database → Users table
Click: Policies → New Policy
  Policy Name: "Users read own profile"
  Allowed operation: SELECT
  Policy expression: (auth.uid()::text = id) OR isActive
```

---

## STEP 8: CONFIGURE BACKUP & RECOVERY

### 8.1 Enable Automatic Backups
```
Dashboard → Settings → Backups
Status: Automatic backups are ON (free tier: 7 days)
```

### 8.2 Manual Backup
```
Dashboard → Database → Backups
Click: Backup Now
Download: SQL file
Save location: local/backups/
```

---

## STEP 9: TEST DATABASE CONNECTION

### 9.1 Test from SQL Editor
```
Dashboard → SQL Editor
Run query:

SELECT COUNT(*) as total_tables
FROM information_schema.tables
WHERE table_schema NOT IN ('information_schema', 'pg_catalog');

Expected result: 35+ (tables created successfully)
```

### 9.2 Test from Command Line (Optional)
```bash
# Install psql if needed:
brew install postgresql  # macOS
apt-get install postgresql-client  # Linux

# Connect to database:
psql postgresql://postgres:[PASSWORD]@[PROJECT].supabase.co:5432/postgres

# List tables:
\dt user_management.*
\dt matching.*

# Exit:
\q
```

---

## STEP 10: SETUP FLUTTER CONNECTION

### 10.1 Add Dependencies
```yaml
dependencies:
  supabase_flutter: ^2.5.0
  dio: ^5.4.0
```

### 10.2 Initialize Supabase
```dart
// main.dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://xxxxx.supabase.co',
    anonKey: 'eyJhbGc...',
  );
  
  runApp(const MyApp());
}
```

### 10.3 Test Connection
```dart
// In your code
final supabase = Supabase.instance.client;

// Test query
final response = await supabase
  .from('user_management.users')
  .select()
  .limit(1)
  .execute();

print('Connection successful!');
print('Users: ${response.data}');
```

---

## PHASE-WISE DEPLOYMENT

### Phase 1 (Week 1-3)
```
✅ All tables 1-11 created (user_management, matching, safety)
✅ Realtime enabled on: messages, matches
✅ Auth: Phone OTP configured
✅ Storage: photos bucket created
✅ Flutter connected and tested

Run SQL: Everything in the .sql file (all phases)
Activate: Phase 1 tables only
```

### Phase 1.5 (Week 3-4)
```
✅ Monetization tables active (12-17)
✅ Razorpay integrated
✅ Admin panel setup
✅ Notifications working

Tables 12-17 already created, just activate features
```

### Phase 2 (Week 5-8)
```
✅ Advanced features tables active (18-25)
✅ Video calling setup (Jitsi)
✅ AI verification (AWS Rekognition)
✅ SOS system operational

Tables 18-25 already created, implement features
```

### Phase 3 (Week 8+)
```
✅ Growth tables active (26-35)
✅ ML recommendations
✅ Events system
✅ Referral program

Tables 26-35 already created, launch features
```

---

## ENVIRONMENT VARIABLES

### .env.local (Flutter)
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc... (backend only)
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret
```

### .env (Server/Backend)
```
DATABASE_URL=postgresql://postgres:[PASSWORD]@[PROJECT]...
JWT_SECRET=your_jwt_secret
API_KEY=your_api_key
```

---

## MONITORING & HEALTH CHECKS

### 8.1 Monitor Database
```
Dashboard → Database → Health
Check:
  ✅ Database connection active
  ✅ Disk usage
  ✅ Query performance
  ✅ Connection count
```

### 8.2 View Logs
```
Dashboard → Logs
Filter by:
  - Database
  - Authentication
  - Storage
  - Realtime
```

---

## COMMON ISSUES & SOLUTIONS

### Issue 1: "Table does not exist"
```
Solution:
1. Check table schema (prefix with schema name)
2. Use: schema_name.table_name in queries
3. Verify SQL ran successfully (check logs)
```

### Issue 2: "Permission denied" on photos table
```
Solution:
1. Check Storage bucket policies
2. Verify user authentication
3. Check RLS policies if enabled
```

### Issue 3: "Real-time not working"
```
Solution:
1. Ensure table has RLS enabled OR realtime toggle ON
2. Check WebSocket connection
3. Verify user is authenticated
```

### Issue 4: "Connection timeout"
```
Solution:
1. Check internet connection
2. Verify project URL is correct
3. Confirm API keys are valid
4. Check firewall/VPN settings
```

---

## BACKUP STRATEGY

### Daily Tasks
```
Dashboard → Backups → View
Automatic backup happens daily
7-day retention (free tier)
14-day retention (pro tier)
```

### Weekly Tasks
```
Download manual backup:
1. Dashboard → Backups
2. Click: Download
3. Save to: /backups/weekly/

```

### Monthly Tasks
```
Archive old backups
Store in: Cloud Storage / Archive
Retain for compliance (if needed)
```

---

## SECURITY CHECKLIST

- ✅ Complex database password set
- ✅ Anon key used only in frontend
- ✅ Service Role key secured (backend only)
- ✅ RLS policies configured
- ✅ Storage bucket policies set
- ✅ HTTPS enforced
- ✅ Regular backups enabled
- ✅ JWT expiry configured
- ✅ Phone/Email verification enabled
- ✅ Rate limiting enabled (if available)

---

## READY TO USE! 🚀

Your database is now fully set up with:
- ✅ 35+ tables across 8 schemas
- ✅ Real-time messaging enabled
- ✅ Authentication configured
- ✅ Storage buckets ready
- ✅ Backups automated
- ✅ Security policies configured

**You can now:**
1. Start Flutter implementation
2. Create repositories for each feature
3. Implement authentication flow
4. Build UI screens
5. Deploy to production

---

## NEXT STEPS

1. **Week 1**: Build authentication screens
2. **Week 2**: Implement profile creation
3. **Week 3**: Build swipe engine
4. **Week 4**: Add verification system
5. **Week 5+**: Add remaining features

---

**Document Version**: 1.0  
**Last Updated**: February 21, 2026  
**Status**: Ready for Production

