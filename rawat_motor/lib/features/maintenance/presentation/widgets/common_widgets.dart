import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

class RawatinCard extends StatelessWidget {
  const RawatinCard({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    super.key,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // Material transparan memberi ListTile/ExpansionTile permukaan untuk
      // menggambar latar dan ripple di dalam card berwarna.
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class RawatinStatusBadge extends StatelessWidget {
  const RawatinStatusBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.eyebrow.copyWith(
              color: color,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class RawatinIconTile extends StatelessWidget {
  const RawatinIconTile({
    required this.icon,
    required this.color,
    required this.soft,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final Color color;
  final Color soft;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: soft,
      borderRadius: BorderRadius.circular(size * .29),
    ),
    child: Icon(icon, color: color, size: size * .5),
  );
}

class RawatinInfoChip extends StatelessWidget {
  const RawatinInfoChip({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.primaryDark, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class RawatinSourceChip extends StatelessWidget {
  const RawatinSourceChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppType.eyebrow.copyWith(
          color: colors.muted,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class RawatinSectionHeading extends StatelessWidget {
  const RawatinSectionHeading({
    required this.eyebrow,
    required this.title,
    super.key,
  });
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RawatinSpeedStripe(color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.eyebrow.copyWith(
                  color: colors.primaryDark,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppType.cardTitle.copyWith(
            color: colors.ink,
            fontSize: 20,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class RawatinOdometerField extends StatelessWidget {
  const RawatinOdometerField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.textInputAction,
    required this.validator,
    this.suffixText = 'km',
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final String? Function(String?) validator;
  final String suffixText;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppType.metric.copyWith(
            color: colors.ink,
            fontSize: 16,
            fontFeatures: const [],
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            prefixIcon: Icon(AppIcons.speed, color: colors.muted, size: 19),
          ),
        ),
      ],
    );
  }
}

class RawatinSafetyNote extends StatelessWidget {
  const RawatinSafetyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.infoOutline, color: colors.muted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pengingat ini membantu mencatat jadwal. Ikuti juga rekomendasi buku manual motormu.',
              style: TextStyle(color: colors.muted, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class RawatinSummaryRow extends StatelessWidget {
  const RawatinSummaryRow({
    required this.label,
    required this.value,
    super.key,
  });
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colors.muted, fontSize: 12.5),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppType.metric.copyWith(
              color: colors.ink,
              fontSize: 13,
              fontFeatures: const [],
            ),
          ),
        ),
      ],
    );
  }
}

class RawatinScreenIntro extends StatelessWidget {
  const RawatinScreenIntro({
    required this.eyebrow,
    required this.title,
    required this.description,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RawatinSpeedStripe(color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                eyebrow,
                style: AppType.eyebrow.copyWith(
                  color: colors.primaryDark,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: AppType.km.copyWith(
            color: colors.ink,
            fontSize: 34,
            height: 1.02,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(color: colors.muted, height: 1.45, fontSize: 13.5),
        ),
      ],
    );
  }
}

class RawatinSpeedStripe extends StatelessWidget {
  const RawatinSpeedStripe({required this.color, super.key});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 3.5,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class RawatinEmptyState extends StatelessWidget {
  const RawatinEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          RawatinIconTile(
            icon: icon,
            color: colors.primaryDark,
            soft: colors.primarySoft,
            size: 50,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppType.cardTitle.copyWith(color: colors.ink, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, height: 1.45, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class RawatinSheetHeading extends StatelessWidget {
  const RawatinSheetHeading({
    required this.eyebrow,
    required this.title,
    required this.icon,
    super.key,
  });

  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Row(
      children: [
        RawatinIconTile(
          icon: icon,
          color: colors.primaryDark,
          soft: colors.primarySoft,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: AppType.eyebrow.copyWith(
                  color: colors.primaryDark,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppType.cardTitle.copyWith(
                  color: colors.ink,
                  fontSize: 21,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
