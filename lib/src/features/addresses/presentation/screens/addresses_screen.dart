import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/widgets/app_text_input.dart';
import 'package:bakery_mobile/src/features/addresses/domain/models/address.dart';

/// Same VN phone rule the checkout form and the server enforce.
final _vnPhoneRegex = RegExp(r'^(0|\+84)(3|5|7|8|9)\d{8}$');

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addressesViewModelProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(addressesViewModelProvider);
    final notifier = ref.read(addressesViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('Sổ địa chỉ (${vm.items.length})')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddressForm(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Thêm địa chỉ'),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          children: [
            if (vm.isLoading && vm.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!vm.isLoading && vm.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.location_off_outlined, size: 42),
                    const SizedBox(height: 10),
                    const Text('Bạn chưa có địa chỉ nào.'),
                    const SizedBox(height: 4),
                    Text(
                      'Thêm địa chỉ để chọn nhanh khi đặt hàng giao tận nơi.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ...vm.items.map(
              (address) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AddressCard(
                  address: address,
                  isPending: vm.pendingId == address.id,
                  onEdit: () => _openAddressForm(existing: address),
                  onSetDefault: () =>
                      _setDefault(address, isPending: vm.pendingId != null),
                  onDelete: () =>
                      _confirmDelete(address, isPending: vm.pendingId != null),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDefault(Address address, {required bool isPending}) async {
    if (isPending) return;
    final ok = await ref
        .read(addressesViewModelProvider.notifier)
        .setDefault(address.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Đã đặt làm địa chỉ mặc định.' : 'Không thể đặt địa chỉ mặc định.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    Address address, {
    required bool isPending,
  }) async {
    if (isPending) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa địa chỉ?'),
          content: Text('Địa chỉ của ${address.fullName} sẽ bị xóa.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(addressesViewModelProvider.notifier)
        .delete(address.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Đã xóa địa chỉ.' : 'Không thể xóa địa chỉ.'),
      ),
    );
  }

  Future<void> _openAddressForm({Address? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressFormSheet(existing: existing),
    );
    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null ? 'Đã thêm địa chỉ mới.' : 'Đã cập nhật địa chỉ.',
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isPending,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final Address address;
  final bool isPending;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    address.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Mặc định',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(address.phone),
            const SizedBox(height: 2),
            Text(address.addressLine, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: isPending ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Sửa'),
                ),
                const SizedBox(width: 8),
                if (!address.isDefault)
                  OutlinedButton.icon(
                    onPressed: isPending ? null : onSetDefault,
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Đặt mặc định'),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: isPending ? null : onDelete,
                  icon: isPending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.delete_outline, color: colorScheme.error),
                  tooltip: 'Xóa địa chỉ',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  const _AddressFormSheet({this.existing});

  final Address? existing;

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  static const _maxFieldLength = 200;

  final _formKey = GlobalKey<FormState>();
  late final _fullNameCtrl = TextEditingController(
    text: widget.existing?.fullName ?? '',
  );
  late final _phoneCtrl = TextEditingController(
    text: widget.existing?.phone ?? '',
  );
  late final _streetCtrl = TextEditingController(
    text: widget.existing?.street ?? '',
  );
  late final _wardCtrl = TextEditingController(text: widget.existing?.ward ?? '');
  late final _districtCtrl = TextEditingController(
    text: widget.existing?.district ?? '',
  );
  late final _provinceCtrl = TextEditingController(
    text: widget.existing?.province ?? '',
  );
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _wardCtrl.dispose();
    _districtCtrl.dispose();
    _provinceCtrl.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Vui lòng nhập $label';
    if (text.length > _maxFieldLength) {
      return '$label tối đa $_maxFieldLength ký tự';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Vui lòng nhập số điện thoại';
    final normalized = text.replaceAll(RegExp(r'[\s.-]'), '');
    if (normalized.length > _maxFieldLength) {
      return 'Số điện thoại tối đa $_maxFieldLength ký tự';
    }
    if (!_vnPhoneRegex.hasMatch(normalized)) {
      return 'Số điện thoại chưa hợp lệ';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final vm = ref.read(addressesViewModelProvider.notifier);
    final existing = widget.existing;
    bool ok;
    if (existing == null) {
      final created = await vm.add(
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        ward: _wardCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        province: _provinceCtrl.text.trim(),
      );
      ok = created != null;
    } else {
      ok = await vm.update(
        existing.id,
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        ward: _wardCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        province: _provinceCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSaving = false;
      _errorMessage = ref.read(addressesViewModelProvider).error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null
                    ? 'Thêm địa chỉ mới'
                    : 'Sửa địa chỉ',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              AppTextInput(
                controller: _fullNameCtrl,
                labelText: 'Họ và tên',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) => _validateRequired(value, 'họ và tên'),
              ),
              const SizedBox(height: 12),
              AppTextInput(
                controller: _phoneCtrl,
                labelText: 'Số điện thoại',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: _validatePhone,
              ),
              const SizedBox(height: 12),
              AppTextInput(
                controller: _streetCtrl,
                labelText: 'Số nhà, tên đường',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.home_outlined),
                validator: (value) => _validateRequired(value, 'số nhà, tên đường'),
              ),
              const SizedBox(height: 12),
              AppTextInput(
                controller: _wardCtrl,
                labelText: 'Phường / Xã',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.location_city_outlined),
                validator: (value) => _validateRequired(value, 'phường / xã'),
              ),
              const SizedBox(height: 12),
              AppTextInput(
                controller: _districtCtrl,
                labelText: 'Quận / Huyện',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.map_outlined),
                validator: (value) => _validateRequired(value, 'quận / huyện'),
              ),
              const SizedBox(height: 12),
              AppTextInput(
                controller: _provinceCtrl,
                labelText: 'Tỉnh / Thành phố',
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.public_outlined),
                validator: (value) =>
                    _validateRequired(value, 'tỉnh / thành phố'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu địa chỉ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
