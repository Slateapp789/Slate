import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';
import '../../shared/widgets/workloop_studio_graphics.dart';
import '../settings/legal_document_screen.dart';
import 'auth_validation.dart';

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
  String? _socialProvider;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithSocial(String provider) async {
    if (_isLoading || _socialProvider != null) return;
    setState(() {
      _socialProvider = provider;
      _error = null;
      _success = null;
    });
    try {
      if (provider == 'apple') {
        await ref.read(authRepositoryProvider).signInWithApple();
        if (mounted) context.go('/');
      } else {
        final opened = await ref
            .read(authRepositoryProvider)
            .signInWithGoogle();
        if (!opened) {
          throw const AuthException('Could not open Google sign in.');
        }
        if (mounted) {
          setState(() {
            _success =
                'Finish signing in with Google, then return to Workloop.';
          });
        }
      }
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code != AuthorizationErrorCode.canceled && mounted) {
        setState(
          () => _error = 'Apple sign in could not be completed. Try again.',
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _error = friendlyAuthErrorMessage(error.message));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Sign in could not be completed. Try again.');
      }
    } finally {
      if (mounted) setState(() => _socialProvider = null);
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final validationError = validateAuthForm(
      email: email,
      password: password,
      intent: switch (_mode) {
        _AuthMode.login => AuthFormIntent.signIn,
        _AuthMode.signup => AuthFormIntent.signUp,
        _AuthMode.reset => AuthFormIntent.resetPassword,
      },
    );
    if (validationError != null) {
      SlateHaptics.warning();
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
        if (mounted) context.go('/');
      } else if (_mode == _AuthMode.signup) {
        final response = await ref
            .read(authRepositoryProvider)
            .signUp(email: email, password: password);
        if (response.session != null) {
          if (mounted) context.go('/');
        } else if (mounted) {
          setState(() {
            _mode = _AuthMode.login;
            _passwordController.clear();
            _success = 'Check your inbox to confirm your email, then sign in.';
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
      TextInput.finishAutofillContext();
      SlateHaptics.success();
    } on AuthException catch (e) {
      SlateHaptics.warning();
      setState(() {
        _error = friendlyAuthErrorMessage(e.message);
      });
    } catch (_) {
      SlateHaptics.warning();
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 700;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.pageX),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (AppSpacing.pageX * 2),
                    ),
                    child: IntrinsicHeight(
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AuthBrandPanel(compact: compactHeight),
                            SizedBox(
                              height: compactHeight
                                  ? AppSpacing.lg
                                  : AppSpacing.xxl,
                            ),
                            AnimatedSwitcher(
                              duration: AppMotion.responsive(
                                context,
                                AppMotion.standard,
                              ),
                              child: Text(
                                _mode.title,
                                key: ValueKey(_mode),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.t1,
                                  letterSpacing: 0,
                                  height: 1.05,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _mode.subtitle,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.t3,
                              ),
                            ),
                            if (_mode == _AuthMode.login) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  key: const ValueKey('auth-first-run-cta'),
                                  onPressed: () => _setMode(_AuthMode.signup),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(44, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                    ),
                                  ),
                                  child: const Text(
                                    'New to Workloop? Create account',
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            _SlateTextField(
                              controller: _emailController,
                              hint: 'Email address',
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: _mode == _AuthMode.reset
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              onSubmitted: _mode == _AuthMode.reset
                                  ? (_) => _submit()
                                  : null,
                            ),
                            if (_mode != _AuthMode.reset) ...[
                              const SizedBox(height: 12),
                              _SlateTextField(
                                controller: _passwordController,
                                hint: 'Password',
                                obscure: true,
                                autofillHints: [
                                  _mode == _AuthMode.signup
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                              ),
                              if (_mode == _AuthMode.signup) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Use $minimumWorkloopPasswordLength+ characters with uppercase, lowercase, a number, and a symbol.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.t3,
                                  ),
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
                              label: _isLoading
                                  ? 'One moment'
                                  : _mode.actionLabel,
                              icon: _isLoading ? null : LucideIcons.arrowRight,
                              onPressed: _isLoading ? null : _submit,
                            ),
                            if (_mode != _AuthMode.reset) ...[
                              const SizedBox(height: AppSpacing.xs),
                              _AuthLegalNotice(
                                onOpen: (document) => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LegalDocumentScreen(
                                      document: document,
                                      backSemanticLabel:
                                          'Back to account access',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const _AuthDivider(),
                              const SizedBox(height: AppSpacing.md),
                              if (!kIsWeb &&
                                  defaultTargetPlatform ==
                                      TargetPlatform.iOS) ...[
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: SignInWithAppleButton(
                                    key: const ValueKey('auth-apple'),
                                    onPressed: _socialProvider == null
                                        ? () => _signInWithSocial('apple')
                                        : () {},
                                    style: SignInWithAppleButtonStyle.white,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(AppRadius.md),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                              WorkloopPrimaryButton(
                                key: const ValueKey('auth-google'),
                                label: _socialProvider == 'google'
                                    ? 'Opening Google'
                                    : 'Continue with Google',
                                secondary: true,
                                onPressed: _socialProvider == null
                                    ? () => _signInWithSocial('google')
                                    : null,
                              ),
                            ],
                            if (_mode == _AuthMode.login) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: () => _setMode(_AuthMode.reset),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(44, 44),
                                  ),
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                key: const ValueKey('auth-mode-toggle'),
                                onPressed: () => _setMode(_mode.toggleMode),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(44, 44),
                                ),
                                child: AnimatedSwitcher(
                                  duration: AppMotion.responsive(
                                    context,
                                    AppMotion.standard,
                                  ),
                                  child: RichText(
                                    key: ValueKey('auth-toggle-$_mode'),
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 14,
                                        color: AppColors.t3,
                                      ),
                                      children: [
                                        TextSpan(text: _mode.togglePrompt),
                                        TextSpan(
                                          text: _mode.toggleAction,
                                          style: TextStyle(
                                            color: AppColors.green,
                                            fontWeight: FontWeight.w600,
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.t3,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _AuthLegalNotice extends StatelessWidget {
  final ValueChanged<WorkloopLegalDocument> onOpen;

  const _AuthLegalNotice({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
    return Semantics(
      container: true,
      child: Column(
        children: [
          const Text(
            'By continuing, you agree to Workloop’s terms and acknowledge its privacy policy.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.t3, fontSize: 11, height: 1.35),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xxs,
            children: [
              TextButton(
                key: const ValueKey('auth-terms-link'),
                onPressed: () => onOpen(WorkloopLegalDocument.terms),
                style: linkStyle,
                child: const Text('Terms of use'),
              ),
              const Text('and', style: TextStyle(color: AppColors.t3)),
              TextButton(
                key: const ValueKey('auth-privacy-link'),
                onPressed: () => onOpen(WorkloopLegalDocument.privacy),
                style: linkStyle,
                child: const Text('Privacy policy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  final bool compact;

  const _AuthBrandPanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      // The panel is a graphic brand asset; operational form copy below keeps
      // the user's full text scale.
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        height: compact ? 246 : 258,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tokens.accentStrong, tokens.primaryAction],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: tokens.accentStrong.withValues(alpha: 0.28),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: 28,
              child: WorkloopStudioLoopMark(
                size: compact ? 120 : 138,
                color: tokens.onAccent,
                secondaryColor: AppColors.modClients,
              ),
            ),
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WORKLOOP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Your work,\nin motion.',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Client · Booking · Work · Payment',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlateTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _SlateTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<_SlateTextField> createState() => _SlateTextFieldState();
}

class _SlateTextFieldState extends State<_SlateTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autocorrect: !widget.obscure,
      enableSuggestions: !widget.obscure,
      style: const TextStyle(color: AppColors.t1, fontSize: 15),
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _obscured ? 'Show password' : 'Hide password',
                onPressed: () {
                  SlateHaptics.selection();
                  setState(() => _obscured = !_obscured);
                },
                icon: Icon(
                  _obscured ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: AppColors.t3,
                  size: 19,
                ),
              )
            : null,
      ),
    );
  }
}
