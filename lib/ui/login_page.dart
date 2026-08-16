import 'package:flutter/material.dart';
import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/auth_repository.dart';
import 'main_invoice_page.dart';
import '../utils/battery_optimization_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FocusNode _passwordFocus = FocusNode();

  bool _isPasswordVisible = false;
  String? _errorMessage;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    final bool useBiometrics = prefs.getBool('use_biometrics') ?? false;
    final String? lastUser = prefs.getString('last_username');

    if (useBiometrics && lastUser != null) {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      if (canAuthenticateWithBiometrics) {
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'لطفاً برای ورود انگشت خود را روی حسگر قرار دهید',
          options: const AuthenticationOptions(biometricOnly: true),
        );

        if (didAuthenticate) {
          _proceedToMain(lastUser);
        }
      }
    }
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'نام کاربری و رمز عبور را وارد کنید\nPlease enter username and password';
      });
      return;
    }

    final user = await _authRepository.login(username, password);

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_username', username);

      if (await _authRepository.isUsingDefaultPassword(username)) {
        setState(() => _isLoading = false);
        _showForceChangePasswordDialog(username);
      } else {
        _proceedToMain(username);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'نام کاربری یا رمز عبور اشتباه است\nIncorrect username or password';
      });
    }
  }

  void _proceedToMain(String username) async {
    if (Platform.isAndroid) {
      final bool isIgnored =
          await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
      if (!isIgnored && mounted) {
        final bool result =
            await BatteryOptimizationHelper.showSimpleBatteryDialog(context);
        if (!result && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ بکاپ خودکار نیاز به خروج از Battery Optimization دارد',
                style: TextStyle(fontFamily: 'Tahoma'),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainInvoicePage()),
      );
    }
  }

  void _showForceChangePasswordDialog(String username) {
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('تغییر اجباری رمز عبور',
                      style: TextStyle(fontFamily: 'Tahoma', fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'رمز عبور شما پیش‌فرض است. لطفاً آن را تغییر دهید.\nYour password is default. Please change it.',
                    style: TextStyle(fontFamily: 'Tahoma', fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPassController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'رمز عبور جدید',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'تکرار رمز عبور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      dialogError!,
                      style: const TextStyle(
                          color: Colors.red, fontFamily: 'Tahoma', fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (newPassController.text.length < 3) {
                      setDialogState(() {
                        dialogError =
                            'رمز باید حداقل ۳ کاراکتر باشد\nPassword must be at least 3 characters';
                      });
                      return;
                    }
                    if (newPassController.text != confirmPassController.text) {
                      setDialogState(() {
                        dialogError =
                            'رمزها یکسان نیستند\nPasswords do not match';
                      });
                      return;
                    }

                    await _authRepository.changePassword(
                        username, newPassController.text);
                    if (mounted) {
                      Navigator.pop(ctx);
                      _proceedToMain(username);
                    }
                  },
                  child: const Text(
                    'ذخیره و ورود',
                    style: TextStyle(color: Colors.white, fontFamily: 'Tahoma'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ===== پس‌زمینه گرادیان زیبا =====
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1B5E20), // سبز تیره
                  Color(0xFF2E7D32), // سبز اصلی
                  Color(0xFF43A047), // سبز روشن‌تر
                  Color(0xFF66BB6A), // سبز ملایم
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),

          // اشکال تزئینی نرم
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.08),
              ),
            ),
          ),

          // ===== محتوا =====
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        // ===== لوگو =====
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            size: 48,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'حمل و نقل هوشمند کشاورزی',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tahoma',
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Smart Agro Transport',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontFamily: 'Tahoma',
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ===== کارت لاگین =====
                        Container(
                          width: size.width > 480 ? 420 : double.infinity,
                          padding:
                              const EdgeInsets.fromLTRB(24, 28, 24, 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'ورود به حساب کاربری',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                    fontFamily: 'Tahoma',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'لطفاً اطلاعات خود را وارد کنید',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontFamily: 'Tahoma',
                                  ),
                                ),
                                const SizedBox(height: 26),

                              // نام کاربری
                              TextField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    FocusScope.of(context)
                                        .requestFocus(_passwordFocus),
                                style: const TextStyle(fontFamily: 'Tahoma'),
                                decoration: InputDecoration(
                                  labelText: 'نام کاربری',
                                  hintText: 'نام کاربری را وارد کنید',
                                  prefixIcon: const Icon(Icons.person_outline,
                                      color: Color(0xFF2E7D32)),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F8E9),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: Colors.green.shade100),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF2E7D32), width: 1.8),
                                  ),
                                  labelStyle: const TextStyle(
                                      fontFamily: 'Tahoma', fontSize: 14),
                                  hintStyle: TextStyle(
                                      fontFamily: 'Tahoma',
                                      color: Colors.grey[400],
                                      fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // رمز عبور
                              TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleLogin(),
                                style: const TextStyle(fontFamily: 'Tahoma'),
                                decoration: InputDecoration(
                                  labelText: 'رمز عبور',
                                  hintText: 'رمز عبور را وارد کنید',
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: Color(0xFF2E7D32)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F8E9),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: Colors.green.shade100),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF2E7D32), width: 1.8),
                                  ),
                                  labelStyle: const TextStyle(
                                      fontFamily: 'Tahoma', fontSize: 14),
                                  hintStyle: TextStyle(
                                      fontFamily: 'Tahoma',
                                      color: Colors.grey[400],
                                      fontSize: 13),
                                ),
                              ),

                              // پیام خطا
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red.shade700, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade800,
                                            fontSize: 12.5,
                                            fontFamily: 'Tahoma',
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // دکمه ورود
                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    disabledBackgroundColor:
                                        const Color(0xFF81C784),
                                    elevation: 4,
                                    shadowColor:
                                        const Color(0xFF2E7D32).withOpacity(0.45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 26,
                                          height: 26,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login_rounded,
                                                color: Colors.white, size: 22),
                                            SizedBox(width: 8),
                                            Text(
                                              'ورود به برنامه',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Tahoma',
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // اثر انگشت
                              TextButton.icon(
                                onPressed: _checkBiometrics,
                                icon: Icon(Icons.fingerprint,
                                    color: Colors.green[700], size: 22),
                                label: Text(
                                  'ورود با اثر انگشت',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontFamily: 'Tahoma',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                        Text(
                          'نسخه ۱.۰.۰',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                            fontFamily: 'Tahoma',
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
