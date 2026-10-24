import 'package:flutter_test/flutter_test.dart';

import 'package:bakery_mobile/src/features/admin/products/data/dtos/product_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';

/// Fixture mirrors the REAL server response of
/// `GET /api/admin/products/{id}` (captured 2026-10-24 against the dev
/// server): the payload is wrapped as `data.product`, money is a numeric
/// string, images carry `displayOrder`/`isPrimary`, categories are m2m
/// join rows, and `attributeAssignments` (when present) come as PER-VALUE
/// rows `{attributeId, valueId, attribute{}, value{}}`.
const _detailJson = {
  'success': true,
  'data': {
    'product': {
      'id': 'prod-1',
      'name': 'Bánh mousse chocolate',
      'slug': 'banh-mousse-chocolate',
      'description': 'Mousse chocolate 70% đậm vị.',
      'shortDescription': 'Mousse chocolate đậm vị',
      'price': '68000', // Decimal string — asNum must coerce.
      'comparePrice': '85000',
      'costPrice': null,
      'weight': null,
      'stock': 30,
      'isActive': true,
      'isFeatured': false,
      'images': [
        {
          'id': 'img-1',
          'productId': 'prod-1',
          'url': '/images/mousse-1.jpg',
          'altText': null,
          'displayOrder': 0,
          'isPrimary': true,
        },
        {
          'id': 'img-2',
          'productId': 'prod-1',
          'url': '/images/mousse-2.jpg',
          'altText': null,
          'displayOrder': 1,
          'isPrimary': false,
        },
      ],
      'variants': [
        {
          'id': 'var-1',
          'productId': 'prod-1',
          'name': 'Cỡ 6 inch',
          'sku': 'MOU-6',
          'price': '68000',
          'stock': 12,
        },
      ],
      'categories': [
        {
          'productId': 'prod-1',
          'categoryId': 'cat-banh',
          'category': {
            'id': 'cat-banh',
            'name': 'Bánh sinh nhật',
            'slug': 'birthday-cakes',
          },
        },
      ],
      // Per-value rows as the server stores them — two rows of the SAME
      // attribute must group into one assignment with two valueIds.
      'attributeAssignments': [
        {
          'id': 'as-1',
          'productId': 'prod-1',
          'attributeId': 'attr-mousse',
          'valueId': 'val-passion',
          'attribute': {'id': 'attr-mousse', 'name': 'Mousse Cheesecake'},
          'value': {'id': 'val-passion', 'value': 'Passion'},
        },
        {
          'id': 'as-2',
          'productId': 'prod-1',
          'attributeId': 'attr-mousse',
          'valueId': 'val-mango',
          'attribute': {'id': 'attr-mousse', 'name': 'Mousse Cheesecake'},
          'value': {'id': 'val-mango', 'value': 'Xoài'},
        },
      ],
    },
  },
};

void main() {
  test('parses the wrapped detail envelope (data.product)', () {
    final detail = AdminProductDetailDto.fromJson(_detailJson['data']! as Map<String, dynamic>);

    expect(detail.id, 'prod-1');
    expect(detail.name, 'Bánh mousse chocolate');
    expect(detail.slug, 'banh-mousse-chocolate');
    expect(detail.price, 68000.0); // string coerced
    expect(detail.comparePrice, 85000.0);
    expect(detail.stock, 30);
    expect(detail.isActive, isTrue);
    expect(detail.isFeatured, isFalse);
    expect(detail.shortDescription, 'Mousse chocolate đậm vị');
    expect(detail.description, 'Mousse chocolate 70% đậm vị.');
  });

  test('parses images (order + primary), variants and category ids', () {
    final detail = AdminProductDetailDto.fromJson(_detailJson['data']! as Map<String, dynamic>);

    expect(detail.images, hasLength(2));
    expect(detail.images[0].url, '/images/mousse-1.jpg');
    expect(detail.images[0].isPrimary, isTrue);
    expect(detail.images[1].isPrimary, isFalse);

    expect(detail.variants.single.name, 'Cỡ 6 inch');
    expect(detail.variants.single.sku, 'MOU-6');
    expect(detail.variants.single.price, 68000.0);
    expect(detail.variants.single.stock, 12);

    expect(detail.categoryIds, ['cat-banh']);
  });

  test('groups per-value assignment rows into one attribute → valueIds set', () {
    final detail = AdminProductDetailDto.fromJson(_detailJson['data']! as Map<String, dynamic>);

    final assignments = detail.assignments;
    expect(assignments, hasLength(1));
    expect(assignments.first.attributeId, 'attr-mousse');
    expect(
      assignments.first.valueIds,
      containsAll(['val-passion', 'val-mango']),
    );
    expect(assignments.first.valueIds, hasLength(2));
  });

  test('parses the attribute catalogue with values', () {
    const json = {
      'attributes': [
        {
          'id': 'attr-mousse',
          'name': 'Mousse Cheesecake',
          'type': 'MULTI_SELECT',
          'values': [
            {'id': 'val-passion', 'value': 'Passion', 'label': 'Passion'},
            {'id': 'val-mango', 'value': 'Xoài', 'label': 'Xoài'},
          ],
        },
        {
          'id': 'attr-size',
          'name': 'Kích cỡ',
          'type': 'SELECT',
          'values': [
            {'id': 'val-s', 'value': 'Nhỏ', 'label': 'Nhỏ'},
          ],
        },
      ],
    };

    final attrs = ProductAttributeCatalogueDto.fromJson(json);

    expect(attrs, hasLength(2));
    expect(attrs.first.name, 'Mousse Cheesecake');
    expect(attrs.first.type, AttributeType.multiSelect);
    expect(attrs.first.values.map((v) => v.label), ['Passion', 'Xoài']);
    expect(attrs.last.type, AttributeType.select);
  });

  test('AdminProductDetailAssignment accepts wire valueIds arrays too', () {
    // Defensive: the POST/PUT side sends {attributeId, valueIds}; if the
    // detail ever echoes that shape, parse it as-is.
    const row = {
      'attributeId': 'attr-size',
      'valueIds': ['val-s'],
    };

    final parsed = AdminProductDetailAssignment.fromJson(row);

    expect(parsed.attributeId, 'attr-size');
    expect(parsed.valueIds, ['val-s']);
  });
}
