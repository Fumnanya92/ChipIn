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

## Workflow

### Write `tasks/todo.md` at session start, not end
- **Mistake**: Tasks folder wasn't created until the end of the session. Progress tracking and gap detection happened ad-hoc.
- **Rule**: First action of any non-trivial session = create `tasks/todo.md` with a full checklist. Check items as you go. Review against the product plan explicitly.
