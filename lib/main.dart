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
    final lightScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ).copyWith(
      surface: Colors.white,
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
