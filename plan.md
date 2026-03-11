# ChipIn — Phase 1 Build Plan
Version 1.0 · Generated 2026-03-11

## Overview
Full reset of the existing Flutter shell into a production-ready Phase 1 of ChipIn.
We follow the product doc (`ChipIn_Product_Plan_v1.docx`) and implement pixel-accurate
screens from the stitch designs (`/stitch/` folder).

---

## Design System
| Token | Value |
|---|---|
| Primary | `#11b4d4` |
| Background | `#f6f8f8` |
| Dark background | `#101f22` |
| Font | Inter (already bundled) |
| Button | Full-width, rounded-12, primary bg, white bold |
| Cards | White, rounded-12, slate border, soft shadow |

Bottom Nav: **Home · Explore · Post (FAB) · Matches · Profile**

---

## Step 0 — Project Setup
- [x] Supabase CLI already installed (v2.75.0)
- [ ] Update `pubspec.yaml`: rename app, add hive_flutter, http, shimmer, timeago, url_launcher
- [ ] Update `app_constants.dart` with real Supabase URL, anon key, Termii base URL + API key
- [ ] Update app name in `pubspec.yaml` + `AndroidManifest.xml` + `Info.plist` → `ChipIn`

## Step 1 — Core Architecture
- [ ] Restructure `lib/` folders to match product doc (features, shared, core)
- [ ] Rebuild `app_theme.dart` with ChipIn design tokens
- [ ] Build `app_router.dart` (GoRouter) with all Phase 1 routes:
  `/splash`, `/onboarding`, `/login`, `/signup`, `/otp`,
  `/home`, `/browse`, `/listing/:id`,
  `/post/category`, `/post/details`, `/post/extras`,
  `/matches`, `/chat/:matchId`,
  `/profile/:userId`, `/me`, `/me/edit`, `/notifications`, `/verify`

## Step 2 — Models
- [ ] `User` model (replaces AppUser) — adds bio, location, phone_verified, id_verified, payment_verified
- [ ] `Listing` model — title, category, total_cost, split_amount, slots_total, slots_filled, duration, location, is_remote, description, tags, status, image_url
- [ ] `Match` model — listing_id, requester_id, owner_id, status (pending/accepted/declined/active/completed)
- [ ] `Message` model — match_id, sender_id, content, read_at
- [ ] `Review` model — reviewer_id, reviewee_id, match_id, rating, comment
- [ ] `Notification` model — user_id, type, title, body, read, data
- [ ] `Dispute` model — match_id, raised_by, reason, evidence_url, status, resolution

## Step 3 — Supabase Database
Run full SQL migration via Supabase CLI (`supabase db push`).

Tables: `users`, `listings`, `matches`, `messages`, `reviews`, `notifications`, `disputes`

RLS policies on all tables. Realtime enabled on `messages` and `notifications`.

## Step 4 — Auth Screens
Built from `onboarding_find/screen.png` stitch:
- [ ] **SplashScreen** — ChipIn logo, teal bg, auth state check → route guard
- [ ] **OnboardingScreen** — 3 slides (Find / Split / Save), image+title+subtitle, page dots, Skip + Next buttons
- [ ] **SignupScreen** — email + password fields, phone number field
- [ ] **OtpScreen** — 6-digit OTP input, Termii integration, resend timer
- [ ] **LoginScreen** — email + password, link to signup
- [ ] **AuthProvider** (Riverpod) — wraps Supabase auth, exposes currentUser stream

## Step 5 — Home Feed
Built from `home_feed/screen.png` stitch:
- [ ] **HomeScreen** — sticky header (avatar + ChipIn logo + notification bell), search bar, category chips row, "Featured Splits" section with listing cards
- [ ] **ListingCard** widget — hero image, category badge, price badge, poster avatar + trust score, slots left, action button (Join/Request)
- [ ] **CategoryChip** widget — icon + label, coloured bg per category

## Step 6 — Browse / Explore
- [ ] **BrowseScreen** — full listing feed, search bar, filter sheet (category, price range, location, verification status), sort options

## Step 7 — Post a Split (3-step wizard)
Built from `post_a_split_category`, `post_a_split_details`, `post_a_split_finish` stitches:
- [ ] **PostCategoryScreen** — 2×3 grid + 1 row "Other", progress bar Step 1/3
- [ ] **PostDetailsScreen** — title field, location toggle (Remote/Global), total cost, slots stepper, auto-calculated per-person share, progress bar Step 2/3
- [ ] **PostExtrasScreen** — description textarea, tags input + chips, listing preview card, Publish / Save as Draft, progress bar Step 3/3
- [ ] **ListingsProvider** — createListing(), getListings(), getListingById()

## Step 8 — Listing Detail
Built from `listing_detail/screen.png` stitch:
- [ ] **ListingDetailScreen** — category badge, title, location chips, poster row (avatar, trust score, View Profile), total/share cost cards, slots availability, about section, feature bullets, "Request to Join" sticky button
- [ ] **MatchProvider** — requestToJoin(), getMatchesForUser()

## Step 9 — My Matches
Built from `my_matches/screen.png` stitch:
- [ ] **MatchesScreen** — Received / Sent tab bar, match cards (listing image, price badge, requester name, message snippet, status badge), Accept Match + Chat buttons

## Step 10 — Real-time Chat
Built from `chat/screen.png` stitch:
- [ ] **ChatScreen** — sticky top bar (avatar, name, trust score, verified badge), "Confirm Split" action banner, message bubbles (sent/received with avatars), escrow reminder system message, input bar (+ attach, message field, template shortcuts, send), bottom quick-action chips (Request Escrow, Send Receipt, Remind)
- [ ] **MessagesProvider** — Supabase Realtime subscription on `messages` table filtered by match_id

## Step 11 — Profile
Built from `user_profile/screen.png` stitch:
- [ ] **ProfileScreen** — avatar with verified badge overlay, name, member since + location, Edit Profile button, Trust Score + Rating side-by-side cards, Verification Badges row, Active Splits list, Past Reviews list
- [ ] **ProfileProvider** — getUserProfile(), getMyProfile()

## Step 12 — Notifications Screen
- [ ] **NotificationsScreen** — feed of in-app notifications (match requests, messages, payment events)

## Step 13 — Polish & Analyze
- [ ] Run `flutter analyze` — fix all warnings and errors
- [ ] Ensure all GoRouter routes are reachable
- [ ] Ensure all Riverpod providers compile correctly

---

## Tech Decisions
| Decision | Choice | Reason |
|---|---|---|
| State | Riverpod (notifier + provider pattern) | Already in project |
| Navigation | GoRouter declarative | Already in project, works with auth guards |
| Chat realtime | Supabase Realtime (channel subscription) | Already using Supabase |
| OTP | Termii HTTP API | Africa-first, as spec'd in product doc |
| Local cache | `shared_preferences` (simple, skip Hive for Phase 1) | Ship fast |
| Image upload | image_picker + Supabase Storage | Already in pubspec |

---

## Files to Delete / Replace
- `lib/core/models/expense.dart` — not needed in Phase 1 (Splitwise-style, post-MVP)
- `lib/core/models/group.dart` — replaced by Listing/Match models
- `lib/features/expenses/` — not needed Phase 1
- `lib/features/groups/` — replaced by listings/matches features
- Old `home_screen.dart` — full replacement

## Credentials
- Supabase URL: `https://ttdablzltxnaeaohkibg.supabase.co`
- Supabase Anon Key: stored in `app_constants.dart`
- Termii Base URL: `https://v3.api.termii.com`
- Termii API Key: stored in `app_constants.dart`
