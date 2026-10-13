<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_number', 30)->unique()
                ->comment('No. nota manusia, mis. WBRK-20260115-0007');

            $table->foreignId('user_id')
                ->constrained('users')
                ->restrictOnDelete()
                ->comment('Pelanggan pemilik pesanan');
            $table->foreignId('processed_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete()
                ->comment('Kasir/admin yang memproses pesanan');

            $table->enum('status', ['pending', 'diproses', 'selesai', 'dibatalkan'])
                ->default('pending')
                ->index()
                ->comment('pending=menunggu-acc kasir, diproses=stok_reserved, selesai=stok_final');

            $table->enum('payment_method', ['tunai', 'transfer', 'qris'])->default('tunai');
            $table->boolean('is_paid')->default(false);

            $table->decimal('subtotal', 14, 2)->default(0);
            $table->decimal('shipping_cost', 14, 2)->default(0);
            $table->decimal('total', 14, 2)->default(0)
                ->comment('Disimpan denormalisasi agar rekap omzet tidak perlu join saat baca');

            $table->text('shipping_address')->nullable();
            $table->text('note')->nullable()->comment('Catatan pelanggan, mis. titip di satpam');

            $table->timestamp('processed_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();

            $table->timestamps();

            $table->index(['status', 'created_at'], 'orders_status_created_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
