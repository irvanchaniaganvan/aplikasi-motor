import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import './ai_orb.dart';
import '../widgets/common_widgets.dart';

/// Kartu promosi asisten AI di Beranda.
///
/// Hanya ditampilkan saat [AiServiceFactory.featureEnabled] aktif dan diklik
/// membuka halaman chat AI.
class AiAssistantCard extends StatelessWidget {
  const AiAssistantCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);

    return RawatinCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const AiOrb(size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          AppIcons.sparkle,
                          size: 14,
                          color: AppPalette.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI',
                          style: TextStyle(
                            color: AppPalette.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tanya Rawatin',
                      style: AppType.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tanya seputar oli, rem, ban, CVT, aki, dan perawatan motor umum.',
                      style: TextStyle(
                        color: colors.inkSoft,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcons.arrowForward,
                size: 20,
                color: colors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
