import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.warmBrown.withValues(alpha: 0.08);
    final highlight = AppTheme.surfaceCream.withValues(alpha: 0.85);

    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final offset = (_controller.value * 2.4) - 1.2;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(offset - 1, 0),
                  end: Alignment(offset + 1, 0),
                  colors: [base, highlight, base],
                  stops: const [0.18, 0.5, 0.82],
                ),
              ),
              child: SizedBox(width: widget.width, height: widget.height),
            );
          },
        ),
      ),
    );
  }
}

class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SkeletonBox(width: 52, height: 52, borderRadius: 10),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: double.infinity, height: 14),
                  SizedBox(height: 10),
                  SkeletonBox(width: 120, height: 12),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const SkeletonBox(width: 34, height: 34, borderRadius: 999),
          ],
        ),
      ),
    );
  }
}

class SkeletonBanner extends StatelessWidget {
  const SkeletonBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: SkeletonBox(width: double.infinity, height: 190, borderRadius: 20),
    );
  }
}

class SkeletonCategoryRail extends StatelessWidget {
  const SkeletonCategoryRail({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 72,
            child: Column(
              children: [
                SkeletonBox(width: 54, height: 54, borderRadius: 999),
                SizedBox(height: 8),
                SkeletonBox(width: 62, height: 10, borderRadius: 999),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 5,
      ),
    );
  }
}

class SkeletonProductGrid extends StatelessWidget {
  const SkeletonProductGrid({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) => const _SkeletonProductCard(),
      ),
    );
  }
}

class SkeletonProductRail extends StatelessWidget {
  const SkeletonProductRail({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return const SizedBox(width: 166, child: _SkeletonProductCard());
        },
      ),
    );
  }
}

class _SkeletonProductCard extends StatelessWidget {
  const _SkeletonProductCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmBrown.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: AppTheme.surfaceCream,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SkeletonBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        borderRadius: 0,
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, 44, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: double.infinity, height: 13),
                      SizedBox(height: 7),
                      SkeletonBox(width: 92, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: const SkeletonBox(width: 38, height: 38, borderRadius: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonBlogCard extends StatelessWidget {
  const SkeletonBlogCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(builder: _skeletonFillBuilder),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 18),
                SizedBox(height: 8),
                SkeletonBox(width: 220, height: 18),
                SizedBox(height: 14),
                SkeletonBox(width: double.infinity, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: 180, height: 13),
                SizedBox(height: 18),
                SkeletonBox(width: 160, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonProductDetail extends StatelessWidget {
  const SkeletonProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasCream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: const [
          SkeletonBox(width: double.infinity, height: 360, borderRadius: 0),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 24),
                SizedBox(height: 10),
                SkeletonBox(width: 230, height: 24),
                SizedBox(height: 18),
                Row(
                  children: [
                    SkeletonBox(width: 142, height: 24),
                    Spacer(),
                    SkeletonBox(width: 92, height: 30, borderRadius: 999),
                  ],
                ),
                SizedBox(height: 24),
                SkeletonBox(width: 130, height: 18),
                SizedBox(height: 12),
                SkeletonBox(width: double.infinity, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: 240, height: 13),
                SizedBox(height: 22),
                SkeletonBox(width: double.infinity, height: 118),
                SizedBox(height: 24),
                SkeletonBox(width: 170, height: 18),
                SizedBox(height: 12),
                SkeletonProductRail(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonBlogDetail extends StatelessWidget {
  const SkeletonBlogDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 92, height: 24, borderRadius: 999),
          SizedBox(height: 14),
          SkeletonBox(width: double.infinity, height: 26),
          SizedBox(height: 10),
          SkeletonBox(width: 260, height: 26),
          SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 56),
          SizedBox(height: 16),
          SkeletonBox(width: 220, height: 14),
          SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(builder: _skeletonFillBuilder),
          ),
          SizedBox(height: 18),
          SkeletonBox(width: double.infinity, height: 160),
          SizedBox(height: 24),
          SkeletonBox(width: 170, height: 18),
          SizedBox(height: 12),
          SkeletonTile(),
          SkeletonTile(),
        ],
      ),
    );
  }
}

class SkeletonNotificationTile extends StatelessWidget {
  const SkeletonNotificationTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SkeletonBox(width: 40, height: 40, borderRadius: 999),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 220, height: 12),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBox(width: 52, height: 28, borderRadius: 999),
        ],
      ),
    );
  }
}

class SkeletonOrderCard extends StatelessWidget {
  const SkeletonOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Row(
              children: [
                SkeletonBox(width: 40, height: 40, borderRadius: 999),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140, height: 14),
                      SizedBox(height: 8),
                      SkeletonBox(width: 210, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                SkeletonBox(width: 82, height: 18),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(width: double.infinity, height: 38),
          ],
        ),
      ),
    );
  }
}

Widget _skeletonFillBuilder(BuildContext context, BoxConstraints constraints) {
  return SkeletonBox(
    width: constraints.maxWidth,
    height: constraints.maxHeight,
    borderRadius: 0,
  );
}
