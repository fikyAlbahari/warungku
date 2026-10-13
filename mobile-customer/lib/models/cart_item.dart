import 'product.dart';

/// Satu baris di keranjang. Menyimpan [Product] penuh supaya nama, harga, dan
/// gambar tetap tampil meski katalog di-refresh.
class CartItem {
  CartItem({required this.product, required this.qty});

  final Product product;
  int qty;

  int get subtotal => product.priceJual * qty;

  /// Jumlah melebihi stok siap. Checkout tetap boleh dikirim, tapi UI
  /// memperingatkan karena stok baru dipotong saat kasir memproses pesanan.
  bool get exceedsStock => qty > product.stock;

  CartItem copyWith({int? qty}) {
    return CartItem(product: product, qty: qty ?? this.qty);
  }
}
