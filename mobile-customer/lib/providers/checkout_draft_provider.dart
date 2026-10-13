import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Asal isi draft pembayaran.
enum DraftSource {
  /// Pelanggan mengetuk satu kartu produk di katalog.
  catalog,

  /// Pelanggan membayar isi keranjang.
  cart,
}

/// Daftar barang yang sedang dibayar di halaman pembayaran.
///
/// Sengaja dipisah dari keranjang: mengetuk kartu produk harus langsung ke
/// pembayaran tanpa mengubah isi keranjang. Keranjang hanya berisi barang yang
/// ditambahkan dengan tombol "+" di katalog.
///
/// Sifat yang sama seperti keranjang berlaku: daftar ini tidak mengambil harga
/// dari server. Harga di HP hanya untuk tampilan, server menghitung ulang dari
/// database saat pesanan dibuat.
class CheckoutDraftProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  DraftSource _source = DraftSource.catalog;

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  /// True kalau draft ini berasal dari keranjang. Setelah pesanan berhasil,
  /// hanya keranjang yang perlu dikosongkan, bukan kalau asal dari katalog.
  bool get isFromCart => _source == DraftSource.cart;

  int get totalQty => _items.fold(0, (sum, item) => sum + item.qty);

  int get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  int get shippingCost => isEmpty ? 0 : ApiConfig.defaultShippingCost;

  int get total => subtotal + shippingCost;

  /// Memulai pembayaran untuk satu produk yang diketuk di katalog. Isi draft
  /// sebelumnya dibuang, karena yang dibayar hanya produk itu.
  void startWithProduct(Product product) {
    _items
      ..clear()
      ..add(CartItem(product: product, qty: 1));
    _source = DraftSource.catalog;
    notifyListeners();
  }

  /// Memulai pembayaran dari isi keranjang.
  ///
  /// Barisnya disalin, bukan dipakai langsung, supaya mengubah jumlah di
  /// halaman pembayaran tidak ikut mengubah keranjang di belakang layar.
  void startFromCart(List<CartItem> cartItems) {
    _items
      ..clear()
      ..addAll(
        cartItems.map((item) => CartItem(product: item.product, qty: item.qty)),
      );
    _source = DraftSource.cart;
    notifyListeners();
  }

  int qtyOf(int productId) {
    final match = _items.where((item) => item.product.id == productId);
    return match.isEmpty ? 0 : match.first.qty;
  }

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

  /// Mengurangi satu, dan menghapus barisnya saat jumlah menyentuh 0.
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

  void remove(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}