<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Sembako', 'description' => 'Beras, gula, garam, minyak goreng, terigu.'],
            ['name' => 'Minuman', 'description' => 'Air mineral, teh, kopi, minuman kaleng.'],
            ['name' => 'Snack dan Roti', 'description' => 'Biscuit, wafer, roti, camilan.'],
            ['name' => 'Kebutuhan Rumah', 'description' => 'Sabun, shampo, deterjen, tisu.'],
            ['name' => 'Tembakau', 'description' => 'Rokok.'],
        ];

        foreach ($categories as $category) {
            $name = $category['name'];
            unset($category['name']);

            Category::firstOrCreate(
                ['name' => $name],
                [...$category, 'slug' => Category::uniqueSlug($name)]
            );
        }
    }
}
