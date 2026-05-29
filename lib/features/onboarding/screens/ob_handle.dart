import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/onboarding_provider.dart';

class ObHandle extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const ObHandle({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<ObHandle> createState() => _ObHandleState();
}

class _ObHandleState extends ConsumerState<ObHandle> {
  final _handleController = TextEditingController();
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Pre-fill from business name
    final state = ref.read(onboardingProvider);
    final suggested = state.businessName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    _handleController.text = suggested;
  }

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _handleController.text.trim().length >= 3 && _error.isEmpty;

  void _validate(String value) {
    final clean = value.toLowerCase().trim();
    if (clean.length < 3) {
      setState(() => _error = 'Must be at least 3 characters');
    } else if (!RegExp(r'^[a-z0-9-]+$').hasMatch(clean)) {
      setState(() => _error = 'Only letters, numbers and hyphens');
    } else {
      setState(() => _error = '');
    }
  }

  void _continue() {
    if (!_canContinue) return;
    ref
        .read(onboardingProvider.notifier)
        .setHandle(_handleController.text.trim().toLowerCase());
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final handle = _handleController.text.trim().toLowerCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Your booking page.',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.t1,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clients can find and book you at this link. You can share it anywhere.',
            style: TextStyle(fontSize: 15, color: AppColors.t3, height: 1.5),
          ),
          const SizedBox(height: 32),

          // URL preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your booking link',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.t3,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text: 'slate.app/',
                        style: TextStyle(color: AppColors.t3),
                      ),
                      TextSpan(
                        text: handle.isEmpty ? 'yourname' : handle,
                        style: TextStyle(
                          color: handle.isEmpty
                              ? AppColors.t3
                              : AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Handle input
          Text(
            'Choose your handle',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.t2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _handleController,
            onChanged: (v) {
              _validate(v);
              setState(() {});
            },
            style: TextStyle(color: AppColors.t1, fontSize: 15),
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              hintText: 'yourname',
              hintStyle: TextStyle(color: AppColors.t3),
              prefixText: 'slate.app/',
              prefixStyle: TextStyle(color: AppColors.t3, fontSize: 15),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _error,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
          if (_error.isEmpty && handle.length >= 3) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Available',
                  style: TextStyle(color: AppColors.success, fontSize: 13),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Letters, numbers and hyphens only. Min 3 characters.',
            style: TextStyle(fontSize: 12, color: AppColors.t3),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _canContinue ? _continue : null,
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
                'Looks good',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
