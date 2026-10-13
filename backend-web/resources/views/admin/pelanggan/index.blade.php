@extends('layouts.admin')

@section('title', 'Verifikasi Pelanggan')

@section('content')
    <div class="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900 shadow-sm">
        Pelanggan yang mendaftar dari aplikasi masuk ke tab <strong>Menunggu</strong> dan belum bisa masuk
        sampai kamu menyetujuinya. Cek dulu nama dan nomor HP-nya supaya tidak ada akun palsu atau salah orang.
    </div>

    <div class="mt-6 flex flex-wrap gap-2">
        @php
            $tab = [
                App\Models\User::STATUS_MENUNGGU => 'Menunggu',
                App\Models\User::STATUS_DISETUJUI => 'Disetujui',
                App\Models\User::STATUS_DITOLAK => 'Ditolak',
            ];
        @endphp
        @foreach ($tab as $key => $label)
            <a href="{{ route('admin.pelanggan.index', ['status' => $key]) }}"
               class="{{ $status === $key ? 'bg-teal-700 text-white shadow-sm' : 'border border-slate-200 bg-white text-slate-700 hover:bg-slate-50' }} inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium transition">
                {{ $label }}
                <span class="{{ $status === $key ? 'bg-white/20' : 'bg-slate-100 text-slate-600' }} rounded-full px-2 py-0.5 text-xs font-semibold">{{ $jumlah[$key] }}</span>
            </a>
        @endforeach
    </div>

    <div class="mt-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <h2 class="mb-4 text-base font-semibold">Daftar Pelanggan</h2>

        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead>
                    <tr class="text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                        <th class="py-2.5 pr-4">Pelanggan</th>
                        <th class="py-2.5 px-4">Kontak</th>
                        <th class="py-2.5 px-4">Alamat</th>
                        <th class="py-2.5 px-4">Daftar</th>
                        <th class="py-2.5 pl-4 text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse ($pelanggan as $p)
                        <tr class="align-top hover:bg-slate-50/50">
                            <td class="py-3 pr-4">
                                <div class="font-medium text-slate-900">{{ $p->name }}</div>
                                <div class="text-xs text-slate-500">{{ $p->email }}</div>
                            </td>
                            <td class="px-4 py-3 text-slate-600">{{ $p->phone ?: '-' }}</td>
                            <td class="max-w-xs px-4 py-3 text-slate-600">
                                <span class="line-clamp-2">{{ $p->address ?: '-' }}</span>
                            </td>
                            <td class="whitespace-nowrap px-4 py-3 text-xs text-slate-500">
                                {{ $p->created_at?->format('d M Y H:i') }}
                            </td>
                            <td class="py-3 pl-4">
                                <div class="flex flex-wrap items-center justify-end gap-2">
                                    @if ($p->status_verifikasi === App\Models\User::STATUS_MENUNGGU)
                                        <form method="POST" action="{{ route('admin.pelanggan.setujui', $p) }}">
                                            @csrf
                                            <button type="submit"
                                                    class="inline-flex items-center gap-1.5 rounded-lg bg-teal-600 px-3 py-1.5 text-xs font-semibold text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/30">
                                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="h-4 w-4">
                                                    <path fill-rule="evenodd" d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z" clip-rule="evenodd" />
                                                </svg>
                                                Setujui
                                            </button>
                                        </form>
                                        <button type="button"
                                                onclick="document.getElementById('tolak-{{ $p->id }}').showModal()"
                                                class="inline-flex items-center gap-1.5 rounded-lg border border-rose-200 bg-white px-3 py-1.5 text-xs font-semibold text-rose-700 shadow-sm transition hover:bg-rose-50 focus:outline-none focus:ring-2 focus:ring-rose-500/20">
                                            Tolak
                                        </button>
                                    @elseif ($p->status_verifikasi === App\Models\User::STATUS_DISETUJUI)
                                        <span class="rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-semibold text-emerald-700">
                                            Disetujui
                                        </span>
                                        @if ($p->disetujuiOleh)
                                            <div class="w-full text-right text-[11px] text-slate-500">
                                                oleh {{ $p->disetujuiOleh->name }} • {{ $p->disetujui_pada?->format('d M Y H:i') }}
                                            </div>
                                        @endif
                                    @else
                                        <span class="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
                                            Ditolak
                                        </span>
                                    @endif
                                </div>
                            </td>
                        </tr>

                        @if ($p->status_verifikasi === App\Models\User::STATUS_MENUNGGU)
                            <tr>
                                <td colspan="5" class="p-0">
                                    <dialog id="tolak-{{ $p->id }}"
                                            class="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-0 shadow-xl backdrop:bg-slate-900/40">
                                        <form method="POST" action="{{ route('admin.pelanggan.tolak', $p) }}">
                                            @csrf
                                            <div class="px-5 py-4">
                                                <h3 class="text-base font-semibold">Tolak akun {{ $p->name }}?</h3>
                                                <p class="mt-1 text-sm text-slate-500">
                                                    Akun tidak bisa masuk setelah ditolak. Pelanggan akan melihat pesannya saat
                                                    mencoba masuk, tapi alasannya belum tersimpan di database.
                                                </p>
                                                <label class="mt-4 block text-xs font-medium text-slate-600">Alasan penolakan</label>
                                                <input type="text" name="alasan" required
                                                       placeholder="Contoh: nomor HP tidak aktif"
                                                       class="mt-1 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20">
                                                @error('alasan')
                                                    <p class="mt-1 text-xs text-rose-600">{{ $message }}</p>
                                                @enderror
                                            </div>
                                            <div class="flex justify-end gap-2 rounded-b-2xl bg-slate-50 px-5 py-3">
                                                <button type="button"
                                                        onclick="document.getElementById('tolak-{{ $p->id }}').close()"
                                                        class="rounded-lg border border-slate-200 bg-white px-3.5 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
                                                    Batal
                                                </button>
                                                <button type="submit"
                                                        class="rounded-lg bg-rose-600 px-3.5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-rose-700">
                                                    Tolak Akun
                                                </button>
                                            </div>
                                        </form>
                                    </dialog>
                                </td>
                            </tr>
                        @endif
                    @empty
                        <tr>
                            <td colspan="5" class="py-10 text-center text-sm text-slate-500">
                                @if ($status === App\Models\User::STATUS_MENUNGGU)
                                    Tidak ada pendaftaran yang menunggu verifikasi.
                                @else
                                    Belum ada pelanggan dengan status ini.
                                @endif
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection