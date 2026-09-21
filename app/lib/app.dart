import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'router/app_router.dart';

class TajirikaApp extends ConsumerWidget {
  const TajirikaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Light status bar icons on mint background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'Tajirika',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.dmSansTextTheme(),
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
        ),
        // navigationBarTheme: NavigationBarThemeData(
        //   backgroundColor: Colors.transparent,
        //   indicatorColor: AppColors.primary.withOpacity(0.15),
        //   height: 60,
        //   labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        //   iconTheme: WidgetStateProperty.resolveWith((states) {
        //     if (states.contains(WidgetState.selected)) {
        //       return const IconThemeData(
        //         color: AppColors.navSelected,
        //         size: 24,
        //       );
        //     }
        //     return const IconThemeData(
        //       color: AppColors.navUnselected,
        //       size: 22,
        //     );
        //   }),
        //   labelTextStyle: WidgetStateProperty.resolveWith((states) {
        //     if (states.contains(WidgetState.selected)) {
        //       return const TextStyle(
        //         color: AppColors.navSelected,
        //         fontSize: 11,
        //         fontWeight: FontWeight.w600,
        //       );
        //     }
        //     return const TextStyle(
        //       color: AppColors.navUnselected,
        //       fontSize: 11,
        //     );
        //   }),
        // ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
