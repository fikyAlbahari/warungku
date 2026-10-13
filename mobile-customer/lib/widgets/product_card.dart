import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme.dart';
import '../utils/currency.dart';
import 'app_card.dart';

/// Kartu produk di katalog, dipakai di grid 2 kolom.
///
/// Tata letaknya foto di atas, lalu informasi singkat, lalu baris aksi selebar
/// kartu.
///
/// Kenapa baris aksi dibuat penuh dan tidak lagi berupa tombol lingkaran yang
/// menutupi foto: lingkaran mengambang menutupi bagian foto dan target
/// sentuhnya cuma 40 piksel, kecil untuk jari. Baris penuh mudah ditebak
/// ("ini tombol tambah ke keranjang"), mudah ditekan, dan keadaannya terbaca
/// sekilas.
///
/// Ketuk kartu langsung membuka halaman pembayaran untuk produk itu, tanpa
/// menyentuh keranjang. Baris aksi hanya berisi satu tombol keranjang selebar
/// kartu: satu ketukan menambah satu barang, ketukan lagi menambah lagi.
/// Mengubah jumlah (dan menambah/mengurangi) dilakukan di halaman Keranjang,
/// bukan di kartu. Dengan begitu kartu selalu tampil sama selama pelanggan
/// mengumpulkan barang sebelum membayar sekaligus dari halaman keranjang.
///
/// Pengunjung yang belum masuk hanya bisa melihat: baris aksi diganti tombol
/// "Masuk untuk beli" dan ketukan kartu membuka halaman login, bukan
/// pembayaran. Katalog tetap terbuka penuh tanpa akun.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onOpenCheckout,
    required this.isLoggedIn,
    required this.onRequireLogin,
  });

  final Product product;
  final VoidCallback onOpenCheckout;

  /// Benar kalau pengguna sudah punya sesi. Pengunjung tanpa sesi tidak boleh
  /// sampai ke keranjang maupun pembayaran.
  final bool isLoggedIn;

  /// Dipanggil saat pengunjung belum masuk menekan kartu atau tombol beli.
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final unavailable = !product.isAvailable;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: unavailable
          ? null
          : (isLoggedIn ? onOpenCheckout : onRequireLogin),
      border: Border.all(color: AppColors.outline),
      shadows: AppShadows.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Thumbnail(product: product),
                Positioned(
                  left: 8,
                  top: 8,
                  child: _CategoryBadge(name: product.category?.name),
                ),
                if (unavailable)
                  // Produk habis tetap ditampilkan supaya katalog tidak terlihat
                  // berlubang, tapi jelas tidak bisa dibeli.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.78),
                    ),
                    child: const Center(
                      child: AppPill(
                        'Stok Habis',
                        icon: Icons.remove_shopping_cart_outlined,
                        color: AppColors.textSecondary,
                        background: AppColors.card,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        formatRupiah(product.priceJual),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '/ ${product.unit}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _StockBadge(product: product),
                const SizedBox(height: 10),
                // Baris aksi. Tombol keranjang selebar kartu menambah satu
                // barang per ketukan. Pengunjung belum masuk tidak melihatnya:
                // mereka cuma bisa melihat harga.
                SizedBox(
                  width: double.infinity,
                  child: isLoggedIn
                      ? _CartAction(product: product)
                      // Produk habis tetap cuma ruang kosong: tidak ada gunanya
                      // menyuruh masuk untuk membeli barang yang tidak dijual.
                      : unavailable
                          ? const SizedBox(height: 38)
                          : _LoginAction(onTap: onRequireLogin),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Area foto produk.
///
/// Kalau produk tidak punya foto, isinya bukan kotak abu-abu datar: pakai
/// gradien lembut supaya kartu yang tanpa foto masih terasa bagian dari
/// tampilan, bukan elemen yang belum termuat.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final placeholder = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySoft, AppColors.surfaceAlt],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: AppColors.primary,
          size: 30,
        ),
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) return placeholder;

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      // Placeholder yang sama dipakai untuk kondisi "sedang memuat" dan "gagal
      // memuat", jadi kartu tidak pernah terlihat kosong sebentar lalu berubah
      // jadi ikon rusak.
      //
      // Katalog harus tetap tampil utuh walau satu foto gagal dimuat.
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded || frame != null) return child;
        return placeholder;
      },
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// Kategori sebagai lencana kecil di pojok kiri foto.
///
/// Letaknya di atas foto, bukan di baris teks, supaya baris bawah kartu bisa
/// dipakai nama dan harga tanpa jadi sempit.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final label = name?.trim() ?? '';
    if (label.isEmpty) return const SizedBox.shrink();

    return AppPill(
      label.toUpperCase(),
      dense: true,
      color: AppColors.textSecondary,
      background: AppColors.card.withValues(alpha: 0.92),
    );
  }
}

/// Lencana stok.
///
/// Bentuknya kapsul, bukan teks polos, karena "Tersisa 3 kg" adalah informasi
/// yang berubah-ubah dan perlukedip mata berbeda dari nama produk. Warna
/// ikut berubah: merah saat habis, kuning saat menipis, netral saat aman.
class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (!product.isAvailable) {
      return const AppPill(
        'Tidak tersedia',
        dense: true,
        icon: Icons.error_outline_rounded,
        color: AppColors.danger,
        background: AppColors.dangerSoft,
      );
    }

    if (product.isNearOut) {
      return AppPill(
        'Sisa ${product.stock} ${product.unit}',
        dense: true,
        icon: Icons.bolt_rounded,
        color: const Color(0xFFB45309),
        background: AppColors.accentSoft,
      );
    }

    return AppPill(
      '${product.stock} ${product.unit}',
      dense: true,
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.success,
      background: AppColors.successSoft,
    );
  }
}

/// Baris aksi keranjang: satu tombol keranjang selebar kartu.
///
/// Satu ketukan menambah satu barang, dan tombolnya tidak pernah menghilang
/// atau bergeser, jadi menambah barang berikutnya cukup mengetuk tempat yang
/// sama. Menambah/mengurangi jumlah lewat tombol [+] dan [-] dilakukan di
/// halaman Keranjang (dibuka lewat navigasi bawah), supaya kartu di katalog
/// tetap seragam dan ringkas tanpa penghitung.
class _CartAction extends StatelessWidget {
  const _CartAction({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (!product.isAvailable) {
      // Baris aksi tetap punya tinggi sama supaya baris stok dan harga tidak
      // meloncat ke atas untuk produk yang habis.
      return const SizedBox(height: 38);
    }

    return _AddButton(product: product);
  }
}

/// Tombol pengganti baris aksi untuk pengunjung yang belum masuk.
///
/// Tingginya 38 seperti [_CartAction], jadi tinggi kartu tidak berbeda antara
/// pengunjung dan pelanggan yang sudah masuk. Isinya cuma ajakan masuk: tidak
/// ada ikon keranjang sama sekali supaya tidak memberi kesan bisa belanja
/// dulu tanpa akun.
class _LoginAction extends StatelessWidget {
  const _LoginAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 6),
              // Flexible: kalau sistem memperbesar huruf (aksesibilitas) atau
              // kartu sempit, label memotong diri sendiri alih-alih meluap
              // dan memicu overflow.
              Flexible(
                child: Text(
                  'Masuk untuk beli',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol keranjang: menambah satu barang.
///
/// Bentuknya selebar kartu, bukan tombol lingkaran, supaya area sentuhnya besar
/// dan selalu bisa ditekan di tempat yang sama untuk menambah lagi.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final inCart = context.select<CartProvider, bool>((c) => c.contains(product.id));

    return _ActionShell(
      color: inCart ? AppColors.primarySoft : AppColors.primary,
      borderColor: inCart ? AppColors.primary.withValues(alpha: 0.24) : null,
      tooltip: 'Tambah ke keranjang',
      onTap: () {
        HapticFeedback.selectionClick();
        context.read<CartProvider>().add(product);
      },
      // Ikon keranjang, bukan ikon plus: yang ditebak orang di toko daring
      // adalah "masukkan ke keranjang", dan tombol ini memang melakukan
      // itu. Warna ikonyya dibalik saat barang sudah ada supaya tombol
      // terlihat "aktif" tanpa perlu badge angka.
      child: Icon(
        Icons.add_shopping_cart_rounded,
        size: 19,
        color: inCart ? AppColors.primaryDark : Colors.white,
      ),
    );
  }
}

/// Cangkang tombol [_AddButton].
///
/// Tinggi dan bentuknya standar supaya baris aksi selalu sama di semua kartu.
/// Seluruh permukaannya adalah area sentuh: ikon hanya hiasan di tengah. Kalau
/// area sentuh cuma selebar ikon, ketukan di tepi kapsul akan jatuh ke `InkWell`
/// kartu di baliknya dan terlampau membuka halaman pembayaran.
class _ActionShell extends StatelessWidget {
  const _ActionShell({
    required this.onTap,
    required this.child,
    this.color = AppColors.primary,
    this.borderColor,
    this.tooltip,
  });

  final VoidCallback onTap;
  final Widget child;
  final String? tooltip;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final inkWell = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        width: double.infinity,
        height: 38,
        child: Center(child: child),
      ),
    );

    return Container(
      width: double.infinity,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      // Tanpa padding: sekecil apapun area buta di dalam kapsul akan jatuh ke
      // InkWell kartu di belakangnya dan membuka halaman pembayaran. Area
      // sentuh harus menempel penuh dari tepi ke tepi kapsul.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: tooltip == null ? inkWell : Tooltip(message: tooltip!, child: inkWell),
      ),
    );
  }
}