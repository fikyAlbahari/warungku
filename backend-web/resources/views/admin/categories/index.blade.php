@extends('layouts.admin')

@section('title', 'Kategori Produk')

@section('content')
    <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 class="mb-4 text-base font-semibold">Tambah Kategori</h2>
            <form method="POST" action="{{ route('admin.categories.store') }}" class="space-y-4">
                @csrf
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Nama Kategori</label>
                    <input type="text" name="name" value="{{ old('name') }}" placeholder="Contoh: Minuman"
                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20" required>
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Deskripsi (opsional)</label>
                    <textarea name="description" rows="3" placeholder="Contoh: Air mineral, teh, kopi, minuman kaleng."
                              class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">{{ old('description') }}</textarea>
                </div>
                <button type="submit"
                        class="inline-flex items-center rounded-lg bg-teal-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                    Simpan Kategori
                </button>
            </form>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 class="mb-3 text-base font-semibold">Cara Pakai</h2>
            <p class="text-sm leading-relaxed text-slate-600">
                Kategori mengelompokkan produk supaya filter di "Manajemen Stok" rapi.
                Kategori yang masih dipakai produk tidak bisa dihapus, jadi pindahkan
                produknya ke kategori lain lebih dulu.
            </p>
            <a href="{{ route('admin.products.index') }}"
               class="mt-4 inline-flex items-center rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                Buka Manajemen Stok
            </a>
        </div>
    </div>

    <div class="mt-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <h2 class="mb-4 text-base font-semibold">Daftar Kategori ({{ $categories->count() }})</h2>
        <div class="overflow-x-auto -mx-5 px-5 sm:mx-0 sm:px-0">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead>
                    <tr class="text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                        <th class="py-2.5 pr-4">Kategori</th>
                        <th class="py-2.5 px-4">Deskripsi</th>
                        <th class="py-2.5 px-4">Produk</th>
                        <th class="w-56 py-2.5 pl-4 text-right sm:text-left">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse ($categories as $category)
                        <tr class="hover:bg-slate-50/50">
                            <td class="whitespace-nowrap py-2.5 pr-4 font-medium text-slate-900">{{ $category->name }}</td>
                            <td class="max-w-xs py-2.5 px-4 text-slate-600">{{ $category->description ?: '-' }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5 text-slate-700">
                                {{ $category->products_count }} produk
                                @if ($category->archived_products_count > 0)
                                    <span class="block text-xs text-slate-500">termasuk {{ $category->archived_products_count }} arsip</span>
                                @endif
                            </td>
                            <td class="whitespace-nowrap py-2.5 pl-4">
                                <div class="flex flex-wrap items-center gap-2">
                                    <button type="button"
                                            onclick="document.getElementById('edit-{{ $category->id }}').showModal()"
                                            class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                                        Edit
                                    </button>
                                    <form method="POST" action="{{ route('admin.categories.destroy', $category) }}"
                                          data-konfirmasi-judul="Hapus Kategori?"
                                          data-konfirmasi="Kategori {{ $category->name }} akan dihapus permanen."
                                          data-konfirmasi-ya="Ya, Hapus" class="inline-flex">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit"
                                                class="inline-flex items-center rounded-lg bg-rose-600 px-2.5 py-1.5 text-xs font-medium text-white shadow-sm transition hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-rose-500/20"
                                                {{ $category->products_count > 0 ? 'disabled' : '' }}>
                                            Hapus
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <td colspan="4" class="p-0">
                                <dialog id="edit-{{ $category->id }}"
                                        class="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-0 shadow-xl backdrop:bg-slate-900/40">
                                    <form method="POST" action="{{ route('admin.categories.update', $category) }}">
                                        @csrf
                                        @method('PUT')
                                        <div class="px-5 py-4">
                                            <h3 class="text-base font-semibold">Edit {{ $category->name }}</h3>
                                            <div class="mt-4 space-y-3">
                                                <div>
                                                    <label class="mb-1 block text-xs font-medium text-slate-600">Nama Kategori</label>
                                                    <input type="text" name="name" value="{{ old('name', $category->name) }}" required
                                                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                                                </div>
                                                <div>
                                                    <label class="mb-1 block text-xs font-medium text-slate-600">Deskripsi</label>
                                                    <textarea name="description" rows="3"
                                                              class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">{{ old('description', $category->description) }}</textarea>
                                                </div>
                                            </div>
                                            @error('name')
                                                <p class="mt-2 text-xs text-rose-600">{{ $message }}</p>
                                            @enderror
                                            @error('description')
                                                <p class="mt-1 text-xs text-rose-600">{{ $message }}</p>
                                            @enderror
                                        </div>
                                        <div class="flex justify-end gap-2 rounded-b-2xl bg-slate-50 px-5 py-3">
                                            <button type="button"
                                                    onclick="document.getElementById('edit-{{ $category->id }}').close()"
                                                    class="rounded-lg border border-slate-200 bg-white px-3.5 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                                                Batal
                                            </button>
                                            <button type="submit"
                                                    class="rounded-lg bg-teal-600 px-3.5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-teal-700">
                                                Simpan
                                            </button>
                                        </div>
                                    </form>
                                </dialog>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="py-8 text-center text-sm text-slate-500">Belum ada kategori.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection
