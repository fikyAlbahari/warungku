<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Memaksa request /api/* diperlakukan sebagai request yang mengharapkan JSON.
 * Tanpa ini, error validasi/401 akan dibalas HTML dan Flutter tidak bisa membacanya.
 */
class ForceJsonResponse
{
    public function handle(Request $request, Closure $next): Response
    {
        $request->headers->set('Accept', 'application/json');

        return $next($request);
    }
}
