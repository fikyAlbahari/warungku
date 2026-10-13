import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Sumber kebenaran untuk isi keranjang.
///
/// Sifat penting: keranjang TIDAK consulting server saat tambah/kurang. Harga
/// dan nama di sini hanya untuk tampilan; saat checkout, server menghitung
/// ulang dari database. Jadi harga di HP tidak pernah bisa jadi sumber kebenaran.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  /// Jumlah unit barang, bukan jumlah baris. Badge di app bar memakai ini.
  int get totalQty => _items.fold(0, (sum, item) => sum + item.qty);

  int get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  int get shippingCost => isEmpty ? 0 : ApiConfig.defaultShippingCost;

  int get total => subtotal + shippingCost;

  /// Baris yang jumlahnya melebihi stok yang tampil di katalog.
  List<CartItem> get itemsExceedingStock =>
      _items.where((item) => item.exceedsStock).toList();

  int qtyOf(int productId) {
    final match = _items.where((item) => item.product.id == productId);
    return match.isEmpty ? 0 : match.first.qty;
  }

  bool contains(int productId) => qtyOf(productId) > 0;

  void add(Product product, {int qty = 1}) {
    if (!product.isAvailable) return;

    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index == -1) {
      _items.add(CartItem(product: product, qty: qty));
    } else {
      _items[index].qty += qty;
    }

    notifyListeners();
  }

  /// Mengurangi satu. Menghapus baris otomatis saat qty menyentuh 0, supaya
  /// keranjang tidak pernah menampilkan baris dengan jumlah 0.
  void decrease(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;

    if (_items[index].qty <= 1) {
      _items.removeAt(index);
    } else {
      _items[index].qty -= 1;
    }

    notifyListeners();
  }

  void setQty(int productId, int qty) {
    if (qty <= 0) {
      remove(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;

    _items[index].qty = qty;
    notifyListeners();
  }

  void remove(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  /// Dipanggil setelah order berhasil dibuat supaya keranjang mulai kosong.
  void clearAfterCheckout() => clear();
}
