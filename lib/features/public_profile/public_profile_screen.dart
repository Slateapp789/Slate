import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/repositories/slate_repositories.dart';

final publicProfileProvider = FutureProvider.family<PublicProfile?, String>((
  ref,
  handle,
) {
  return ref.watch(profileRepositoryProvider).getPublicProfile(handle);
});

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String handle;
  const PublicProfileScreen({super.key, required this.handle});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedServiceId;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(PublicProfile profile) async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showSnack('Name and phone are required', AppColors.warning);
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .createBookingRequest(
            workspaceId: profile.profile.workspaceId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            serviceId: _selectedServiceId,
            message: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          );
      if (mounted) {
        setState(() {
          _sent = true;
          _sending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        _showSnack('Could not send request. Try again.', AppColors.error);
      }
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(publicProfileProvider(widget.handle));
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: profile.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.green),
        ),
        error: (_, __) => const _ProfileMessage(
          title: 'Could not load profile',
          body: 'Check the link and try again.',
        ),
        data: (data) {
          if (data == null) {
            return const _ProfileMessage(
              title: 'Profile not found',
              body: 'This Slate profile is not available.',
            );
          }
          return _ProfileContent(
            profile: data,
            selectedServiceId: _selectedServiceId,
            nameController: _nameController,
            phoneController: _phoneController,
            messageController: _messageController,
            sending: _sending,
            sent: _sent,
            onServiceChanged: (id) => setState(() => _selectedServiceId = id),
            onSubmit: () => _sendRequest(data),
          );
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final PublicProfile profile;
  final String? selectedServiceId;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController messageController;
  final bool sending;
  final bool sent;
  final ValueChanged<String?> onServiceChanged;
  final VoidCallback onSubmit;

  const _ProfileContent({
    required this.profile,
    required this.selectedServiceId,
    required this.nameController,
    required this.phoneController,
    required this.messageController,
    required this.sending,
    required this.sent,
    required this.onServiceChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        children: [
          _Hero(profile: profile),
          const SizedBox(height: 24),
          if (profile.profile.noticeText?.isNotEmpty == true) ...[
            _Notice(text: profile.profile.noticeText!),
            const SizedBox(height: 16),
          ],
          _Section(
            title: 'Services',
            child: profile.services.isEmpty
                ? const Text(
                    'Services will appear here soon.',
                    style: TextStyle(color: AppColors.t3),
                  )
                : Column(
                    children: profile.services
                        .map(
                          (service) => _ServiceRow(
                            name: service.name,
                            duration: service.durationMins,
                            price: service.price,
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Working hours',
            child: profile.workingHours.isEmpty
                ? const Text(
                    'Hours not published yet.',
                    style: TextStyle(color: AppColors.t3),
                  )
                : Column(
                    children: profile.workingHours.entries
                        .map(
                          (entry) =>
                              _HoursRow(day: entry.key, value: entry.value),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Request a booking',
            child: sent
                ? const _SentState()
                : Column(
                    children: [
                      _ProfileField(
                        controller: nameController,
                        hint: 'Your name',
                      ),
                      const SizedBox(height: 10),
                      _ProfileField(
                        controller: phoneController,
                        hint: 'Phone number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedServiceId,
                        dropdownColor: AppColors.bgCard,
                        decoration: const InputDecoration(hintText: 'Service'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Not sure yet'),
                          ),
                          ...profile.services.map(
                            (service) => DropdownMenuItem<String?>(
                              value: service.id,
                              child: Text(service.name),
                            ),
                          ),
                        ],
                        onChanged: onServiceChanged,
                      ),
                      const SizedBox(height: 10),
                      _ProfileField(
                        controller: messageController,
                        hint: 'Message',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: sending ? null : onSubmit,
                          child: sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Send request'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final PublicProfile profile;
  const _Hero({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              profile.businessName.isEmpty
                  ? 'S'
                  : profile.businessName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          profile.businessName,
          style: const TextStyle(
            color: AppColors.t1,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          profile.profile.bio?.isNotEmpty == true
              ? profile.profile.bio!
              : profile.industry ?? 'Independent service business',
          style: const TextStyle(
            color: AppColors.t2,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(LucideIcons.link, color: AppColors.t3, size: 15),
            const SizedBox(width: 6),
            Text(
              'slate.app/${profile.profile.handle}',
              style: const TextStyle(color: AppColors.t3, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.greenDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.t1, fontSize: 13),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final String name;
  final int duration;
  final double price;
  const _ServiceRow({
    required this.name,
    required this.duration,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.t1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$duration min',
                  style: const TextStyle(color: AppColors.t3, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '£${price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.t1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String day;
  final dynamic value;
  const _HoursRow({required this.day, required this.value});

  @override
  Widget build(BuildContext context) {
    final map = value is Map
        ? Map<String, dynamic>.from(value as Map)
        : <String, dynamic>{};
    final enabled = map['enabled'] as bool? ?? false;
    final label = enabled
        ? '${map['start'] ?? ''} - ${map['end'] ?? ''}'
        : 'Closed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(day, style: const TextStyle(color: AppColors.t2)),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.t1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.t1),
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _SentState extends StatelessWidget {
  const _SentState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 34),
        SizedBox(height: 10),
        Text(
          'Request sent',
          style: TextStyle(
            color: AppColors.t1,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'The business owner will contact you to confirm.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.t3, fontSize: 13),
        ),
      ],
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  final String title;
  final String body;
  const _ProfileMessage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.t1,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.t3),
            ),
          ],
        ),
      ),
    );
  }
}
