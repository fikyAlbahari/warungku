<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Hanya admin utama yang boleh masuk, kasir tidak cukup.
 *
 * Dipakai untuk halaman verifikasi pelanggan: menyetujui akun berarti memberi
 * akses belanja ke orang sungguhan, jadi kasir tidak cukup.
 */
class EnsureUserIsAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user) {
            return redirect()->route('login');
        }

        if (! $user->isAdmin()) {
            abort(403, 'Verifikasi pelanggan hanya untuk Admin.');
        }

        return $next($request);
    }
}