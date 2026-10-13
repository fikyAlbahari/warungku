import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_draft_provider.dart';
import '../providers/checkout_provider.dart';
import '../theme.dart';
import '../utils/currency.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/swal.dart';
import 'login_page.dart';
import 'pesanan_saya_page.dart';

/// Formulir pembayaran. Alamat pengiriman wajib diisi karena backend mewajibkannya,
/// dan pilihan metode pembayaran menentukan apa yang dilihat kasir.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String _paymentMethod = 'tunai';

  static const _paymentOptions = <String, String>{
    'tunai': 'Bayar Tunai di Warung',
    'transfer': 'Transfer Bank',
    'qris': 'QRIS',
  };

  /// Ikon per metode bayar supaya pilihan lebih cepat dikenali sekilas.
  static const _paymentIcons = <String, IconData>{
    'tunai': Icons.payments_outlined,
    'transfer': Icons.account_balance_outlined,
    'qris': Icons.qr_code_2_rounded,
  };

  @override
  void initState() {
    super.initState();

    // Alamat dari profil dipakai sebagai nilai awal supaya pelanggan tidak
    // perlu mengetik ulang setiap kali memesan.
    final saved = context.read<AuthProvider>().savedAddress;
    if (saved != null && saved.isNotEmpty) {
      _addressController.text = saved;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final checkout = context.read<CheckoutProvider>();

    // 1. Cek form di HP dulu supaya tidak membuang request ke server.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 2. Wajib login. Endpoint /api/orders berada di balik auth:sanctum,
    //    jadi tanpa token server membalas 401.
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (loggedIn ?? false) return _submit();
      return;
    }

    final draft = context.read<CheckoutDraftProvider>();
    if (draft.isEmpty) {
      Swal.toastPeringatan(context, 'Keranjang kosong, pilih produk dulu.');
      return;
    }

    // Draft yang dikirim adalah salinan. Kalau server mengembalikan error,
    // isi pembayaran lokal tidak boleh ikut berubah di tengah proses.
    final items = draft.items
        .map((CartItem item) => CartItem(product: item.product, qty: item.qty))
        .toList();

    // Ditandai dulu sebelum submit, karena setelah pesanan berhasil draft
    // dikosongkan dan asal barisnya tidak terbaca lagi.
    final dariKeranjang = draft.isFromCart;

    // 3. Proses ini melibatkan server dan bisa lama: tampilkan pop-up loading
    // ala SweetAlert2, lalu tutup begitu server menjawab.
    final navigator = Navigator.of(context, rootNavigator: true);
    Swal.muat(context, pesan: 'Membuat pesanan...');

    final order = await checkout.submit(
      items: items,
      shippingAddress: _addressController.text.trim(),
      paymentMethod: _paymentMethod,
      note: _noteController.text.trim(),
    );

    navigator.pop();

    if (!mounted) return;

    if (order == null) {
      return; // Pesan error sudah ditampilkan oleh CheckoutProvider.
    }

    draft.clear();
    // Kalau yang dibayar berasal dari keranjang, keranjang ikut kosong.
    // Kalau dari katalog, keranjang tidak boleh tersentuh.
    if (dariKeranjang) context.read<CartProvider>().clearAfterCheckout();

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PesananSuksesPage(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<CheckoutDraftProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final auth = context.watch<AuthProvider>();

    if (draft.isEmpty && checkout.lastOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Keranjang kosong',
          message: 'Pilih produk dulu sebelum lanjut ke pembayaran.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!auth.isLoggedIn) ...[
              const _PeringatanLogin(),
              const SizedBox(height: 16),
            ],
            if (checkout.error != null) ...[
              _ErrorBanner(message: checkout.error!),
              const SizedBox(height: 16),
            ],

            const SectionHeading('Rincian Pesanan'),
            const SizedBox(height: 10),
            _RincianPesanan(items: draft.items),

            const SizedBox(height: 24),
            const SectionHeading('Metode Pembayaran'),
            const SizedBox(height: 10),
            ..._paymentOptions.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PaymentOptionTile(
                  label: entry.value,
                  icon: _paymentIcons[entry.key]!,
                  selected: _paymentMethod == entry.key,
                  onTap: () => setState(() => _paymentMethod = entry.key),
                ),
              ),
            ),

            const SizedBox(height: 14),
            const SectionHeading('Alamat Pengiriman'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Jl. Merdeka No. 10, RT 02 / RW 05, Bandung',
                errorText: checkout.errorFor('shipping_address'),
              ),
              validator: (value) {
                final fieldError = checkout.errorFor('shipping_address');
                if (fieldError != null) return fieldError;
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat pengiriman wajib diisi.';
                }
                if (value.trim().length < 10) {
                  return 'Alamat terlalu pendek, tambahkan patokan agar kurir tidak nyasar.';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),
            const SectionHeading('Catatan untuk Warung (opsional)'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: Titip ke kasir, saya ambil sore',
                errorText: checkout.errorFor('note'),
              ),
            ),

            const SizedBox(height: 24),
            _RingkasanBiaya(
              subtotal: draft.subtotal,
              shippingCost: draft.shippingCost,
              total: draft.total,
            ),

            const SizedBox(height: 18),
            FilledButton(
              onPressed: checkout.isSubmitting ? null : _submit,
              child: checkout.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Buat Pesanan • ${formatRupiah(draft.total)}'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pesanan masuk dengan status "Menunggu" dan stok baru dipotong '
              'setelah kasir memprosesnya.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio sederhana. RadioListTile bawaan Flutter sudah deprecated grup-nya
/// (groupValue/onChanged) sejak 3.32, jadi selector-nya dibuat sendiri.
class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      color: selected ? AppColors.primarySoft : AppColors.card,
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.outline,
        width: selected ? 1.5 : 1,
      ),
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? AppColors.primary : AppColors.outline,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _PeringatanLogin extends StatelessWidget {
  const _PeringatanLogin();

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      icon: Icons.info_outline,
      color: const Color(0xFFB45309),
      background: AppColors.accentSoft,
      message:
          'Kamu belum masuk. Pesanan tetap bisa dibuat setelah kamu masuk.',
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      icon: Icons.error_outline,
      color: AppColors.danger,
      background: AppColors.dangerSoft,
      message: message,
    );
  }
}

/// Daftar barang yang akan dibayar, lengkap dengan pengubah jumlah di sini.
///
/// Jumlah bisa diubah langsung di halaman pembayaran supaya orang tidak perlu
/// balik ke katalog atau keranjang hanya untuk menambah satu barang.
class _RincianPesanan extends StatelessWidget {
  const _RincianPesanan({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final draft = context.read<CheckoutDraftProvider>();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatRupiah(items[i].product.priceJual)} / '
                          '${items[i].product.unit}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _QtyStepper(
                          qty: items[i].qty,
                          onDecrease: () => draft.decrease(items[i].product.id),
                          onIncrease: () => draft.add(items[i].product),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRupiah(items[i].subtotal),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      IconButton(
                        tooltip: 'Hapus barang',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => draft.remove(items[i].product.id),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pengubah jumlah berbentuk pil, dipakai di halaman pembayaran.
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int qty;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Kurangi',
            visualDensity: VisualDensity.compact,
            onPressed: onDecrease,
            icon: const Icon(Icons.remove, size: 17, color: AppColors.primary),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tambah',
            visualDensity: VisualDensity.compact,
            onPressed: onIncrease,
            icon: const Icon(Icons.add, size: 17, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _RingkasanBiaya extends StatelessWidget {
  const _RingkasanBiaya({
    required this.subtotal,
    required this.shippingCost,
    required this.total,
  });

  final int subtotal;
  final int shippingCost;
  final int total;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceAlt,
      child: Column(
        children: [
          DetailRow('Subtotal', formatRupiah(subtotal)),
          const SizedBox(height: 6),
          DetailRow('Ongkir', formatRupiah(shippingCost)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          DetailRow('Total Bayar', formatRupiah(total), emphasize: true),
        ],
      ),
    );
  }
}

/// Ditampilkan setelah pesanan berhasil dibuat.
class PesananSuksesPage extends StatelessWidget {
  const PesananSuksesPage({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Berhasil'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const SizedBox(height: 12),
          // Centang besar dilingkupi warna primer lembut supaya tampil sebagai
          // konfirmasi, bukan sekadar ikon di atas teks.
          Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 56,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pesanan kamu sudah masuk',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Menunggu diproses oleh kasir Warung Nara.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          AppCard(
            child: Column(
              children: [
                DetailRow('No. Nota', order.orderNumber),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                const DetailRow('Status', 'Menunggu diproses'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                DetailRow(
                  'Total',
                  formatRupiah(order.total),
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PesananSayaPage()),
            ),
            child: const Text('Lihat Pesanan Saya'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Kembali ke Katalog'),
          ),
        ],
      ),
    );
  }
}
