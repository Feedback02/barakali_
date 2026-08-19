import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/theme/brand_colors.dart';
import 'package:barakali/core/theme/spacing.dart';
import 'package:barakali/core/widgets/barakali_button.dart';
import '../providers/onboarding_provider.dart';

/// First-run value-prop intro (3 lightweight slides), shown ahead of the login
/// screen to unauthenticated first-run users. Skippable; completing or skipping
/// persists the "seen" flag so it never shows again. No guest browse — this
/// reduces first-run friction with context, the auth gate stays.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_SlideData> _slides(AppLocalizations l10n) => [
    _SlideData(
      icon: Icons.restaurant_rounded,
      color: kBrandGreen,
      title: l10n.onboardingSlide1Title,
      body: l10n.onboardingSlide1Body,
    ),
    _SlideData(
      icon: Icons.savings_rounded,
      color: kBrandAmber,
      title: l10n.onboardingSlide2Title,
      body: l10n.onboardingSlide2Body,
    ),
    _SlideData(
      icon: Icons.eco_rounded,
      color: kBrandTerracotta,
      title: l10n.onboardingSlide3Title,
      body: l10n.onboardingSlide3Body,
    ),
  ];

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (!mounted) return;
    context.go('/auth/phone');
  }

  void _next(int count) {
    if (_page >= count - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final slides = _slides(l10n);
    final isLast = _page == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: slides.length,
                itemBuilder: (_, i) => _Slide(data: slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: BarakaliButton(
                label: isLast ? l10n.onboardingGetStarted : l10n.onboardingNext,
                onPressed: () => _next(slides.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data});

  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 60, color: data.color),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
