<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')
                ->constrained('orders')
                ->cascadeOnDelete()
                ->comment('Hapus order = hapus itemnya');

            $table->foreignId('product_id')
                ->nullable()
                ->constrained('products')
                ->nullOnDelete()
                ->comment('Nullable: produk soft-deleted tidak boleh hilang dari nota lama');

            $table->string('product_name')
                ->comment('SNAPSHOT nama produk saat transaksi');
            $table->decimal('price', 14, 2)
                ->comment('SNAPSHOT harga jual per satuan saat transaksi');
            $table->decimal('price_modal', 14, 2)
                ->default(0)
                ->comment('SNAPSHOT harga modal per satuan saat transaksi, dasar hitung laba historis');
            $table->unsignedInteger('qty');
            $table->decimal('subtotal', 14, 2)
                ->comment('= price * qty, disimpan agar nota lama tidak ikut berubah saat harga produk diubah');

            $table->timestamps();

            $table->index(['order_id', 'product_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_items');
    }
};
