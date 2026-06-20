// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary      = Color(0xFF1565C0);
  static const primaryDark  = Color(0xFF0D47A1);
  static const primaryLight = Color(0xFF1976D2);
  static const onPrimary    = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFD6E4FF);

  static const surface      = Color(0xFFF8FAFE);
  static const background   = Color(0xFFF0F4FF);
  static const card         = Color(0xFFFFFFFF);

  static const slotVacantBg = Color(0xFFE8F5E9);
  static const slotVacantFg = Color(0xFF2E7D32);
  static const slotOccupiedBg = Color(0xFFFFEBEE);
  static const slotOccupiedFg = Color(0xFFC62828);
  static const slotFaultBg  = Color(0xFFFFF8E1);
  static const slotFaultFg  = Color(0xFFF57C00);
  static const slotOfflineBg = Color(0xFFF5F5F5);
  static const slotOfflineFg = Color(0xFF616161);
  static const slotReservedBg = Color(0xFFEDE7F6);
  static const slotReservedFg = Color(0xFF5E35B1);

  static const error   = Color(0xFFD32F2F);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57C00);
  static const info    = Color(0xFF1565C0);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: GoogleFonts.spaceGrotesk(
              fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.spaceGrotesk(
              fontSize: 26, fontWeight: FontWeight.bold),
          displaySmall: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.w600),
          headlineMedium: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.bold),
          headlineSmall: GoogleFonts.spaceGrotesk(
              fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.dmSans(fontSize: 16),
          bodyMedium: GoogleFonts.dmSans(fontSize: 14),
          bodySmall: GoogleFonts.dmSans(fontSize: 12),
          labelLarge: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.card,
          elevation: 0,
          scrolledUnderElevation: 2,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: AppColors.primary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.card,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Color(0xFF9E9E9E),
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFBBCCEE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFBBCCEE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: Color(0xFF546E7A)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        chipTheme: ChipThemeData(
          labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE3EAF6),
          thickness: 1,
        ),
      );
}
