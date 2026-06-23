import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/design_menu_action.dart';

class DesignMenuFab extends StatefulWidget {
  const DesignMenuFab({
    super.key,
    required this.onAction,
  });

  final ValueChanged<DesignMenuAction> onAction;

  @override
  State<DesignMenuFab> createState() => _DesignMenuFabState();
}

class _DesignMenuFabState extends State<DesignMenuFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const _actions = DesignMenuAction.values;
  static const _itemSpacing = 8.0;
  static const _iconSize = 36.0;
  static const _iconGlyphSize = 17.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_fadeAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _select(DesignMenuAction action) {
    _toggle();
    widget.onAction(action);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxMenuHeight = MediaQuery.sizeOf(context).height * 0.52;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IgnorePointer(
          ignoring: !_isOpen,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxMenuHeight),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _actions.map((action) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: _itemSpacing),
                        child: _MenuItem(
                          label: action.label,
                          icon: action.icon,
                          iconSize: _iconSize,
                          iconGlyphSize: _iconGlyphSize,
                          labelStyle: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          iconColor: colorScheme.onPrimaryContainer,
                          iconBackground: colorScheme.primaryContainer,
                          labelBackground: colorScheme.surfaceContainerHighest,
                          onTap: () => _select(action),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        FloatingActionButton(
          heroTag: 'design_fab_main',
          onPressed: _toggle,
          elevation: 2,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 220),
            child: Icon(
              _isOpen ? Icons.close : Icons.tune,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.iconGlyphSize,
    required this.labelStyle,
    required this.iconColor,
    required this.iconBackground,
    required this.labelBackground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final double iconSize;
  final double iconGlyphSize;
  final TextStyle? labelStyle;
  final Color iconColor;
  final Color iconBackground;
  final Color labelBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
              elevation: 1,
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              color: labelBackground,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(label, style: labelStyle),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              elevation: 2,
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.15),
              color: iconBackground,
              shape: const CircleBorder(),
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: Icon(icon, size: iconGlyphSize, color: iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
