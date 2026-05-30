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
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        await ref
            .read(authRepositoryProvider)
            .signIn(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
      } else {
        await ref
            .read(authRepositoryProvider)
            .signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                  _isLogin ? 'Welcome back.' : 'Create your account.',
                  key: ValueKey(_isLogin),
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
                _isLogin
                    ? 'Sign in to your workspace.'
                    : 'Start running your business from one app.',
                style: TextStyle(fontSize: 15, color: AppColors.t3),
              ),
              const Spacer(),
              _SlateTextField(
                controller: _emailController,
                hint: 'Email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _SlateTextField(
                controller: _passwordController,
                hint: 'Password',
                obscure: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                SlateErrorState(message: _error!),
              ],
              const SizedBox(height: 16),
              SlateButton(
                label: _isLoading
                    ? 'One moment'
                    : _isLogin
                    ? 'Sign in'
                    : 'Create account',
                icon: _isLoading ? null : LucideIcons.arrowRight,
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isLogin = !_isLogin;
                    _error = null;
                  }),
                  child: AnimatedSwitcher(
                    duration: AppMotion.standard,
                    child: RichText(
                      key: ValueKey('auth-toggle-$_isLogin'),
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: AppColors.t3),
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? "Don't have an account? "
                                : 'Already have an account? ',
                          ),
                          TextSpan(
                            text: _isLogin ? 'Sign up' : 'Sign in',
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
