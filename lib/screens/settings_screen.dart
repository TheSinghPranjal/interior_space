import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_nav_settings_provider.dart';
import '../providers/company_profile_provider.dart';
import '../providers/pdf_export_settings_provider.dart';
import '../providers/room_design_provider.dart';
import '../widgets/company/company_image.dart';
import 'material_library/material_library_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _syncingFields = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(companyProfileProvider);
    _nameController = TextEditingController(text: profile.companyName);
    _addressController = TextEditingController(text: profile.address);
    _phoneController = TextEditingController(text: profile.contactNumber);
    _emailController = TextEditingController(text: profile.email);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncControllersFromProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _syncControllersFromProfile() {
    final profile = ref.read(companyProfileProvider);
    _syncingFields = true;
    _nameController.text = profile.companyName;
    _addressController.text = profile.address;
    _phoneController.text = profile.contactNumber;
    _emailController.text = profile.email;
    _syncingFields = false;
  }

  Future<void> _pickLogo() async {
    await ref.read(companyProfileProvider.notifier).pickLogo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company logo updated')),
      );
    }
  }

  Future<void> _pickCover() async {
    await ref.read(companyProfileProvider.notifier).pickCoverImage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover image updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(companyProfileProvider);
    final premiumFurniture = ref.watch(premiumFurnitureProvider);
    final pdfSettings = ref.watch(pdfExportSettingsProvider);
    final navSettings = ref.watch(appNavSettingsProvider);

    ref.listen(companyProfileProvider, (previous, next) {
      if (previous?.logoPath != next.logoPath ||
          previous?.coverImagePath != next.coverImagePath) {
        setState(() {});
      }
    });

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Company Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your company details are saved automatically and available across the app.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionCard(
          title: 'Material Library',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.grid_view, color: theme.colorScheme.primary),
            title: const Text('Browse Materials'),
            subtitle: const Text(
              'Floor, wall, ceiling & furniture textures — add your own and reuse anywhere',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const MaterialLibraryScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionCard(
          title: '3D Preview',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              Icons.auto_awesome,
              color: premiumFurniture
                  ? Colors.amber.shade700
                  : theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            title: const Text('Premium'),
            subtitle: Text(
              'Use high-detail 3D models for furniture, AC units, and appliances. Add daily objects and highly designed furniture.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            value: premiumFurniture,
            onChanged: (value) {
              ref.read(premiumFurnitureProvider.notifier).state = value;
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Cover Image',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompanyImage(
                path: profile.coverImagePath,
                height: 160,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                placeholderIcon: Icons.landscape_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickCover,
                      icon: const Icon(Icons.upload_outlined, size: 18),
                      label: const Text('Upload cover'),
                    ),
                  ),
                  if (profile.hasCover) ...[
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      tooltip: 'Remove cover',
                      onPressed: () =>
                          ref.read(companyProfileProvider.notifier).removeCoverImage(),
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Company Logo',
          child: Row(
            children: [
              CompanyImage(
                path: profile.logoPath,
                width: 88,
                height: 88,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                placeholderIcon: Icons.business_outlined,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.upload_outlined, size: 18),
                      label: const Text('Upload logo'),
                    ),
                    if (profile.hasLogo) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(companyProfileProvider.notifier).removeLogo(),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove logo'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Company Details',
          child: Column(
            children: [
              _ProfileField(
                controller: _nameController,
                label: 'Company name',
                hint: 'Enter company name',
                icon: Icons.business_outlined,
                onChanged: (value) {
                  if (_syncingFields) return;
                  ref.read(companyProfileProvider.notifier).updateCompanyName(value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileField(
                controller: _addressController,
                label: 'Company address',
                hint: 'Street, city, state, zip',
                icon: Icons.location_on_outlined,
                maxLines: 3,
                onChanged: (value) {
                  if (_syncingFields) return;
                  ref.read(companyProfileProvider.notifier).updateAddress(value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileField(
                controller: _phoneController,
                label: 'Contact number',
                hint: '+1 234 567 8900',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  if (_syncingFields) return;
                  ref.read(companyProfileProvider.notifier).updateContactNumber(value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileField(
                controller: _emailController,
                label: 'Company email',
                hint: 'hello@company.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  if (_syncingFields) return;
                  ref.read(companyProfileProvider.notifier).updateEmail(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'PDF Settings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.view_in_ar_outlined,
                  color: pdfSettings.include3dPreview
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                title: const Text('Include 3D previews'),
                subtitle: Text(
                  'Add rendered 3D views when exporting room or apartment PDFs.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                value: pdfSettings.include3dPreview,
                onChanged: (value) {
                  ref
                      .read(pdfExportSettingsProvider.notifier)
                      .setInclude3dPreview(value);
                },
              ),
              if (pdfSettings.include3dPreview) ...[
                const Divider(height: 24),
                Text(
                  'Views to include',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Top view'),
                  subtitle: const Text(
                    'Bird\'s-eye view of each room and the full apartment layout.',
                  ),
                  value: pdfSettings.includeTopView,
                  onChanged: (value) {
                    if (value == null) return;
                    ref
                        .read(pdfExportSettingsProvider.notifier)
                        .setIncludeTopView(value);
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Front view'),
                  subtitle: const Text(
                    'Front-facing view of each room and the apartment layout.',
                  ),
                  value: pdfSettings.includeFrontView,
                  onChanged: (value) {
                    if (value == null) return;
                    ref
                        .read(pdfExportSettingsProvider.notifier)
                        .setIncludeFrontView(value);
                  },
                ),
              ],
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.draw_outlined,
                  color: pdfSettings.includeSketchInPdf
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                title: const Text('Include sketch pages'),
                subtitle: Text(
                  'Append edited sketch pages at the end of exported PDFs. '
                  'Only rooms and apartments with sketch annotations are included.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                value: pdfSettings.includeSketchInPdf,
                onChanged: (value) {
                  ref
                      .read(pdfExportSettingsProvider.notifier)
                      .setIncludeSketchInPdf(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Navigation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.draw_outlined,
                  color: navSettings.showSketchTab
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                title: const Text('Show Sketch tab'),
                subtitle: Text(
                  'Display the Sketch tab in the bottom navigation bar.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                value: navSettings.showSketchTab,
                onChanged: (value) {
                  ref.read(appNavSettingsProvider.notifier).setShowSketchTab(value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.auto_awesome_outlined,
                  color: navSettings.showAiAssistTab
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                title: const Text('Show AI Assist tab'),
                subtitle: Text(
                  'Display the AI Assist tab in the bottom navigation bar.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                value: navSettings.showAiAssistTab,
                onChanged: (value) {
                  ref.read(appNavSettingsProvider.notifier).setShowAiAssistTab(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (profile.hasAnyDetails)
          OutlinedButton.icon(
            onPressed: () {
              _syncControllersFromProfile();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fields refreshed from saved profile')),
              );
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh fields'),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
