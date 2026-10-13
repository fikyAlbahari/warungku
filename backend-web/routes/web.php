<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ExpenseController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\PelangganController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ProfileController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes - Panel Admin Warung Berkah
|--------------------------------------------------------------------------
| Hanya diakses lewat browser oleh Admin & Kasir (middleware auth + staff).
| Pelanggan tidak pernah menyentuh bagian ini, mereka pakai API /api/*.
|
*/

Route::get('/', fn () => redirect()->route('admin.dashboard'));

/* ---------- Auth Panel Admin ---------- */
Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');
});

Route::post('/logout', [AuthController::class, 'logout'])
    ->middleware('auth')
    ->name('logout');

/* ---------- Panel Admin (butuh login sebagai admin/kasir) ---------- */
Route::middleware(['auth', 'staff'])->prefix('admin')->name('admin.')->group(function () {

    // 1. Ringkasan Finansial & Omzet
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');

    // Profil akun yang sedang login (admin & kasir)
    Route::get('profil', [ProfileController::class, 'edit'])->name('profil.edit');
    Route::put('profil', [ProfileController::class, 'update'])->name('profil.update');

    // 2. Manajemen Stok / CRUD Produk
    Route::resource('products', ProductController::class)->except(['show']);
    Route::post('products/{product}/stock', [ProductController::class, 'adjustStock'])
        ->name('products.stock');
    Route::post('products/{product}/restore', [ProductController::class, 'restore'])
        ->name('products.restore');

    // Kategori produk
    Route::get('categories', [CategoryController::class, 'index'])->name('categories.index');
    Route::post('categories', [CategoryController::class, 'store'])->name('categories.store');
    Route::put('categories/{category}', [CategoryController::class, 'update'])->name('categories.update');
    Route::delete('categories/{category}', [CategoryController::class, 'destroy'])->name('categories.destroy');

    // 3. Rekap Pesanan Masuk
    Route::get('orders', [OrderController::class, 'index'])->name('orders.index');
    Route::get('orders/{order}', [OrderController::class, 'show'])->name('orders.show');
    Route::patch('orders/{order}/status', [OrderController::class, 'updateStatus'])->name('orders.status');
    Route::delete('orders/{order}', [OrderController::class, 'destroy'])->name('orders.destroy');

    // 4. Rekap Pengeluaran
    Route::get('expenses', [ExpenseController::class, 'index'])->name('expenses.index');
    Route::get('expenses/create', [ExpenseController::class, 'create'])->name('expenses.create');
    Route::post('expenses', [ExpenseController::class, 'store'])->name('expenses.store');
    Route::get('expenses/{expense}/edit', [ExpenseController::class, 'edit'])->name('expenses.edit');
    Route::put('expenses/{expense}', [ExpenseController::class, 'update'])->name('expenses.update');
    Route::delete('expenses/{expense}', [ExpenseController::class, 'destroy'])->name('expenses.destroy');
});

/* ---------- Verifikasi Akun Pelanggan (hanya Admin) ---------- */
// Pisah dari grup admin di atas dengan sengaja: kasir boleh menangani
// operasional toko, tapi tidak boleh menyetujui akun baru. Menyetujui akun
// berarti memberi akses belanja ke orang sungguhan, jadi kasir tidak cukup.
Route::middleware(['auth', 'admin'])->prefix('admin/pelanggan')->name('admin.pelanggan.')->group(function () {
    Route::get('/', [PelangganController::class, 'index'])->name('index');
    Route::post('{user}/setujui', [PelangganController::class, 'setujui'])->name('setujui');
    Route::post('{user}/tolak', [PelangganController::class, 'tolak'])->name('tolak');
});
