@extends('layouts.admin')

@section('title', 'Manajemen Stok')

@section('content')
    <div class="mb-6 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
        <form method="GET" class="flex flex-wrap items-end gap-3">
            <div class="min-w-[220px] flex-1">
                <label class="mb-1 block text-xs font-medium text-slate-600">Cari Produk / SKU / Barcode</label>
                <input type="text" name="cari" value="{{ $filters['cari'] ?? '' }}" placeholder="Contoh: Beras"
                       class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
            </div>
            <div class="min-w-[160px]">
                <label class="mb-1 block text-xs font-medium text-slate-600">Kategori</label>
                <select name="kategori"
                        class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                    <option value="">Semua</option>
                    @foreach ($categories as $category)
                        <option value="{{ $category->slug }}" @selected(($filters['kategori'] ?? '') === $category->slug)>
                            {{ $category->name }}
                        </option>
                    @endforeach
                </select>
            </div>
            <div class="min-w-[160px]">
                <label class="mb-1 block text-xs font-medium text-slate-600">Status</label>
                <select name="status"
                        class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                    <option value="">Semua</option>
                    <option value="stok-menipis" @selected(($filters['status'] ?? '') === 'stok-menipis')>Stok Menipis</option>
                </select>
            </div>
            <div class="flex items-center gap-2">
                <label class="flex items-center gap-2 text-xs font-medium text-slate-600">
                    <input type="checkbox" name="arsip" value="1" class="h-4 w-4 rounded border-slate-300 text-teal-600 focus:ring-teal-500" @checked($filters['arsip'] ?? false)>
                    Lihat Arsip
                </label>
            </div>
            <div class="flex gap-2">
                <button type="submit"
                        class="inline-flex items-center rounded-lg bg-teal-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                    Terapkan
                </button>
                <a href="{{ route('admin.products.index') }}"
                   class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                    Reset
                </a>
            </div>
        </form>
    </div>

    <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <h2 class="text-base font-semibold">Daftar Produk ({{ $products->total() }})</h2>
            <a href="{{ route('admin.products.create') }}"
               class="inline-flex items-center rounded-lg bg-teal-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                + Tambah Produk
            </a>
        </div>

        <div class="overflow-x-auto -mx-5 px-5 sm:mx-0 sm:px-0">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead>
                    <tr class="text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                        <th class="py-2.5 pr-4">Produk</th>
                        <th class="py-2.5 px-4">Kategori</th>
                        <th class="py-2.5 px-4">Modal</th>
                        <th class="py-2.5 px-4">Jual</th>
                        <th class="py-2.5 px-4">Stok</th>
                        <th class="py-2.5 px-4">Profit/Item</th>
                        <th class="py-2.5 px-4">Status</th>
                        <th class="w-56 py-2.5 pl-4 text-right sm:text-left">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse ($products as $product)
                        <tr class="hover:bg-slate-50/50">
                            <td class="py-2.5 pr-4">
                                <div class="font-medium text-slate-900">{{ $product->name }}</div>
                                @if ($product->sku)
                                    <div class="text-xs text-slate-500">SKU: {{ $product->sku }}</div>
                                @endif
                            </td>
                            <td class="whitespace-nowrap px-4 py-2.5 text-slate-600">{{ $product->category?->name ?? '-' }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5 text-slate-700">Rp {{ number_format($product->price_modal, 0, ',', '.') }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5 font-medium text-slate-900">Rp {{ number_format($product->price_jual, 0, ',', '.') }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5">
                                <span class="{{ $product->is_low_stock ? 'font-semibold text-rose-600' : 'text-slate-700' }}">
                                    {{ $product->stock }} {{ $product->unit }}
                                </span>
                                @if ($product->is_low_stock)
                                    <div class="text-xs text-rose-600">min. {{ $product->min_stock }}</div>
                                @endif
                            </td>
                            <td class="whitespace-nowrap px-4 py-2.5 text-emerald-600 font-medium">Rp {{ number_format($product->profit_per_unit, 0, ',', '.') }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5">
                                @if ($product->is_active)
                                    <span class="inline-flex items-center rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-medium text-emerald-800 ring-1 ring-emerald-200">Aktif</span>
                                @else
                                    <span class="inline-flex items-center rounded-full bg-rose-100 px-2.5 py-0.5 text-xs font-medium text-rose-800 ring-1 ring-rose-200">Nonaktif</span>
                                @endif
                            </td>
                            <td class="whitespace-nowrap py-2.5 pl-4">
                                <div class="flex flex-wrap items-center gap-1.5">
                                    <a href="{{ route('admin.products.edit', $product) }}"
                                       class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                                        Edit
                                    </a>
                                    <form method="POST" action="{{ route('admin.products.stock', $product) }}">
                                        @csrf
                                        <input type="hidden" name="type" value="masuk">
                                        <input type="hidden" name="qty" value="1">
                                        <button type="submit"
                                                class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 shadow-sm transition hover:bg-slate-50"
                                                title="Tambah 1 {{ $product->unit }}">
                                            +{{ strtoupper($product->unit) }}
                                        </button>
                                    </form>
                                    @if ($product->trashed())
                                        <form method="POST" action="{{ route('admin.products.restore', $product->id) }}">
                                            @csrf
                                            <button type="submit"
                                                    class="inline-flex items-center rounded-lg bg-teal-600 px-2.5 py-1.5 text-xs font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                                                Pulihkan
                                            </button>
                                        </form>
                                    @else
                                        <form method="POST" action="{{ route('admin.products.destroy', $product) }}"
                                               data-konfirmasi-judul="Arsipkan Produk?"
                                               data-konfirmasi="Produk {{ $product->name }} akan dipindahkan ke arsip dan tidak tampil di katalog."
                                               data-konfirmasi-ya="Ya, Arsipkan">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit"
                                                    class="inline-flex items-center rounded-lg bg-rose-600 px-2.5 py-1.5 text-xs font-medium text-white shadow-sm transition hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-rose-500/20">
                                                Arsipkan
                                            </button>
                                        </form>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="py-8 text-center text-sm text-slate-500">Belum ada produk. Klik "Tambah Produk" untuk mulai.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="mt-6">
            {{ $products->withQueryString()->links() }}
        </div>
    </div>
@endsection
