class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.variantId,
    this.variantName,
  });

  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String? variantId;
  final String? variantName;

  double get lineTotal => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
      variantId: variantId,
      variantName: variantName,
    );
  }

  Map<String, dynamic> toOrderItemPayload() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}

