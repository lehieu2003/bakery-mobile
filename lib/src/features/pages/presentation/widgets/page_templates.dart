import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class PageTemplateData {
  const PageTemplateData({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget body;
}

PageTemplateData? builtInPageTemplate(String slug) {
  switch (slug) {
    case 've-chung-toi':
      return const PageTemplateData(
        eyebrow: 'Giới thiệu',
        title: 'Về chúng tôi',
        subtitle: 'Câu chuyện thương hiệu và cửa hàng Phương Loan Bakery.',
        icon: Icons.bakery_dining_rounded,
        body: _AboutBody(),
      );
    case 'thanh-vien':
      return const PageTemplateData(
        eyebrow: 'Thành viên',
        title: 'Chương trình thành viên',
        subtitle: 'Tích điểm, thăng hạng và mở khóa ưu đãi theo cấp bậc.',
        icon: Icons.workspace_premium_rounded,
        body: _MembershipBody(),
      );
    case 'store':
    case 'cua-hang':
      return const PageTemplateData(
        eyebrow: 'Cửa hàng',
        title: 'Cửa hàng',
        subtitle: 'Địa chỉ, thời gian hoạt động và thông tin liên hệ.',
        icon: Icons.storefront_rounded,
        body: _StoreBody(),
      );
    case 'chinh-sach-bao-mat':
      return const PageTemplateData(
        eyebrow: 'Thông tin',
        title: 'Chính sách bảo mật',
        subtitle: 'Cách chúng tôi thu thập và bảo vệ dữ liệu cá nhân.',
        icon: Icons.shield_rounded,
        body: _SectionListBody(sections: _privacySections),
      );
    case 'chinh-sach-giao-hang':
      return const PageTemplateData(
        eyebrow: 'Thông tin',
        title: 'Chính sách giao hàng',
        subtitle: 'Phí vận chuyển, thời gian giao và khu vực áp dụng.',
        icon: Icons.local_shipping_rounded,
        body: _ShippingBody(),
      );
    case 'chinh-sach-doi-tra':
      return const PageTemplateData(
        eyebrow: 'Thông tin',
        title: 'Chính sách đổi trả',
        subtitle: 'Điều kiện, quy trình và hình thức bồi hoàn.',
        icon: Icons.assignment_return_rounded,
        body: _SectionListBody(sections: _returnSections),
      );
    case 'dieu-khoan-su-dung':
      return const PageTemplateData(
        eyebrow: 'Thông tin',
        title: 'Điều khoản sử dụng',
        subtitle: 'Quy định khi sử dụng website/app và dịch vụ.',
        icon: Icons.description_rounded,
        body: _SectionListBody(sections: _termsSections),
      );
    default:
      return null;
  }
}

class BuiltInPageBody extends StatelessWidget {
  const BuiltInPageBody({super.key, required this.template});

  final PageTemplateData template;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.x3l,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.16),
                scheme.primaryContainer.withValues(alpha: 0.42),
              ],
            ),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.surfaceFrostedAvatar,
                    child: Icon(template.icon, color: scheme.primary),
                  ),
                  const Gap(AppSpacing.md),
                  Text(
                    template.eyebrow.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.md),
              Text(
                template.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(AppSpacing.sm),
              Text(
                template.subtitle,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.lg),
        template.body,
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Gap(AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const Gap(AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionListBody extends StatelessWidget {
  const _SectionListBody({required this.sections});

  final List<_SectionData> sections;

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'Nội dung chi tiết',
      child: Column(
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            _SectionTile(data: sections[i]),
            if (i < sections.length - 1) const Gap(AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.data});

  final _SectionData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Gap(AppSpacing.sm),
          for (final line in data.lines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _AboutBody extends StatelessWidget {
  const _AboutBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CardSection(
          title: 'Câu chuyện',
          child: Text(
            'Phương Loan Bakery được xây dựng từ tình yêu bánh thủ công. Chúng tôi tập trung vào chất lượng nguyên liệu, quy trình kỹ lưỡng và trải nghiệm thân thiện.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
        const Gap(AppSpacing.md),
        const _CardSection(
          title: 'Hệ thống chi nhánh',
          child: Column(
            children: [
              _MetaRow(
                icon: Icons.location_on_rounded,
                label: 'Quảng Ngãi',
                value: 'ĐT624, TT. Chợ Chùa, Nghĩa Hành, Quảng Ngãi',
              ),
              Gap(AppSpacing.sm),
              _MetaRow(
                icon: Icons.schedule_rounded,
                label: 'Giờ mở cửa',
                value: 'Thứ 2 - Chủ nhật: 8:00 - 21:00',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MembershipBody extends StatelessWidget {
  const _MembershipBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CardSection(
          title: 'Hạng thành viên',
          child: Column(
            children: const [
              _MembershipTierTile(
                name: 'Bạc',
                points: '0 - 299 điểm',
                discount: 'Giảm 3%',
              ),
              Gap(AppSpacing.md),
              _MembershipTierTile(
                name: 'Vàng',
                points: '300 - 899 điểm',
                discount: 'Giảm 7%',
              ),
              Gap(AppSpacing.md),
              _MembershipTierTile(
                name: 'Bạch kim',
                points: 'Từ 900 điểm',
                discount: 'Giảm 12%',
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.md),
        const _SectionListBody(sections: _membershipSections),
      ],
    );
  }
}

class _MembershipTierTile extends StatelessWidget {
  const _MembershipTierTile({
    required this.name,
    required this.points,
    required this.discount,
  });

  final String name;
  final String points;
  final String discount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const Gap(AppSpacing.xxs),
                Text(points, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              color: scheme.primary.withValues(alpha: 0.12),
            ),
            child: Text(
              discount,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreBody extends StatelessWidget {
  const _StoreBody();

  @override
  Widget build(BuildContext context) {
    return const _CardSection(
      title: 'Thông tin cửa hàng',
      child: Column(
        children: [
          _MetaRow(
            icon: Icons.location_on_rounded,
            label: 'Địa chỉ',
            value: '2QXG+RXV, ĐT624, TT. Chợ Chùa, Nghĩa Hành, Quảng Ngãi',
          ),
          Gap(AppSpacing.sm),
          _MetaRow(
            icon: Icons.phone_rounded,
            label: 'Điện thoại',
            // The shop hotline, same number as the web footer and policies.
            value: '1900 779907',
          ),
          Gap(AppSpacing.sm),
          _MetaRow(
            icon: Icons.schedule_rounded,
            label: 'Giờ mở cửa',
            value: '08:00 - 21:00 (Thứ Hai - Chủ Nhật)',
          ),
        ],
      ),
    );
  }
}

class _ShippingBody extends StatelessWidget {
  const _ShippingBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _CardSection(
          title: 'Bảng phí giao hàng',
          child: Column(
            children: [
              _MetaRow(
                icon: Icons.local_shipping_rounded,
                label: 'Trong bán kính 10km từ cửa hàng',
                value: '2 - 4 tiếng | 20.000đ - 35.000đ | Miễn phí từ 500.000đ',
              ),
              Gap(AppSpacing.sm),
              _MetaRow(
                icon: Icons.local_shipping_rounded,
                label: 'Các khu vực còn lại của Quảng Ngãi',
                value: '4 - 8 tiếng | 40.000đ - 60.000đ | Miễn phí từ 500.000đ',
              ),
              Gap(AppSpacing.sm),
              _MetaRow(
                icon: Icons.local_shipping_rounded,
                label: 'Tỉnh thành lân cận',
                value: '1 - 2 ngày | 60.000đ - 100.000đ | Liên hệ tư vấn',
              ),
            ],
          ),
        ),
        Gap(AppSpacing.md),
        _SectionListBody(sections: _shippingSections),
      ],
    );
  }
}

class _SectionData {
  const _SectionData({required this.title, required this.lines});
  final String title;
  final List<String> lines;
}

const _privacySections = <_SectionData>[
  _SectionData(
    title: 'Thu thập dữ liệu',
    lines: [
      'Thu thập thông tin cần thiết để xử lý đơn hàng và chăm sóc khách hàng.',
      'Dữ liệu truy cập và cookie được dùng để cải thiện trải nghiệm.',
    ],
  ),
  _SectionData(
    title: 'Sử dụng và chia sẻ',
    lines: [
      'Chỉ chia sẻ dữ liệu cần thiết cho đơn vị vận chuyển/thanh toán.',
      'Không bán hoặc trao đổi dữ liệu cá nhân vì mục đích thương mại.',
    ],
  ),
  _SectionData(
    title: 'Quyền của khách hàng',
    lines: [
      'Có quyền yêu cầu xem, chỉnh sửa hoặc xóa dữ liệu cá nhân.',
      'Có thể từ chối nhận thông tin tiếp thị bất cứ lúc nào.',
    ],
  ),
];

const _shippingSections = <_SectionData>[
  _SectionData(
    title: 'Thời gian giao hàng',
    lines: [
      'Đơn trước 14:00 có thể giao trong ngày ở khu vực nội thành.',
      'Lễ/Tết và cuối tuần có thể chậm hơn do lưu lượng đơn tăng cao.',
    ],
  ),
  _SectionData(
    title: 'Quy trình đóng gói',
    lines: [
      'Sản phẩm được đóng gói cẩn thận để hạn chế hư hỏng khi vận chuyển.',
      'Sản phẩm cần lạnh được bảo quản phù hợp trong quá trình giao nhận.',
    ],
  ),
];

const _returnSections = <_SectionData>[
  _SectionData(
    title: 'Trường hợp được đổi trả',
    lines: [
      'Sản phẩm lỗi, sai đơn hoặc hư hỏng do vận chuyển.',
      'Sản phẩm không đúng mô tả đã xác nhận với khách hàng.',
    ],
  ),
  _SectionData(
    title: 'Quy trình xử lý',
    lines: [
      'Gửi thông tin và ảnh trong vòng 2 giờ sau khi nhận hàng.',
      'CSKH xác minh và thống nhất phương án đổi/trả phù hợp.',
    ],
  ),
];

const _termsSections = <_SectionData>[
  _SectionData(
    title: 'Tài khoản và đặt hàng',
    lines: [
      'Người dùng cần cung cấp thông tin chính xác khi tạo tài khoản.',
      'Đơn hàng được xử lý sau khi xác nhận thanh toán thành công.',
    ],
  ),
  _SectionData(
    title: 'Sở hữu trí tuệ',
    lines: [
      'Nội dung thương hiệu thuộc sở hữu của Phương Loan Bakery.',
      'Không sử dụng nội dung vì mục đích thương mại khi chưa được chấp thuận.',
    ],
  ),
];

const _membershipSections = <_SectionData>[
  _SectionData(
    title: 'Cách tích điểm',
    lines: [
      'Mỗi 10.000đ chi tiêu nhận 1 điểm.',
      'Điểm tự động cộng sau khi đơn hàng hoàn tất.',
    ],
  ),
  _SectionData(
    title: 'Điều kiện duy trì',
    lines: [
      'Hệ thống xét hạng dựa trên tổng điểm tích lũy.',
      'Quyền lợi hạng cao bao gồm ưu đãi và hỗ trợ ưu tiên.',
    ],
  ),
];
