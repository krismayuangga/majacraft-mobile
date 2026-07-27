import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Warna tema — sama dengan website MajaCraft
  static const _bg = Color(0xFF1A1712);
  static const _card = Color(0xFF242018);
  static const _gold = Color(0xFFBF8E0A);
  static const _goldLight = Color(0xFFD4A020);
  static const _border = Color(0xFF3A3222);
  static const _textMuted = Color(0xFF9A8C6A);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white70,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Logo + Brand
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo-maja-splash.png',
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'MAJA CRAFT',
                          style: TextStyle(
                            color: _goldLight,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Heading
                    const Text(
                      'Selamat Datang',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Masuk ke MajaCraft',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textMuted, fontSize: 14),
                    ),

                    const SizedBox(height: 28),

                    // Google Sign-In button
                    OutlinedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _card,
                        side: const BorderSide(color: _border, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google G logo
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              'G',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Masuk dengan Google',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider ATAU
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: _border, thickness: 1),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'ATAU',
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: _border, thickness: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // EMAIL label
                    const Text(
                      'EMAIL',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      enabled: !authProvider.isLoading,
                      decoration: InputDecoration(
                        hintText: 'nama@email.com',
                        hintStyle: const TextStyle(
                          color: _textMuted,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: _textMuted,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: _card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _gold,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.red.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email harus diisi';
                        if (!v.contains('@')) return 'Email tidak valid';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // PASSWORD label + Lupa password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Lupa password?',
                            style: TextStyle(color: _goldLight, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      enabled: !authProvider.isLoading,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(
                          color: _textMuted,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: _textMuted,
                          size: 18,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _textMuted,
                            size: 18,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        filled: true,
                        fillColor: _card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _gold,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.red.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Password harus diisi';
                        if (v.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Masuk button — gold gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4A020), Color(0xFF8B6000)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4A020).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    const Divider(color: _border, thickness: 1),

                    const SizedBox(height: 16),

                    // Daftar link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(color: _textMuted, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: authProvider.isLoading
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                          child: const Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                              color: _goldLight,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

