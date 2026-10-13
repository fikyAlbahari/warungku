<?php

namespace App\Providers;

use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // Jumlah akun yang menunggu verifikasi dipakai di sidebar panel admin,
        // supaya admin tahu ada antrean tanpa harus membuka halamannya dulu.
        // Query hanya jalan kalau yang login admin, jadi kasir tidak menambah
        // query yang tidak terpakai.
        View::composer('layouts.admin', function ($view) {
            $jumlahMenungguVerifikasi = Auth::check() && Auth::user()->isAdmin()
                ? User::pelanggan()->menungguVerifikasi()->count()
                : 0;

            $view->with('jumlahMenungguVerifikasi', $jumlahMenungguVerifikasi);
        });
    }
}