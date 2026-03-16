import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF11B4D4);
  static const Color primaryLight = Color(0xFFE0F7FC);
  static const Color primaryDark  = Color(0xFF0090AA);

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF6F8F8);
  static const Color backgroundDark  = Color(0xFF101F22); // canonical dark teal

  // ── Card / Surface ────────────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark  = Color(0xFF1E293B); // slate-800
  static const Color cardDark     = Color(0xFF1E293B); // slate-800
  static const Color cardTeal     = Color(0xFF1A2E32); // teal-tinted card (latest feed)
  static const Color inputDark    = Color(0xFF111C1F); // slate-850 (post form inputs)
  static const Color slateMid     = Color(0xFF0F172A); // slate-900

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A);   // slate-900 (light mode)
  static const Color textSecondary = Color(0xFF64748B);   // slate-500
  static const Color textMuted     = Color(0xFF94A3B8);   // slate-400
  static const Color textSubtle    = Color(0xFFCBD5E1);   // slate-300
  static const Color textDark      = Color(0xFFF1F5F9);   // slate-100  (dark mode primary text)

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color borderLight  = Color(0xFFE2E8F0);  // slate-200
  static const Color borderDark   = Color(0xFF1E293B);  // slate-800
  static const Color borderSlate  = Color(0xFF334155);  // slate-700

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // Match status badges
  static const Color statusPending  = Color(0xFFFBBF24); // amber-400
  static const Color statusPendingBg = Color(0x1AFBBF24); // amber-400/10
  static const Color statusActive   = Color(0xFF34D399); // emerald-400
  static const Color statusActiveBg = Color(0x1A34D399); // emerald-400/10

  // Verified badge (green)
  static const Color verifiedGreen  = Color(0xFF4ADE80); // green-400
  static const Color verifiedBg     = Color(0x1A22C55E); // green-500/10
  static const Color verifiedBorder = Color(0x4D22C55E); // green-500/30

  // Stars
  static const Color starColor = Color(0xFFEAB308); // yellow-500

  // ── Category icon colours ─────────────────────────────────────────────────
  static const Color catSubscription = Color(0xFF11B4D4);
  static const Color catHousing      = Color(0xFFF97316); // orange-500
  static const Color catTravel       = Color(0xFF60A5FA); // blue-400
  static const Color catGroceries    = Color(0xFF4ADE80); // green-400
  static const Color catWork         = Color(0xFFC084FC); // purple-400
  static const Color catCarpool      = Color(0xFF11B4D4);
  static const Color catBills        = Color(0xFF60A5FA); // blue-400
  static const Color catOther        = Color(0xFF94A3B8); // slate-400

  // ── Category background colours (light mode) ──────────────────────────────
  static const Color catSubscriptionBg = Color(0xFFE0F7FC);
  static const Color catHousingBg      = Color(0xFFFFF3E8);
  static const Color catTravelBg       = Color(0xFFEFF6FF);
  static const Color catGroceriesBg    = Color(0xFFF0FDF4);
  static const Color catWorkBg         = Color(0xFFFAF5FF);
  static const Color catCarpoolBg      = Color(0xFFE0F7FC);
  static const Color catBillsBg        = Color(0xFFE0F3FB);
  static const Color catOtherBg        = Color(0xFFF1F5F9);

  // ── Theme-aware helpers ───────────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surface(BuildContext context) =>
      isDark(context) ? cardDark : surfaceLight;

  static Color scaffoldBg(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : borderLight;

  static Color textOn(BuildContext context) =>
      isDark(context) ? textDark : textPrimary;

  static Color textSub(BuildContext context) =>
      isDark(context) ? textSubtle : textSecondary;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surfaceLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge:  TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 28, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.textPrimary),
        headlineSmall:  TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.textPrimary),
        titleLarge:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary),
        titleMedium:    TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
        bodyLarge:      TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 16, color: AppColors.textPrimary),
        bodyMedium:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: AppColors.textSecondary),
        bodySmall:      TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 12, color: AppColors.textMuted),
        labelLarge:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14),
        labelSmall:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundLight,
        selectedColor: AppColors.primaryLight,
        labelStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColors.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }

  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge:  TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 28, color: AppColors.textDark),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.textDark),
        headlineSmall:  TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.textDark),
        titleLarge:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textDark),
        titleMedium:    TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark),
        bodyLarge:      TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 16, color: AppColors.textDark),
        bodyMedium:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: AppColors.textSubtle),
        bodySmall:      TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 12, color: AppColors.textMuted),
        labelLarge:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
        labelSmall:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5, color: AppColors.textSubtle),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardDark,
        selectedColor: Color(0x33117DB4),
        labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColors.borderDark),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
      ),
    );
  }
}
