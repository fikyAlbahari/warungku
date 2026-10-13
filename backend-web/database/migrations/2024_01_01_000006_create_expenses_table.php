<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('expenses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete()
                ->comment('Kasir/admin yang mencatat pengeluaran');

            $table->enum('category', ['kulakan', 'sewa', 'listrik', 'air', 'transport', 'gaji', 'perawatan', 'lainnya'])
                ->default('kulakan')
                ->index()
                ->comment('kulakan = belanja stok, sisanya biaya operasional warung');

            $table->string('description');
            $table->decimal('amount', 14, 2);

            $table->date('expense_date')
                ->comment('Tanggal transaksi, DIKTASAKAN dari created_at supaya rekap bulanan tetap benar saat input Mundur');
            $table->string('receipt', 255)->nullable()->comment('Path/nama file bukti belanja');

            $table->timestamps();

            $table->index(['expense_date', 'category'], 'expenses_date_category_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('expenses');
    }
};
