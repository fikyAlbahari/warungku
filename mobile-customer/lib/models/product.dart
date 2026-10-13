class Category {
  const Category({required this.id, required this.name, required this.slug});

  final int id;
  final String name;
  final String slug;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.priceJual,
    required this.stock,
    required this.unit,
    this.sku,
    this.description,
    this.imageUrl,
    this.category,
  });

  final int id;
  final String name;
  final String? sku;
  final String? description;
  final int priceJual;
  final int stock;
  final String unit;
  final String? imageUrl;
  final Category? category;

  bool get isAvailable => stock > 0;

  /// Sisa stok untuk_flash sale, dipakai sebagai batas tombol tambah.
  bool get isNearOut => stock > 0 && stock <= 5;

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];

    return Product(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      sku: json['sku']?.toString(),
      description: json['description']?.toString(),
      priceJual: _toInt(json['price_jual']),
      stock: _toInt(json['stock']),
      unit: (json['unit'] ?? 'pcs').toString(),
      imageUrl: json['image_url']?.toString(),
      category: rawCategory is Map<String, dynamic>
          ? Category.fromJson(rawCategory)
          : null,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return double.tryParse(value)?.round() ?? 0;
  return 0;
}
