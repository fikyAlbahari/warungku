@extends('layouts.admin')

@section('title', $expense->exists ? 'Edit Pengeluaran' : 'Catat Pengeluaran')

@section('content')
    <form method="POST" enctype="multipart/form-data"
          action="{{ $expense->exists ? route('admin.expenses.update', $expense) : route('admin.expenses.store') }}"
          class="space-y-6">
        @csrf
        @if ($expense->exists) @method('PUT') @endif

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 class="mb-4 text-base font-semibold">Detail Pengeluaran</h2>
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Kategori *</label>
                    <select name="category" required
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                        @foreach (['kulakan' => 'Kulakan (Belanja Stok)', 'sewa' => 'Sewa Kios', 'listrik' => 'Listrik', 'air' => 'Air', 'transport' => 'Transportasi', 'gaji' => 'Gaji Karyawan', 'perawatan' => 'Perawatan', 'lainnya' => 'Lainnya'] as $key => $label)
                            <option value="{{ $key }}" @selected(old('category', $expense->category) === $key)>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Tanggal Transaksi *</label>
                    <input type="date" name="expense_date" max="{{ date('Y-m-d') }}"
                           value="{{ old('expense_date', $expense->expense_date?->toDateString()) }}" required
                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                </div>
                <div>
                    <label class="mb-1 block text-xs font-medium text-slate-600">Nominal (Rp) *</label>
                    <input type="number" step="0.01" min="0" name="amount"
                           value="{{ old('amount', $expense->amount) }}" required
                           class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                </div>
            </div>

            <div class="mt-4">
                <label class="mb-1 block text-xs font-medium text-slate-600">Keterangan *</label>
                <input type="text" name="description" value="{{ old('description', $expense->description) }}"
                       placeholder="Contoh: Beli 25 kg beras dari supplier" required
                       class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
            </div>

            <div class="mt-4">
                <label class="mb-1 block text-xs font-medium text-slate-600">Bukti / Nota (maks 2 MB)</label>
                <input type="file" name="receipt" accept="image/*"
                       class="block w-full text-sm text-slate-600 file:mr-3 file:rounded-lg file:border-0 file:bg-teal-50 file:px-3 file:py-2 file:text-sm file:font-medium file:text-teal-700 hover:file:bg-teal-100">
                @if ($expense->receipt)
                    <img src="{{ asset('storage/'.$expense->receipt) }}" alt="Bukti"
                         class="mt-3 max-w-[120px] rounded-lg border border-slate-200 shadow-sm">
                @endif
            </div>
        </div>

        <div class="flex flex-wrap gap-3">
            <button type="submit"
                    class="inline-flex items-center rounded-lg bg-teal-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                {{ $expense->exists ? 'Simpan Perubahan' : 'Simpan Pengeluaran' }}
            </button>
            <a href="{{ route('admin.expenses.index') }}"
               class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                Batal
            </a>
        </div>
    </form>
@endsection
