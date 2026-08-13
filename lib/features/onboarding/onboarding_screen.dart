import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/onboarding_provider.dart';
import '../../shared/widgets/slate_ui.dart';
import 'screens/ob_welcome.dart';
import 'screens/ob_profile.dart';
import 'screens/ob_handle.dart';
import 'screens/ob_services.dart';
import 'screens/ob_hours.dart';
import 'screens/ob_preferences.dart';
import 'screens/ob_revenue_target.dart';
import 'screens/ob_first_booking.dart';
import 'screens/ob_complete.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentPage = 0;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    await ref.read(onboardingProvider.notifier).restore();
    if (!mounted) return;
    final restoredStep = ref.read(onboardingProvider).currentStep;
    setState(() {
      _currentPage = restoredStep.clamp(0, 8);
      _restoring = false;
    });
  }

  void nextPage() {
    final next = (_currentPage + 1).clamp(0, 8);
    ref.read(onboardingProvider.notifier).setStep(next);
    setState(() => _currentPage = next);
  }

  void prevPage() {
    if (_currentPage <= 0) return;
    final previous = _currentPage - 1;
    ref.read(onboardingProvider.notifier).setStep(previous);
    setState(() => _currentPage = previous);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ObWelcome(onNext: nextPage),
      ObProfile(onNext: nextPage, onBack: prevPage),
      ObHandle(onNext: nextPage, onBack: prevPage),
      ObServices(onNext: nextPage, onBack: prevPage),
      ObHours(onNext: nextPage, onBack: prevPage),
      ObPreferences(onNext: nextPage, onBack: prevPage),
      ObRevenueTarget(onNext: nextPage, onBack: prevPage),
      ObFirstBooking(onNext: nextPage, onBack: prevPage),
      const ObComplete(),
    ];

    if (_restoring) {
      return const WorkloopPage(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: Column(
              children: [
                if (_currentPage > 0 && _currentPage < screens.length - 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageX,
                      AppSpacing.screenTop,
                      AppSpacing.pageX,
                      0,
                    ),
                    child: Row(
                      children: [
                        WorkloopIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          semanticLabel: 'Previous onboarding step',
                          onTap: prevPage,
                          size: 38,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadius.capsule,
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                end: _currentPage / (screens.length - 1),
                              ),
                              duration: AppMotion.responsive(
                                context,
                                AppMotion.deliberate,
                              ),
                              curve: AppMotion.curve,
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: AppColors.t1.withValues(
                                    alpha: 0.06,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.accentPrimaryStrong,
                                      ),
                                  minHeight: 5,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: screens[_currentPage]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
