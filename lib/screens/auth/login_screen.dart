import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/config/routes.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/utils/validators.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(email: _emailController.text, password: _passwordController.text);
    if (success && mounted) context.go(AppRoutes.home);
  }

  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reset Password'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Enter your university email to receive a reset link.'),
        const SizedBox(height: 16),
        TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Email', hintText: 'you@fulafia.edu.ng', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (ctrl.text.trim().isEmpty) return;
          final ok = await context.read<AuthProvider>().resetPassword(ctrl.text.trim());
          if (ctx.mounted) Navigator.pop(ctx);
          if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset email sent!')));
        }, child: const Text('Send')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 60),
            Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(child: Text('Welcome Back', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700))),
            const SizedBox(height: 8),
            Center(child: Text('Sign in with your FULafia account', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary))),
            const SizedBox(height: 40),

            // Error
            Consumer<AuthProvider>(builder: (context, auth, _) {
              if (auth.error == null) return const SizedBox.shrink();
              return Container(width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 20), const SizedBox(width: 8),
                  Expanded(child: Text(auth.error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                  GestureDetector(onTap: auth.clearError, child: const Icon(Icons.close, color: AppTheme.error, size: 18)),
                ]));
            }),

            TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'University Email', hintText: 'you@fulafia.edu.ng', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, validator: Validators.email),
            const SizedBox(height: 16),
            TextFormField(controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
              obscureText: _obscurePassword, textInputAction: TextInputAction.done,
              validator: (v) => v == null || v.isEmpty ? 'Password is required' : null, onFieldSubmitted: (_) => _handleLogin()),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _showForgotPassword, child: const Text('Forgot Password?'))),
            const SizedBox(height: 24),
            Consumer<AuthProvider>(builder: (context, auth, _) => PrimaryButton(label: 'Sign In', onPressed: _handleLogin, isLoading: auth.isLoading, icon: Icons.login)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Don\'t have an account? ', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
              GestureDetector(onTap: () => context.go(AppRoutes.register), child: Text('Register', style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 32),
          ])),
        ),
      ),
    );
  }
}
