<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Status verifikasi pendaftaran akun baru.
 *
 * Pelanggan mendaftar lewat aplikasi, tapi tidak langsung bisa login. Admin di
 * panel yang memeriksa dulu, lalu menyetujui. Tanpa ini, siapa pun bisa mendaftar
 * dan langsung membuat pesanan tanpa pernah diperiksa.
 *
 * Kolom ini sengaja terpisah dari `role`: role menentukan apa yang boleh
 * dilakukan, status menentukan boleh masuk atau tidak.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('status_verifikasi', ['menunggu', 'disetujui', 'ditolak'])
                ->default('disetujui')
                ->after('role')
                ->comment('Pelanggan baru daftar = menunggu, disetujui admin setelah diperiksa');

            $table->timestamp('disetujui_pada')->nullable()->after('status_verifikasi');
            $table->foreignId('disetujui_oleh')->nullable()->after('disetujui_pada')
                ->constrained('users')->nullOnDelete();

            $table->index(['role', 'status_verifikasi']);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['disetujui_oleh']);
            $table->dropIndex(['role', 'status_verifikasi']);
            $table->dropColumn(['status_verifikasi', 'disetujui_pada', 'disetujui_oleh']);
        });
    }
};