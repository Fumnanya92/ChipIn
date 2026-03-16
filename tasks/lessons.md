# Lessons Learned

## Theme / Dark Mode

### Never hardcode `backgroundColor` in Scaffold widgets
- **Mistake**: All 12 feature screens set `backgroundColor: AppColors.backgroundLight` explicitly in their Scaffold, completely overriding the theme system. Dark mode never worked because the scaffold always got the light color.
- **Rule**: Let `scaffoldBackgroundColor` from `AppTheme.darkTheme` / `AppTheme.lightTheme` handle scaffold color automatically. Only override `backgroundColor` if a specific screen truly needs to differ from the theme default.

### Always use context-aware colors for card/surface containers
- **Mistake**: Card containers used `color: Colors.white` and `border: Border.all(color: AppColors.borderLight)` — always white regardless of mode.
- **Rule**: Use `AppColors.surface(context)` for card backgrounds and `AppColors.border(context)` for card borders. These resolve to the correct dark/light values at runtime.

### Theme toggle must be prominent and labeled
- **Mistake**: The Dark Mode toggle was only a tiny icon button hidden in the AppBar of the Profile screen. Users couldn't find it.
- **Rule**: Place the Appearance/Dark Mode toggle in the profile screen **body** as a full-width labeled row (icon + "Dark Mode" text + Switch widget). The AppBar icon can remain as a shortcut but is not sufficient alone.

## Feature Completeness

### Review the product plan before calling a session "done"
- **Mistake**: The Submit Review screen was in the product plan (Section 11 — `reviews/`) but had never been created. The escrow completion flow showed a SnackBar saying "Please leave a review" but didn't navigate anywhere.
- **Rule**: After any major feature session, do a complete diff of `lib/features/` against the product plan feature list. Create a `tasks/todo.md` checklist at session start so nothing gets missed.

## Code Organization

### Keep static context-sensitive color helpers in `AppColors`
- **Pattern**: Static methods on `AppColors` that accept `BuildContext` and return the right color for current brightness:
  ```dart
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardDark : surfaceLight;
  ```
- **Why**: Centralizes theme logic, avoids `Theme.of(context).brightness == Brightness.dark` duplication across 20+ files.

## Design Implementation

### Always include Auth + Splash + Loading screens in design pass
- **Mistake**: During full app redesign pass covering 19 screens, forgot to update: splash/loading screen, login screen, signup screen, OTP screen, and all verification flow screens.
- **Rule**: Maintain a canonical screen list that includes auth gates (splash, login, signup, OTP) — these are the first thing users see. Auth screens are never optional in a design pass.

### Bottom nav structure must match Stitch designs exactly
- **Current ChipIn nav (correct)**: Home | Explore | Post (FAB center) | Matches | Profile
- **Mistake**: Messages was given its own bottom tab, but Stitch designs never have a Messages tab — chat is accessed from the Matches flow.
- **Rule**: Messages moves to top-bar icon (near bell). Bottom nav = 4 shell branches (Home, Browse, Matches, Profile) + center FAB push route. Removing a shell branch requires updating BOTH `app_router.dart` + `app_shell.dart`.

### Don't rely on Stitch export color tokens across screens — use canonical brand token
- **Finding**: Different Stitch exports for the same app used slightly different primary hex values (`#0f9dbd` vs `#11b4d4`) and slightly different dark backgrounds. The canonical brand color is ALWAYS `AppColors.primary = #11B4D4`. Use it everywhere.
- **Rule**: Ignore per-screen color variations in Stitch exports. They're artifacts of different export sessions. Always use the `AppColors.*` constants.

## Infrastructure

### Create Supabase storage buckets in migrations, not manually
- **Rule**: Storage bucket creation SQL belongs in `supabase/migrations/` so all environments stay in sync. Use `INSERT INTO storage.buckets` and add RLS policies in the same migration.

### For large binary assets (listing images, avatars), Supabase Storage is fine up to ~50MB per file
- If S3 is needed for cost, configure via a single `storage_service.dart` abstraction so the upload URL is swappable without touching feature screens.

## Workflow

### Write `tasks/todo.md` at session start, not end
- **Mistake**: Tasks folder wasn't created until the end of the session. Progress tracking and gap detection happened ad-hoc.
- **Rule**: First action of any non-trivial session = create `tasks/todo.md` with a full checklist. Check items as you go. Review against the product plan explicitly.

## Static Color Methods and Dark Mode

### `_inputDecor()` must never be static in ConsumerStatefulWidget
- **Mistake (repeated)**: Helper methods that build `InputDecoration` were marked `static`, so they had no `BuildContext` and hardcoded `AppColors.borderLight` for borders + `AppColors.textPrimary` for labels. Forms were completely invisible/broken in dark mode.
- **Rule**: If a helper method produces any color/style derived from the current theme, it MUST accept `BuildContext context` as a parameter. Make it non-static. This applies to `_inputDecor()`, `_labelStyle()`, `_buildField()`, etc.

### Don't use Dark-named static constants without an isDark guard
- **Mistake**: `AppColors.textDark`, `AppColors.cardDark`, `AppColors.backgroundDark`, `AppColors.borderSlate` were used as unconditional constants in widget code. In light mode these produced near-white/dark-teal on white backgrounds (invisible).
- **Rule**: Dark-named constants (`*Dark`, `*Slate`) are FOR use in `if (isDark)` branches or as the second arm of a ternary: `color: isDark ? AppColors.textDark : AppColors.textPrimary`. Never use them unconditionally mid-widget.

### `ref.read` in `build()` misses reactive updates for security checks
- **Bug**: `final currentUserId = ref.read(currentUserIdProvider)` in `build()` — since `ref.read` doesn't subscribe, if auth loads AFTER the page first mounts (Supabase session restore race), `currentUserId` is null and `isOwner = false`. Users could self-request their own listing.
- **Rule**: Use `ref.watch(currentUserIdProvider)` in `build()` for any security-critical check. `ref.read` is only for event handlers (onPressed, etc.) where you want a one-time snapshot.

## Nav Bar Implementation

### AnimatedSlide fraction for Magic Nav indicator
- **Formula**: For the active icon to reach the circle center, lift fraction = `navH/2 / iconSize`. With `_navH=60` and icon size `23`, fraction ≈ `30/23 ≈ 1.3`. But accounting for Column centering with label overhead, actual fraction ≈ `1.05`.
- **Rule**: Use `AnimatedSlide(offset: Offset(0, -1.05))` on the icon only (not the whole Column) with `clipBehavior: Clip.none` on the parent Stack to allow overflow into the circle area.
- **Circle depth**: Set `_overflow = _indicatorD / 2` so the circle center sits exactly at the nav bar top edge. Active icon lifts from nav center to nav top = into the circle.

## Payment Flow

### Pre-escrow manual payment: both parties confirm
- For MVP before formal escrow, implement: `accepted` → `requester_paid_at` (requester taps "I've Paid") → `owner_confirmed_at` (owner taps "Received") → `status: active`.
- Add `payment_instructions` text column to matches so owner can share bank/OPay details.
- DB migration: add nullable columns, update status constraint. Never remove status values that might be in production data.

### Receipt upload: Storage path + model field + provider method
- Pattern: `uploadReceipt(matchId, bytes, ext)` in MatchNotifier → uploads to `payment-receipts/$matchId/receipt.$ext` → calls `getPublicUrl()` → updates `matches.receipt_url`.
- Always `upsert: true` in FileOptions so re-uploading doesn't error.
- DB migration adds `receipt_url text` column. Storage bucket created in same migration SQL.

## Edit Safety

### Splitting an existing method line when using Edit tool causes syntax errors
- **Mistake**: Used old_string `void _showInstructionsSheet(MatchModel match) {\n    showModalBottomSheet(` to insert code before it, but the replacement accidentally dropped the `showModalBottomSheet(` call, leaving naked named args as statements.
- **Rule**: When inserting code BEFORE an existing method, include enough of the method body in old_string to preserve the full opening call. Or target a blank line ABOVE the method entirely.


