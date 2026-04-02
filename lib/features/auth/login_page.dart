import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onLoggedIn, this.onTapSignUp});

  final VoidCallback? onLoggedIn;
  final VoidCallback? onTapSignUp;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool loading = false;
  bool obscurePassword = true;

  final emailCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    forceCodeForRefreshToken: true,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
  }

  @override
  void dispose() {
    emailCtl.dispose();
    passwordCtl.dispose();
    super.dispose();
  }

  // ✅ Sign in with Email & Password
  Future<void> _signInWithEmail() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);
    ScaffoldMessenger.of(context).clearSnackBars();

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtl.text.trim(),
        password: passwordCtl.text,
      );

      if (mounted && userCredential.user != null) {
        Navigator.of(context).pushReplacementNamed('/home');
        widget.onLoggedIn?.call();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = switch (e.code) {
          'user-not-found' => 'ไม่พบบัญชี กรุณาสมัครสมาชิก',
          'wrong-password' => 'รหัสผ่านไม่ถูกต้อง',
          'invalid-email' => 'อีเมลไม่ถูกต้อง',
          'user-disabled' => 'บัญชีนี้ถูกปิดใช้งาน',
          _ => 'เข้าสู่ระบบไม่สำเร็จ: ${e.message ?? e.code}',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ✅ Sign in with Google
  Future<void> _signInWithGoogle() async {
    setState(() => loading = true);
    ScaffoldMessenger.of(context).clearSnackBars();

    try {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Sign out error: $e');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => loading = false);
        return;
      }

      final GoogleSignInAuthentication? googleAuth =
          await googleUser.authentication;

      if (googleAuth == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get Google authentication'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => loading = false);
        return;
      }

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get access token'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => loading = false);
        return;
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      ) as OAuthCredential;

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted && userCredential.user != null) {
        Navigator.of(context).pushReplacementNamed('/home');
        widget.onLoggedIn?.call();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = switch (e.code) {
          'account-exists-with-different-credential' =>
            'Account exists with different provider',
          'invalid-credential' => 'Invalid credential',
          'operation-not-allowed' => 'Google Sign-In not enabled',
          'user-disabled' => 'User account has been disabled',
          'user-not-found' => 'User not found',
          _ => 'Firebase error: ${e.code}',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอกอีเมล';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(v.trim())) return 'อีเมลไม่ถูกต้อง';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 6) return 'รหัสผ่านอย่างน้อย 6 ตัวอักษร';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 3, 1, 59),
              Color.fromARGB(255, 41, 28, 114)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Logo
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/ChatGPT_Image_1.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Welcome Back 👋',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Focus Planner',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ✅ Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: loading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4285F4),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Image.asset(
                                      'assets/images/google.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ✅ Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Or',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ✅ Email & Password Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            // ✅ Email Input
                            TextFormField(
                              controller: emailCtl,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Email',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ✅ Password Input
                            TextFormField(
                              controller: passwordCtl,
                              validator: _validatePassword,
                              obscureText: obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: 'Password',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  onPressed: () =>
                                      setState(() => obscurePassword = !obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ✅ Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ✅ Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4285F4),
                                      Color(0xFF1F5FE0)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4285F4).withOpacity(0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: loading ? null : _signInWithEmail,
                                  child: Text(
                                    loading ? 'กำลังเข้าสู่ระบบ...' : 'Sign In',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ✅ Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                                ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.9)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      enabledBorder: _border(Colors.white.withOpacity(0.35)),
      focusedBorder: _border(Colors.white),
      errorBorder: _border(Colors.redAccent),
      focusedErrorBorder: _border(Colors.redAccent),
    );
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: 1.2),
      );
}