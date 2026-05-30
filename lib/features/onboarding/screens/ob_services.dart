import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/onboarding_provider.dart';

const Map<String, List<Map<String, dynamic>>> industryServices = {
  'Hair & Barbering': [
    {'name': 'Haircut', 'duration': 30, 'price': 25.0},
    {'name': 'Haircut & Beard', 'duration': 45, 'price': 35.0},
    {'name': 'Beard Trim', 'duration': 20, 'price': 15.0},
    {'name': 'Skin Fade', 'duration': 30, 'price': 28.0},
  ],
  'Beauty & Aesthetics': [
    {'name': 'Gel Nails', 'duration': 60, 'price': 35.0},
    {'name': 'Lash Extensions', 'duration': 90, 'price': 55.0},
    {'name': 'Eyebrow Threading', 'duration': 20, 'price': 12.0},
    {'name': 'Facial', 'duration': 60, 'price': 45.0},
  ],
  'Health & Fitness': [
    {'name': '1-to-1 PT Session', 'duration': 60, 'price': 50.0},
    {'name': 'Online Coaching Session', 'duration': 45, 'price': 40.0},
    {'name': 'Group Class', 'duration': 45, 'price': 15.0},
  ],
  'Massage & Therapy': [
    {'name': 'Swedish Massage', 'duration': 60, 'price': 55.0},
    {'name': 'Deep Tissue Massage', 'duration': 60, 'price': 65.0},
    {'name': 'Sports Massage', 'duration': 45, 'price': 50.0},
  ],
  'Cleaning & Home Services': [
    {'name': 'Standard Clean', 'duration': 120, 'price': 60.0},
    {'name': 'Deep Clean', 'duration': 180, 'price': 120.0},
    {'name': 'End of Tenancy Clean', 'duration': 240, 'price': 180.0},
  ],
  'Mobile Trades': [
    {'name': 'Callout & Assessment', 'duration': 60, 'price': 60.0},
    {'name': 'Standard Booking', 'duration': 120, 'price': 120.0},
  ],
  'Tutoring & Coaching': [
    {'name': '1-to-1 Session', 'duration': 60, 'price': 45.0},
    {'name': 'Online Session', 'duration': 60, 'price': 40.0},
    {'name': 'Group Session', 'duration': 90, 'price': 20.0},
  ],
  'Photography': [
    {'name': 'Portrait Session', 'duration': 60, 'price': 150.0},
    {'name': 'Event Photography', 'duration': 240, 'price': 400.0},
  ],
  'Other': [
    {'name': 'Consultation', 'duration': 30, 'price': 30.0},
    {'name': '1 Hour Session', 'duration': 60, 'price': 60.0},
  ],
};

class ObServices extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const ObServices({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<ObServices> createState() => _ObServicesState();
}

class _ObServicesState extends ConsumerState<ObServices> {
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    final industry = ref.read(onboardingProvider).industry;
    _services = List<Map<String, dynamic>>.from(
      industryServices[industry] ?? industryServices['Other']!,
    );
  }

  void _removeService(int index) {
    setState(() => _services.removeAt(index));
  }

  void _addService() {
    setState(() {
      _services.add({'name': 'New Service', 'duration': 60, 'price': 50.0});
    });
  }

  void _continue() {
    ref.read(onboardingProvider.notifier).setServices(_services);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Your services.',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.t1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve added some defaults based on what you do. Edit, remove, or add your own.',
            style: TextStyle(fontSize: 15, color: AppColors.t3, height: 1.5),
          ),
          const SizedBox(height: 28),
          ..._services.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.t1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s['duration']} min  ·  £${s['price'].toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 13, color: AppColors.t3),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _removeService(i),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.errorDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.error,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Add service button
          GestureDetector(
            onTap: _addService,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: AppColors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add a service',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _services.isNotEmpty ? _continue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                disabledBackgroundColor: AppColors.bgInteract,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.t3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: widget.onNext,
              child: Text(
                'Skip — add services later',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.t3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
