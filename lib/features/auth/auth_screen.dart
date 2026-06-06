import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMode _mode = _AuthMode.login;
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final validationError = _validate(email: email, password: password);
    if (validationError != null) {
      setState(() {
        _error = validationError;
        _success = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      if (_mode == _AuthMode.login) {
        await ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password);
      } else if (_mode == _AuthMode.signup) {
        await ref
            .read(authRepositoryProvider)
            .signUp(email: email, password: password);
        if (mounted) {
          setState(() {
            _success =
                'Account created. If email confirmation is enabled, check your inbox before signing in.';
          });
        }
      } else {
        await ref.read(authRepositoryProvider).sendPasswordReset(email);
        if (mounted) {
          setState(() {
            _success = 'Password reset email sent. Check your inbox.';
          });
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _error = _friendlyAuthError(e);
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validate({required String email, required String password}) {
    if (email.isEmpty) return 'Enter your email address.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    if (_mode == _AuthMode.reset) return null;
    if (password.isEmpty) return 'Enter your password.';
    if (_mode == _AuthMode.signup && password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'Wrong email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (message.contains('already registered') ||
        message.contains('already been registered')) {
      return 'An account already exists for that email. Try signing in.';
    }
    if (message.contains('password') && message.contains('weak')) {
      return 'Choose a stronger password.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return error.message.isEmpty ? 'Authentication failed.' : error.message;
  }

  void _setMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _success = null;
      if (mode == _AuthMode.reset) _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageX),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.t1.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.t1.withValues(alpha: 0.09),
                  ),
                ),
                child: const Icon(
                  LucideIcons.layers,
                  color: AppColors.slateLight,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSwitcher(
                duration: AppMotion.standard,
                child: Text(
                  _mode.title,
                  key: ValueKey(_mode),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.t1,
                    letterSpacing: 0,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _mode.subtitle,
                style: TextStyle(fontSize: 15, color: AppColors.t3),
              ),
              const Spacer(),
              _SlateTextField(
                controller: _emailController,
                hint: 'Email address',
                keyboardType: TextInputType.emailAddress,
              ),
              if (_mode != _AuthMode.reset) ...[
                const SizedBox(height: 12),
                _SlateTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  obscure: true,
                ),
                if (_mode == _AuthMode.signup) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Use at least 8 characters.',
                    style: TextStyle(fontSize: 12, color: AppColors.t3),
                  ),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                SlateErrorState(message: _error!),
              ],
              if (_success != null) ...[
                const SizedBox(height: 12),
                _AuthSuccessState(message: _success!),
              ],
              const SizedBox(height: 16),
              SlateButton(
                label: _isLoading ? 'One moment' : _mode.actionLabel,
                icon: _isLoading ? null : LucideIcons.arrowRight,
                onPressed: _isLoading ? null : _submit,
              ),
              if (_mode == _AuthMode.login) ...[
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () => _setMode(_AuthMode.reset),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => _setMode(_mode.toggleMode),
                  child: AnimatedSwitcher(
                    duration: AppMotion.standard,
                    child: RichText(
                      key: ValueKey('auth-toggle-$_mode'),
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: AppColors.t3),
                        children: [
                          TextSpan(text: _mode.togglePrompt),
                          TextSpan(
                            text: _mode.toggleAction,
                            style: TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AuthMode {
  login,
  signup,
  reset;

  String get title => switch (this) {
    _AuthMode.login => 'Welcome back.',
    _AuthMode.signup => 'Create your account.',
    _AuthMode.reset => 'Reset password.',
  };

  String get subtitle => switch (this) {
    _AuthMode.login => 'Sign in to your workspace.',
    _AuthMode.signup => 'Start running your business from one app.',
    _AuthMode.reset => 'Enter your email and we will send a reset link.',
  };

  String get actionLabel => switch (this) {
    _AuthMode.login => 'Sign in',
    _AuthMode.signup => 'Create account',
    _AuthMode.reset => 'Send reset email',
  };

  _AuthMode get toggleMode => switch (this) {
    _AuthMode.login => _AuthMode.signup,
    _AuthMode.signup => _AuthMode.login,
    _AuthMode.reset => _AuthMode.login,
  };

  String get togglePrompt => switch (this) {
    _AuthMode.login => "Don't have an account? ",
    _AuthMode.signup => 'Already have an account? ',
    _AuthMode.reset => 'Remembered it? ',
  };

  String get toggleAction => switch (this) {
    _AuthMode.login => 'Sign up',
    _AuthMode.signup => 'Sign in',
    _AuthMode.reset => 'Sign in',
  };
}

class _AuthSuccessState extends StatelessWidget {
  final String message;

  const _AuthSuccessState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.28)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SlateTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;

  const _SlateTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.t1, fontSize: 15),
      decoration: InputDecoration(hintText: hint),
    );
  }
}
