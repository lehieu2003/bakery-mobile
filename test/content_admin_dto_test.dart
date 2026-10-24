import 'package:flutter_test/flutter_test.dart';

import 'package:bakery_mobile/src/features/admin/content/banners/data/dtos/banner_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/data/dtos/notification_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/domain/models/admin_notification.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/data/dtos/page_admin_dto.dart';

/// Fixtures mirror REAL server payloads (captured 2026-10-24): banners and
/// pages return BARE ARRAYS under `data`; notifications wraps
/// `{notifications, pagination}`.
void main() {
  test('parses a banner row (description field, bare-array list)', () {
    const row = {
      'id': 'b-1',
      'title': 'Ưu đãi mùa bánh cưới',
      'description': 'Đặt bánh cưới trong mơ của bạn ngay hôm nay!',
      'imageUrl': '/images/cake-3.jpg',
      'linkUrl': '/category/wedding',
      'displayOrder': 1,
      'isActive': true,
      'createdAt': '2026-03-09T16:48:47.983Z',
    };

    final banner = BannerAdminDto.fromJson(row);

    expect(banner.id, 'b-1');
    expect(banner.title, 'Ưu đãi mùa bánh cưới');
    expect(banner.description, contains('bánh cưới'));
    expect(banner.imageUrl, '/images/cake-3.jpg');
    expect(banner.linkUrl, '/category/wedding');
    expect(banner.displayOrder, 1);
    expect(banner.isActive, isTrue);
  });

  test('parses a banner with every optional field null', () {
    const row = {
      'id': 'b-2',
      'title': 'T',
      'description': null,
      'imageUrl': null,
      'linkUrl': null,
      'displayOrder': 0,
      'isActive': false,
      'createdAt': '2026-03-09T16:48:47.983Z',
    };

    final banner = BannerAdminDto.fromJson(row);

    expect(banner.description, isNull);
    expect(banner.imageUrl, isNull);
    expect(banner.isActive, isFalse);
  });

  test('parses the notifications list envelope with pagination', () {
    const data = {
      'notifications': [
        {
          'id': 'n-1',
          'title': 'Order Update',
          'content': 'Đơn #BK của bạn đã được xác nhận.',
          'imageUrl': null,
          'linkUrl': 'http://localhost:3000/orders/BK1',
          'audience': 'USER',
          'targetUserId': 'u-1',
          'status': 'PUBLISHED',
          'createdAt': '2026-10-24T04:00:00.000Z',
        },
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 7, 'totalPages': 1},
    };

    final page = NotificationAdminListDto.fromJson(data);

    expect(page.items.single.title, 'Order Update');
    expect(page.items.single.status, NotificationStatus.published);
    expect(page.items.single.audience, 'USER');
    expect(page.total, 7);
    expect(page.totalPages, 1);
  });

  test('parses DRAFT and ARCHIVED statuses too', () {
    expect(
      NotificationAdminDto.fromJson({
        'id': 'x',
        'title': 't',
        'content': 'c',
        'status': 'DRAFT',
        'createdAt': '2026-01-01T00:00:00.000Z',
      }).status,
      NotificationStatus.draft,
    );
    expect(
      NotificationAdminDto.fromJson({
        'id': 'x',
        'title': 't',
        'content': 'c',
        'status': 'ARCHIVED',
        'createdAt': '2026-01-01T00:00:00.000Z',
      }).status,
      NotificationStatus.archived,
    );
  });

  test('parses a static page row (content verbatim)', () {
    const row = {
      'id': 'p-1',
      'title': 'Về chúng tôi',
      'slug': 've-chung-toi',
      'content': 'Dòng 1\n\nDòng 2 sau xuống dòng trống.',
      'isPublished': true,
      'createdAt': '2026-03-01T00:00:00.000Z',
    };

    final page = PageAdminDto.fromJson(row);

    expect(page.title, 'Về chúng tôi');
    expect(page.slug, 've-chung-toi');
    expect(page.content, 'Dòng 1\n\nDòng 2 sau xuống dòng trống.');
    expect(page.isPublished, isTrue);
  });
}
