import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// صفحه ارتباط با ما — با کلیک روی هر مورد، اپ مربوطه باز می‌شود
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // اطلاعات پشتیبانی (مطابق نسخه اندروید)
  static const String phoneNumber = '989010388244';
  static const String whatsappNumber = '989010388244';
  static const String emailAddress = 'export.saeid@gmail.com';

  Future<void> _openPhone(BuildContext context) async {
    final uri = Uri.parse('tel:+$phoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _toast(context, 'امکان باز کردن تلفن وجود ندارد');
      }
    } catch (e) {
      _toast(context, 'خطا در باز کردن تلفن');
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/$whatsappNumber');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _toast(context, 'واتساپ یافت نشد');
    } catch (e) {
      _toast(context, 'خطا در باز کردن واتساپ');
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      query: 'subject=${Uri.encodeComponent('پشتیبانی SmartAgroTransport')}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _toast(context, 'برنامه ایمیل یافت نشد');
      }
    } catch (e) {
      _toast(context, 'خطا در باز کردن ایمیل');
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Tahoma'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('ارتباط با ما', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
          backgroundColor: Colors.green[800],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).cardColor,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.support_agent, size: 42, color: Colors.green[800]),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ارتباط با پشتیبانی',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tahoma'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'روی هر مورد کلیک کنید تا خودکار باز شود',
                        style: TextStyle(color: Colors.grey[600], fontFamily: 'Tahoma', fontSize: 13),
                      ),
                      const SizedBox(height: 28),
                      _ContactTile(
                        icon: Icons.chat,
                        iconColor: const Color(0xFF25D366),
                        title: 'واتساپ',
                        subtitle: '+$whatsappNumber',
                        onTap: () => _openWhatsApp(context),
                      ),
                      const SizedBox(height: 12),
                      _ContactTile(
                        icon: Icons.phone,
                        iconColor: Colors.blue,
                        title: 'تماس تلفنی',
                        subtitle: '+$phoneNumber',
                        onTap: () => _openPhone(context),
                      ),
                      const SizedBox(height: 12),
                      _ContactTile(
                        icon: Icons.email,
                        iconColor: Colors.orange,
                        title: 'ایمیل',
                        subtitle: emailAddress,
                        onTap: () => _openEmail(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '⏰ پاسخگویی: ۹ صبح تا ۹ شب',
                style: TextStyle(color: Colors.grey[600], fontFamily: 'Tahoma'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[850]
        : Colors.grey[100];
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.15),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tahoma', fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontFamily: 'Tahoma', fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}
