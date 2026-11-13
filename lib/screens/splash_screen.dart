import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../widgets/branding/app_logo.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 2600), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDFCFA),
              AppTheme.surface,
              Color(0xFFEDE8E1),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomMultiChildLayout(
            delegate: _SplashLayoutDelegate(),
            children: [
              LayoutId(
                id: _SplashLayoutDelegate.mark,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fade.value,
                        child: Transform.scale(
                          scale: _scale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(size: 104),
                        const SizedBox(height: AppSpacing.xxl),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Loading your workspace…',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              LayoutId(
                id: _SplashLayoutDelegate.byline,
                child: FadeTransition(
                  opacity: _fade,
                  child: const _LazyBearClubByline(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps the existing splash mark centered, and moves it up only when the
/// bottom byline would otherwise overlap it. Short screens scale the mark.
class _SplashLayoutDelegate extends MultiChildLayoutDelegate {
  _SplashLayoutDelegate();

  static const mark = 'mark';
  static const byline = 'byline';
  static const _gap = 8.0;

  @override
  void performLayout(Size size) {
    final bylineSize = layoutChild(
      byline,
      BoxConstraints(
        maxWidth: size.width,
        maxHeight: math.max(0.0, size.height * 0.45),
      ),
    );
    final spaceAbove = math.max(0.0, size.height - bylineSize.height);
    final markSize = layoutChild(
      mark,
      BoxConstraints(
        maxWidth: size.width,
        maxHeight: spaceAbove,
      ),
    );

    final idealTop = (size.height - markSize.height) / 2;
    final overlaps = idealTop + markSize.height > spaceAbove - _gap;
    final top = overlaps ? (spaceAbove - markSize.height) / 2 : idealTop;

    positionChild(
      mark,
      Offset(
        (size.width - markSize.width) / 2,
        top.clamp(0.0, spaceAbove),
      ),
    );
    positionChild(
      byline,
      Offset(
        (size.width - bylineSize.width) / 2,
        size.height - bylineSize.height,
      ),
    );
  }

  @override
  bool shouldRelayout(covariant _SplashLayoutDelegate oldDelegate) => false;
}

/// Studio credit pinned to the bottom of the splash.
///
/// Ink is the app's light-surface palette. The splash gradient stays cream
/// in light and dark themes, so the byline stays readable on either theme.
class _LazyBearClubByline extends StatelessWidget {
  const _LazyBearClubByline();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final iconSize = shortestSide >= 600 ? 44.0 : 36.0;

    final byStyle = (textTheme.labelMedium ?? const TextStyle()).copyWith(
      color: AppTheme.textSecondary,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w500,
      height: 1.1,
    );
    final nameStyle = (textTheme.titleSmall ?? const TextStyle()).copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.15,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('by', style: byStyle),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/branding/lazy_bear_club.png',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('The Lazy Bear Club', style: nameStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
