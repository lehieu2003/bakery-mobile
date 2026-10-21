import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Rounded square behind each onboarding illustration.
const double _illustrationRadius = 42;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onComplete, super.key});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _isCompleting = false;

  static const _slides = [
    _OnboardingSlide(
      title: 'Bánh mới mỗi ngày',
      description: 'Khám phá bánh ngọt, bánh mì và món mới từ Bakery Shop.',
      icon: Icons.bakery_dining_rounded,
      accent: AppTheme.pastryPeach,
    ),
    _OnboardingSlide(
      title: 'Tìm món hợp khẩu vị',
      description: 'Dễ dàng tìm kiếm, xem danh mục và nhận gợi ý phù hợp.',
      icon: Icons.manage_search_rounded,
      accent: AppTheme.blushPink,
    ),
    _OnboardingSlide(
      title: 'Đặt hàng nhanh hơn',
      description: 'Thêm vào giỏ, theo dõi đơn hàng và tích điểm thành viên.',
      icon: Icons.shopping_bag_rounded,
      accent: AppTheme.primaryPink,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.canvasCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isCompleting ? null : _complete,
                  child: const Text('Bỏ qua'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    return _OnboardingPage(slide: _slides[index]);
                  },
                ),
              ),
              _OnboardingDots(activeIndex: _index, count: _slides.length),
              const Gap(AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isCompleting
                      ? null
                      : isLast
                      ? _complete
                      : _next,
                  child: _isCompleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isLast ? 'Bắt đầu' : 'Tiếp tục'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _next() {
    _controller.animateToPage(
      _index + 1,
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    setState(() => _isCompleting = true);
    await widget.onComplete();
    if (!mounted) return;
    setState(() => _isCompleting = false);
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BakeryIllustration(slide: slide),
        const Gap(AppSpacing.x4l),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.inkBrown,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const Gap(AppSpacing.lg),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textMuted,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BakeryIllustration extends StatelessWidget {
  const _BakeryIllustration({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 246,
      height: 246,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 218,
            height: 218,
            decoration: BoxDecoration(
              color: slide.accent.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            bottom: 30,
            child: Container(
              width: 196,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.warmBrown.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCream,
              borderRadius: BorderRadius.circular(_illustrationRadius),
              border: Border.all(
                color: AppTheme.warmBrown.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warmBrown.withValues(alpha: 0.13),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Icon(slide.icon, size: 72, color: AppTheme.warmBrown),
          ),
          Positioned(
            top: 32,
            right: 44,
            child: _AccentChip(color: slide.accent),
          ),
          Positioned(
            left: 36,
            bottom: 58,
            child: _AccentChip(color: AppTheme.blushPink, small: true),
          ),
        ],
      ),
    );
  }
}

class _AccentChip extends StatelessWidget {
  const _AccentChip({required this.color, this.small = false});

  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 18.0 : 28.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.surfaceCream, width: 3),
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.activeIndex, required this.count});

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primaryPink
                : AppTheme.warmBrown.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}
