import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/config/constants.dart';
import 'package:lost_and_found/config/routes.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/utils/validators.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _matricController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedFaculty;
  String? _selectedDepartment;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _matricController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFaculty == null || _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your faculty and department')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      matricNumber: _matricController.text.trim().toUpperCase(),
      faculty: _selectedFaculty!,
      department: _selectedDepartment!,
      phoneNumber: _phoneController.text.trim(),
    );

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Header
                Text('Create Account', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Join the FULafia Lost & Found community', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 24),

                // Error display
                Consumer<AuthProvider>(builder: (context, auth, _) {
                  if (auth.error == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(auth.error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                    ]),
                  );
                }),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outlined)),
                  textInputAction: TextInputAction.next,
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'University Email', hintText: 'you@fulafia.edu.ng', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),

                // Matric Number
                TextFormField(
                  controller: _matricController,
                  decoration: const InputDecoration(labelText: 'Matriculation Number', hintText: '20/108002/6CEP', prefixIcon: Icon(Icons.badge_outlined)),
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  validator: Validators.matricNumber,
                ),
                const SizedBox(height: 14),

                // Faculty Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedFaculty,
                  decoration: const InputDecoration(labelText: 'Faculty', prefixIcon: Icon(Icons.school_outlined)),
                  isExpanded: true,
                  items: AppConstants.faculties.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (val) => setState(() { _selectedFaculty = val; _selectedDepartment = null; }),
                  validator: (v) => Validators.dropdown(v, 'faculty'),
                ),
                const SizedBox(height: 14),

                // Department Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedDepartment,
                  decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.account_balance_outlined)),
                  isExpanded: true,
                  items: (_selectedFaculty != null ? AppConstants.departmentsByFaculty[_selectedFaculty] ?? [] : <String>[])
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (val) => setState(() => _selectedDepartment = val),
                  validator: (v) => Validators.dropdown(v, 'department'),
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number', hintText: '08012345678', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phoneNumber,
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                ),
                const SizedBox(height: 14),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                  onFieldSubmitted: (_) => _handleRegister(),
                ),
                const SizedBox(height: 28),

                // Register Button
                Consumer<AuthProvider>(builder: (context, auth, _) {
                  return PrimaryButton(label: 'Create Account', onPressed: _handleRegister, isLoading: auth.isLoading, icon: Icons.person_add);
                }),
                const SizedBox(height: 20),

                // Login link
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already have an account? ', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: Text('Sign In', style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
