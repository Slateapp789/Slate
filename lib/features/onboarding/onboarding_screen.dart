import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'screens/ob_welcome.dart';
import 'screens/ob_profile.dart';
import 'screens/ob_handle.dart';
import 'screens/ob_services.dart';
import 'screens/ob_hours.dart';
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

  void nextPage() {
    setState(() => _currentPage++);
  }

  void prevPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ObWelcome(onNext: nextPage),
      ObProfile(onNext: nextPage, onBack: prevPage),
      ObHandle(onNext: nextPage, onBack: prevPage),
      ObServices(onNext: nextPage, onBack: prevPage),
      ObHours(onNext: nextPage, onBack: prevPage),
      ObRevenueTarget(onNext: nextPage, onBack: prevPage),
      ObFirstBooking(onNext: nextPage, onBack: prevPage),
      const ObComplete(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            if (_currentPage > 0 && _currentPage < screens.length - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: prevPage,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.t2,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _currentPage / (screens.length - 1),
                              backgroundColor: AppColors.bgInteract,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.green,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(child: screens[_currentPage]),
          ],
        ),
      ),
    );
  }
}
