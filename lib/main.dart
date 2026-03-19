import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'pages/home_page.dart';
import 'providers/app_providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  Intl.defaultLocale = 'zh_CN';

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const CalendarApp(),
    ),
  );
}

class CalendarApp extends ConsumerWidget {
  const CalendarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.light;
    const darkBase = Color(0xFF0E141B);
    const darkText = Color(0xFFEAF2F8);
    final lightScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ).copyWith(
      surface: Colors.white,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: darkBase,
      brightness: Brightness.dark,
    ).copyWith(
      primary: darkBase,
      secondary: darkBase,
      tertiary: darkBase,
      surface: darkBase,
      surfaceContainer: darkBase,
      surfaceContainerHigh: darkBase,
      surfaceContainerHighest: darkBase,
      surfaceContainerLow: darkBase,
      surfaceContainerLowest: darkBase,
      primaryContainer: darkBase,
      onSurface: darkText,
      onPrimary: darkText,
      onSecondary: darkText,
      onTertiary: darkText,
      onPrimaryContainer: darkText,
      outline: Colors.white24,
      surfaceTint: Colors.transparent,
    );

    return MaterialApp(
      title: '本地日历',
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: lightScheme,
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.transparent,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        scaffoldBackgroundColor: darkBase,
        canvasColor: darkBase,
        dividerColor: Colors.white12,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBase,
          foregroundColor: darkText,
          surfaceTintColor: Colors.transparent,
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: darkBase,
          selectedColor: darkBase,
          disabledColor: darkBase,
          side: BorderSide(color: Colors.white24),
          labelStyle: TextStyle(color: darkText),
          secondaryLabelStyle: TextStyle(color: darkText),
          checkmarkColor: darkText,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
