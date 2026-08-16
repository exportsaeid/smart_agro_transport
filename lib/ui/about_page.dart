import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _version = '1.0.0';

  Future<void> _shareApp(BuildContext context) async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=ir.smartagro.transport',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('امکان اشتراک‌گذاری وجود ندارد', style: TextStyle(fontFamily: 'Tahoma'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('درباره اپ', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
          backgroundColor: Colors.green[800],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_shipping, size: 56, color: Colors.green[800]),
              ),
              const SizedBox(height: 16),
              Text(
                'فاکتور هوشمند کشاورزی',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  fontFamily: 'Tahoma',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'نسخه $_version',
                style: TextStyle(color: Colors.grey[600], fontFamily: 'Tahoma'),
              ),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ویژگی‌های اپلیکیشن',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                          fontFamily: 'Tahoma',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _feature('مدیریت آسان فاکتورهای کشاورزی'),
                      _feature('محاسبه خودکار سود و زیان'),
                      _feature('گزارش‌گیری حرفه‌ای'),
                      _feature('پشتیبانی از محصولات متنوع کشاورزی'),
                      _feature('رابط کاربری ساده و زیبا'),
                      _feature('بکاپ خودکار و امن'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareApp(context),
                  icon: const Icon(Icons.share),
                  label: const Text('اشتراک‌گذاری اپلیکیشن', style: TextStyle(fontFamily: 'Tahoma')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: Colors.green[800]!),
                    foregroundColor: Colors.green[800],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '© 2024–2026 فاکتور هوشمند کشاورزی\nکلیه حقوق محفوظ است.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Tahoma', height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.green[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Tahoma', fontSize: 14))),
        ],
      ),
    );
  }
}
