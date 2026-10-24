/// Catalogue attribute shown in the "Bộ lọc sản phẩm" admin module.
class AdminCatalogueAttribute {
  const AdminCatalogueAttribute({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.values,
  });

  final String id;
  final String name;
  final String code;
  final String type;
  final List<AdminCatalogueValue> values;
}

class AdminCatalogueValue {
  const AdminCatalogueValue({required this.id, required this.label});

  final String id;
  final String label;
}
