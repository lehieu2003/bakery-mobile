import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/widgets/app_text_input_widget.dart';
import 'package:bakery_mobile/src/features/addresses/domain/models/address.dart';
import 'package:bakery_mobile/src/features/addresses/presentation/controllers/addresses_view_model.dart';
import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/summary_row_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Mirrors the per-order limit in bakery-web app/api/incentives/preview.
const int _maxIncentiveCodes = 5;

/// Suggested incentive chips shown before the user types a code.
const int _incentivesShown = 4;

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
    'VNPAY',
  ];
  static const _paymentMethodLabels = <String, String>{
    'VNPAY': 'VNPAY (QR/ATM/Visa)',
  };
  static const _deliveryMethodLabels = <DeliveryMethod, String>{
    DeliveryMethod.pickup: 'Nhận tại tiệm',
    DeliveryMethod.delivery: 'Giao tận nơi',
  };
  static final _vnPhoneRegex = RegExp(r'^(0|\+84)(3|5|7|8|9)\d{8}$');
  static const _nameDraftKey = 'checkout_draft_name';
  static const _phoneDraftKey = 'checkout_draft_phone';
  static const _addressDraftKey = 'checkout_draft_address';

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _incentiveCtrl = TextEditingController();
  String _paymentMethod = 'COD';
  DeliveryMethod _deliveryMethod = DeliveryMethod.pickup;
  List<String> _selectedIncentiveCodes = const [];
  List<AvailableIncentive> _availableIncentives = const [];
  PreviewIncentiveResult? _previewPricing;
  bool _isLoadingIncentives = false;
  bool _isApplyingIncentive = false;
  String? _incentiveMessage;
  String? _incentiveError;
  SharedPreferences? _prefs;

  /// Id of the saved address picked from the radio list; null when the user
  /// types a manual address. Hand-editing the address text drops the id so
  /// the backend never snapshots a saved address for edited text.
  String? _selectedAddressId;
  String? _selectedAddressLine;

  @override
  void dispose() {
    _nameCtrl.removeListener(_saveDraft);
    _phoneCtrl.removeListener(_saveDraft);
    _addressCtrl.removeListener(_saveDraft);
    _addressCtrl.removeListener(_onAddressTextChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _incentiveCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_saveDraft);
    _phoneCtrl.addListener(_saveDraft);
    _addressCtrl.addListener(_saveDraft);
    _addressCtrl.addListener(_onAddressTextChanged);
    _restoreDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIncentivesAndPricing();
      _loadSavedAddresses();
    });
  }

  Future<void> _loadSavedAddresses() async {
    if (ref.read(authViewModelProvider).user == null) return;
    await ref.read(addressesViewModelProvider.notifier).load();
  }

  Future<void> _restoreDraft() async {
    final auth = ref.read(authViewModelProvider);
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString(_nameDraftKey) ?? '';
    final savedPhone = prefs.getString(_phoneDraftKey) ?? '';
    final savedAddress = prefs.getString(_addressDraftKey) ?? '';
    if (!mounted) return;

    _prefs = prefs;
    // Only non-empty drafts overwrite the fields: an empty draft must not
    // clobber a saved-address selection that was auto-filled in the meantime.
    if (savedName.isNotEmpty) {
      _nameCtrl.text = savedName;
    } else if ((auth.user?.name ?? '').isNotEmpty) {
      _nameCtrl.text = auth.user!.name!;
    }
    if (savedPhone.isNotEmpty) _phoneCtrl.text = savedPhone;
    if (savedAddress.isNotEmpty) _addressCtrl.text = savedAddress;
  }

  void _saveDraft() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(_nameDraftKey, _nameCtrl.text.trim());
    prefs.setString(_phoneDraftKey, _phoneCtrl.text.trim());
    prefs.setString(_addressDraftKey, _addressCtrl.text.trim());
  }

  /// Mirrors the web behavior: any hand edit that no longer matches the
  /// selected saved address line drops the addressId.
  void _onAddressTextChanged() {
    if (_selectedAddressId == null) return;
    final current = _addressCtrl.text.trim();
    if (current != (_selectedAddressLine ?? '').trim()) {
      setState(() {
        _selectedAddressId = null;
        _selectedAddressLine = null;
      });
    }
  }

  void _selectAddress(Address address) {
    final line = address.addressLine;
    setState(() {
      _selectedAddressId = address.id;
      _selectedAddressLine = line;
      _nameCtrl.text = address.fullName;
      _phoneCtrl.text = address.phone;
      _addressCtrl.text = line;
    });
  }

  void _handleAddressesChanged(AddressesState next) {
    // Drop a selection whose address disappeared (deleted in the address
    // book, or on sign-out).
    if (_selectedAddressId != null &&
        !next.items.any((item) => item.id == _selectedAddressId)) {
      setState(() {
        _selectedAddressId = null;
        _selectedAddressLine = null;
      });
      return;
    }
    // Pre-select the default (or first) saved address, but never clobber a
    // restored draft or typed text.
    if (_selectedAddressId == null &&
        _addressCtrl.text.trim().isEmpty &&
        next.items.isNotEmpty) {
      final selected = next.defaultOrFirst();
      if (selected != null) _selectAddress(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartViewModelProvider);
    final auth = ref.watch(authViewModelProvider);
    final orders = ref.watch(ordersViewModelProvider);
    final addresses = ref.watch(addressesViewModelProvider);
    ref.listen(addressesViewModelProvider, (_, next) {
      _handleAddressesChanged(next);
    });
    final subtotal = cart.subtotal;
    final pricing = _previewPricing;
    final membershipDiscount = pricing?.membershipDiscount ?? 0;
    final couponDiscount = pricing?.couponDiscount ?? 0;
    final total = pricing?.total ?? subtotal;
    final isDelivery = _deliveryMethod == DeliveryMethod.delivery;
    // The charged total must never exceed the displayed one: a delivery order
    // waits for the fee-aware preview before it can be placed.
    final isPricingPending =
        _isLoadingIncentives ||
        _isApplyingIncentive ||
        (isDelivery && pricing == null);
    final canPlaceOrder = !orders.isCreatingOrder && !isPricingPending;

    if (cart.items.isEmpty) {
      return const Scaffold(body: Center(child: Text('Cart is empty')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    AppTextInputWidget(
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
                    const Gap(AppSpacing.md),
                    AppTextInputWidget(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      labelText: 'Customer phone',
                      validator: _validatePhone,
                    ),
                    const Gap(AppSpacing.md),
                    Text(
                      'Hình thức nhận hàng',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        for (final method in DeliveryMethod.values)
                          ChoiceChip(
                            label: Text(_deliveryMethodLabels[method]!),
                            selected: _deliveryMethod == method,
                            onSelected: orders.isCreatingOrder
                                ? null
                                : (_) => _changeDeliveryMethod(method),
                          ),
                      ],
                    ),
                    const Gap(AppSpacing.md),
                    if (isDelivery &&
                        auth.user != null &&
                        addresses.items.isNotEmpty) ...[
                      Text(
                        'Địa chỉ đã lưu',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ...addresses.items.map(
                        (address) => RadioListTile<String>(
                          value: address.id,
                          groupValue: _selectedAddressId,
                          onChanged: orders.isCreatingOrder
                              ? null
                              : (_) => _selectAddress(address),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            address.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${address.phone}\n${address.addressLine}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                    ],
                    if (isDelivery)
                      AppTextInputWidget(
                        controller: _addressCtrl,
                        minLines: 2,
                        maxLines: 3,
                        labelText: 'Địa chỉ giao hàng',
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Vui lòng nhập địa chỉ giao hàng'
                            : null,
                      ),
                  ],
                ),
              ),
            ),
            const Gap(AppSpacing.md),
            _IncentivesCard(
              controller: _incentiveCtrl,
              selectedCodes: _selectedIncentiveCodes,
              availableIncentives: _availableIncentives,
              isLoading: _isLoadingIncentives,
              isApplying: _isApplyingIncentive,
              message: _incentiveMessage,
              error: _incentiveError,
              onApply: () => _applyIncentive(_incentiveCtrl.text),
              onApplyCode: _applyIncentive,
              onRemoveCode: _removeIncentive,
            ),
            const Gap(AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _paymentMethods
                          .map(
                            (method) => ChoiceChip(
                              label: Text(
                                _paymentMethodLabels[method] ?? method,
                              ),
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
            const Gap(AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    ...cart.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity} x ${item.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(formatVnd(item.lineTotal)),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    if (membershipDiscount > 0)
                      SummaryRowWidget(
                        variant: SummaryRowVariant.emphasis,
                        label: 'Membership saving',
                        value: '-${_formatMoney(membershipDiscount)}',
                        valueColor: AppTheme.warmBrown,
                      ),
                    if (couponDiscount > 0)
                      SummaryRowWidget(
                        variant: SummaryRowVariant.emphasis,
                        label: 'Coupon saving',
                        value: '-${_formatMoney(couponDiscount)}',
                        valueColor: AppTheme.warmBrown,
                      ),
                    if (isDelivery)
                      SummaryRowWidget(
                        label: 'Phí giao hàng',
                        value: pricing == null
                            ? '—'
                            : pricing.deliveryFee > 0
                            ? _formatMoney(pricing.deliveryFee)
                            : 'Miễn phí',
                      ),
                    if (isDelivery &&
                        pricing == null &&
                        !_isLoadingIncentives &&
                        !_isApplyingIncentive)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loadIncentivesAndPricing,
                          child: const Text(
                            'Không tải được phí giao hàng · Thử lại',
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          _formatMoney(total),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(AppSpacing.lg),
            FilledButton(
              onPressed: !canPlaceOrder
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
                        Gap(AppSpacing.md),
                        Text('Creating order...'),
                      ],
                    )
                  : const Text('Place order'),
            ),
            if (orders.errorMessage != null) ...[
              const Gap(AppSpacing.md),
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

    // Only signed-in users can reference a saved address; the server resolves
    // the addressId against the current user's address book. Pick-up orders
    // carry no address at all.
    final isLoggedIn = ref.read(authViewModelProvider).user != null;
    final isDelivery = _deliveryMethod == DeliveryMethod.delivery;
    final result = await ref
        .read(ordersViewModelProvider.notifier)
        .createOrder(
          customerName: _nameCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim().replaceAll(
            RegExp(r'[\s.-]'),
            '',
          ),
          customerEmail: email,
          customerAddress: isDelivery ? _addressCtrl.text.trim() : null,
          addressId: isDelivery && isLoggedIn ? _selectedAddressId : null,
          paymentMethod: _paymentMethod,
          deliveryMethod: _deliveryMethod,
          incentiveCodes: _selectedIncentiveCodes,
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
    // No status line: the create response carries none (a new order is
    // always PENDING), and a payment-init failure never reaches this dialog.
    final detailLines = <String>[
      'Order number: ${result.order.orderNumber}',
      if (result.appliedIncentives.isNotEmpty)
        'Savings: ${result.appliedIncentives.map((item) => '${item.code} -${_formatMoney(item.discount)}').join(', ')}',
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
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(line),
                ),
              ),
              if (result.paymentUrl != null) ...[
                const Gap(AppSpacing.sm),
                const Text(
                  'Payment URL',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Gap(AppSpacing.xs),
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
            if (result.paymentUrl != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
            if (result.paymentUrl != null)
              FilledButton.icon(
                onPressed: () => _openPaymentUrl(context, result.paymentUrl!),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Pay now'),
              )
            else
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openPaymentUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment URL is invalid')));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;

    if (opened) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open payment URL')));
  }

  Future<void> _loadIncentivesAndPricing() async {
    if (!mounted) return;
    final cart = ref.read(cartViewModelProvider);
    if (cart.items.isEmpty) return;

    setState(() {
      _isLoadingIncentives = true;
      _incentiveError = null;
    });

    try {
      final repository = ref.read(orderRepositoryProvider);
      final contextItems = _cartContextPayload(cart.items);
      final results = await Future.wait([
        repository.previewIncentives(
          deliveryMethod: _deliveryMethod,
          incentiveCodes: _selectedIncentiveCodes,
          items: contextItems,
        ),
        repository.getAvailableIncentives(
          subtotal: cart.subtotal,
          cart: contextItems,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _previewPricing = results[0] as PreviewIncentiveResult;
        _availableIncentives = results[1] as List<AvailableIncentive>;
        _isLoadingIncentives = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingIncentives = false;
        _incentiveError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _applyIncentive(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _incentiveError = 'Please enter an incentive code.';
        _incentiveMessage = null;
      });
      return;
    }

    final nextCodes = {..._selectedIncentiveCodes, code}.toList();
    if (nextCodes.length > _maxIncentiveCodes) {
      setState(
        () =>
            _incentiveError = 'You can apply up to $_maxIncentiveCodes codes.',
      );
      return;
    }

    await _previewCodes(nextCodes, successMessage: 'Applied $code.');
    if (mounted) _incentiveCtrl.clear();
  }

  Future<void> _removeIncentive(String code) async {
    final nextCodes = _selectedIncentiveCodes
        .where((item) => item != code)
        .toList();
    await _previewCodes(nextCodes, successMessage: 'Updated incentive codes.');
  }

  /// The fee depends on the method, so the quoted pricing is re-fetched; the
  /// stale one is dropped first so it can never be shown or ordered against.
  Future<void> _changeDeliveryMethod(DeliveryMethod method) async {
    if (method == _deliveryMethod) return;
    setState(() {
      _deliveryMethod = method;
      _previewPricing = null;
    });
    await _previewCodes(_selectedIncentiveCodes);
  }

  /// Re-prices the cart for [codes]; [successMessage] is shown only for an
  /// explicit coupon change.
  Future<void> _previewCodes(
    List<String> codes, {
    String? successMessage,
  }) async {
    final cart = ref.read(cartViewModelProvider);
    setState(() {
      _isApplyingIncentive = true;
      _incentiveError = null;
      _incentiveMessage = null;
    });

    try {
      final preview = await ref
          .read(orderRepositoryProvider)
          .previewIncentives(
            deliveryMethod: _deliveryMethod,
            incentiveCodes: codes,
            items: _cartContextPayload(cart.items),
          );
      if (!mounted) return;
      setState(() {
        _selectedIncentiveCodes = codes;
        _previewPricing = preview;
        _isApplyingIncentive = false;
        _incentiveMessage = successMessage == null
            ? null
            : codes.isEmpty
            ? 'Removed all incentive codes.'
            : '$successMessage Coupon saving: -${_formatMoney(preview.couponDiscount)}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isApplyingIncentive = false;
        _incentiveError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> _cartContextPayload(List<CartItem> items) {
    return items
        .map((item) => {'productId': item.productId, 'quantity': item.quantity})
        .toList();
  }

  String _formatMoney(double value) {
    return formatVnd(value);
  }
}

class _IncentivesCard extends StatelessWidget {
  const _IncentivesCard({
    required this.controller,
    required this.selectedCodes,
    required this.availableIncentives,
    required this.isLoading,
    required this.isApplying,
    required this.onApply,
    required this.onApplyCode,
    required this.onRemoveCode,
    this.message,
    this.error,
  });

  final TextEditingController controller;
  final List<String> selectedCodes;
  final List<AvailableIncentive> availableIncentives;
  final bool isLoading;
  final bool isApplying;
  final VoidCallback onApply;
  final ValueChanged<String> onApplyCode;
  final ValueChanged<String> onRemoveCode;
  final String? message;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: AppTheme.warmBrown,
                  size: 20,
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'Savings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const Gap(AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppTextInputWidget(
                    controller: controller,
                    textInputAction: TextInputAction.done,
                    labelText: 'Incentive code',
                    prefixIcon: const Icon(Icons.confirmation_num_outlined),
                    enabled: !isApplying,
                    onSubmitted: (_) => onApply(),
                  ),
                ),
                const Gap(AppSpacing.sm),
                FilledButton(
                  onPressed: isApplying ? null : onApply,
                  child: isApplying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
            if (selectedCodes.isNotEmpty) ...[
              const Gap(AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: selectedCodes
                    .map(
                      (code) => InputChip(
                        label: Text(code),
                        onDeleted: isApplying ? null : () => onRemoveCode(code),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (availableIncentives.isNotEmpty) ...[
              const Gap(AppSpacing.md),
              Text(
                'Available now',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.inkBrown,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: availableIncentives.take(_incentivesShown).map((
                  incentive,
                ) {
                  return ActionChip(
                    label: Text(_incentiveLabel(incentive)),
                    onPressed: isApplying
                        ? null
                        : () => onApplyCode(incentive.code),
                  );
                }).toList(),
              ),
            ],
            if (message != null) ...[
              const Gap(AppSpacing.sm),
              Text(
                message!,
                style: const TextStyle(
                  color: AppTheme.warmBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (error != null) ...[
              const Gap(AppSpacing.sm),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _incentiveLabel(AvailableIncentive incentive) {
    final value = incentive.type == 'PERCENTAGE'
        ? '${incentive.value.toStringAsFixed(0)}%'
        : formatVnd(incentive.value);
    return '${incentive.code} • $value';
  }
}
