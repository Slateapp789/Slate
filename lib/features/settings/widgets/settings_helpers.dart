import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/slate_ui.dart';

Widget sectionLabel(String text) => WorkloopCaption(text);

Widget infoRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 14, color: AppColors.t2)),
      Flexible(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.t1,
          ),
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
);

Widget tappableRow({
  required String label,
  required String value,
  required VoidCallback onTap,
  Color? valueColor,
}) => Material(
  color: Colors.transparent,
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.t2),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.t1,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.pencil, size: 14, color: AppColors.t3),
        ],
      ),
    ),
  ),
);

Widget skeletonBox(double height) => Container(
  height: height,
  decoration: BoxDecoration(
    color: AppColors.t1.withValues(alpha: 0.035),
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
);

Widget saveBtn({
  required String label,
  required VoidCallback onTap,
  bool loading = false,
  bool disabled = false,
  Color color = AppColors.accentPrimaryStrong,
}) => SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
    onPressed: loading || disabled ? null : onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: color == AppColors.accentPrimaryStrong
          ? AppColors.onBrandAccent
          : AppColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      elevation: 0,
    ),
    child: loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: color == AppColors.accentPrimaryStrong
                  ? AppColors.onBrandAccent
                  : AppColors.bg,
              strokeWidth: 2,
            ),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
  ),
);

Widget cancelBtn(BuildContext ctx) => SizedBox(
  width: double.infinity,
  height: 52,
  child: TextButton(
    onPressed: () => Navigator.pop(ctx),
    child: const Text(
      'Cancel',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.t3,
      ),
    ),
  ),
);

Widget settingsField({
  required String label,
  required TextEditingController controller,
  String? hint,
  TextInputType? keyboardType,
  bool autofocus = false,
  int maxLines = 1,
  int? maxLength,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: AppColors.t3,
      ),
    ),
    const SizedBox(height: 8),
    TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: autofocus,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(color: AppColors.t1, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        counterText: maxLength == null ? null : '',
        hintStyle: const TextStyle(color: AppColors.t3),
        filled: true,
        fillColor: AppColors.t1.withValues(alpha: 0.028),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.accentPrimary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    ),
  ],
);
