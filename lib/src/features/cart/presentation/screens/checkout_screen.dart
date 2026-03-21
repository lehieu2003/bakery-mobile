import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/features/orders/presentation/controllers/orders_view_model.dart';
import 'package:bakery_mobile/src/features/cart/presentation/controllers/cart_view_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _paymentMethods = <String>[
    'COD',
    'BANK_TRANSFER',
    'MOMO',
    'ZALOPAY',
  ];
  static final _vnPhoneRegex = RegExp(r'^(0|/+84)(3|5|7|8|9)/d{8}$');

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _paymentMethod = 'COD';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthViewModel>();
    _nameCtrl.text = _nameCtrl.text.isEmpty
        ? (auth.user?.name ?? '')
        : _nameCtrl.text;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    final auth = context.watch<AuthViewModel>();
    final orders = context.watch<OrdersViewModel>();

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
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Customer name',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Customer name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Customer phone',
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Customer address (optional)',
                      ),
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
    final normalized = text.replaceAll(RegExp(r'[/s.-]'), '');
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

    final result = await context.read<OrdersViewModel>().createOrder(
      customerName: _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim().replaceAll(RegExp(r'[/s.-]'), ''),
      customerEmail: email,
      customerAddress: _addressCtrl.text.trim(),
      paymentMethod: _paymentMethod,
      items: items.map((item) => item.toOrderItemPayload()).toList(),
    );

    if (!mounted || result == null) return;

    context.read<CartViewModel>().clear();

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


