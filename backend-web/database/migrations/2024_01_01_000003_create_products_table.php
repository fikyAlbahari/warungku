<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')
                ->constrained('categories')
                ->restrictOnDelete()
                ->comment('Produk wajib punya kategori agar filter katalog konsisten');

            $table->string('name');
            $table->string('sku', 50)->nullable()->unique()->comment('Kode internal warung');
            $table->string('barcode', 50)->nullable()->index()->comment('Dipakai saat scan di kasir');

            $table->enum('unit', ['pcs', 'pack', 'box', 'kg', 'gram', 'liter', 'botol', 'biji', 'renteng', 'sachet'])
                ->default('pcs')
                ->comment('Satuan jual, mis. pcs / pack / kg');

            $table->decimal('price_modal', 14, 2)
                ->comment('Harga beli dari supplier. Dasar hitung laba & HPP');
            $table->decimal('price_jual', 14, 2)
                ->comment('Harga jual ke pelanggan');

            $table->unsignedInteger('stock')->default(0)->comment('Stok ready, satuan sama dengan unit');
            $table->unsignedInteger('min_stock')->default(0)
                ->comment('Ambang stok menipis, dashboard & API tandai produk ini');

            $table->text('description')->nullable();
            $table->string('image')->nullable()->comment('Path foto produk');
            $table->boolean('is_active')->default(true)->index();

            $table->timestamps();
            $table->softDeletes();

            $table->index(['category_id', 'is_active'], 'products_category_active_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
