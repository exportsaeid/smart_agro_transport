 import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/login_page.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database/database_helper.dart';
import 'utils/backup_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BackupScheduler.initialize();
  // اگر بکاپ خودکار فعال است، زمان‌بندی را دوباره اعمال کن
  final bootPrefs = await SharedPreferences.getInstance();
  final backupEnabled = bootPrefs.getBool('backup_enabled') ?? false;
  final backupEmail = bootPrefs.getString('backup_email') ?? '';
  if (backupEnabled && backupEmail.contains('@')) {
    await BackupScheduler.scheduleCustomBackup(
      email: backupEmail,
      time: bootPrefs.getString('backup_time') ?? '02:30',
      intervalDays: bootPrefs.getInt('backup_interval_days') ??
          bootPrefs.getInt('backupDays') ??
          7,
    );
  }

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(initialDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool initialDarkMode;
  const MyApp({super.key, required this.initialDarkMode});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  void changeTheme(bool isDark) {
    setState(() => _isDarkMode = isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'فاکتور هوشمند کشاورزی',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        PersianMaterialLocalizations.delegate,
        PersianCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fa', 'IR'),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        fontFamily: 'Tahoma',
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        fontFamily: 'Tahoma',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[850],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[900],
          foregroundColor: Colors.white,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: LoginPage(),
      ),
    );
  }
}
