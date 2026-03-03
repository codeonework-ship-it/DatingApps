# DART MODELS REFERENCE GUIDE
# All Database Models Generated

**Date**: February 21, 2026  
**Status**: Ready for Use

---

## MODELS CREATED

### 1. User Management Models
**File**: `app/lib/features/user/models/user_models.dart`

```dart
// Core user data
User(
  id, phoneNumber, name, dateOfBirth, gender,
  bio, heightCm, education, profession, incomeRange,
  drinking, smoking, religion,
  profileCompletion, isVerified, verificationBadge,
  createdAt, lastLogin, isActive, isBlocked,
  blockedUsers, updatedAt
)

// Search preferences
Preferences(
  id, userId,
  seekingGenders, minAgeYears, maxAgeYears,
  maxDistanceKm, minHeightCm, maxHeightCm,
  educationFilter, seriousOnly, verifiedOnly,
  updatedAt
)

// Profile photos
Photo(
  id, userId, photoUrl, storagePath,
  ordering, uploadedAt, isModerated, isFlagged
)

// User settings
UserSettings(
  userId, showAge, showExactDistance, showOnlineStatus,
  notifyNewMatch, notifyNewMessage, notifyLikes,
  theme, updatedAt
)

// Emergency contacts
EmergencyContact(
  id, userId, name, phoneNumber, ordering, addedAt
)
```

---

### 2. Matching Models
**File**: `app/lib/features/matching/models/matching_models.dart`

```dart
// Like/pass history
Swipe(
  id, userId, targetUserId, isLike, createdAt
)

// Mutual matches
Match(
  id, userId1, userId2, createdAt,
  user1Status, user2Status,
  lastMessageAt, user1Blocked, user2Blocked,
  chatCount
)

// Chat messages
Message(
  id, matchId, senderId, text, createdAt,
  deliveredAt, readAt, isDeleted, deletedAt
)
```

---

### 3. Safety Models
**File**: `app/lib/features/safety/models/safety_models.dart`

```dart
// ID verification
Verification(
  id, userId, status,
  idPhotoPath, selfiePhotoPath,
  submittedAt, verifiedAt, rejectionReason,
  retryCount, expiresAt, verifiedBy
)

// User reports
Report(
  id, reporterId, reportedUserId,
  messageId, reason, description,
  status, createdAt, reviewedAt,
  reviewedBy, action
)

// Safety detection
SafetyFlag(
  id, userId, flagType, severity,
  description, createdAt, isResolved,
  action, actionedAt
)
```

---

### 4. Monetization Models
**File**: `app/lib/features/monetization/models/monetization_models.dart`

```dart
// Subscription tiers (Free/Premium/VIP)
SubscriptionPlan(
  id, name, monthlyPrice, yearlyPrice,
  likesPerDay, messagesPerDay,
  advancedFilters, verifiedBadge, prioritySupport,
  features, description, isActive,
  createdAt, updatedAt
)

// User subscriptions
Subscription(
  id, userId, planId, status, billingCycle,
  startDate, endDate, nextBillingDate,
  autoRenew, razorpaySubscriptionId,
  razorpayCustomerId, cancelledAt,
  cancelReason, updatedAt
)

// Payment transactions
Payment(
  id, userId, subscriptionId, amount,
  currency, paymentMethod, status,
  razorpayPaymentId, razorpayOrderId,
  orderId, receipt, failureReason,
  refundedAmount, refundedAt,
  transactionDate, createdAt
)
```

---

### 5. Admin & Analytics Models
**File**: `app/lib/features/admin/models/admin_models.dart`

```dart
// Admin/moderator accounts
AdminUser(
  id, userId, role, permissions,
  email, passwordHash, isActive,
  lastLogin, notes, createdAt, updatedAt
)

// Push notifications
Notification(
  id, userId, type, title, body,
  data, isRead, readAt, sentAt,
  expiresAt, createdAt
)

// User activity log
ActivityLog(
  id, userId, action, resourceType,
  resourceId, metadata, ipAddress,
  userAgent, createdAt
)

// Daily/weekly metrics
AnalyticsMetrics(
  id, metricDate, metricType,
  totalUsers, activeUsers, newUsers,
  totalMatches, totalSwipes, totalMessages,
  verificationRate, premiumConversion,
  averageSessionTime, reportCount,
  metadata, createdAt
)
```

---

### 6. Advanced Features Models (Phase 2)
**File**: `app/lib/features/advanced/models/advanced_models.dart`

```dart
// Video call sessions
VideoCallSession(
  id, matchId, initiatorId, recipientId,
  startTime, endTime, duration, status,
  jitsiRoomId, recordingUrl, qualityScore,
  createdAt
)

// Face liveness AI verification
LivenessVerification(
  id, verificationId, livenessScore,
  aiProvider, detectedElements,
  passedLiveness, attempts, resultAt,
  failureReason, createdAt
)

// Emergency SOS alerts
SosAlert(
  id, userId, matchId, latitude, longitude,
  location, details, emergencyLevel,
  status, responders, respondedAt,
  resolution, createdAt
)

// Fraud detection
BehaviorPattern(
  id, userId, swipePattern, messagePattern,
  reportedCount, suspiciousScore, isFlagger,
  accountAgeDays, photoQuality,
  profileCompleteness, verificationStatus,
  analysisDate, flagReason, updatedAt
)

// User bans
UserBan(
  id, userId, banType, reason, details,
  bannedBy, startDate, endDate,
  appealSubmittedAt, appealReason,
  appealStatus, isActive, createdAt
)

// Moderation queue
ModerationQueue(
  id, reportId, itemType, itemId,
  userId, priority, assignedTo,
  status, actionTaken, moderationNotes,
  reviewedAt, createdAt
)

// Support tickets
SupportTicket(
  id, userId, title, description,
  category, priority, status,
  assignedTo, responses, resolution,
  rating, ratingComment, resolvedAt,
  createdAt, updatedAt
)
```

---

### 7. Growth Models (Phase 3)
**File**: `app/lib/features/growth/models/growth_models.dart`

```dart
// ML compatibility matching
AiRecommendation(
  id, userId, recommendedUserId,
  compatibilityScore, reason, model,
  scoringFactors, isAccepted, feedback,
  createdAt
)

// Preference change history
UserPreferenceHistory(
  id, userId, previousPreferences,
  newPreferences, changedFields, changedAt
)

// Location tracking
LocationHistory(
  id, userId, latitude, longitude,
  address, city, state, country,
  accuracy, recordedAt, createdAt
)

// Social network imports
SocialImport(
  id, userId, platform,
  importedContacts, matchedUsers,
  importedAt, expiresAt, createdAt
)

// Match success metrics
MatchMetrics(
  id, matchId, messageCount,
  firstMessageTime, responseTime,
  messageFrequency, lastInteractionDaysAgo,
  successIndicators, quality, updatedAt
)

// Dating events
Event(
  id, title, description, category,
  locationCity, latitude, longitude,
  eventDate, registrationDeadline,
  maxCapacity, currentAttendees, price,
  images, organizer, status, createdAt
)

// Event attendees
EventRegistration(
  id, eventId, userId, registeredAt,
  attended, attendedAt, feedback
)

// Success stories
Testimonial(
  id, userId, partnerUserId, matchId,
  rating, title, content, category,
  isVerified, isPublished, publishedAt,
  createdAt
)

// Referral tracking
Referral(
  id, referrerId, referredUserId,
  referralCode, status, rewardType,
  rewardAmount, claimedAt, createdAt
)

// Partnership tracking
Partnership(
  id, partnerName, category, description,
  logo, website, contactEmail, status,
  commission, startDate, endDate,
  notes, createdAt
)
```

---

## HOW TO USE THESE MODELS

### 1. Generate Freezed Code
```bash
# In app directory
flutter pub run build_runner build

# Or watch mode
flutter pub run build_runner watch
```

### 2. Use in Repositories
```dart
class UserRepository {
  final supabase = Supabase.instance.client;
  
  Future<User> getUser(String userId) async {
    final response = await supabase
      .from('user_management.users')
      .select()
      .eq('id', userId)
      .single()
      .execute();
    
    return User.fromJson(response.data);
  }
  
  Future<void> updateUser(User user) async {
    await supabase
      .from('user_management.users')
      .update(user.toJson())
      .eq('id', user.id)
      .execute();
  }
}
```

### 3. Use in Riverpod Providers
```dart
final userProvider = FutureProvider.autoDispose<User>((ref) async {
  final userId = ref.watch(userIdProvider);
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUser(userId);
});
```

### 4. Use in UI
```dart
Consumer(
  builder: (context, ref, child) {
    final userAsync = ref.watch(userProvider);
    
    return userAsync.when(
      data: (user) => Text('Hi ${user.name}!'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  },
)
```

---

## MODELS ORGANIZATION STRUCTURE

```
app/lib/
├── features/
│   ├── user/
│   │   └── models/
│   │       └── user_models.dart (5 models)
│   ├── matching/
│   │   └── models/
│   │       └── matching_models.dart (3 models)
│   ├── safety/
│   │   └── models/
│   │       └── safety_models.dart (3 models)
│   ├── monetization/
│   │   └── models/
│   │       └── monetization_models.dart (3 models)
│   ├── admin/
│   │   └── models/
│   │       └── admin_models.dart (4 models)
│   ├── advanced/
│   │   └── models/
│   │       └── advanced_models.dart (7 models)
│   └── growth/
│       └── models/
│           └── growth_models.dart (10 models)
```

---

## TOTAL MODELS COUNT

| Feature | Count | Models |
|---------|-------|--------|
| User Management | 5 | User, Preferences, Photo, UserSettings, EmergencyContact |
| Matching | 3 | Swipe, Match, Message |
| Safety | 3 | Verification, Report, SafetyFlag |
| Monetization | 3 | SubscriptionPlan, Subscription, Payment |
| Admin & Analytics | 4 | AdminUser, Notification, ActivityLog, AnalyticsMetrics |
| Advanced Features | 7 | VideoCallSession, LivenessVerification, SosAlert, BehaviorPattern, UserBan, ModerationQueue, SupportTicket |
| Growth | 10 | AiRecommendation, UserPreferenceHistory, LocationHistory, SocialImport, MatchMetrics, Event, EventRegistration, Testimonial, Referral, Partnership |
| **TOTAL** | **35** | **All database tables have corresponding models** |

---

## NEXT STEPS

1. **Generate Models**: Run `flutter pub run build_runner build`
2. **Fix Imports**: Ensure all imports are correct
3. **Create Repositories**: Implement data layer for each feature
4. **Create Providers**: Setup Riverpod state management
5. **Build UI**: Create screens that consume the models

---

**Document Version**: 1.0  
**Status**: Ready for Development  
**Last Updated**: February 21, 2026
