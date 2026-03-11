# ChipIn — Build Todo
Last updated: reflects full product plan parity audit. See plan.md for full detail.

## Step 0 — Project Setup
- [x] Add all required packages to pubspec.yaml (go_router, flutter_riverpod, supabase_flutter, timeago, shimmer, etc.)
- [x] Update app_constants.dart with Supabase URL + anon key
- [x] Rename app to ChipIn in pubspec + native configs (applicationId = com.chipin.app)
- [x] Download Inter font (all 9 weights 100–900) into assets/fonts/
- [x] Fix Android core-library desugaring (minSdk=21, isCoreLibraryDesugaringEnabled=true)

## Step 1 — Core Architecture
- [x] Restructure lib/ folders (features, shared, core)
- [x] Rebuild app_theme.dart (ChipIn design tokens: #11B4D4 primary, #F6F8F8 background)
- [x] Build app_router.dart (all 21 GoRouter routes + auth guard)

## Step 2 — Shared Models
- [x] UserModel (lib/shared/models/user_model.dart)
- [x] ListingModel (lib/shared/models/listing_model.dart)
- [x] MatchModel + MatchStatus enum (lib/shared/models/match_model.dart)
- [x] MessageModel (lib/shared/models/message_model.dart)
- [x] ReviewModel (lib/shared/models/review_model.dart)
- [x] NotificationModel (lib/shared/models/notification_model.dart)

## Step 3 — Database
- [x] Write full SQL migration — supabase/migrations/20240101000000_initial_schema.sql
      Tables: users, listings, matches, messages, escrow_payments, reviews, notifications, disputes
      Includes: RLS policies on all 8 tables, realtime on messages/notifications/matches/escrow_payments,
               handle_new_user trigger, update_user_avg_rating trigger
- [ ] supabase db push (run when Supabase CLI is set up)

## Step 4 — Auth
- [x] SplashScreen (/splash) — auth redirect logic
- [x] OnboardingScreen (/onboarding) — 3 slides
- [x] SignupScreen (/signup) — email + password
- [x] OtpScreen (/otp) — verification flow
- [x] LoginScreen (/login) — email + password
- [x] AuthProvider (Riverpod) — Supabase Auth integration

## Step 5 — Home Feed
- [x] HomeScreen (/home) — feed with listings
- [x] ListingCard widget
- [x] CategoryChip widget
- [x] ListingsProvider — fetchListings, createListing, searchListings

## Step 6 — Browse / Explore
- [x] BrowseScreen (/browse) — search + filter by category

## Step 7 — Post a Split (3-screen wizard)
- [x] PostCategoryScreen (/post/category — Step 1/3)
- [x] PostDetailsScreen (/post/details — Step 2/3)
- [x] PostExtrasScreen (/post/extras — Step 3/3)

## Step 8 — Listing Detail
- [x] ListingDetailScreen (/listing/:id) — full detail + request to join
- [x] MatchProvider.requestToJoin() — insert into matches table
- [x] "View Profile" → /profile/:userId — WIRED

## Step 9 — My Matches
- [x] MatchesScreen (/matches) — Received/Sent tabs
- [x] MatchProvider.getMatchesForUser() (receivedMatchesProvider / sentMatchesProvider)
- [x] Accept / Decline buttons → matchNotifierProvider.acceptMatch() / declineMatch()
- [x] Chat button (accepted/active) → /chat/:matchId — WIRED
- [x] Pay Escrow button (accepted) → /pay/:matchId — WIRED
- [x] Escrow button (active) → /escrow/:matchId — WIRED

## Step 10 — Chat
- [x] ChatScreen (/chat/:matchId) — Supabase Realtime messages
- [x] MessagesProvider — send + stream messages
- [x] "Request Escrow" quick-chip → /pay/:matchId — WIRED

## Step 11 — Escrow & Payments
- [x] EscrowDepositScreen (/pay/:matchId) — deposit share, confirm → /escrow/:matchId
- [x] EscrowStatusScreen (/escrow/:matchId) — payment breakdown, confirm-active, raise dispute CTA
- [x] DisputeScreen (/dispute/:matchId) — reason + evidence, submits to disputes table

## Step 12 — Profile
- [x] ProfileScreen (/me and /profile/:userId) — avatar, stats, trust score, listings, reviews
- [x] ProfileProvider — userProfileProvider, profileNotifierProvider (updateProfile)
- [x] Reviews section — userReviewsProvider, _ReviewsSection, _ReviewCard
- [x] Edit Profile button → /me/edit — WIRED
- [x] Verify Identity button → /verify — WIRED

## Step 13 — Edit Profile
- [x] EditProfileScreen (/me/edit) — update name/bio/location, calls profileNotifierProvider.updateProfile()

## Step 14 — Verification / Trust Score
- [x] VerificationScreen (/verify) — trust score progress bar, 3 verification tiles (Phone/ID/Payment)

## Step 15 — Notifications
- [x] NotificationsScreen (/notifications) — reads notifications table, mark as read

## Step 16 — Flutter Analyze
- [ ] Run flutter analyze and fix all errors/warnings

## Step 17 — Final Build Test
- [ ] flutter build apk --debug → must produce ✓ Built message

---

## Full Screen Checklist (Product Plan Section 12)
| Screen | Route | Status |
|--------|-------|--------|
| Splash | /splash | ✅ |
| Onboarding | /onboarding | ✅ |
| Sign Up | /signup | ✅ |
| OTP Verification | /otp | ✅ |
| Log In | /login | ✅ |
| Home | /home | ✅ |
| Browse | /browse | ✅ |
| Listing Detail | /listing/:id | ✅ |
| Post Step 1 | /post/category | ✅ |
| Post Step 2 | /post/details | ✅ |
| Post Step 3 | /post/extras | ✅ |
| My Matches | /matches | ✅ (Chat + Escrow wired) |
| Chat | /chat/:matchId | ✅ (Escrow chip wired) |
| Escrow Deposit | /pay/:matchId | ✅ |
| Escrow Status | /escrow/:matchId | ✅ |
| Dispute | /dispute/:matchId | ✅ |
| Profile (any user) | /profile/:userId | ✅ (reviews + profile push) |
| My Profile | /me | ✅ |
| Edit Profile | /me/edit | ✅ |
| Notifications | /notifications | ✅ |
| Verification | /verify | ✅ |
