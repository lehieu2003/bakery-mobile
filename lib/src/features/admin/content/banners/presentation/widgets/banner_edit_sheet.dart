import 'dart:convert' show base64Encode;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/domain/models/admin_banner.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/presentation/controllers/banners_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/widgets/product_images_section.dart'
    show imagePickerProvider;

/// Create/edit banner bottom sheet. New images upload lazily on save
/// (single image); existing hosted urls pass straight through.
Future<void> showBannerEditSheet(
  BuildContext context, {
  AdminBanner? banner,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BannerEditSheet(banner: banner),
  );
}

class _BannerEditSheet extends ConsumerStatefulWidget {
  const _BannerEditSheet({this.banner});

  final AdminBanner? banner;

  @override
  ConsumerState<_BannerEditSheet> createState() => _BannerEditSheetState();
}

class _BannerEditSheetState extends ConsumerState<_BannerEditSheet> {
  late final _title = TextEditingController(text: widget.banner?.title ?? '');
  late final _description = TextEditingController(
    text: widget.banner?.description ?? '',
  );
  late final _linkUrl = TextEditingController(
    text: widget.banner?.linkUrl ?? '',
  );
  late bool _isActive;
  String? _imageUrl;
  bool _isLocalPick = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isActive = widget.banner?.isActive ?? true;
    _imageUrl = widget.banner?.imageUrl;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _linkUrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picker = ref.read(imagePickerProvider);
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() {
      _imageUrl = picked.first.path;
      _isLocalPick = true;
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Tiêu đề không được để trống');
      return;
    }
    String? hostedUrl = _imageUrl;
    if (_isLocalPick && hostedUrl != null) {
      try {
        final bytes = File(hostedUrl).readAsBytesSync();
        hostedUrl = await _upload(base64Encode(bytes));
      } catch (_) {
        setState(() => _error = 'Tải ảnh lên thất bại — thử lại');
        return;
      }
    }
    final notifier = ref.read(bannersAdminViewModelProvider.notifier);
    final ok = await notifier.save(
      id: widget.banner?.id,
      title: _title.text.trim(),
      description: _description.text.trim(),
      imageUrl: hostedUrl,
      linkUrl: _linkUrl.text.trim().isEmpty ? null : _linkUrl.text.trim(),
      isActive: _isActive,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(
        () => _error = ref.read(bannersAdminViewModelProvider).error,
      );
    }
  }

  Future<String> _upload(String base64) async {
    return ref
        .read(uploadApiServiceProvider)
        .uploadImages(['data:image/jpeg;base64,$base64'])
        .then((urls) => urls.single);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(
      bannersAdminViewModelProvider,
    ).isSaving;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.banner == null ? 'Thêm banner' : 'Sửa banner',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Gap(16),
          Row(
            children: [
              GestureDetector(
                onTap: _pick,
                child: Container(
                  width: 96,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageUrl == null
                      ? const Icon(Icons.add_photo_alternate_outlined)
                      : _isLocalPick
                      ? Image.file(File(_imageUrl!), fit: BoxFit.cover)
                      : Image.network(_imageUrl!, fit: BoxFit.cover),
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Chọn ảnh banner'),
                ),
              ),
            ],
          ),
          const Gap(12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
          ),
          const Gap(12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
            maxLines: 2,
          ),
          const Gap(12),
          TextField(
            controller: _linkUrl,
            decoration: const InputDecoration(
              labelText: 'Liên kết (không bắt buộc)',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Đang hiện trên trang chủ'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const Gap(8),
          FilledButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
