import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/settings/presentation/controllers/settings_admin_view_model.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// "Cài đặt" admin: flat store settings form (name, email, phone,
/// address, opening hours). Save PUTs the whole map.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _hours = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(settingsAdminViewModelProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _hours.dispose();
    super.dispose();
  }

  void _fillFromState(Map<String, String> values) {
    _name.text = values['store_name'] ?? '';
    _email.text = values['store_email'] ?? '';
    _phone.text = values['store_phone'] ?? '';
    _address.text = values['store_address'] ?? '';
    _hours.text = values['opening_hours'] ?? '';
  }

  Future<void> _save() async {
    final ok = await ref.read(settingsAdminViewModelProvider.notifier).save({
      'store_name': _name.text.trim(),
      'store_email': _email.text.trim(),
      'store_phone': _phone.text.trim(),
      'store_address': _address.text.trim(),
      'opening_hours': _hours.text.trim(),
    });
    if (mounted) {
      final state = ref.read(settingsAdminViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Đã lưu cài đặt' : (state.error ?? 'Lưu thất bại'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsAdminViewModelProvider);
    final vm = ref.read(settingsAdminViewModelProvider.notifier);

    if (!_initialized && state.values.isNotEmpty) {
      _initialized = true;
      _fillFromState(state.values);
    }

    if (state.isLoading && state.values.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null && state.values.isEmpty) {
      return Scaffold(
        body: ErrorRetryWidget(message: state.error!, onRetry: vm.load),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Tên cửa hàng',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: _hours,
              decoration: const InputDecoration(
                labelText: 'Giờ mở cửa (VD: 06:30 - 21:30)',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
            ),
            const Gap(AppSpacing.xl),
            FilledButton.icon(
              onPressed: state.isSaving ? null : _save,
              icon: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(state.isSaving ? 'Đang lưu…' : 'Lưu cài đặt'),
            ),
          ],
        ),
      ),
    );
  }
}
