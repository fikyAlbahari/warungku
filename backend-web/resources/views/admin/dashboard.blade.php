@extends('layouts.admin')

@section('title', 'Dashboard')

@section('content')
    {{-- Hero sambutan --}}
    <div class="mb-6 overflow-hidden rounded-2xl bg-gradient-to-r from-teal-700 via-teal-600 to-emerald-600 shadow-sm">
        <div class="flex flex-col gap-3 p-5 sm:flex-row sm:items-center sm:justify-between sm:p-6">
            <div>
                <h2 class="text-lg font-semibold text-white sm:text-xl">
                    Selamat datang, {{ auth()->user()?->name }}
                </h2>
                <p class="mt-1 text-sm text-teal-50/90">
                    Ringkasan performa warung untuk periode {{ $periodLabel }}.
                </p>
            </div>
            <div class="inline-flex w-fit items-center gap-2 rounded-xl bg-white/15 px-3 py-2 text-xs font-medium text-white ring-1 ring-white/20 sm:text-sm">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                    stroke="currentColor" class="h-4 w-4">
                    <path stroke-linecap="round" stroke-linejoin="round"
                        d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5" />
                </svg>
                {{ $from }} — {{ $to }}
            </div>
        </div>
        <div class="flex flex-wrap gap-2 border-t border-white/15 px-5 py-3 sm:px-6">
            @foreach (['hari-ini' => 'Hari Ini', '7-hari' => '7 Hari', 'bulan-ini' => 'Bulan Ini', 'tahun-ini' => 'Tahun Ini'] as $key => $label)
                <a href="{{ route('admin.dashboard', ['periode' => $key]) }}"
                    class="{{ request('periode', 'bulan-ini') === $key ? 'bg-white text-teal-700 shadow-sm' : 'text-white/90 ring-1 ring-white/25 hover:bg-white/10' }} inline-flex items-center rounded-lg px-3 py-1.5 text-xs font-medium transition sm:text-sm">
                    {{ $label }}
                </a>
            @endforeach
        </div>
    </div>

    {{-- Kartu ringkasan --}}
    <div class="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md">
            <div class="flex items-start justify-between gap-3">
                <div class="text-xs font-medium uppercase tracking-wide text-slate-500">Omzet</div>
                <span class="flex h-9 w-9 items-center justify-center rounded-lg bg-teal-50 text-teal-600 ring-1 ring-teal-100">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                        stroke="currentColor" class="h-5 w-5">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M12 6v12m-3-2.818l.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                </span>
            </div>
            <div class="mt-3 text-2xl font-semibold tracking-tight sm:text-3xl">Rp {{ number_format($revenue, 0, ',', '.') }}</div>
            <div class="mt-1 text-xs text-slate-500">{{ $orderCount }} pesanan • rata-rata Rp {{ number_format($averageOrderValue, 0, ',', '.') }}</div>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md">
            <div class="flex items-start justify-between gap-3">
                <div class="text-xs font-medium uppercase tracking-wide text-slate-500">Harga Pokok (HPP)</div>
                <span class="flex h-9 w-9 items-center justify-center rounded-lg bg-rose-50 text-rose-600 ring-1 ring-rose-100">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                        stroke="currentColor" class="h-5 w-5">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M2.25 6L9 12.75l4.286-4.286a11.948 11.948 0 014.306 6.43l.776 2.898m0 0l3.182-5.511m-3.182 5.51l-5.511-3.181" />
                    </svg>
                </span>
            </div>
            <div class="mt-3 text-2xl font-semibold tracking-tight text-rose-600 sm:text-3xl">Rp {{ number_format($cogs, 0, ',', '.') }}</div>
            <div class="mt-1 text-xs text-slate-500">{{ $itemSold }} item terjual</div>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md">
            <div class="flex items-start justify-between gap-3">
                <div class="text-xs font-medium uppercase tracking-wide text-slate-500">Laba Kotor</div>
                <span class="flex h-9 w-9 items-center justify-center rounded-lg bg-emerald-50 text-emerald-600 ring-1 ring-emerald-100">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                        stroke="currentColor" class="h-5 w-5">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941" />
                    </svg>
                </span>
            </div>
            <div class="mt-3 text-2xl font-semibold tracking-tight text-emerald-600 sm:text-3xl">Rp {{ number_format($grossProfit, 0, ',', '.') }}</div>
            <div class="mt-1 text-xs text-slate-500">Omzet − HPP</div>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md">
            <div class="flex items-start justify-between gap-3">
                <div class="text-xs font-medium uppercase tracking-wide text-slate-500">Laba Bersih</div>
                <span class="flex h-9 w-9 items-center justify-center rounded-lg bg-amber-50 text-amber-600 ring-1 ring-amber-100">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                        stroke="currentColor" class="h-5 w-5">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M21 12a2.25 2.25 0 00-2.25-2.25H15a3 3 0 11-6 0H5.25A2.25 2.25 0 003 12m18 0v6a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 18v-6m18 0V9M3 12V9m18 0a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 9m18 0V6a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 6v3" />
                    </svg>
                </span>
            </div>
            <div class="mt-3 text-2xl font-semibold tracking-tight {{ $netProfit >= 0 ? 'text-emerald-600' : 'text-rose-600' }} sm:text-3xl">
                Rp {{ number_format($netProfit, 0, ',', '.') }}
            </div>
            <div class="mt-1 text-xs text-slate-500">Laba kotor − pengeluaran Rp {{ number_format($expenseTotal, 0, ',', '.') }}</div>
        </div>
    </div>

    {{-- Grafik --}}
    <div class="mb-6 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="mb-4 flex items-center justify-between">
                <h2 class="text-base font-semibold">Omzet Harian</h2>
                <span class="rounded-full bg-teal-50 px-2.5 py-0.5 text-xs font-medium text-teal-700 ring-1 ring-teal-100">{{ $periodLabel }}</span>
            </div>
            @php $max = max(1, collect($dailyChart)->max('omzet')); @endphp
            <div class="max-h-72 space-y-4 overflow-y-auto pr-1">
                @forelse ($dailyChart as $day)
                    <div>
                        <div class="mb-1.5 flex items-center justify-between text-xs">
                            <span class="font-medium text-slate-700">{{ $day['label'] }}</span>
                            <span class="text-slate-500">Rp {{ number_format($day['omzet'], 0, ',', '.') }}</span>
                        </div>
                        <div class="h-2 w-full overflow-hidden rounded-full bg-slate-100">
                            <div class="h-2 rounded-full bg-gradient-to-r from-teal-500 to-emerald-500 transition-all" style="width: {{ round($day['omzet'] / $max * 100, 1) }}%"></div>
                        </div>
                    </div>
                @empty
                    <div class="py-8 text-center text-sm text-slate-500">Belum ada penjualan pada periode ini.</div>
                @endforelse
            </div>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="mb-4 flex items-center justify-between">
                <h2 class="text-base font-semibold">Pengeluaran per Kategori</h2>
                <span class="rounded-full bg-rose-50 px-2.5 py-0.5 text-xs font-medium text-rose-600 ring-1 ring-rose-100">{{ $periodLabel }}</span>
            </div>
            @php $maxExp = max(1, collect($expenseByCategory)->max('total')); @endphp
            <div class="max-h-72 space-y-4 overflow-y-auto pr-1">
                @forelse ($expenseByCategory as $row)
                    <div>
                        <div class="mb-1.5 flex items-center justify-between text-xs">
                            <span class="font-medium capitalize text-slate-700">{{ $row['category'] }}</span>
                            <span class="text-slate-500">Rp {{ number_format($row['total'], 0, ',', '.') }}</span>
                        </div>
                        <div class="h-2 w-full overflow-hidden rounded-full bg-slate-100">
                            <div class="h-2 rounded-full bg-gradient-to-r from-rose-500 to-orange-400 transition-all" style="width: {{ round($row['total'] / $maxExp * 100, 1) }}%"></div>
                        </div>
                    </div>
                @empty
                    <div class="py-8 text-center text-sm text-slate-500">Belum ada pengeluaran tercatat.</div>
                @endforelse
            </div>
        </div>
    </div>

    {{-- Tabel --}}
    <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="mb-4 flex items-center justify-between">
                <h2 class="flex items-center gap-2 text-base font-semibold">
                    Pesanan Menunggu
                    <span class="rounded-full bg-amber-100 px-2 py-0.5 text-xs font-semibold text-amber-800 ring-1 ring-amber-200">{{ $pendingOrderCount }}</span>
                </h2>
                <a href="{{ route('admin.orders.index', ['status' => 'pending']) }}"
                    class="inline-flex items-center gap-1 rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                    Lihat semua
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-3.5 w-3.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                    </svg>
                </a>
            </div>
            <div class="max-h-72 overflow-auto -mx-5 px-5 sm:mx-0 sm:px-0">
                <table class="min-w-full divide-y divide-slate-200 text-sm">
                    <thead>
                        <tr class="text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                            <th class="py-2.5 pr-4">No. Nota</th>
                            <th class="py-2.5 px-4">Pelanggan</th>
                            <th class="py-2.5 px-4">Total</th>
                            <th class="py-2.5 pl-4 text-right sm:text-left">Status</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @forelse ($latestOrders->take(8) as $order)
                            <tr class="transition hover:bg-slate-50/60">
                                <td class="whitespace-nowrap py-2.5 pr-4 font-medium text-teal-700">
                                    <a href="{{ route('admin.orders.show', $order) }}">{{ $order->order_number }}</a>
                                </td>
                                <td class="whitespace-nowrap px-4 py-2.5 text-slate-700">{{ $order->user?->name ?? '-' }}</td>
                                <td class="whitespace-nowrap px-4 py-2.5 text-slate-700">Rp {{ number_format($order->total, 0, ',', '.') }}</td>
                                <td class="whitespace-nowrap py-2.5 pl-4">
                                    <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium
                                        @if ($order->status === 'pending') bg-amber-100 text-amber-800 ring-1 ring-amber-200
                                        @elseif ($order->status === 'diproses') bg-blue-100 text-blue-800 ring-1 ring-blue-200
                                        @elseif ($order->status === 'selesai') bg-emerald-100 text-emerald-800 ring-1 ring-emerald-200
                                        @elseif ($order->status === 'dibatalkan') bg-rose-100 text-rose-800 ring-1 ring-rose-200
                                        @else bg-slate-100 text-slate-700 ring-1 ring-slate-200 @endif">
                                        {{ ucfirst($order->status) }}
                                    </span>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="4" class="py-8 text-center text-sm text-slate-500">Belum ada pesanan masuk.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="mb-4 flex items-center justify-between">
                <h2 class="flex items-center gap-2 text-base font-semibold">
                    Stok Menipis
                    <span class="rounded-full bg-rose-100 px-2 py-0.5 text-xs font-semibold text-rose-700 ring-1 ring-rose-200">{{ $lowStockProducts->count() }}</span>
                </h2>
                <a href="{{ route('admin.products.index') }}"
                    class="inline-flex items-center gap-1 rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                    Kelola stok
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-3.5 w-3.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                    </svg>
                </a>
            </div>
            <div class="max-h-72 overflow-auto -mx-5 px-5 sm:mx-0 sm:px-0">
                <table class="min-w-full divide-y divide-slate-200 text-sm">
                    <thead>
                        <tr class="text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                            <th class="py-2.5 pr-4">Produk</th>
                            <th class="py-2.5 px-4">Kategori</th>
                            <th class="py-2.5 pl-4 text-right sm:text-left">Sisa</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @forelse ($lowStockProducts as $product)
                            <tr class="transition hover:bg-slate-50/60">
                                <td class="whitespace-nowrap py-2.5 pr-4 font-medium text-teal-700">
                                    <a href="{{ route('admin.products.edit', $product) }}">{{ $product->name }}</a>
                                </td>
                                <td class="whitespace-nowrap px-4 py-2.5 text-slate-500">{{ $product->category?->name ?? '-' }}</td>
                                <td class="whitespace-nowrap py-2.5 pl-4 font-semibold text-rose-600">
                                    {{ $product->stock }} / {{ $product->min_stock }} {{ $product->unit }}
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="3" class="py-8 text-center text-sm text-slate-500">Semua stok aman.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
@endsection
