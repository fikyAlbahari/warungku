@extends('layouts.admin')

@section('title', 'Detail ' . $order->order_number)

@section('content')
    <div class="mb-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <h2 class="text-lg font-semibold">No. Nota: {{ $order->order_number }}</h2>
                <div class="mt-1 flex flex-wrap items-center gap-2 text-sm text-slate-600">
                    <span>{{ $order->created_at->format('d F Y, H:i') }}</span>
                    <span>•</span>
                    <span>Pelanggan: <strong class="text-slate-900">{{ $order->user?->name ?? '-' }}</strong></span>
                    <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium
                        @if ($order->status === 'pending') bg-amber-100 text-amber-800 ring-1 ring-amber-200
                        @elseif ($order->status === 'diproses') bg-blue-100 text-blue-800 ring-1 ring-blue-200
                        @elseif ($order->status === 'selesai') bg-emerald-100 text-emerald-800 ring-1 ring-emerald-200
                        @elseif ($order->status === 'dibatalkan') bg-rose-100 text-rose-800 ring-1 ring-rose-200
                        @else bg-slate-100 text-slate-700 ring-1 ring-slate-200 @endif">
                        {{ ucfirst($order->status) }}
                    </span>
                </div>
            </div>
            <a href="{{ route('admin.orders.index') }}"
               class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                ← Kembali
            </a>
        </div>
    </div>

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 class="mb-4 text-base font-semibold">Item Pesanan</h2>
            <div class="overflow-x-auto -mx-5 px-5 sm:mx-0 sm:px-0">
                <table class="min-w-full divide-y divide-slate-200 text-sm">
                    <thead>
                        <tr class="text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                            <th class="py-2.5 pr-4">Produk</th>
                            <th class="py-2.5 px-4">Harga</th>
                            <th class="py-2.5 px-4">Qty</th>
                            <th class="py-2.5 pl-4">Subtotal</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @foreach ($order->items as $item)
                            <tr>
                                <td class="py-2.5 pr-4 text-slate-900">{{ $item->product_name }}</td>
                                <td class="whitespace-nowrap px-4 py-2.5 text-slate-700">Rp {{ number_format($item->price, 0, ',', '.') }}</td>
                                <td class="whitespace-nowrap px-4 py-2.5 text-slate-700">{{ $item->qty }}</td>
                                <td class="whitespace-nowrap py-2.5 pl-4 font-medium text-slate-900">Rp {{ number_format($item->subtotal, 0, ',', '.') }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                    <tfoot>
                        <tr class="border-t border-slate-200">
                            <td colspan="3" class="py-2 pr-4 text-right text-sm text-slate-600">Subtotal</td>
                            <td class="py-2 pl-4 text-sm font-medium text-slate-900">Rp {{ number_format($order->subtotal, 0, ',', '.') }}</td>
                        </tr>
                        <tr>
                            <td colspan="3" class="py-2 pr-4 text-right text-sm text-slate-600">Ongkir</td>
                            <td class="py-2 pl-4 text-sm text-slate-700">Rp {{ number_format($order->shipping_cost, 0, ',', '.') }}</td>
                        </tr>
                        <tr>
                            <td colspan="3" class="py-2 pr-4 text-right text-base font-semibold text-slate-900">Total</td>
                            <td class="py-2 pl-4 text-base font-semibold text-emerald-600">Rp {{ number_format($order->total, 0, ',', '.') }}</td>
                        </tr>
                    </tfoot>
                </table>
            </div>
        </div>

        <div class="space-y-6">
            <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
                <h2 class="mb-3 text-base font-semibold">Alamat &amp; Catatan</h2>
                <p class="text-sm text-slate-700">
                    <strong>Dikirim ke:</strong><br>
                    {{ $order->shipping_address ?? '-' }}
                </p>
                @if ($order->note)
                    <p class="mt-3 text-sm text-slate-600">
                        <strong class="text-slate-700">Catatan:</strong> {{ $order->note }}
                    </p>
                @endif
                @if ($order->processedBy)
                    <p class="mt-3 text-xs text-slate-500">Diproses oleh: {{ $order->processedBy->name }}</p>
                @endif
            </div>

            @if ($order->status === 'pending')
                <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
                    <h2 class="mb-2 text-base font-semibold">Aksi Kasir</h2>
                    <p class="mb-4 text-sm text-slate-600">
                        Memproses pesanan ini akan otomatis mengurangi stok produk.
                    </p>
                    <div class="flex flex-wrap gap-3">
                        <form method="POST" action="{{ route('admin.orders.status', $order) }}">
                            @csrf @method('PATCH')
                            <input type="hidden" name="status" value="diproses">
                            <button type="submit"
                                    class="inline-flex items-center rounded-lg bg-teal-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                                Terima &amp; Proses
                            </button>
                        </form>
                        <form method="POST" action="{{ route('admin.orders.status', $order) }}"
                              data-konfirmasi-judul="Batalkan Pesanan?"
                              data-konfirmasi="Pesanan {{ $order->order_number }} akan dibatalkan dan stok kembali dikembalikan."
                              data-konfirmasi-ya="Ya, Batalkan">
                            @csrf @method('PATCH')
                            <input type="hidden" name="status" value="dibatalkan">
                            <button type="submit"
                                    class="inline-flex items-center rounded-lg bg-rose-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-rose-500/20">
                                Tolak / Batalkan
                            </button>
                        </form>
                    </div>
                </div>
            @elseif ($order->status === 'diproses')
                <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
                    <h2 class="mb-4 text-base font-semibold">Selesaikan Pesanan</h2>
                    <form method="POST" action="{{ route('admin.orders.status', $order) }}" class="space-y-4">
                        @csrf @method('PATCH')
                        <input type="hidden" name="status" value="selesai">
                        <div>
                            <label class="mb-1 block text-xs font-medium text-slate-600">Metode Pembayaran</label>
                            <select name="payment_method"
                                    class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                                @foreach (['tunai', 'transfer', 'qris'] as $method)
                                    <option value="{{ $method }}" @selected($order->payment_method === $method)>{{ ucfirst($method) }}</option>
                                @endforeach
                            </select>
                        </div>
                        <button type="submit"
                                class="inline-flex items-center rounded-lg bg-teal-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                            Tandai Sudah Dibayar &amp; Selesai
                        </button>
                    </form>
                </div>
            @elseif ($order->status === 'dibatalkan')
                <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
                    <h2 class="mb-2 text-base font-semibold">Pesanan Dibatalkan</h2>
                    <p class="mb-4 text-sm text-slate-600">Stok produk sudah dikembalikan. Nota boleh dihapus bila tidak perlu disimpan.</p>
                    <form method="POST" action="{{ route('admin.orders.destroy', $order) }}"
                          data-konfirmasi-judul="Hapus Nota?"
                          data-konfirmasi="Nota {{ $order->order_number }} akan dihapus permanen dan tidak bisa dikembalikan."
                          data-konfirmasi-ya="Ya, Hapus">
                        @csrf @method('DELETE')
                        <button type="submit"
                                class="inline-flex items-center rounded-lg bg-rose-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-rose-500/20">
                            Hapus Nota
                        </button>
                    </form>
                </div>
            @endif
        </div>
    </div>
@endsection
