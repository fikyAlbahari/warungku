import 'package:flutter/foundation.dart' hide Category;

import '../models/order.dart';
import '../models/product.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';

/// Memuat katalog: daftar kategori + produk.
///
/// Menyimpan [isLoadingMore] supaya tombol "Muat lagi" tidak muncul saat
/// sedang append halaman berikutnya.
class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._api);

  final ApiService _api;

  final List<Product> _products = [];
  final List<Category> _categories = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingCategories = false;

  // Kategori dan produk punya pesan kesalahan yang terpisah. Kalau keduanya
  // berbagi satu field, request kategori yang selesai belakangan akan menghapus
  // pesan gagal dari request produk: katalog yang gagal dimuat lalu tampil
  // sebagai "Belum ada produk", padahal masalahnya adalah jaringan.
  String? _error;
  String? _categoriesError;

  String? _search;
  String? _categorySlug;
  int _currentPage = 1;
  int _lastPage = 1;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get error => _error;
  String? get categoriesError => _categoriesError;

  List<Product> get products => List.unmodifiable(_products);
  List<Category> get categories => List.unmodifiable(_categories);

  String? get activeCategorySlug => _categorySlug;
  String? get search => _search;

  bool get hasNextPage => _currentPage < _lastPage;

  bool get isEmpty => _products.isEmpty && !_isLoading;

  /// Dipakai widget untuk membedakan "katalog kosong" dari "kategori ini kosong".
  bool get hasActiveFilter =>
      (_categorySlug != null && _categorySlug!.isNotEmpty) ||
      (_search != null && _search!.isNotEmpty);

  Future<void> loadCategories() async {
    if (_isLoadingCategories) return;
    _isLoadingCategories = true;
    notifyListeners();

    try {
      _categories
        ..clear()
        ..addAll(await _api.fetchCategories());
      _categoriesError = null;
    } on ApiException catch (e) {
      _categoriesError = e.message;
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
    } else if (_isLoadingMore) {
      return;
    }

    _isLoading = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      final page = await _api.fetchProducts(
        search: _search,
        categorySlug: _categorySlug,
        page: _currentPage,
      );

      _products
        ..clear()
        ..addAll(page.products);

      _currentPage = page.currentPage;
      _lastPage = page.lastPage;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasNextPage) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage += 1;
      final page = await _api.fetchProducts(
        search: _search,
        categorySlug: _categorySlug,
        page: _currentPage,
      );

      // Guard: kalau server mengembalikan halaman kosong, jangan naikkan
      // _currentPage lagi atau nextPage akan menggantung.
      if (page.products.isEmpty) {
        _currentPage -= 1;
      } else {
        _products.addAll(page.products);
        _lastPage = page.lastPage;
      }
      _error = null;
    } on ApiException catch (e) {
      _currentPage -= 1;
      _error = e.message;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed == (_search ?? '')) return;

    _search = trimmed.isEmpty ? null : trimmed;
    await loadProducts(refresh: true);
  }

  Future<void> selectCategory(String? slug) async {
    if (slug == _categorySlug) return;

    _categorySlug = slug;
    await loadProducts(refresh: true);
  }

  Future<void> clearFilters() async {
    _search = null;
    _categorySlug = null;
    await loadProducts(refresh: true);
  }
}

/// Status pemuatan untuk daftar pesanan saya.
class OrderListProvider extends ChangeNotifier {
  OrderListProvider(this._api);

  final ApiService _api;

  final List<Order> _orders = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String? _statusFilter;

  int _currentPage = 1;
  int _lastPage = 1;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String? get statusFilter => _statusFilter;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get hasNextPage => _currentPage < _lastPage;

  Future<void> load({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
    } else if (_isLoadingMore) {
      return;
    }

    _isLoading = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      final page = await _api.fetchOrders(status: _statusFilter, page: _currentPage);
      _orders
        ..clear()
        ..addAll(page.orders);
      _currentPage = page.currentPage;
      _lastPage = page.lastPage;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasNextPage) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage += 1;
      final page = await _api.fetchOrders(status: _statusFilter, page: _currentPage);

      if (page.orders.isEmpty) {
        _currentPage -= 1;
      } else {
        _orders.addAll(page.orders);
        _lastPage = page.lastPage;
      }
      _error = null;
    } on ApiException catch (e) {
      _currentPage -= 1;
      _error = e.message;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> filterByStatus(String? status) async {
    if (status == _statusFilter) return;
    _statusFilter = status;
    await load(refresh: true);
  }

  /// Mengganti status satu order secara lokal setelah pembatalan berhasil,
  /// supaya daftar tidak perlu fetch ulang dari server.
  /// Membuang daftar pesanan yang sudah dimuat.
  ///
  /// Dipanggil setelah keluar dari akun. Tanpa ini, pesanan akun sebelumnya
  /// masih terlihat sampai halaman pesanan me-refresh sendiri, dan kalau
  /// pelanggan langsung masuk dengan akun lain, dia sempat melihat pesanan
  /// orang lain.
  void reset() {
    if (_orders.isEmpty && _error == null) return;

    _orders.clear();
    _error = null;
    _statusFilter = null;
    _currentPage = 1;
    _lastPage = 1;
    notifyListeners();
  }

  void markCancelled(int orderId) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return;

    _orders[index] = Order.fromJson({
      'id': _orders[index].id,
      'order_number': _orders[index].orderNumber,
      'status': 'dibatalkan',
      'total': _orders[index].total,
      'item_count': _orders[index].itemCount,
      'is_paid': false,
    });

    notifyListeners();
  }
}
