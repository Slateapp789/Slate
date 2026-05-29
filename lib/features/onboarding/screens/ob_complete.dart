import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/onboarding_provider.dart';
import '../../../shared/repositories/slate_repositories.dart';
import '../../../main.dart';

class ObComplete extends ConsumerStatefulWidget {
  const ObComplete({super.key});

  @override
  ConsumerState<ObComplete> createState() => _ObCompleteState();
}

class _ObCompleteState extends ConsumerState<ObComplete>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<double>(
      begin: 30,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _saveWorkspace();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveWorkspace() async {
    setState(() => _saving = true);
    try {
      final onboarding = ref.read(onboardingProvider);
      await ref
          .read(onboardingRepositoryProvider)
          .complete(
            businessName: onboarding.businessName,
            industry: onboarding.industry,
            handle: onboarding.handle,
            services: onboarding.services,
            workingHours: onboarding.workingHours,
            revenueTarget: onboarding.revenueTarget,
            firstBooking: onboarding.firstBooking,
          );
    } catch (e, stack) {
      debugPrint('Error saving workspace: $e');
      debugPrint('Stack: $stack');
    } finally {
      setState(() => _saving = false);
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeIn.value,
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            const Text(
              'Your workspace\nis ready.',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.t1,
                letterSpacing: -1.2,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 20),
            _SummaryRow(
              icon: Icons.business_rounded,
              label: onboarding.businessName,
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              icon: Icons.link_rounded,
              label: 'slate.app/${onboarding.handle}',
              color: AppColors.green,
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              icon: Icons.design_services_rounded,
              label: '${onboarding.services.length} services configured',
            ),
            if (onboarding.revenueTarget > 0) ...[
              const SizedBox(height: 10),
              _SummaryRow(
                icon: Icons.track_changes_rounded,
                label:
                    '£${onboarding.revenueTarget.toStringAsFixed(0)} monthly target set',
                color: AppColors.green,
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _goToDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  disabledBackgroundColor: AppColors.bgInteract,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Go to my Dashboard',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _SummaryRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.t2, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.t1,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 18,
          ),
        ],
      ),
    );
  }
}
