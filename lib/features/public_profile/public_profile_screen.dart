import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/workloop_app_info.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/utils/currency_format.dart';
import '../../shared/utils/workflow_idempotency.dart';
import '../../shared/utils/working_hours.dart';
import '../../shared/widgets/slate_ui.dart';

final publicProfileProvider = FutureProvider.family<PublicProfile?, String>((
  ref,
  handle,
) {
  return ref.watch(profileRepositoryProvider).getPublicProfile(handle);
});

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String handle;
  final PublicProfile? previewProfile;

  const PublicProfileScreen({
    super.key,
    required this.handle,
    this.previewProfile,
  });

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _preferredTimeController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedServiceId;
  String? _nameError;
  String? _phoneError;
  String? _submitError;
  bool _sending = false;
  bool _sent = false;
  final String _requestToken = createPublicRequestToken();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _preferredTimeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(PublicProfile profile) async {
    if (_sending || _sent) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final nameError = name.isEmpty ? 'Add your name' : null;
    final phoneError = phone.isEmpty
        ? 'Add a phone number'
        : phoneDigits.length < 7
        ? 'Add a valid phone number'
        : null;
    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _submitError = null;
    });
    if (nameError != null || phoneError != null) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .createBookingRequest(
            handle: profile.profile.handle,
            name: name,
            phone: phone,
            requestToken: _requestToken,
            serviceId: _selectedServiceId,
            preferredTimeText: _preferredTimeController.text.trim().isEmpty
                ? null
                : _preferredTimeController.text.trim(),
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
        setState(() {
          _sending = false;
          _submitError =
              'Your request was not sent. Check your connection and try again.';
        });
      }
    }
  }

  void _clearNameError(String _) {
    if (_nameError != null) setState(() => _nameError = null);
  }

  void _clearPhoneError(String _) {
    if (_phoneError != null) setState(() => _phoneError = null);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PublicProfile?> profile = widget.previewProfile == null
        ? ref.watch(publicProfileProvider(widget.handle))
        : AsyncValue.data(widget.previewProfile);
    final canGoBack = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          Positioned.fill(
            child: profile.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              ),
              error: (_, _) => _ProfileMessage(
                title: 'Could not load profile',
                body: 'Check the link and try again.',
                onRetry: () =>
                    ref.invalidate(publicProfileProvider(widget.handle)),
              ),
              data: (data) {
                if (data == null) {
                  return const _ProfileMessage(
                    title: 'Profile not found',
                    body: 'This Workloop profile is not available.',
                  );
                }
                return _ProfileContent(
                  profile: data,
                  selectedServiceId: _selectedServiceId,
                  nameController: _nameController,
                  phoneController: _phoneController,
                  preferredTimeController: _preferredTimeController,
                  messageController: _messageController,
                  sending: _sending,
                  sent: _sent,
                  nameError: _nameError,
                  phoneError: _phoneError,
                  submitError: _submitError,
                  topInset: canGoBack ? 84 : 28,
                  onNameChanged: _clearNameError,
                  onPhoneChanged: _clearPhoneError,
                  onServiceChanged: (id) =>
                      setState(() => _selectedServiceId = id),
                  onPreferredTimePicked: (value) =>
                      setState(() => _preferredTimeController.text = value),
                  onSubmit: () => _sendRequest(data),
                );
              },
            ),
          ),
          if (canGoBack)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.pageX,
                  top: AppSpacing.sm,
                ),
                child: WorkloopIconButton(
                  icon: LucideIcons.chevronLeft,
                  semanticLabel: 'Back to profile',
                  backgroundColor: AppColors.bgCard.withValues(alpha: 0.94),
                  onTap: () => workloopGoBack(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final PublicProfile profile;
  final String? selectedServiceId;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController preferredTimeController;
  final TextEditingController messageController;
  final bool sending;
  final bool sent;
  final String? nameError;
  final String? phoneError;
  final String? submitError;
  final double topInset;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String?> onServiceChanged;
  final ValueChanged<String> onPreferredTimePicked;
  final VoidCallback onSubmit;

  const _ProfileContent({
    required this.profile,
    required this.selectedServiceId,
    required this.nameController,
    required this.phoneController,
    required this.preferredTimeController,
    required this.messageController,
    required this.sending,
    required this.sent,
    required this.nameError,
    required this.phoneError,
    required this.submitError,
    required this.topInset,
    required this.onNameChanged,
    required this.onPhoneChanged,
    required this.onServiceChanged,
    required this.onPreferredTimePicked,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bookingClosed = profile.profile.bookingMode != 'manual';
    final bookingSectionKey = GlobalKey();
    final enabledBadges = <_ProfileBadgeData>[
      if (profile.profile.reviewsEnabled)
        const _ProfileBadgeData(LucideIcons.star, 'Reviews enabled'),
      if (profile.profile.galleryEnabled)
        const _ProfileBadgeData(
          LucideIcons.galleryThumbnails,
          'Gallery enabled',
        ),
    ];

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, topInset, 20, 40),
        children: [
          _Hero(profile: profile),
          if (!bookingClosed && !sent) ...[
            const SizedBox(height: AppSpacing.lg),
            WorkloopPrimaryButton(
              label: 'Request a booking',
              icon: LucideIcons.calendarPlus,
              onPressed: () {
                final target = bookingSectionKey.currentContext;
                if (target == null) return;
                Scrollable.ensureVisible(
                  target,
                  duration: AppMotion.responsive(context, AppMotion.standard),
                  curve: AppMotion.curve,
                  alignment: 0.06,
                );
              },
            ),
          ],
          const SizedBox(height: 24),
          if (enabledBadges.isNotEmpty) ...[
            _ProfileBadges(items: enabledBadges),
            const SizedBox(height: 16),
          ],
          if (profile.profile.isNoticeActive()) ...[
            _Notice(text: profile.profile.noticeText!),
            const SizedBox(height: 16),
          ],
          if (profile.profile.galleryEnabled &&
              profile.profile.galleryImageUrls.isNotEmpty) ...[
            _Section(
              title: 'Gallery',
              child: _GalleryGrid(urls: profile.profile.galleryImageUrls),
            ),
            const SizedBox(height: 16),
          ],
          if (profile.profile.reviewsEnabled &&
              profile.profile.reviewQuotes.isNotEmpty) ...[
            _Section(
              title: 'Reviews',
              child: _ReviewsList(quotes: profile.profile.reviewQuotes),
            ),
            const SizedBox(height: 16),
          ],
          _Section(
            title: 'Services',
            child: profile.services.isEmpty
                ? const Text(
                    'No services are currently listed.',
                    style: TextStyle(color: AppColors.t3),
                  )
                : Column(
                    children: profile.services
                        .map(
                          (service) => _ServiceRow(
                            name: service.name,
                            duration: service.durationMins,
                            price: service.price,
                            description: service.description,
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
                    children: workingHourDays.map((day) {
                      final shortDay = shortToLongDay.entries
                          .firstWhere((entry) => entry.value == day)
                          .key;
                      return _HoursRow(
                        day: day,
                        value:
                            profile.workingHours[day] ??
                            profile.workingHours[shortDay],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            key: bookingSectionKey,
            child: _Section(
              title: 'Request a booking',
              child: bookingClosed
                  ? const _ClosedBookingState()
                  : sent
                  ? const _SentState()
                  : Column(
                      children: [
                        _ProfileField(
                          controller: nameController,
                          label: 'Name',
                          hint: 'Your name',
                          errorText: nameError,
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                          onChanged: onNameChanged,
                          maxLength: 80,
                        ),
                        const SizedBox(height: 10),
                        _ProfileField(
                          controller: phoneController,
                          label: 'Phone',
                          hint: 'Phone number',
                          errorText: phoneError,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          textInputAction: TextInputAction.next,
                          onChanged: onPhoneChanged,
                          keyboardType: TextInputType.phone,
                          maxLength: 32,
                        ),
                        const SizedBox(height: 10),
                        WorkloopPickerField<String?>(
                          value: selectedServiceId,
                          title: 'Choose a service',
                          hint: 'Service',
                          searchHint: 'Search services',
                          options: [
                            const WorkloopPickerOption<String?>(
                              value: null,
                              label: 'Not sure yet',
                            ),
                            ...profile.services.map(
                              (service) => WorkloopPickerOption<String?>(
                                value: service.id,
                                label: service.name,
                              ),
                            ),
                          ],
                          onChanged: onServiceChanged,
                        ),
                        const SizedBox(height: 10),
                        _ProfileField(
                          controller: preferredTimeController,
                          label: 'Preferred time',
                          hint: 'Preferred day or time',
                          maxLength: 160,
                        ),
                        const SizedBox(height: 8),
                        _PreferredTimeShortcuts(onPick: onPreferredTimePicked),
                        const SizedBox(height: 10),
                        _ProfileField(
                          controller: messageController,
                          label: 'Message',
                          hint: 'Anything we should know?',
                          maxLines: 3,
                          maxLength: 1000,
                        ),
                        if (submitError != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Semantics(
                            liveRegion: true,
                            container: true,
                            label: submitError,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  LucideIcons.circleAlert,
                                  color: AppColors.error,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    submitError!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                      color: AppColors.onBrandAccent,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Send request'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const _BookingPrivacyNotice(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingPrivacyNotice extends StatelessWidget {
  const _BookingPrivacyNotice();

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(WorkloopAppInfo.privacyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The privacy policy could not be opened')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Column(
        children: [
          const Text(
            'Workloop sends these details to this business so they can respond to your request.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.t3, fontSize: 12, height: 1.4),
          ),
          WorkloopTextButton(
            label: 'Privacy policy',
            onPressed: () => _openPrivacyPolicy(context),
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
    final coverUrl = profile.profile.coverPhotoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (coverUrl?.isNotEmpty == true) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.bgCard,
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.imageOff,
                    color: AppColors.t3,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ] else ...[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentPrimaryStrong,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                profile.businessName.isEmpty
                    ? 'S'
                    : profile.businessName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.onBrandAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        Text(
          profile.businessName,
          style: const TextStyle(
            color: AppColors.t1,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
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
            Expanded(
              child: Text(
                'workloop.app/${profile.profile.handle}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.t3, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  final List<String> urls;

  const _GalleryGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    final visibleUrls = urls.take(6).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.12,
      ),
      itemCount: visibleUrls.length,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          visibleUrls[index],
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppColors.bgInteract,
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.imageOff,
              color: AppColors.t3,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  final List<String> quotes;

  const _ReviewsList({required this.quotes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: quotes
          .take(3)
          .map(
            (quote) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgInteract,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.star,
                    color: AppColors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      quote,
                      style: const TextStyle(
                        color: AppColors.t2,
                        fontSize: 13,
                        height: 1.38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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

class _ProfileBadgeData {
  final IconData icon;
  final String label;

  const _ProfileBadgeData(this.icon, this.label);
}

class _ProfileBadges extends StatelessWidget {
  final List<_ProfileBadgeData> items;

  const _ProfileBadges({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: AppColors.green, size: 15),
                  const SizedBox(width: 7),
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: AppColors.t2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
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
  final String? description;
  const _ServiceRow({
    required this.name,
    required this.duration,
    required this.price,
    this.description,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$duration min',
                  style: const TextStyle(color: AppColors.t3, fontSize: 12),
                ),
                if (description?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    style: const TextStyle(
                      color: AppColors.t3,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            formatPounds(price),
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
    final label = enabled ? formatWorkingHourValue(map) : 'Closed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(day, style: const TextStyle(color: AppColors.t2)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.t1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? errorText;
  final int maxLines;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    this.errorText,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        buildCounter: maxLength == null
            ? null
            : (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.t1),
        decoration: _fieldDecoration(hint, label: label, errorText: errorText),
      ),
    );
  }
}

class _PreferredTimeShortcuts extends StatelessWidget {
  final ValueChanged<String> onPick;

  const _PreferredTimeShortcuts({required this.onPick});

  @override
  Widget build(BuildContext context) {
    const options = ['This week', 'Next week', 'Weekend', 'Evening'];
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (option) => WorkloopFilterChip(
                label: option,
                selected: false,
                onTap: () => onPick(option),
              ),
            )
            .toList(),
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  String hint, {
  String? label,
  String? errorText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    hintStyle: const TextStyle(color: AppColors.t3),
    filled: true,
    fillColor: AppColors.bgInteract,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accentInk, width: 1.5),
    ),
  );
}

class _SentState extends StatelessWidget {
  const _SentState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      label: 'Request sent. The business owner will contact you to confirm.',
      child: const ExcludeSemantics(
        child: Column(
          children: [
            Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 34),
            SizedBox(height: 10),
            Text(
              'Request sent',
              style: TextStyle(
                color: AppColors.t1,
                fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}

class _ClosedBookingState extends StatelessWidget {
  const _ClosedBookingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgInteract,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.lock, color: AppColors.t3, size: 22),
          SizedBox(height: 12),
          Text(
            'Booking requests are closed',
            style: TextStyle(
              color: AppColors.t1,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'This business is not accepting new booking requests right now.',
            style: TextStyle(color: AppColors.t3, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onRetry;

  const _ProfileMessage({
    required this.title,
    required this.body,
    this.onRetry,
  });

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
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.t3),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              WorkloopPrimaryButton(
                label: 'Try again',
                icon: LucideIcons.refreshCw,
                secondary: true,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
