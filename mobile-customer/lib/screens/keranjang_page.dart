import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_draft_provider.dart';
import '../theme.dart';
import '../utils/currency.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/swal.dart';
import 'checkout_page.dart';

/// Ringkasan isi keranjang sebelum masuk ke halaman pembayaran.
class KeranjangPage extends StatelessWidget {
  const KeranjangPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Keranjang${cart.isEmpty ? '' : ' (${cart.totalQty})'}'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: const Text(
                'Kosongkan',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Keranjang masih kosong',
                    message: 'Pilih produk di halaman Beranda dulu ya.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _CartRow(item: cart.items[index]),
                  ),
          ),
          if (cart.isNotEmpty) const _RingkasanBayar(),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, CartProvider cart) async {
    final confirmed = await Swal.konfirmasi(
      context,
      judul: 'Kosongkan keranjang?',
      pesan: 'Semua barang yang dipilih akan dihapus.',
      teksYa: 'Kosongkan',
      teksTidak: 'Batal',
      berbahaya: true,
    );

    if (confirmed) cart.clear();
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatRupiah(item.product.priceJual)} / ${item.product.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatRupiah(item.subtotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (item.exceedsStock) ...[
            const SizedBox(height: 10),
            _StokPeringatan(item: item),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Hapus',
                visualDensity: VisualDensity.compact,
                onPressed: () => cart.remove(item.product.id),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              _QuantityStepper(
                qty: item.qty,
                onDecrease: () => cart.decrease(item.product.id),
                onIncrease: () => cart.add(item.product),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Peringatan muncul karena server memotong stok saat kasir memproses pesanan,
/// bukan saat pesanan dibuat. Pelanggan boleh memesan melebihi stok siap, tapi
/// kasir bisa menolak saat memproses.
class _StokPeringatan extends StatelessWidget {
  const _StokPeringatan({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFB45309),
      background: AppColors.accentSoft,
      message: 'Stok siap ${item.product.stock} ${item.product.unit}, '
          'Anda memilih ${item.qty}. Warung mungkin belum bisa memenuhi.',
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
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
          _StepperButton(
            icon: Icons.remove,
            tooltip: 'Kurangi',
            onPressed: onDecrease,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            tooltip: 'Tambah',
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 18, color: AppColors.primary),
    );
  }
}

class _RingkasanBayar extends StatelessWidget {
  const _RingkasanBayar();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.outline)),
        boxShadow: AppShadows.lifted,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DetailRow('Subtotal', formatRupiah(cart.subtotal)),
              const SizedBox(height: 6),
              DetailRow('Ongkir', formatRupiah(cart.shippingCost)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              DetailRow('Total', formatRupiah(cart.total), emphasize: true),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                // Bayar dari keranjang memakai salinan isi keranjang, supaya
                // mengubah jumlah di halaman pembayaran tidak mengubah
                // keranjang sebelum pesanan benar-benar dibuat.
                context
                    .read<CheckoutDraftProvider>()
                    .startFromCart(cart.items);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutPage()),
                );
              },
                  child: const Text('Lanjut ke Pembayaran'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}