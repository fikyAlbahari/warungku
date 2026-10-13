import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';

/// Mengatur satu proses submit pesanan.
///
/// Sengaja dipisah dari CartProvider supaya tombol checkout bisa menampilkan
/// spinner tanpa memicu rebuild seluruh isi keranjang.
class CheckoutProvider extends ChangeNotifier {
  CheckoutProvider(this._api);

  final ApiService _api;

  bool _isSubmitting = false;

  /// Pesan error umum. Untuk error validasi per-field, baca [ApiException.errorFor].
  String? _error;

  Map<String, List<String>> _fieldErrors = const {};

  Order? _lastOrder;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  /// Nota yang baru saja dibuat, dipakai halaman sukses untuk menampilkan
  /// nomor nota tanpa fetch ulang.
  Order? get lastOrder => _lastOrder;

  String? errorFor(String field) {
    final messages = _fieldErrors[field];
    if (messages == null || messages.isEmpty) return null;
    return messages.first;
  }

  void reset() {
    _isSubmitting = false;
    _error = null;
    _fieldErrors = const {};
    _lastOrder = null;
    notifyListeners();
  }

  /// Mengirim pesanan. Mengembalikan order bila berhasil, null bila gagal.
  /// Galat di sini sengaja dilempar sebagai nilai balik, bukan exception,
  /// supaya UI bisa menampilkannya tanpa try/catch di setiap pemanggil.
  Future<Order?> submit({
    required List<CartItem> items,
    required String shippingAddress,
    required String paymentMethod,
    String? note,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _error = null;
    _fieldErrors = const {};
    _lastOrder = null;
    notifyListeners();

    try {
      final order = await _api.checkout(
        items: items,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        note: note,
      );

      _lastOrder = order;
      return order;
    } on ApiException catch (e) {
      _error = e.message;
      _fieldErrors = e.fieldErrors;
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
