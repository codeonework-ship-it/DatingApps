-- COMPLETE DATABASE SCHEMA - ALL PHASES
-- Dating App Database Schema with Multiple Modules
-- Created: February 21, 2026
-- Database Name: dating_apps
-- Status: Production Ready

-- ============================================================================
-- INITIALIZATION & SCHEMA CREATION
-- ============================================================================

-- Create database (run locally, Supabase has one pre-created)
-- CREATE DATABASE dating_apps;

-- Create schemas for different modules
CREATE SCHEMA IF NOT EXISTS user_management;
CREATE SCHEMA IF NOT EXISTS matching;
CREATE SCHEMA IF NOT EXISTS safety;
CREATE SCHEMA IF NOT EXISTS monetization;
CREATE SCHEMA IF NOT EXISTS admin_panel;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS advanced_features;
CREATE SCHEMA IF NOT EXISTS growth;

-- Set search_path so we can reference tables without schema prefix within transactions
SET search_path TO public, user_management, matching, safety, monetization, admin_panel, analytics, advanced_features, growth;

-- ============================================================================
-- PHASE 1: CORE MVP
-- ============================================================================

-- --- USER MANAGEMENT SCHEMA ---

CREATE TABLE user_management.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phoneNumber TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  dateOfBirth DATE NOT NULL,
  gender TEXT NOT NULL CHECK (gender IN ('M', 'F', 'Other')),
  bio TEXT,
  heightCm INTEGER,
  education TEXT,
  profession TEXT,
  incomeRange TEXT,
  drinking TEXT DEFAULT 'Never',
  smoking TEXT DEFAULT 'Never',
  religion TEXT,
  profileCompletion INTEGER DEFAULT 0,
  isVerified BOOLEAN DEFAULT FALSE,
  verificationBadge BOOLEAN DEFAULT FALSE,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  lastLogin TIMESTAMP WITH TIME ZONE,
  isActive BOOLEAN DEFAULT TRUE,
  isBlocked BOOLEAN DEFAULT FALSE,
  blockedUsers UUID[] DEFAULT '{}',
  updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_phoneNumber ON user_management.users(phoneNumber);
CREATE INDEX idx_users_isVerified ON user_management.users(isVerified);
CREATE INDEX idx_users_gender_dateOfBirth ON user_management.users(gender, dateOfBirth);
CREATE INDEX idx_users_createdAt ON user_management.users(createdAt DESC);
CREATE INDEX idx_users_isActive ON user_management.users(isActive);

CREATE TABLE user_management.preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID UNIQUE NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  seekingGenders TEXT[] DEFAULT '{"M", "F"}',
  minAgeYears INTEGER DEFAULT 18,
  maxAgeYears INTEGER DEFAULT 60,
  maxDistanceKm INTEGER DEFAULT 50,
  minHeightCm INTEGER,
  maxHeightCm INTEGER,
  educationFilter TEXT[] DEFAULT '{}',
  seriousOnly BOOLEAN DEFAULT TRUE,
  verifiedOnly BOOLEAN DEFAULT FALSE,
  updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_preferences_userId ON user_management.preferences(userId);

CREATE TABLE user_management.photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  photoUrl TEXT NOT NULL,
  storagePath TEXT NOT NULL,
  ordering INTEGER NOT NULL DEFAULT 0,
  uploadedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  isModerated BOOLEAN DEFAULT FALSE,
  isFlagged BOOLEAN DEFAULT FALSE,
  UNIQUE(userId, ordering)
);

CREATE INDEX idx_photos_userId ON user_management.photos(userId);
CREATE INDEX idx_photos_userId_ordering ON user_management.photos(userId, ordering);

CREATE TABLE user_management.userSettings (
  userId UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  showAge BOOLEAN DEFAULT TRUE,
  showExactDistance BOOLEAN DEFAULT FALSE,
  showOnlineStatus BOOLEAN DEFAULT TRUE,
  notifyNewMatch BOOLEAN DEFAULT TRUE,
  notifyNewMessage BOOLEAN DEFAULT TRUE,
  notifyLikes BOOLEAN DEFAULT TRUE,
  theme TEXT DEFAULT 'auto',
  updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_management.emergencyContacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phoneNumber TEXT NOT NULL,
  ordering INTEGER NOT NULL CHECK (ordering >= 1 AND ordering <= 3),
  addedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(userId, ordering)
);

CREATE INDEX idx_emergencyContacts_userId ON user_management.emergencyContacts(userId);

-- --- MATCHING SCHEMA ---

CREATE TABLE matching.swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  targetUserId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  isLike BOOLEAN NOT NULL,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(userId, targetUserId)
);

CREATE INDEX idx_swipes_userId_createdAt ON matching.swipes(userId, createdAt DESC);
CREATE INDEX idx_swipes_userId_targetUserId ON matching.swipes(userId, targetUserId);
CREATE INDEX idx_swipes_targetUserId ON matching.swipes(targetUserId);

CREATE TABLE matching.matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId1 UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  userId2 UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  user1Status TEXT DEFAULT 'active' CHECK (user1Status IN ('active', 'unmatched', 'reported')),
  user2Status TEXT DEFAULT 'active' CHECK (user2Status IN ('active', 'unmatched', 'reported')),
  lastMessageAt TIMESTAMP WITH TIME ZONE,
  user1Blocked BOOLEAN DEFAULT FALSE,
  user2Blocked BOOLEAN DEFAULT FALSE,
  chatCount INTEGER DEFAULT 0,
  UNIQUE(userId1, userId2),
  CHECK (userId1 < userId2)
);

CREATE INDEX idx_matches_userId1 ON matching.matches(userId1);
CREATE INDEX idx_matches_userId2 ON matching.matches(userId2);
CREATE INDEX idx_matches_lastMessageAt ON matching.matches(lastMessageAt DESC);
CREATE INDEX idx_matches_createdAt ON matching.matches(createdAt DESC);

CREATE TABLE matching.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  matchId UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  senderId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  deliveredAt TIMESTAMP WITH TIME ZONE,
  readAt TIMESTAMP WITH TIME ZONE,
  isDeleted BOOLEAN DEFAULT FALSE,
  deletedAt TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_messages_matchId_createdAt ON matching.messages(matchId, createdAt DESC);
CREATE INDEX idx_messages_senderId ON matching.messages(senderId);

-- --- SAFETY SCHEMA ---

CREATE TABLE safety.verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID UNIQUE NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected', 'expired')),
  idPhotoPath TEXT,
  selfiePhotoPath TEXT,
  submittedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  verifiedAt TIMESTAMP WITH TIME ZONE,
  rejectionReason TEXT,
  retryCount INTEGER DEFAULT 0,
  expiresAt TIMESTAMP WITH TIME ZONE,
  verifiedBy UUID,
  UNIQUE(userId)
);

CREATE INDEX idx_verifications_userId_status ON safety.verifications(userId, status);
CREATE INDEX idx_verifications_status_submittedAt ON safety.verifications(status, submittedAt);

CREATE TABLE safety.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporterId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  reportedUserId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  messageId UUID,
  reason TEXT NOT NULL CHECK (reason IN ('harassment', 'inappropriate', 'fraud', 'fake')),
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'actioned', 'dismissed')),
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  reviewedAt TIMESTAMP WITH TIME ZONE,
  reviewedBy UUID,
  action TEXT
);

CREATE INDEX idx_reports_reportedUserId ON safety.reports(reportedUserId);
CREATE INDEX idx_reports_status_createdAt ON safety.reports(status, createdAt DESC);

CREATE TABLE safety.safetyFlags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  flagType TEXT NOT NULL,
  severity INTEGER CHECK (severity >= 1 AND severity <= 10),
  description TEXT,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  isResolved BOOLEAN DEFAULT FALSE,
  action TEXT,
  actionedAt TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_safetyFlags_userId ON safety.safetyFlags(userId);
CREATE INDEX idx_safetyFlags_severity ON safety.safetyFlags(severity DESC);

-- ============================================================================
-- PHASE 1.5: MONETIZATION
-- ============================================================================

-- --- MONETIZATION SCHEMA ---

CREATE TABLE monetization.subscriptionPlans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE, -- 'Free', 'Premium', 'VIP'
  monthlyPrice INTEGER NOT NULL, -- In paisa
  yearlyPrice INTEGER,
  likesPerDay INTEGER DEFAULT 10,
  messagesPerDay INTEGER DEFAULT 50,
  advancedFilters BOOLEAN DEFAULT FALSE,
  verifiedBadge BOOLEAN DEFAULT FALSE,
  prioritySupport BOOLEAN DEFAULT FALSE,
  features JSONB DEFAULT '{}',
  description TEXT,
  isActive BOOLEAN DEFAULT TRUE,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_subscriptionPlans_isActive ON monetization.subscriptionPlans(isActive);

CREATE TABLE monetization.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  planId UUID NOT NULL REFERENCES monetization.subscriptionPlans(id),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'paused')),
  billingCycle TEXT DEFAULT 'monthly' CHECK (billingCycle IN ('monthly', 'yearly')),
  startDate TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  endDate TIMESTAMP WITH TIME ZONE,
  nextBillingDate TIMESTAMP WITH TIME ZONE,
  autoRenew BOOLEAN DEFAULT TRUE,
  razorpaySubscriptionId TEXT,
  razorpayCustomerId TEXT,
  cancelledAt TIMESTAMP WITH TIME ZONE,
  cancelReason TEXT,
  updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(userId)
);

CREATE INDEX idx_subscriptions_userId_status ON monetization.subscriptions(userId, status);
CREATE INDEX idx_subscriptions_status ON monetization.subscriptions(status);
CREATE INDEX idx_subscriptions_nextBillingDate ON monetization.subscriptions(nextBillingDate);

CREATE TABLE monetization.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  subscriptionId UUID REFERENCES monetization.subscriptions(id),
  amount INTEGER NOT NULL, -- In paisa
  currency TEXT DEFAULT 'INR',
  paymentMethod TEXT DEFAULT 'card', -- card, upi, wallet
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  razorpayPaymentId TEXT UNIQUE,
  razorpayOrderId TEXT,
  orderId TEXT UNIQUE,
  receipt TEXT,
  failureReason TEXT,
  refundedAmount INTEGER,
  refundedAt TIMESTAMP WITH TIME ZONE,
  transactionDate TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_userId ON monetization.payments(userId);
CREATE INDEX idx_payments_status ON monetization.payments(status);
CREATE INDEX idx_payments_razorpayPaymentId ON monetization.payments(razorpayPaymentId);

-- --- ADMIN PANEL SCHEMA ---

CREATE TABLE admin_panel.adminUsers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID UNIQUE NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'moderator', 'support', 'analyst')),
  permissions TEXT[] DEFAULT '{}',
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  isActive BOOLEAN DEFAULT TRUE,
  lastLogin TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_adminUsers_role ON admin_panel.adminUsers(role);
CREATE INDEX idx_adminUsers_isActive ON admin_panel.adminUsers(isActive);
CREATE INDEX idx_adminUsers_email ON admin_panel.adminUsers(email);

CREATE TABLE admin_panel.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- 'match', 'message', 'like', 'verification', 'subscription'
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  isRead BOOLEAN DEFAULT FALSE,
  readAt TIMESTAMP WITH TIME ZONE,
  sentAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  expiresAt TIMESTAMP WITH TIME ZONE,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_userId_isRead ON admin_panel.notifications(userId, isRead);
CREATE INDEX idx_notifications_userId_createdAt ON admin_panel.notifications(userId, createdAt DESC);

-- --- ANALYTICS SCHEMA ---

CREATE TABLE analytics.activityLogs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL, -- 'login', 'profile_update', 'swipe', 'match', 'message', 'report'
  resourceType TEXT,
  resourceId TEXT,
  metadata JSONB DEFAULT '{}',
  ipAddress INET,
  userAgent TEXT,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activityLogs_userId_createdAt ON analytics.activityLogs(userId, createdAt DESC);
CREATE INDEX idx_activityLogs_action ON analytics.activityLogs(action);

CREATE TABLE analytics.analyticsMetrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metricDate DATE NOT NULL,
  metricType TEXT NOT NULL, -- 'daily', 'weekly', 'monthly'
  totalUsers INTEGER DEFAULT 0,
  activeUsers INTEGER DEFAULT 0,
  newUsers INTEGER DEFAULT 0,
  totalMatches INTEGER DEFAULT 0,
  totalSwipes INTEGER DEFAULT 0,
  totalMessages INTEGER DEFAULT 0,
  verificationRate FLOAT DEFAULT 0,
  premiumConversion FLOAT DEFAULT 0,
  averageSessionTime INTEGER DEFAULT 0, -- seconds
  reportCount INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_analyticsMetrics_metricDate ON analytics.analyticsMetrics(metricDate DESC);
CREATE INDEX idx_analyticsMetrics_metricType ON analytics.analyticsMetrics(metricType);

-- ============================================================================
-- PHASE 2: ADVANCED FEATURES
-- ============================================================================

-- --- ADVANCED FEATURES SCHEMA ---

CREATE TABLE advanced_features.videoCallSessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  matchId UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  initiatorId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  recipientId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  startTime TIMESTAMP WITH TIME ZONE,
  endTime TIMESTAMP WITH TIME ZONE,
  duration INTEGER, -- seconds
  status TEXT DEFAULT 'initiated' CHECK (status IN ('initiated', 'ringing', 'connected', 'ended', 'missed', 'declined')),
  jitsiRoomId TEXT,
  recordingUrl TEXT,
  qualityScore FLOAT DEFAULT 0,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_videoCallSessions_matchId ON advanced_features.videoCallSessions(matchId);
CREATE INDEX idx_videoCallSessions_status ON advanced_features.videoCallSessions(status);
CREATE INDEX idx_videoCallSessions_createdAt ON advanced_features.videoCallSessions(createdAt DESC);

CREATE TABLE advanced_features.livenessVerifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  verificationId UUID NOT NULL REFERENCES safety.verifications(id) ON DELETE CASCADE,
  livenessScore FLOAT, -- 0.0 to 1.0
  aiProvider TEXT DEFAULT 'AWS Rekognition',
  detectedElements JSONB, -- blink, mouth open, head movement
  passedLiveness BOOLEAN,
  attempts INTEGER DEFAULT 1,
  resultAt TIMESTAMP WITH TIME ZONE,
  failureReason TEXT,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_livenessVerifications_verificationId ON advanced_features.livenessVerifications(verificationId);
CREATE INDEX idx_livenessVerifications_passedLiveness ON advanced_features.livenessVerifications(passedLiveness);

CREATE TABLE advanced_features.sosAlerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  matchId UUID REFERENCES matching.matches(id) ON DELETE SET NULL,
  latitude FLOAT,
  longitude FLOAT,
  location TEXT,
  details TEXT,
  emergencyLevel TEXT DEFAULT 'medium' CHECK (emergencyLevel IN ('low', 'medium', 'high', 'critical')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'false_alarm', 'assisted')),
  responders UUID[] DEFAULT '{}',
  respondedAt TIMESTAMP WITH TIME ZONE,
  resolution TEXT,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sosAlerts_userId ON advanced_features.sosAlerts(userId);
CREATE INDEX idx_sosAlerts_status ON advanced_features.sosAlerts(status);
CREATE INDEX idx_sosAlerts_emergencyLevel ON advanced_features.sosAlerts(emergencyLevel);
CREATE INDEX idx_sosAlerts_createdAt ON advanced_features.sosAlerts(createdAt DESC);

CREATE TABLE advanced_features.behaviorPatterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  swipePattern JSONB, -- Time of day, frequency, selectivity
  messagePattern JSONB, -- Response time, word count, language tone
  reportedCount INTEGER DEFAULT 0,
  suspiciousScore FLOAT DEFAULT 0, -- 0.0 to 1.0
  isFlagger BOOLEAN DEFAULT FALSE,
  accountAgeDays INTEGER,
  photoQuality FLOAT DEFAULT 0,
  profileCompleteness FLOAT DEFAULT 0,
  verificationStatus TEXT,
  analysisDate TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  flagReason TEXT,
  updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_behaviorPatterns_userId ON advanced_features.behaviorPatterns(userId);
CREATE INDEX idx_behaviorPatterns_suspiciousScore ON advanced_features.behaviorPatterns(suspiciousScore DESC);

CREATE TABLE advanced_features.userBans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  banType TEXT NOT NULL CHECK (banType IN ('temporary', 'permanent')),
  reason TEXT NOT NULL,
  details TEXT,
  bannedBy UUID REFERENCES admin_panel.adminUsers(id),
  startDate TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  endDate TIMESTAMP WITH TIME ZONE,
  appealSubmittedAt TIMESTAMP WITH TIME ZONE,
  appealReason TEXT,
  appealStatus TEXT, -- pending, approved, rejected
  isActive BOOLEAN DEFAULT TRUE,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_userBans_userId ON advanced_features.userBans(userId);
CREATE INDEX idx_userBans_isActive ON advanced_features.userBans(isActive);
CREATE INDEX idx_userBans_endDate ON advanced_features.userBans(endDate);

CREATE TABLE advanced_features.moderationQueue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reportId UUID REFERENCES safety.reports(id) ON DELETE CASCADE,
  itemType TEXT NOT NULL, -- 'profile', 'photo', 'message', 'report'
  itemId TEXT,
  userId UUID REFERENCES user_management.users(id),
  priority INTEGER DEFAULT 0,
  assignedTo UUID REFERENCES admin_panel.adminUsers(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_review', 'approved', 'rejected')),
  actionTaken TEXT,
  moderationNotes TEXT,
  reviewedAt TIMESTAMP WITH TIME ZONE,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_moderationQueue_status ON advanced_features.moderationQueue(status);
CREATE INDEX idx_moderationQueue_assignedTo ON advanced_features.moderationQueue(assignedTo);
CREATE INDEX idx_moderationQueue_priority ON advanced_features.moderationQueue(priority DESC);

CREATE TABLE advanced_features.supportTickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL, -- 'bug', 'feature_request', 'payment', 'account', 'other'
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'on_hold', 'resolved', 'closed')),
  assignedTo UUID REFERENCES admin_panel.adminUsers(id),
  responses JSONB DEFAULT '[]',
  resolution TEXT,
  rating INTEGER, -- 1-5 stars
  ratingComment TEXT,
  resolvedAt TIMESTAMP WITH TIME ZONE,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_supportTickets_userId ON advanced_features.supportTickets(userId);
CREATE INDEX idx_supportTickets_status ON advanced_features.supportTickets(status);
CREATE INDEX idx_supportTickets_priority ON advanced_features.supportTickets(priority DESC);

-- ============================================================================
-- PHASE 3: ML & GROWTH
-- ============================================================================

-- --- GROWTH SCHEMA ---

CREATE TABLE growth.aiRecommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  recommendedUserId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  compatibilityScore FLOAT, -- 0.0 to 1.0
  reason TEXT, -- Why recommended
  model TEXT DEFAULT 'v1', -- Model version
  scoringFactors JSONB, -- Breakdown of factors
  isAccepted BOOLEAN,
  feedback JSONB,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_aiRecommendations_userId ON growth.aiRecommendations(userId);
CREATE INDEX idx_aiRecommendations_compatibilityScore ON growth.aiRecommendations(compatibilityScore DESC);

CREATE TABLE growth.userPreferenceHistory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  previousPreferences JSONB NOT NULL,
  newPreferences JSONB NOT NULL,
  changedFields TEXT[] NOT NULL,
  changedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_userPreferenceHistory_userId ON growth.userPreferenceHistory(userId);

CREATE TABLE growth.locationHistory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  accuracy FLOAT,
  recordedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_locationHistory_userId ON growth.locationHistory(userId);
CREATE INDEX idx_locationHistory_recordedAt ON growth.locationHistory(recordedAt DESC);

CREATE TABLE growth.socialImports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  platform TEXT NOT NULL, -- 'contacts', 'facebook', 'instagram', 'linkedin'
  importedContacts INTEGER DEFAULT 0,
  matchedUsers INTEGER DEFAULT 0,
  importedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  expiresAt TIMESTAMP WITH TIME ZONE,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_socialImports_userId ON growth.socialImports(userId);

CREATE TABLE growth.matchMetrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  matchId UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  messageCount INTEGER DEFAULT 0,
  firstMessageTime INTEGER, -- seconds after match
  responseTime FLOAT, -- avg seconds
  messageFrequency FLOAT,
  lastInteractionDaysAgo INTEGER,
  successIndicators JSONB, -- met in person, continuing contact
  quality FLOAT DEFAULT 0, -- 0-1 score
  updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_matchMetrics_matchId ON growth.matchMetrics(matchId);
CREATE INDEX idx_matchMetrics_quality ON growth.matchMetrics(quality DESC);

CREATE TABLE growth.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL, -- 'dating_event', 'speed_dating', 'workshop'
  locationCity TEXT NOT NULL,
  latitude FLOAT,
  longitude FLOAT,
  eventDate TIMESTAMP WITH TIME ZONE NOT NULL,
  registrationDeadline TIMESTAMP WITH TIME ZONE,
  maxCapacity INTEGER,
  currentAttendees INTEGER DEFAULT 0,
  price INTEGER DEFAULT 0, -- 0 for free
  images TEXT[],
  organizer TEXT,
  status TEXT DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'ongoing', 'completed', 'cancelled')),
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_events_eventDate ON growth.events(eventDate);
CREATE INDEX idx_events_status ON growth.events(status);

CREATE TABLE growth.eventRegistrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  eventId UUID NOT NULL REFERENCES growth.events(id) ON DELETE CASCADE,
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  registeredAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  attended BOOLEAN DEFAULT NULL,
  attendedAt TIMESTAMP WITH TIME ZONE,
  feedback JSONB,
  UNIQUE(eventId, userId)
);

CREATE INDEX idx_eventRegistrations_eventId ON growth.eventRegistrations(eventId);
CREATE INDEX idx_eventRegistrations_userId ON growth.eventRegistrations(userId);

CREATE TABLE growth.testimonials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  partnerUserId UUID,
  matchId UUID REFERENCES matching.matches(id) ON DELETE SET NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  content TEXT,
  category TEXT, -- 'success_story', 'app_feedback', 'experience'
  isVerified BOOLEAN DEFAULT FALSE,
  isPublished BOOLEAN DEFAULT FALSE,
  publishedAt TIMESTAMP WITH TIME ZONE,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_testimonials_userId ON growth.testimonials(userId);
CREATE INDEX idx_testimonials_rating ON growth.testimonials(rating DESC);
CREATE INDEX idx_testimonials_isPublished ON growth.testimonials(isPublished);

CREATE TABLE growth.referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrerId UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  referredUserId UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  referralCode TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'claimed')),
  rewardType TEXT DEFAULT 'credits', -- credits, premium_days
  rewardAmount INTEGER,
  claimedAt TIMESTAMP WITH TIME ZONE,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_referrals_referrerId ON growth.referrals(referrerId);
CREATE INDEX idx_referrals_referralCode ON growth.referrals(referralCode);
CREATE INDEX idx_referrals_status ON growth.referrals(status);

CREATE TABLE growth.partnerships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partnerName TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL, -- 'brand', 'influencer', 'corporate'
  description TEXT,
  logo TEXT,
  website TEXT,
  contactEmail TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'paused')),
  commission FLOAT DEFAULT 0, -- percentage
  startDate DATE,
  endDate DATE,
  notes TEXT,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_partnerships_status ON growth.partnerships(status);

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

CREATE VIEW user_management.user_profiles_summary AS
SELECT
  u.id,
  u.phoneNumber,
  u.name,
  EXTRACT(YEAR FROM AGE(u.dateOfBirth)) as age,
  u.gender,
  u.bio,
  u.heightCm,
  u.education,
  u.isVerified,
  COUNT(p.id) as photoCount,
  COALESCE(COUNT(DISTINCT s.id) FILTER (WHERE s.isLike), 0) as likeCount,
  COALESCE(COUNT(DISTINCT m.id), 0) as matchCount,
  u.createdAt
FROM user_management.users u
LEFT JOIN user_management.photos p ON u.id = p.userId
LEFT JOIN matching.swipes s ON u.id = s.targetUserId
LEFT JOIN matching.matches m ON u.id IN (m.userId1, m.userId2)
GROUP BY u.id;

CREATE VIEW matching.active_matches_view AS
SELECT
  m.id,
  m.userId1,
  m.userId2,
  m.createdAt,
  m.lastMessageAt,
  (SELECT text FROM matching.messages WHERE matchId = m.id ORDER BY createdAt DESC LIMIT 1) as lastMessage,
  (SELECT COUNT(*) FROM matching.messages WHERE matchId = m.id) as messageCount
FROM matching.matches m
WHERE m.user1Status = 'active' AND m.user2Status = 'active';

-- ============================================================================
-- ROW LEVEL SECURITY (Optional - Enable as needed)
-- ============================================================================

-- ALTER TABLE matching.messages ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE matching.matches ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE user_management.users ENABLE ROW LEVEL SECURITY;

-- Users can only view messages they're part of
-- CREATE POLICY messages_user_policy ON matching.messages
--   FOR SELECT USING (
--     senderId = auth.uid() OR
--     matchId IN (
--       SELECT id FROM matching.matches
--       WHERE (userId1 = auth.uid() OR userId2 = auth.uid())
--     )
--   );

-- ============================================================================
-- COMPLETION
-- ============================================================================

-- Database initialization complete!
-- Total Tables: 35+
-- Schemas: 8 (user_management, matching, safety, monetization, admin_panel, analytics, advanced_features, growth)
-- Status: Ready for production
-- Created: February 21, 2026
