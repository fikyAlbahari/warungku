import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/checkout_draft_provider.dart';
import '../theme.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import '../widgets/swal.dart';
import 'checkout_page.dart';
import 'keranjang_page.dart';
import 'login_page.dart';
import 'pesanan_saya_page.dart';
import 'server_settings_page.dart';

/// Beranda pelanggan: blok hero, pencarian, filter kategori, lalu grid produk.
///
/// Seluruh halaman ini satu [CustomScrollView] berisi hero, kotak pencarian,
/// chip kategori, dan grid. Kalau hero dan chip dikunci di luar daftar memakai
/// `Column` + `Expanded`, layar pertama hanya menyisakan sedikit ruang untuk
/// produk, sehingga katalog terasa kosong padahal datanya sudah termuat.
class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalog = context.read<CatalogProvider>();
      catalog.loadCategories();
      catalog.loadProducts();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Muat halaman berikutnya sebelum pengguna benar-benar sampai bawah,
    // supaya daftar tidak pernah terlihat berhenti di tengah.
    final threshold = _scrollController.position.maxScrollExtent - 320;
    if (_scrollController.position.pixels >= threshold) {
      context.read<CatalogProvider>().loadMore();
    }
  }

  /// Menunda pencarian supaya tidak satu request per ketikan.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) context.read<CatalogProvider>().searchProducts(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  Future<void> _openCart() async {
    // Pengunjung belum masuk tidak boleh membuka keranjang: tanpa akun mereka
    // hanya bisa melihat katalog.
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      await _openLogin();
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      Swal.toastPeringatan(context, 'Keranjang masih kosong.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KeranjangPage()),
    );
  }

  /// Ketuk kartu produk langsung ke halaman pembayaran, tanpa lewat keranjang.
  ///
  /// Isi keranjang tidak boleh ikut berubah: pembayaran memakai daftar sendiri
  /// ([CheckoutDraftProvider]) yang hanya berisi produk itu. Kalau tidak begitu,
  /// badge keranjang naik sendiri padahal pelanggan tidak pernah memilih
  /// keranjang, dan isi keranjang bisa berbeda dari yang sebenarnya dibayar.
  Future<void> _openCheckout(Product product) async {
    // Pembayaran butuh akun (/api/orders di belakang Sanctum). Pengunjung
    // belum masuk diarahkan ke login dulu, bukan dibuka lalu gagal di akhir.
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      await _openLogin();
      return;
    }

    context.read<CheckoutDraftProvider>().startWithProduct(product);

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
  }

  Future<void> _openServerSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ServerSettingsPage()),
    );

    // Katalog mungkin gagal tadi karena alamat server salah; muat ulang agar
    // pengguna langsung melihat hasilnya setelah memperbaikinya.
    if (!mounted) return;
    final catalog = context.read<CatalogProvider>();
    if (catalog.products.isEmpty || catalog.error != null) {
      await catalog.loadCategories();
      await catalog.loadProducts(refresh: true);
    }
  }

  Future<void> _openLogin() => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginPage()),
  );

  /// Membuka panel akun: profil singkat, pintasan, dan keluar.
  ///
  /// Panel ini, bukan tombol langsung, karena "Keluar" adalah tindakan yang
  /// merusak sesi. Satu ketukan yang salah akan membuang token dan menyuruh
  /// pelanggan mengetik password lagi tanpa ada kesempatan untuk membatalkan.
  Future<void> _openAccount() async {
    final auth = context.read<AuthProvider>();

    // Belum login tidak ada akun yang bisa dibuka: langsung arahkan ke login
    // supaya tombol profil tidak jadi jalan buntu.
    if (!auth.isLoggedIn) {
      await _openLogin();
      return;
    }

    final action = await showModalBottomSheet<_AccountAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountSheet(auth: auth),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _AccountAction.logout:
        await _logout();
      case _AccountAction.orders:
        await _openOrders();
      case _AccountAction.settings:
        await _openServerSettings();
    }
  }

  Future<void> _logout() async {
    final confirmed = await Swal.konfirmasi(
      context,
      judul: 'Keluar dari akun?',
      pesan: 'Sesi di HP ini akan dihapus. Kamu perlu masuk lagi untuk '
          'melihat pesanan di akun ini.',
      teksYa: 'Keluar',
      teksTidak: 'Batal',
      berbahaya: true,
    );

    if (!confirmed || !mounted) return;

    // Provider diambil sebelum `await` logout: `logout()` menyentuh jaringan,
    // jadi `context` tidak boleh dipakai lagi sesudahnya.
    final auth = context.read<AuthProvider>();
    final orders = context.read<OrderListProvider>();

    await auth.logout();

    // Daftar pesanan milik akun sebelumnya tidak boleh masih tampil setelah
    // keluar: pesanan yang dimuat dari cache lokal akan terlihat seperti milik
    // akun yang baru masuk.
    orders.reset();

    if (!mounted) return;
    Swal.toastSukses(context, 'Kamu sudah keluar dari akun.');
  }

  Future<void> _openOrders() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      await _openLogin();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PesananSayaPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();
    final cartQty = context.select<CartProvider, int>((c) => c.totalQty);

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _HeroHeader(
              auth: auth,
              cartQty: cartQty,
              onOpenCart: _openCart,
              onOpenOrders: _openOrders,
              onOpenSettings: _openServerSettings,
              onOpenAccount: _openAccount,
            ),
          ),
          Expanded(
            child: _CatalogBody(
              controller: _scrollController,
              catalog: catalog,
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              onClearSearch: _clearSearch,
              onOpenSettings: _openServerSettings,
              onOpenCheckout: _openCheckout,
              isLoggedIn: auth.isLoggedIn,
              onRequireLogin: _openLogin,
            ),
          ),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        isLoggedIn: auth.isLoggedIn,
        cartQty: cartQty,
        onOpenOrders: _openOrders,
        onOpenCart: _openCart,
        onOpenLogin: _openLogin,
      ),
    );
  }
}

/// Blok atas beranda: sapaan, pintasan, dan ajakan belanja.
///
/// Sengaja bukan AppBar. AppBar untuk halaman katalog memaksa judul toko dan
/// ikon aksi berdesakan di satu baris sempit; dengan hero, pencarian bisa jadi
/// elemen utama dan tombol aksi diberi ruang yang layak.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.auth,
    required this.cartQty,
    required this.onOpenCart,
    required this.onOpenOrders,
    required this.onOpenSettings,
    required this.onOpenAccount,
  });

  final AuthProvider auth;
  final int cartQty;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.hero),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sapaan(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      auth.isLoggedIn ? auth.displayName : 'Warung Nara',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _HeroIconButton(
                icon: auth.isLoggedIn
                    ? Icons.person_outline_rounded
                    : Icons.login_rounded,
                tooltip: auth.isLoggedIn ? 'Akun saya' : 'Masuk',
                onTap: onOpenAccount,
              ),
              const SizedBox(width: 8),
              _HeroIconButton(
                icon: Icons.dns_outlined,
                tooltip: 'Koneksi server',
                onTap: onOpenSettings,
              ),
              // Pintasan pesanan dan keranjang hanya untuk yang sudah masuk.
              // Pengunjung tanpa akun cuma bisa melihat katalog, jadi kedua
              // ikon ini disembunyikan, bukan dibuka lalu menolak di dalam.
              if (auth.isLoggedIn) ...[
                const SizedBox(width: 8),
                _HeroIconButton(
                  icon: Icons.receipt_long_outlined,
                  tooltip: 'Pesanan saya',
                  onTap: onOpenOrders,
                ),
                const SizedBox(width: 8),
                _HeroIconButton(
                  icon: Icons.shopping_bag_outlined,
                  tooltip: 'Keranjang',
                  onTap: onOpenCart,
                  badge: cartQty,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            auth.isLoggedIn
                ? 'Mau belanja apa hari ini?'
                : 'Sembako fresh, diantar ke rumah.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }

  /// Sapaan menyesuaikan waktu hari supaya terasa personal, bukan label statis.
  String _sapaan() {
    if (!auth.isLoggedIn) return 'Selamat datang';

    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
}

/// Tombol ikon bulat di atas gradien hero.
///
/// Tombol app bar tidak dipakai ulang karena latar gradien menuntut versi
/// gelap: ikon putih di atas putih transparan, tanpa kotak solid yang akan
/// terlihat seperti tambalan.
class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                if (badge > 0)
                  Positioned(right: 3, top: 3, child: _CountBadge(count: badge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge jumlah barang, dipakai di hero dan navigasi bawah.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.card, width: 1.5),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          height: 1.25,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Hasil pilihan dari [_AccountSheet].
enum _AccountAction { orders, settings, logout }

/// Panel akun yang muncul dari bawah layar.
///
/// Isinya profil singkat, dua pintasan, dan tombol keluar. Ditaruh di sheet,
/// bukan dialog, karena isinya daftar aksi yang wajar ditutup dengan menggeser
/// ke bawah.
class _AccountSheet extends StatelessWidget {
  const _AccountSheet({required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    final email = user?['email']?.toString() ?? '-';

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.all(
            Radius.circular(AppRadius.hero),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titik seret di atas: penanda bahwa sheet bisa ditutup dengan
            // digeser, bukan hanya dengan tombol.
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
              child: Row(
                children: [
                  const _Avatar(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.outline),

            _SheetAction(
              icon: Icons.receipt_long_outlined,
              label: 'Pesanan saya',
              onTap: () => Navigator.of(context).pop(_AccountAction.orders),
            ),
            _SheetAction(
              icon: Icons.dns_outlined,
              label: 'Koneksi server',
              onTap: () => Navigator.of(context).pop(_AccountAction.settings),
            ),

            const Divider(height: 1, color: AppColors.outline),

            _SheetAction(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              // Merah karena ini satu-satunya aksi yang menghapus sesi di HP.
              color: AppColors.danger,
              onTap: () => Navigator.of(context).pop(_AccountAction.logout),
            ),

            // ruang jeda supaya baris terakhir tidak menempel tepi bawah
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// Lingkaran inisial di panel akun.
///
/// Inisial lebih cepat dibaca daripada ikon orang generik, dan tetap
/// membedakan dua akun yang berbeda hanya dari nama depan.
class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final name = context.read<AuthProvider>().displayName.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Satu baris aksi di panel akun.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigasi bawah melayang untuk tiga tujuan utama.
///
/// Kustom, bukan NavigationBar bawaan, karena baris bawaan memakai tinggi
/// tetap dan selalu menampilkan label. Di sini baris menempel ke bawah layar,
/// diberi bayangan ke atas, dan label tujuan aktif ditebalkan.
///
/// Pengunjung belum masuk hanya melihat katalog, jadi "Pesanan" dan
/// "Keranjang" diganti satu item "Masuk": tidak ada yang bisa dibuka tanpa
/// akun, dan jumlah item tetap genap supaya tata letaknya seimbang.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.isLoggedIn,
    required this.cartQty,
    required this.onOpenOrders,
    required this.onOpenCart,
    required this.onOpenLogin,
  });

  final bool isLoggedIn;
  final int cartQty;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        boxShadow: AppShadows.nav,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Expanded(
              child: _NavItem(
                icon: Icons.storefront_rounded,
                label: 'Beranda',
                selected: true,
              ),
            ),
            if (isLoggedIn) ...[
              Expanded(
                child: _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Pesanan',
                  onTap: onOpenOrders,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: 'Keranjang',
                  badge: cartQty,
                  onTap: onOpenCart,
                ),
              ),
            ] else
              Expanded(
                child: _NavItem(
                  icon: Icons.login_rounded,
                  label: 'Masuk',
                  onTap: onOpenLogin,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.selected = false,
    this.badge = 0,
    this.onTap,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textTertiary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? (activeIcon ?? icon) : icon,
                  size: 22,
                  color: color,
                ),
                if (badge > 0)
                  Positioned(
                    right: -9,
                    top: -5,
                    child: _CountBadge(count: badge),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badan katalog: pencarian, chip kategori, dan grid produk dalam satu daftar.
class _CatalogBody extends StatelessWidget {
  const _CatalogBody({
    required this.controller,
    required this.catalog,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenSettings,
    required this.onOpenCheckout,
    required this.isLoggedIn,
    required this.onRequireLogin,
  });

  final ScrollController controller;
  final CatalogProvider catalog;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenSettings;
  final ValueChanged<Product> onOpenCheckout;
  final bool isLoggedIn;
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final showSkeleton = catalog.isLoading && catalog.products.isEmpty;
    final showError = catalog.error != null && catalog.products.isEmpty;
    final showEmpty = !showSkeleton && !showError && catalog.products.isEmpty;

    return RefreshIndicator(
      onRefresh: () => catalog.loadProducts(refresh: true),
      child: CustomScrollView(
        controller: controller,
        // Katalog bisa muat satu baris saja di layar kecil. Tanpa
        // AlwaysScrollableScrollPhysics, tarikan untuk refresh tidak
        // terdeteksi karena tidak ada yang bisa digulir.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _SearchBar(
              controller: searchController,
              onChanged: onSearchChanged,
              onClear: onClearSearch,
            ),
          ),
          SliverToBoxAdapter(child: _CategoryFilter(catalog: catalog)),

          if (showSkeleton)
            const SliverToBoxAdapter(child: _CatalogSkeleton())
          else if (showError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.cloud_off,
                title: 'Gagal memuat katalog',
                message: catalog.error!,
                actionLabel: 'Atur Alamat Server',
                onAction: onOpenSettings,
              ),
            )
          else if (showEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: catalog.hasActiveFilter
                    ? Icons.search_off
                    : Icons.storefront_outlined,
                title: catalog.hasActiveFilter
                    ? 'Produk tidak ditemukan'
                    : 'Belum ada produk',
                message: catalog.hasActiveFilter
                    ? 'Coba kata kunci atau kategori lain.'
                    : 'Toko belum menambahkan produk.',
                actionLabel: catalog.hasActiveFilter ? 'Hapus filter' : null,
                onAction: catalog.hasActiveFilter ? catalog.clearFilters : null,
              ),
            )
          else ...[
            // Padding ditulis di sini, bukan di dalam SectionHeading, supaya
            // judul sejajar dengan kartu produk: grid pakai SliverPadding 16,
            // dan sliver lain harus memakai jarak tepi yang sama.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: SectionHeading(
                  catalog.hasActiveFilter ? 'Hasil Pencarian' : 'Semua Produk',
                  eyebrow: 'KATALOG',
                  subtitle: '${catalog.products.length} produk tersedia',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  // 2 kolom di HP, otomatis bertambah di layar lebar.
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  // Tinggi tetap dipakai, bukan tinggi children, supaya semua
                  // kartu sama tinggi dan grid tidak melompat saat produk
                  // dengan nama 1 baris dan 2 baris bercampur.
                  //
                  // Nilainya mengikuti isi kartu sekarang: foto, nama
                  // (sampai 2 baris), harga, lencana stok, dan baris aksi
                  // setinggi 36. [_CatalogSkeleton] memakai angka yang sama
                  // supaya tidak ada lompatan saat data selesai dimuat.
                  mainAxisExtent: 316,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(
                    product: catalog.products[index],
                    onOpenCheckout: () => onOpenCheckout(catalog.products[index]),
                    isLoggedIn: isLoggedIn,
                    onRequireLogin: onRequireLogin,
                  ),
                  childCount: catalog.products.length,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _ListFooter(catalog: catalog)),
          ],

          // Ruang untuk baris navigasi bawah. Tanpa ini, kartu terakhir akan
          // tertutup HomeBottomNav saat digulir sampai paling bawah.
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

/// Kotak pencarian berbentuk kapsul yang menempel di bawah hero.
///
/// Berlatar putih solid dan berbayang sendiri. Kalau ikut memakai putih
/// transparan seperti tombol hero, kontrasnya hilang karena latar di
/// belakang berganti antara gradien teal dan abu terang.
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.lifted,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 6),
          // Field dibuat tanpa border dan tanpa fill sendiri supaya yang
          // terlihat hanya bentuk kapsul dari container pembungkus.
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Cari beras, minyak, kopi...',
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (hasText)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: widget.onClear,
              splashRadius: 18,
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.catalog});

  final CatalogProvider catalog;

  @override
  Widget build(BuildContext context) {
    if (catalog.isLoadingCategories && catalog.categories.isEmpty) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Kalau kategori gagal dimuat, produknya sendiri masih bisa tampil. Karena
    // itu kegagalannya reported di baris chip saja, bukan dengan menggagalkan
    // seluruh halaman.
    if (catalog.categoriesError != null && catalog.categories.isEmpty) {
      return SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _Chip(
              label: 'Kategori gagal dimuat',
              icon: Icons.cloud_off_rounded,
              selected: true,
              onTap: () => catalog.loadCategories(),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'Semua',
            icon: Icons.grid_view_rounded,
            selected: catalog.activeCategorySlug == null,
            onTap: () => catalog.selectCategory(null),
          ),
          for (final category in catalog.categories)
            _Chip(
              label: category.name,
              selected: catalog.activeCategorySlug == category.slug,
              onTap: () => catalog.selectCategory(category.slug),
            ),
        ],
      ),
    );
  }
}

/// Chip filter kategori.
///
/// Yang aktif memakai isian primer pekat dan teks putih, bukan outline tipis.
/// Perbedaan kontras yang tinggi membuat kategori aktif langsung terbaca tanpa
/// harus membaca teksnya dulu.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: Material(
        color: selected ? AppColors.primary : AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder kotak selagi katalog dimuat. Bentuknya sengaja sama dengan
/// kartu produk supaya layout tidak melompat setelah data datang.
class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // Nilainya harus sama persis dengan grid katalog yang sebenarnya, kalau tidak
        // kartu akan melompat ke bawah tepat setelah skeleton hilang.
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 316,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: ColoredBox(color: AppColors.surfaceAlt)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bentuk placeholder mengikuti urutan isi kartu: nama,
                    // harga, lencana stok, baris aksi.
                    _Bar(width: double.infinity, height: 13),
                    const SizedBox(height: 6),
                    _Bar(width: 80, height: 16),
                    const SizedBox(height: 8),
                    _Bar(width: 74, height: 15),
                    const SizedBox(height: 10),
                    const _Bar(width: double.infinity, height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.catalog});

  final CatalogProvider catalog;

  @override
  Widget build(BuildContext context) {
    if (catalog.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!catalog.hasNextPage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
        child: Text(
          'Menampilkan ${catalog.products.length} produk',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return const SizedBox(height: 16);
  }
}