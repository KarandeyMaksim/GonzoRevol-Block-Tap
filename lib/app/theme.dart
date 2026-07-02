import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens extracted from the Figma file `AKV8rliogvFA8XkwZCDWp3`.
class AppColors {
  AppColors._();

  static const cream = Color(0xFFEEDDC7);
  static const creamDim = Color(0xFFCAB291);

  static const bgTealDark = Color(0xFF12342D);
  static const bgTeal = Color(0xFF1F5A4A);

  static const boardFrame = Color(0xFF635D54);
  static const boardCell = Color(0xFFAA9D95);
  static const boardCellBorder = Color(0x7D72625C);

  static const trayPanel = Color(0xFF785E3E);
  static const trayPanelBorder = Color(0xFF372C1F);

  static const gold1 = Color(0xFFB88830);
  static const gold2 = Color(0xFFD8BB6F);
  static const gold3 = Color(0xFFC39231);

  static const playBtnTop = Color(0xFFBA481E);
  static const playBtnBottom = Color(0xFF682C14);

  static const collectBtnTop = Color(0xFFB88830);
  static const collectBtnMid = Color(0xFFD8BB6F);
  static const collectBtnBottom = Color(0xFFC39231);

  static const buyBtnTop = Color(0xFF622C0F);
  static const buyBtnBottom = Color(0xFFC85A1F);
  static const buyBtnBorder = Color(0xFF471607);

  static const dropdownBg = Color(0xFF31594D);

  static const panelDark = Color(0xFF3C6B54);
  static const panelDarkEnd = Color(0xFF181C0E);

  static const shopCardBg = Color(0xFFCAB291);
  static const shopCardBorder = Color(0xFF58452B);
  static const shopCardTitle = Color(0xFF7C3A16);

  static const textShadowDark = Color(0xFF1F1F1F);

  static const sliderTrack = Color(0xFFF5E4C7);
  static const sliderFillOn = Color(0xFF703B1B);
  static const sliderFillOff = Color(0xFF2B2926);

  static const exchangeBarFilled = Color(0xFFC07455);
  static const exchangeBarBase = Color(0xFF5F281C);
  static const exchangeSliderTrack = Color(0xFFCE631C);

  static const success = Color(0xFF3CA96E);
  static const danger = Color(0xFFCC4B2E);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle display({
    double size = 36,
    Color color = AppColors.cream,
    FontWeight weight = FontWeight.w600,
  }) =>
      GoogleFonts.gemunuLibre(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1.0,
      );

  static TextStyle body({
    double size = 16,
    Color color = Colors.black,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.roboto(
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  static TextStyle displayShadowed({
    double size = 36,
    Color color = AppColors.cream,
    FontWeight weight = FontWeight.w600,
  }) =>
      display(size: size, color: color, weight: weight).copyWith(
        shadows: const [
          Shadow(color: AppColors.textShadowDark, offset: Offset(0, 2)),
        ],
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgTealDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold2,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      );
}

/// Reference design canvas from Figma (frame size used for every screen).
class DesignConstants {
  DesignConstants._();

  static const double canvasWidth = 430;
  static const double canvasHeight = 932;
}
