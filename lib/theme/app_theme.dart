import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цвета приложения (светлая тема).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF81262B);
  static const Color primaryLight = Color(0xFFA3353B);
  static const Color surface = Color(0xFFF3F3F3);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF6A6A6A);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFB71C1C);
  static const Color success = Color(0xFF2E7D32);
}

/// Единая тема приложения: веб и iOS.
class AppTheme {
  AppTheme._();

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _isWeb => kIsWeb;

  static ScrollPhysics get scrollPhysics {
    if (_isIOS) return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
    if (_isWeb) return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
    return const ClampingScrollPhysics();
  }

  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: GoogleFonts.manrope(fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary),
      bodySmall: GoogleFonts.manrope(fontSize: 12, color: AppColors.textTertiary),
      labelLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600),
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.divider,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: !_isWeb,
        titleTextStyle: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerColor: AppColors.divider,
      splashFactory: InkRipple.splashFactory,
    );
  }

  static ThemeData darkTheme() {
    const surfaceDark = Color(0xFF1E1E1E);
    const cardDark = Color(0xFF2D2D2D);
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      titleMedium: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: GoogleFonts.manrope(fontSize: 16, color: Colors.white),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, color: Colors.white70),
      bodySmall: GoogleFonts.manrope(fontSize: 12, color: Colors.white54),
      labelLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600),
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryLight,
        surface: surfaceDark,
        surfaceContainerHighest: cardDark,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
      ),
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        elevation: 0,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(color: cardDark, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      dividerColor: Colors.white24,
      dialogTheme: DialogThemeData(backgroundColor: cardDark, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: cardDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF3D3D3D),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF383838),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      popupMenuTheme: PopupMenuThemeData(color: cardDark, surfaceTintColor: Colors.transparent),
    );
  }
}
