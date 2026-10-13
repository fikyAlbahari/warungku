<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $products = [
            ['category' => 'Sembako', 'name' => 'Beras Pandan Wangi', 'unit' => 'kg', 'price_modal' => 13500, 'price_jual' => 15500, 'stock' => 45, 'min_stock' => 5],
            ['category' => 'Sembako', 'name' => 'Beras Premium', 'unit' => 'kg', 'price_modal' => 16800, 'price_jual' => 19000, 'stock' => 20, 'min_stock' => 5],
            ['category' => 'Sembako', 'name' => 'Gula Pasir Gulaku', 'unit' => 'kg', 'price_modal' => 14000, 'price_jual' => 15500, 'stock' => 30, 'min_stock' => 4],
            ['category' => 'Sembako', 'name' => 'Minyak Goreng Kita', 'unit' => 'liter', 'price_modal' => 14500, 'price_jual' => 16500, 'stock' => 24, 'min_stock' => 6],
            ['category' => 'Sembako', 'name' => 'Garam Halus', 'unit' => 'pack', 'price_modal' => 1500, 'price_jual' => 2000, 'stock' => 8, 'min_stock' => 10],
            ['category' => 'Sembako', 'name' => 'Telur Ayam Negeri', 'unit' => 'kg', 'price_modal' => 27000, 'price_jual' => 30000, 'stock' => 12, 'min_stock' => 3],

            ['category' => 'Minuman', 'name' => 'Air Mineral 600ml', 'unit' => 'botol', 'price_modal' => 2000, 'price_jual' => 3500, 'stock' => 96, 'min_stock' => 24],
            ['category' => 'Minuman', 'name' => 'Air Mineral 1.5L', 'unit' => 'botol', 'price_modal' => 4500, 'price_jual' => 6000, 'stock' => 40, 'min_stock' => 12],
            ['category' => 'Minuman', 'name' => 'Teh Kotak Sosro', 'unit' => 'pcs', 'price_modal' => 3800, 'price_jual' => 5000, 'stock' => 60, 'min_stock' => 12],
            ['category' => 'Minuman', 'name' => 'Kopi Kapal Api Sachet', 'unit' => 'sachet', 'price_modal' => 1000, 'price_jual' => 1500, 'stock' => 150, 'min_stock' => 30],
            ['category' => 'Minuman', 'name' => 'Susu UHT Ultra', 'unit' => 'pcs', 'price_modal' => 5200, 'price_jual' => 6500, 'stock' => 18, 'min_stock' => 12],

            ['category' => 'Snack dan Roti', 'name' => 'Roti Sari Roti Tawar', 'unit' => 'pack', 'price_modal' => 15500, 'price_jual' => 17500, 'stock' => 14, 'min_stock' => 5],
            ['category' => 'Snack dan Roti', 'name' => 'Biscuit Khong Guan', 'unit' => 'pack', 'price_modal' => 8500, 'price_jual' => 10000, 'stock' => 25, 'min_stock' => 6],
            ['category' => 'Snack dan Roti', 'name' => 'Wafer Beng-Beng', 'unit' => 'pcs', 'price_modal' => 900, 'price_jual' => 1500, 'stock' => 200, 'min_stock' => 40],

            ['category' => 'Kebutuhan Rumah', 'name' => 'Sabun Mandi Lifebuoy', 'unit' => 'pcs', 'price_modal' => 3800, 'price_jual' => 5000, 'stock' => 32, 'min_stock' => 8],
            ['category' => 'Kebutuhan Rumah', 'name' => 'Deterjen Rinso', 'unit' => 'pack', 'price_modal' => 12500, 'price_jual' => 14500, 'stock' => 9, 'min_stock' => 4],
            ['category' => 'Kebutuhan Rumah', 'name' => 'Tisu Sapi', 'unit' => 'pack', 'price_modal' => 4200, 'price_jual' => 5500, 'stock' => 22, 'min_stock' => 6],

            ['category' => 'Tembakau', 'name' => 'Rokok Kretek 12', 'unit' => 'biji', 'price_modal' => 22000, 'price_jual' => 25000, 'stock' => 16, 'min_stock' => 5],
        ];

        foreach ($products as $row) {
            $category = Category::where('name', $row['category'])->first();

            if (! $category) {
                continue;
            }

            $name = $row['name'];
            unset($row['category'], $row['name']);

            Product::firstOrCreate(
                ['name' => $name],
                [...$row, 'category_id' => $category->id, 'is_active' => true]
            );
        }
    }
}
