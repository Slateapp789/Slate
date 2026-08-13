import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/onboarding_provider.dart';
import '../../../shared/widgets/slate_ui.dart';

const List<String> industries = [
  'Hair & Barbering',
  'Beauty & Aesthetics',
  'Health & Fitness',
  'Massage & Therapy',
  'Cleaning & Home Services',
  'Mobile Trades',
  'Tutoring & Coaching',
  'Photography',
  'Other',
];

class ObProfile extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const ObProfile({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<ObProfile> createState() => _ObProfileState();
}

class _ObProfileState extends ConsumerState<ObProfile> {
  final _firstNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  String? _selectedIndustry;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider);
    _firstNameController.text = draft.firstName;
    _businessNameController.text = draft.businessName;
    _selectedIndustry = draft.industry.isEmpty ? null : draft.industry;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _firstNameController.text.trim().isNotEmpty &&
      _businessNameController.text.trim().isNotEmpty &&
      _selectedIndustry != null;

  void _continue() {
    if (!_canContinue) return;
    ref
        .read(onboardingProvider.notifier)
        .setName(
          _firstNameController.text.trim(),
          _businessNameController.text.trim(),
        );
    ref.read(onboardingProvider.notifier).setIndustry(_selectedIndustry!);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pageX),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Tell us about\nyourself.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.t1,
              letterSpacing: 0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how you\'ll appear to clients.',
            style: TextStyle(fontSize: 15, color: AppColors.t3),
          ),
          const SizedBox(height: 32),
          _label('Your name'),
          const SizedBox(height: 8),
          _field(
            controller: _firstNameController,
            hint: 'Alex',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          _label('Business name'),
          const SizedBox(height: 8),
          _field(
            controller: _businessNameController,
            hint: 'Alex\'s Barbershop',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          _label('What do you do?'),
          const SizedBox(height: 8),
          WorkloopPickerField<String>(
            value: _selectedIndustry,
            title: 'Choose your industry',
            hint: 'Select your industry',
            searchHint: 'Search industries',
            options: industries
                .map(
                  (industry) =>
                      WorkloopPickerOption(value: industry, label: industry),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedIndustry = value),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _canContinue ? _continue : null,
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.t2,
        letterSpacing: 0,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.t1, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.t3),
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.green, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
    );
  }
}
