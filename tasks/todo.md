# ChipIn — Task Tracker

## Session: Dark Mode Fix + Missing Features

### Theme / Dark Mode
- [x] Remove `backgroundColor: AppColors.backgroundLight` from all 12 Scaffold widgets
- [x] Add `AppColors.surface(context)` helper to `app_theme.dart`
- [x] Add `AppColors.border(context)` helper to `app_theme.dart`
- [x] Add `AppColors.scaffoldBg(context)`, `textOn(context)`, `textSub(context)` helpers
- [x] Fix card container `Colors.white` → `AppColors.surface(context)` in:
  - [x] `home_screen.dart` — notification button, search bar, listing card
  - [x] `matches_screen.dart` — match card
  - [x] `chat_screen.dart` — chat input bar
  - [x] `listing_detail_screen.dart` — poster row, availability row, slot option card
  - [x] `profile_screen.dart` — verification badges, stat cards, review cards
- [x] Fix `Border.all(color: AppColors.borderLight)` → `AppColors.border(context)` across the same files
- [x] Add prominent Appearance section (Dark Mode switch) to Profile screen body

### Missing Features
- [x] Create `lib/features/reviews/presentation/pages/submit_review_screen.dart`
- [x] Add `/review/:matchId` route to `app_router.dart`
- [x] Wire navigation to Submit Review after escrow completion in `escrow_status_screen.dart`

### Quality Gates
- [x] `flutter analyze` — zero issues
- [ ] `flutter build apk --debug` — successful build
- [ ] Git commit and push

---

## Product Plan Checklist (Section 12 — All 21 Screens)

| # | Screen | Status |
|---|--------|--------|
| 1 | Splash / auth gate | ✅ |
| 2 | Onboarding | ✅ |
| 3 | Login / Signup / OTP | ✅ |
| 4 | Home feed | ✅ |
| 5 | Browse / search | ✅ |
| 6 | Listing detail | ✅ |
| 7 | Post a split (category → details → extras) | ✅ |
| 8 | Matches | ✅ |
| 9 | Chat | ✅ |
| 10 | Escrow deposit / status / dispute | ✅ |
| 11 | Profile (own + other) | ✅ |
| 12 | Edit profile | ✅ |
| 13 | Notifications | ✅ |
| 14 | Verification (intro / ID upload / selfie) | ✅ |
| 15 | Submit review | ✅ (added this session) |
| 16 | Trust system display | ✅ (trust score on profile) |
| 17 | Analytics | — (scaffold only, no data) |
| 18 | Payments history | — (escrow covers current scope) |
| 19 | Dark mode appearance toggle | ✅ (added this session) |
| 20 | App settings | — (out of scope v1) |
| 21 | Home shell / bottom nav | ✅ |
