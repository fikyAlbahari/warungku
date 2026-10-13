<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

/**
 * Verifikasi akun pelanggan yang mendaftar dari aplikasi.
 *
 * Alur: pelanggan mendaftar lewat app dengan status `menunggu` dan belum bisa
 * login. Di halaman ini admin melihat antrean, lalu menyetujui atau menolak.
 *
 * Menolak tidak menghapus akun, supaya pelanggan bisa tahu kalau daftarnya
 * ditolak dan tidak bingung menganggap emailnya salah ketik.
 */
class PelangganController extends Controller
{
    public function index(Request $request): View
    {
        // Tab: menunggu / disetujui / ditolak. Default antrean menunggu
        // supaya admin langsung melihat yang perlu ditindak.
        $status = $request->query('status', User::STATUS_MENUNGGU);

        if (! in_array($status, [User::STATUS_MENUNGGU, User::STATUS_DISETUJUI, User::STATUS_DITOLAK], true)) {
            $status = User::STATUS_MENUNGGU;
        }

        $pelanggan = User::pelanggan()
            ->where('status_verifikasi', $status)
            ->with('disetujuiOleh')
            ->orderByDesc('created_at')
            ->get();

        $jumlah = [
            User::STATUS_MENUNGGU => User::pelanggan()->menungguVerifikasi()->count(),
            User::STATUS_DISETUJUI => User::pelanggan()->where('status_verifikasi', User::STATUS_DISETUJUI)->count(),
            User::STATUS_DITOLAK => User::pelanggan()->where('status_verifikasi', User::STATUS_DITOLAK)->count(),
        ];

        return view('admin.pelanggan.index', compact('pelanggan', 'status', 'jumlah'));
    }

    public function setujui(Request $request, User $user): RedirectResponse
    {
        $this->pastikanPelanggan($user);

        // forceFill: `disetujui_oleh` tidak ada di $fillable. Kolom ini diisi server
        // dari user yang sedang login, bukan dari input, jadi tidak boleh bisa
        // dikirim lewat mass assignment.
        $user->forceFill([
            'status_verifikasi' => User::STATUS_DISETUJUI,
            'disetujui_pada' => now(),
            'disetujui_oleh' => $request->user()->id,
        ])->save();

        return back()->with('success', "Akun {$user->name} disetujui. Sekarang bisa masuk dari aplikasi.");
    }

    public function tolak(Request $request, User $user): RedirectResponse
    {
        $this->pastikanPelanggan($user);

        $validated = $request->validate([
            'alasan' => ['required', 'string', 'max:255'],
        ], [
            'alasan.required' => 'Tuliskan alasan penolakan, supaya kalau pelanggan bertanya admin tahu jawabannya.',
        ]);

        $user->forceFill([
            'status_verifikasi' => User::STATUS_DITOLAK,
            'disetujui_pada' => null,
            'disetujui_oleh' => null,
        ])->save();

        return back()->with('success', "Akun {$user->name} ditolak: {$validated['alasan']}");
    }

    /**
     * Route model binding menyelesaikan User berdasarkan id, jadi id milik admin
     * atau kasir bisa ikut ke URL di sini. Endpoint ini mengubah status akun,
     * jadi dicegat lebih dulu supaya tidak ada yang bisa mengubah akun staff
     * dari halaman pelanggan.
     */
    private function pastikanPelanggan(User $user): void
    {
        if ($user->role !== User::ROLE_PELANGGAN) {
            abort(404, 'Akun yang dimaksud bukan pelanggan.');
        }
    }
}