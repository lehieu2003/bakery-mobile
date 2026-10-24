import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/controllers/product_form_view_model.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';

/// Gallery section of the product form: picks local images (deferred
/// upload — hosted at save time), shows existing server images, and lets
/// the admin set the primary shot or drop entries. Holds at most 10.
class ProductImagesSection extends ConsumerWidget {
  const ProductImagesSection({super.key, this.productId});

  final String? productId;

  static const int maxImages = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productFormViewModelProvider(productId));
    final vm = ref.read(productFormViewModelProvider(productId).notifier);
    final remaining = maxImages - state.images.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (var i = 0; i < state.images.length; i++)
              _ImageTile(
                image: state.images[i],
                onSetPrimary: () => vm.setPrimary(i),
                onRemove: () => vm.removeImage(i),
              ),
            if (remaining > 0)
              _AddTile(
                onTap: () async {
                  final picker = ref.read(imagePickerProvider);
                  final picked = await picker.pickMultiImage();
                  if (picked.isNotEmpty) {
                    vm.addLocalImages(picked.map((x) => x.path).toList());
                  }
                },
              ),
          ],
        ),
        const Gap(AppSpacing.sm),
        Text(
          state.images.isEmpty
              ? 'Chưa có ảnh — thêm tối đa $maxImages ảnh'
              : '${state.images.length}/$maxImages ảnh · chạm ảnh để đặt làm ảnh chính',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// `image_picker` facade so tests can override the picker.
final imagePickerProvider = Provider<ImagePickerFacade>(
  (ref) => ImagePickerFacade(),
);

/// Thin wrapper over ImagePicker (mockable in tests).
class ImagePickerFacade {
  Future<List<PickedFileLike>> pickMultiImage() async {
    // Wrapped lazily to keep this file importable in tests without the
    // plugin platform.
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    return files.map((f) => PickedFileLike(path: f.path)).toList();
  }
}

/// Minimal shape the section needs from a picked file.
class PickedFileLike {
  const PickedFileLike({required this.path});

  final String path;
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.image,
    required this.onSetPrimary,
    required this.onRemove,
  });

  final FormImage image;
  final VoidCallback onSetPrimary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onSetPrimary,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: image.isPrimary
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: image.isPrimary ? 3 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: image.isLocal
                ? Image.file(File(image.source), fit: BoxFit.cover)
                : AppNetworkImageWidget(url: image.source),
          ),
        ),
        if (image.isPrimary)
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Chính',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              minimumSize: const Size(28, 28),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined, size: 32),
      ),
    );
  }
}
