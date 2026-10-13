import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/catalog_provider.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/currency.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/swal.dart';

/// Riwayat pesanan pelanggan beserta statusnya.
class PesananSayaPage extends StatefulWidget {
  const PesananSayaPage({super.key});

  @override
  State<PesananSayaPage> createState() => _PesananSayaPageState();
}

class _PesananSayaPageState extends State<PesananSayaPage> {
  late final OrderListProvider _provider;
  final _scrollController = ScrollController();

  // Value null berarti "semua status", jadi disimpan sebagai List (bukan Map)
  // karena key Map harus String dan tidak boleh null.
  static const _filters = <(String?, String)>[
    (null, 'Semua'),
    ('pending', 'Menunggu'),
    ('diproses', 'Diproses'),
    ('selesai', 'Selesai'),
    ('dibatalkan', 'Dibatalkan'),
  ];

  @override
  void initState() {
    super.initState();
    _provider = context.read<OrderListProvider>();
    // Ditunda sampai setelah frame: load() langsung memanggil notifyListeners()
    // di baris pertama, dan memanggilnya saat initState berjalan (masih fase
    // build) membuat provider scope menandai dirinya kotor di tengah build --
    // crash "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _provider.load(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      _provider.loadMore();
    }
  }

  Future<void> _cancel(Order order) async {
    final confirmed = await Swal.konfirmasi(
      context,
      judul: 'Batalkan pesanan?',
      pesan: 'No. nota ${order.orderNumber} akan dibatalkan.',
      teksYa: 'Batalkan',
      teksTidak: 'Tidak',
      berbahaya: true,
    );

    if (!confirmed || !mounted) return;

    try {
      await context.read<ApiService>().cancelOrder(order.id);
      _provider.markCancelled(order.id);
      if (mounted) {
        Swal.toastSukses(context, 'Pesanan dibatalkan.');
      }
    } on ApiException catch (e) {
      if (mounted) Swal.toastGagal(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: Consumer<OrderListProvider>(
              builder: (context, provider, _) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  for (final (status, label) in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: provider.statusFilter == status,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.card,
                        side: BorderSide(
                          color: provider.statusFilter == status
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: provider.statusFilter == status
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: provider.statusFilter == status
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        onSelected: (_) => provider.filterByStatus(status),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Consumer<OrderListProvider>(
              builder: (context, provider, _) => _buildList(provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(OrderListProvider provider) {
    if (provider.isLoading && provider.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.orders.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Gagal memuat pesanan',
        message: provider.error,
        actionLabel: 'Coba lagi',
        onAction: () => provider.load(refresh: true),
      );
    }

    if (provider.orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada pesanan',
        message: 'Pesanan yang kamu buat akan muncul di sini.',
        actionLabel: 'Mulai Belanja',
        onAction: () => Navigator.of(context).popUntil((route) => route.isFirst),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.load(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: provider.orders.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == provider.orders.length) {
            if (provider.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return const SizedBox(height: 4);
          }

          final order = provider.orders[index];
          return _OrderCard(order: order, onCancel: () => _cancel(order));
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onCancel});

  final Order order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            order.createdAt == null ? '-' : _formatTanggal(order.createdAt!),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.itemCount} item',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                formatRupiah(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          // Pembatalan hanya boleh saat masih "Menunggu", mengikuti aturan
          // di backend: setelah diproses, stok sudah keluar dari rak.
          if (order.isPending) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Batalkan'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTanggal(DateTime value) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${value.day} ${bulan[value.month - 1]} ${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background, icon) = switch (status) {
      'pending' => (
          'Menunggu',
          const Color(0xFFB45309),
          AppColors.accentSoft,
          Icons.schedule_rounded,
        ),
      'diproses' => (
          'Diproses',
          AppColors.info,
          AppColors.infoSoft,
          Icons.local_shipping_outlined,
        ),
      'selesai' => (
          'Selesai',
          AppColors.success,
          AppColors.successSoft,
          Icons.check_circle_outline,
        ),
      _ => (
          'Dibatalkan',
          AppColors.textSecondary,
          AppColors.surfaceAlt,
          Icons.cancel_outlined,
        ),
    };

    return AppPill(label, color: color, background: background, icon: icon);
  }
}
