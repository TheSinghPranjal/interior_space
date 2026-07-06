import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/company_profile_provider.dart';
import 'company_image.dart';

/// Small square slot for the uploaded company logo.
class CompanyLogoSquare extends ConsumerWidget {
  const CompanyLogoSquare({
    super.key,
    this.size = 28,
  });

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoPath = ref.watch(companyProfileProvider).logoPath;
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CompanyImage(
        path: logoPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderIcon: Icons.business_outlined,
      ),
    );
  }
}
