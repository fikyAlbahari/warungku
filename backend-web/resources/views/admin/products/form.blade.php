@extends('layouts.admin')

@section('title', $product->exists ? 'Edit Produk' : 'Tambah Produk')

@section('content')
    <form method="POST"
          action="{{ $product->exists ? route('admin.products.update', $product) : route('admin.products.store') }}"
          enctype="multipart/form-data"
          class="space-y-6">
        @csrf
        @if ($product->exists) @method('PUT') @endif

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 class="mb-4 text-base font-semibold">Informasi Produk</h2>
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Nama Produk *</label>
                    <input type="text" name="name" value="{{ old('name', $product->name) }}" required
                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Kategori *</label>
                    <select name="category_id" required
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                        <option value="">-- Pilih Kategori --</option>
                        @foreach ($categories as $category)
                            <option value="{{ $category->id }}" @selected(old('category_id', $product->category_id) == $category->id)>
                                {{ $category->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">SKU</label>
                    <input type="text" name="sku" value="{{ old('sku', $product->sku) }}"
                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Barcode</label>
                    <input type="text" name="barcode" value="{{ old('barcode', $product->barcode) }}"
                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                </div>
            </div>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 class="mb-4 text-base font-semibold">Harga &amp; Stok</h2>
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Satuan *</label>
                    <select name="unit" required
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                        @foreach (['pcs', 'pack', 'box', 'kg', 'gram', 'liter', 'botol', 'biji', 'renteng', 'sachet'] as $unit)
                            <option value="{{ $unit }}" @selected(old('unit', $product->unit) === $unit)>{{ $unit }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Harga Modal (Rp) *</label>
                    <input type="number" step="0.01" min="0" name="price_modal"
                           value="{{ old('price_modal', $product->price_modal) }}" required
                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Harga Jual (Rp) *</label>
                    <input type="number" step="0.01" min="0" name="price_jual"
                           value="{{ old('price_jual', $product->price_jual) }}" required
                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Stok Saat Ini *</label>
                    <input type="number" min="0" name="stock" value="{{ old('stock', $product->stock ?? 0) }}" required
                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Batas Stok Menipis *</label>
                    <input type="number" min="0" name="min_stock" value="{{ old('min_stock', $product->min_stock ?? 0) }}" required
                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Status</label>
                    <select name="is_active"
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                        <option value="1" @selected(old('is_active', $product->is_active ?? true))>Aktif</option>
                        <option value="0" @selected(! old('is_active', $product->is_active ?? true))>Nonaktif</option>
                    </select>
                </div>
            </div>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 class="mb-4 text-base font-semibold">Lainnya</h2>
            <div>
                <label class="mb-1 block text-xs font-medium text-slate-600">Deskripsi</label>
                <textarea name="description" rows="3"
                          class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">{{ old('description', $product->description) }}</textarea>
            </div>
            <div class="mt-4">
                <label class="mb-1 block text-xs font-medium text-slate-600">Foto Produk (maks 2 MB)</label>
                <input type="file" name="image" accept="image/*"
                       class="block w-full text-sm text-slate-600 file:mr-3 file:rounded-lg file:border-0 file:bg-teal-50 file:px-3 file:py-2 file:text-sm file:font-medium file:text-teal-700 hover:file:bg-teal-100">
                @if ($product->image)
                    <img src="{{ asset('storage/'.$product->image) }}" alt="Foto produk"
                         class="mt-3 max-w-[120px] rounded-lg border border-slate-200 shadow-sm">
                @endif
            </div>
        </div>

        <div class="flex flex-wrap gap-3">
            <button type="submit"
                    class="inline-flex items-center rounded-lg bg-teal-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                {{ $product->exists ? 'Simpan Perubahan' : 'Simpan Produk' }}
            </button>
            <a href="{{ route('admin.products.index') }}"
               class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                Batal
            </a>
        </div>
    </form>
@endsection
