<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('role', ['admin', 'kasir', 'pelanggan'])
                ->default('pelanggan')
                ->after('password')
                ->comment('Hak akses: admin=kelola penuh, kasir=operasional, pelanggan=belanja via app');

            $table->string('phone', 20)->nullable()->after('role');
            $table->text('address')->nullable()->after('phone')->comment('Alamat pengiriman pelanggan');

            $table->index('role');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['role']);
            $table->dropColumn(['role', 'phone', 'address']);
        });
    }
};
