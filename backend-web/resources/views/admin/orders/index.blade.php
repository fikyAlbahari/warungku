@extends('layouts.admin')

@section('title', 'Pesanan Masuk')

@section('content')
    <div class="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        @foreach ([
            'pending' => 'Menunggu',
            'diproses' => 'Diproses',
            'selesai' => 'Selesai',
            'dibatalkan' => 'Dibatalkan',
        ] as $key => $label)
            <a href="{{ route('admin.orders.index', ['status' => $key]) }}" class="group block">
                <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md">
                    <div class="text-xs font-medium uppercase tracking-wide text-slate-500">{{ $label }}</div>
                    <div class="mt-2 text-2xl font-semibold tracking-tight sm:text-3xl">{{ $statusCounts[$key] ?? 0 }}</div>
                    <div class="mt-2 text-xs text-slate-500 group-hover:text-teal-700">Lihat daftar →</div>
                </div>
            </a>
        @endforeach
    </div>

    <div class="mb-6 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
        <form method="GET" class="flex flex-wrap items-end gap-3">
            <div class="min-w-[200px] flex-1">
                <label class="mb-1 block text-xs font-medium text-slate-600">Cari No. Nota / Pelanggan</label>
                <input type="text" name="cari" value="{{ $filters['cari'] ?? '' }}"
                       class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
            </div>
            <div class="min-w-[160px]">
                <label class="mb-1 block text-xs font-medium text-slate-600">Status</label>
                <select name="status"
                        class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                    <option value="">Semua</option>
                    @foreach (['pending' => 'Menunggu', 'diproses' => 'Diproses', 'selesai' => 'Selesai', 'dibatalkan' => 'Dibatalkan'] as $key => $label)
                        <option value="{{ $key }}" @selected(($filters['status'] ?? '') === $key)>{{ $label }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="mb-1 block text-xs font-medium text-slate-600">Dari</label>
                <input type="date" name="dari" value="{{ $filters['dari'] ?? '' }}"
                       class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
            </div>
            <div>
                <label class="mb-1 block text-xs font-medium text-slate-600">Sampai</label>
                <input type="date" name="sampai" value="{{ $filters['sampai'] ?? '' }}"
                       class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
            </div>
            <div class="flex gap-2">
                <button type="submit"
                        class="inline-flex items-center rounded-lg bg-teal-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                    Terapkan
                </button>
                <a href="{{ route('admin.orders.index') }}"
                   class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                    Reset
                </a>
            </div>
        </form>
    </div>

    <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <h2 class="mb-4 text-base font-semibold">Rekap Pesanan ({{ $orders->total() }})</h2>
        <div class="overflow-x-auto -mx-5 px-5 sm:mx-0 sm:px-0">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead>
                    <tr class="text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                        <th class="py-2.5 pr-4">No. Nota</th>
                        <th class="py-2.5 px-4">Tanggal</th>
                        <th class="py-2.5 px-4">Pelanggan</th>
                        <th class="py-2.5 px-4">Item</th>
                        <th class="py-2.5 px-4">Total</th>
                        <th class="py-2.5 px-4">Bayar</th>
                        <th class="py-2.5 px-4">Status</th>
                        <th class="py-2.5 pl-4 text-right sm:text-left">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse ($orders as $order)
                        <tr class="hover:bg-slate-50/50">
                            <td class="whitespace-nowrap py-2.5 pr-4 font-medium text-teal-700">
                                <a href="{{ route('admin.orders.show', $order) }}">{{ $order->order_number }}</a>
                            </td>
                            <td class="whitespace-nowrap px-4 py-2.5 text-slate-600">{{ $order->created_at->format('d/m/Y H:i') }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5 text-slate-700">{{ $order->user?->name ?? '-' }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5 text-slate-600">{{ $order->items->count() }} jenis</td>
                            <td class="whitespace-nowrap px-4 py-2.5 font-medium text-slate-900">Rp {{ number_format($order->total, 0, ',', '.') }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5">
                                <div class="flex flex-wrap items-center gap-2">
                                    <span class="text-xs capitalize text-slate-600">{{ $order->payment_method }}</span>
                                    @if ($order->is_paid)
                                        <span class="inline-flex items-center rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-800 ring-1 ring-emerald-200">Lunas</span>
                                    @endif
                                </div>
                            </td>
                            <td class="whitespace-nowrap px-4 py-2.5">
                                <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium
                                    @if ($order->status === 'pending') bg-amber-100 text-amber-800 ring-1 ring-amber-200
                                    @elseif ($order->status === 'diproses') bg-blue-100 text-blue-800 ring-1 ring-blue-200
                                    @elseif ($order->status === 'selesai') bg-emerald-100 text-emerald-800 ring-1 ring-emerald-200
                                    @elseif ($order->status === 'dibatalkan') bg-rose-100 text-rose-800 ring-1 ring-rose-200
                                    @else bg-slate-100 text-slate-700 ring-1 ring-slate-200 @endif">
                                    {{ ucfirst($order->status) }}
                                </span>
                            </td>
                            <td class="whitespace-nowrap py-2.5 pl-4">
                                <a href="{{ route('admin.orders.show', $order) }}"
                                   class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                                    Detail
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="py-8 text-center text-sm text-slate-500">Tidak ada pesanan pada filter ini.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div class="mt-6">
            {{ $orders->withQueryString()->links() }}
        </div>
    </div>
@endsection
