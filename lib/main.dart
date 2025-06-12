import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_ai/utils/app_colors.dart';

import 'screens/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          background: AppColors.background,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: AppColors.surface,
          onSecondary: AppColors.surface,
          onBackground: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
          onError: AppColors.surface,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(bodyLarge: GoogleFonts.poppins(color: AppColors.textPrimary), bodyMedium: GoogleFonts.poppins(color: AppColors.textSecondary), bodySmall: GoogleFonts.poppins(color: AppColors.textHint)),
      ),
      home: const HomeScreen(),
    );
  }
}
