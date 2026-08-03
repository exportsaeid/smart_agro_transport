import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'views/login_screen.dart';

// ✅ تابع تشخیص وب (جایگزین dart:io)
bool get isWeb {
  return const bool.fromEnvironment('dart.library.html');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ فقط در صورتی که وب نباشیم، کدهای دسکتاپ اجرا شوند
  if (!isWeb) {
    // برای ویندوز، لینوکس، مک
    // از Platform.isWindows استفاده نمی‌کنیم چون در وب خطا می‌دهد
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('✅ دیتابیس برای دسکتاپ مقداردهی شد');
    } catch (e) {
      print('⚠️ خطا در مقداردهی دیتابیس: $e');
    }
  } else {
    print('✅ اجرا روی وب - دیتابیس غیرفعال است');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حمل و نقل هوشمند کشاورزی',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        // ✅ در وب از فونت پیش‌فرض استفاده می‌کنیم
        fontFamily: isWeb ? null : 'Vazir',
      ),
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: LoginScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}