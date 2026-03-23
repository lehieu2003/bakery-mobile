import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/widgets/app_text_input.dart';
import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  static const _paymentMethods = <String>[
    'COD',
    'BANK_TRANSFER',
    'MOMO',
    'ZALOPAY',
  ];
  static final _vnPhoneRegex = RegExp(r'^(0|\+84)(3|5|7|8|9)\d{8}$');
  static const _nameDraftKey = 'checkout_draft_name';
  static const _phoneDraftKey = 'checkout_draft_phone';
  static const _addressDraftKey = 'checkout_draft_address';

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _paymentMethod = 'COD';
  SharedPreferences? _prefs;

  @override
  void dispose() {
    _nameCtrl.removeListener(_saveDraft);
    _phoneCtrl.removeListener(_saveDraft);
    _addressCtrl.removeListener(_saveDraft);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_saveDraft);
    _phoneCtrl.addListener(_saveDraft);
    _addressCtrl.addListener(_saveDraft);
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final auth = ref.read(authViewModelProvider);
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString(_nameDraftKey) ?? '';
    final savedPhone = prefs.getString(_phoneDraftKey) ?? '';
    final savedAddress = prefs.getString(_addressDraftKey) ?? '';
    if (!mounted) return;

    _prefs = prefs;
    _nameCtrl.text = savedName.isNotEmpty ? savedName : (auth.user?.name ?? '');
    _phoneCtrl.text = savedPhone;
    _addressCtrl.text = savedAddress;
  }

  void _saveDraft() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(_nameDraftKey, _nameCtrl.text.trim());
    prefs.setString(_phoneDraftKey, _phoneCtrl.text.trim());
    prefs.setString(_addressDraftKey, _addressCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartViewModelProvider);
    final auth = ref.watch(authViewModelProvider);
    final orders = ref.watch(ordersViewModelProvider);

    if (cart.items.isEmpty) {
      return const Scaffold(body: Center(child: Text('Cart is empty')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextInput(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      labelText: 'Customer name',
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Customer name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextInput(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      labelText: 'Customer phone',
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),
                    AppTextInput(
                      controller: _addressCtrl,
                      minLines: 2,
                      maxLines: 3,
                      labelText: 'Customer address (optional)',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paymentMethods
                          .map(
                            (method) => ChoiceChip(
                              label: Text(method),
                              selected: _paymentMethod == method,
                              onSelected: orders.isCreatingOrder
                                  ? null
                                  : (_) =>
                                        setState(() => _paymentMethod = method),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...cart.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity} x ${item.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('${item.lineTotal.toStringAsFixed(0)} VND'),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${cart.subtotal.toStringAsFixed(0)} VND',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: orders.isCreatingOrder
                  ? null
                  : () =>
                        _placeOrder(items: cart.items, email: auth.user?.email),
              child: orders.isCreatingOrder
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Creating order...'),
                      ],
                    )
                  : const Text('Place order'),
            ),
            if (orders.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                orders.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Customer phone is required';
    final normalized = text.replaceAll(RegExp(r'[\s.-]'), '');
    if (!_vnPhoneRegex.hasMatch(normalized)) {
      return 'Please enter a valid Vietnamese phone number';
    }
    return null;
  }

  Future<void> _placeOrder({
    required List<CartItem> items,
    required String? email,
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = await ref
        .read(ordersViewModelProvider.notifier)
        .createOrder(
          customerName: _nameCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim().replaceAll(
            RegExp(r'[\s.-]'),
            '',
          ),
          customerEmail: email,
          customerAddress: _addressCtrl.text.trim(),
          paymentMethod: _paymentMethod,
          items: items.map((item) => item.toOrderItemPayload()).toList(),
        );

    if (!mounted || result == null) return;

    ref.read(cartViewModelProvider.notifier).clear();

    await _showOrderResultDialog(result);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showOrderResultDialog(CreateOrderResult result) async {
    final title = result.paymentUrl != null
        ? 'Order created - payment required'
        : 'Order created successfully';
    final detailLines = <String>[
      'Order number: ${result.order.orderNumber}',
      'Status: ${result.order.status}',
      if (result.paymentError != null && result.paymentError!.isNotEmpty)
        'Payment warning: ${result.paymentError}',
    ];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...detailLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(line),
                ),
              ),
              if (result.paymentUrl != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Payment URL',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                SelectableText(result.paymentUrl!),
              ],
            ],
          ),
          actions: [
            if (result.paymentUrl != null)
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: result.paymentUrl!),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment URL copied')),
                    );
                  }
                },
                child: const Text('Copy payment URL'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
