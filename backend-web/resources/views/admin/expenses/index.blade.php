@extends('layouts.admin')

@section('title', 'Rekap Pengeluaran')

@section('content')
    <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 class="mb-3 text-base font-semibold">Ringkasan ({{ $from }} s/d {{ $to }})</h2>
            <div>
                <div class="text-xs font-medium uppercase tracking-wide text-slate-500">Total Pengeluaran</div>
                <div class="mt-2 text-2xl font-semibold tracking-tight text-rose-600 sm:text-3xl">Rp {{ number_format($total, 0, ',', '.') }}</div>
            </div>
        </div>
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h2 class="mb-4 text-base font-semibold">Per Kategori</h2>
            <div class="overflow-x-auto -mx-5 px-5 sm:mx-0 sm:px-0">
                <table class="min-w-full divide-y divide-slate-200 text-sm">
                    <thead>
                        <tr class="text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                            <th class="py-2.5 pr-4">Kategori</th>
                            <th class="py-2.5 px-4">Jumlah Catatan</th>
                            <th class="py-2.5 pl-4">Total</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @forelse ($byCategory as $row)
                            <tr class="hover:bg-slate-50/50">
                                <td class="whitespace-nowrap py-2.5 pr-4 font-medium capitalize text-slate-900">{{ $row['category'] }}</td>
                                <td class="whitespace-nowrap px-4 py-2.5 text-slate-600">{{ $row['jumlah'] }}</td>
                                <td class="whitespace-nowrap py-2.5 pl-4 font-medium text-slate-900">Rp {{ number_format($row['total'], 0, ',', '.') }}</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="3" class="py-8 text-center text-sm text-slate-500">Belum ada pengeluaran pada periode ini.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div class="mt-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <form method="GET" class="flex flex-wrap items-end gap-3">
            <div class="min-w-[200px] flex-1">
                <label class="mb-1 block text-xs font-medium text-slate-600">Cari Keterangan</label>
                <input type="text" name="cari" value="{{ $filters['cari'] ?? '' }}"
                       class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
            </div>
            <div class="min-w-[160px]">
                <label class="mb-1 block text-xs font-medium text-slate-600">Kategori</label>
                <select name="kategori"
                        class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                    <option value="">Semua</option>
                    @foreach (['kulakan', 'sewa', 'listrik', 'air', 'transport', 'gaji', 'perawatan', 'lainnya'] as $cat)
                        <option value="{{ $cat }}" @selected(($filters['kategori'] ?? '') === $cat)>{{ ucfirst($cat) }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="mb-1 block text-xs font-medium text-slate-600">Dari</label>
                <input type="date" name="dari" value="{{ $filters['dari'] ?? $from }}"
                       class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
            </div>
            <div>
                <label class="mb-1 block text-xs font-medium text-slate-600">Sampai</label>
                <input type="date" name="sampai" value="{{ $filters['sampai'] ?? $to }}"
                       class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
            </div>
            <div class="flex gap-2">
                <button type="submit"
                        class="inline-flex items-center rounded-lg bg-teal-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                    Terapkan
                </button>
                <a href="{{ route('admin.expenses.index') }}"
                   class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                    Reset
                </a>
            </div>
        </form>

        <div class="mt-6 overflow-x-auto -mx-5 px-5 sm:mx-0 sm:px-0">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead>
                    <tr class="text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                        <th class="py-2.5 pr-4">Tanggal</th>
                        <th class="py-2.5 px-4">Kategori</th>
                        <th class="py-2.5 px-4">Keterangan</th>
                        <th class="py-2.5 px-4">Nominal</th>
                        <th class="py-2.5 px-4">Bukti</th>
                        <th class="py-2.5 pl-4 text-right sm:text-left">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse ($expenses as $expense)
                        <tr class="hover:bg-slate-50/50">
                            <td class="whitespace-nowrap py-2.5 pr-4 text-slate-700">{{ $expense->expense_date->format('d/m/Y') }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5 capitalize text-slate-700">{{ $expense->category }}</td>
                            <td class="max-w-xs px-4 py-2.5 text-slate-700">{{ $expense->description }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5 font-medium text-slate-900">Rp {{ number_format($expense->amount, 0, ',', '.') }}</td>
                            <td class="whitespace-nowrap px-4 py-2.5">
                                @if ($expense->receipt)
                                    <a href="{{ asset('storage/'.$expense->receipt) }}" target="_blank"
                                       class="text-xs font-medium text-teal-700 hover:text-teal-900">Lihat</a>
                                @else
                                    <span class="text-xs text-slate-400">-</span>
                                @endif
                            </td>
                            <td class="whitespace-nowrap py-2.5 pl-4">
                                <div class="flex flex-wrap items-center gap-2">
                                    <a href="{{ route('admin.expenses.edit', $expense) }}"
                                       class="inline-flex items-center rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">Edit</a>
                                    <form method="POST" action="{{ route('admin.expenses.destroy', $expense) }}"
                                          data-konfirmasi-judul="Hapus Pengeluaran?"
                                          data-konfirmasi="Pengeluaran ini akan dihapus permanen. Lanjutkan?"
                                          data-konfirmasi-ya="Ya, Hapus">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit"
                                                class="inline-flex items-center rounded-lg bg-rose-600 px-2.5 py-1.5 text-xs font-medium text-white shadow-sm transition hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-rose-500/20">
                                            Hapus
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="py-8 text-center text-sm text-slate-500">Belum ada pengeluaran.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="mt-6">
            {{ $expenses->withQueryString()->links() }}
        </div>

        <div class="mt-4">
            <a href="{{ route('admin.expenses.create') }}"
               class="inline-flex items-center rounded-lg bg-teal-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                Catat Pengeluaran Baru
            </a>
        </div>
    </div>
@endsection
