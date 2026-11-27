import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme/app_theme.dart';

enum AuthMode { signIn, signUp, forgot }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialMode = AuthMode.signIn});

  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AuthMode _mode = widget.initialMode;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (_mode != AuthMode.signUp) return null;
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid Nigerian phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (_mode == AuthMode.forgot) return null;
    if ((value ?? '').length < 8) return 'Use at least 8 characters';
    return null;
  }

  String _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) return '+234${digits.substring(1)}';
    if (digits.startsWith('234')) return '+$digits';
    return digits.isEmpty ? '' : '+$digits';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    setState(() => _busy = true);
    try {
      switch (_mode) {
        case AuthMode.signIn:
          await auth.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
          if (mounted) Navigator.of(context).pop(true);
          break;
        case AuthMode.signUp:
          await auth.signUp(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _nameController.text,
            phone: _normalizePhone(_phoneController.text),
          );
          if (mounted) Navigator.of(context).pop(true);
          break;
        case AuthMode.forgot:
          await auth.resetPassword(_emailController.text);
          if (!mounted) return;
          setState(() => _mode = AuthMode.signIn);
          _showMessage('Password reset link sent. Check your email inbox.');
          break;
      }
    } on AuthFailure catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _mode == AuthMode.signUp;
    final isForgot = _mode == AuthMode.forgot;

    return Scaffold(
      appBar: AppBar(title: const Text('Your AMAL account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [AmalColors.navyDeep, AmalColors.navy],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AmalColors.goldSoft,
                      size: 30,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isForgot
                          ? 'Reset your password'
                          : isSignUp
                          ? 'Create your AMAL account'
                          : 'Welcome back to AMAL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isForgot
                          ? 'We will email you a secure reset link.'
                          : 'Track orders, save addresses and check out faster.',
                      style: const TextStyle(
                        color: AmalColors.goldSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isForgot)
                SegmentedButton<AuthMode>(
                  segments: const [
                    ButtonSegment(
                      value: AuthMode.signIn,
                      label: Text('Sign in'),
                      icon: Icon(Icons.login),
                    ),
                    ButtonSegment(
                      value: AuthMode.signUp,
                      label: Text('Create'),
                      icon: Icon(Icons.person_add_alt),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (value) {
                    setState(() => _mode = value.first);
                  },
                ),
              const SizedBox(height: 20),
              if (isSignUp) ...[
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => _required(value, 'Full name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '0801 234 5678',
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: _validateEmail,
              ),
              if (!isForgot) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isForgot
                            ? 'Send reset link'
                            : isSignUp
                            ? 'Create account'
                            : 'Sign in',
                      ),
              ),
              const SizedBox(height: 12),
              if (!isForgot)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _mode = AuthMode.forgot),
                  child: const Text('Forgot password?'),
                ),
              if (isForgot)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _mode = AuthMode.signIn),
                  child: const Text('Back to sign in'),
                ),
              const SizedBox(height: 8),
              const Text(
                'By continuing you agree to shop with AMAL — Ahmad Market Link. '
                'Your account is protected by Supabase Auth.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AmalColors.muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
