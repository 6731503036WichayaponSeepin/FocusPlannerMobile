import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final emailCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final confirmCtl = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool loading = false;
  bool obscure1 = true;
  bool obscure2 = true;

  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอกอีเมล';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(v.trim())) return 'อีเมลไม่ถูกต้อง กรุณาใส่ @gmail.com เท่านั้น';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.length < 6) return 'รหัสผ่านอย่างน้อย 6 ตัวอักษร';
    return null;
  }

  String? validateConfirm(String? v) {
    if (v != passwordCtl.text) return 'รหัสผ่านไม่ตรงกัน';
    return null;
  }

  Future<void> register() async {

    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtl.text.trim(),
        password: passwordCtl.text,
      );

      await credential.user!.sendEmailVerification();

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสมาชิกสำเร็จ กรุณาไปกดยืนยันอีเมลก่อนเข้าสู่ระบบ'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {

      final msg = switch (e.code) {
        'email-already-in-use' => 'อีเมลนี้ถูกใช้แล้ว',
        'invalid-email' => 'อีเมลไม่ถูกต้อง',
        'weak-password' => 'รหัสผ่านอ่อนเกินไป',
        _ => e.message ?? 'สมัครสมาชิกไม่สำเร็จ'
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }

    setState(() => loading = false);
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
                  children: [

                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    const SizedBox(height: 20),

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
                      child: const Icon(Icons.person_add,
                          color: Colors.white,size: 40),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Create Account 🚀',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Join Focus Planner',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),

                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [

                            TextFormField(
                              controller: emailCtl,
                              validator: validateEmail,
                              style: const TextStyle(color: Colors.white),
                              decoration: inputDecoration(
                                label: 'Email',
                                icon: Icons.email_outlined,
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: passwordCtl,
                              validator: validatePassword,
                              obscureText: obscure1,
                              style: const TextStyle(color: Colors.white),
                              decoration: inputDecoration(
                                label: 'Password',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    obscure1
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() => obscure1 = !obscure1);
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: confirmCtl,
                              validator: validateConfirm,
                              obscureText: obscure2,
                              style: const TextStyle(color: Colors.white),
                              decoration: inputDecoration(
                                label: 'Confirm Password',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    obscure2
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() => obscure2 = !obscure2);
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: loading ? null : register,
                                child: Text(
                                  loading
                                      ? 'กำลังสมัครสมาชิก...'
                                      : 'Sign Up',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
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

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
      prefixIcon: Icon(icon, color: Colors.white),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      enabledBorder: border(Colors.white.withOpacity(0.35)),
      focusedBorder: border(Colors.white),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent),
    );
  }

  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: 1.2),
      );
}