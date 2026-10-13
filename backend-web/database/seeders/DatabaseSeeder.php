<?php

namespace Database\Seeders;

use App\Models\Expense;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
            CategorySeeder::class,
            ProductSeeder::class,
        ]);

        $this->seedDemoOrders();
        $this->seedDemoExpenses();
    }

    private function seedDemoOrders(): void
    {
        $products = Product::with('category')->get();
        $pelanggan = User::pelanggan()->get();
        $kasir = User::where('role', User::ROLE_KASIR)->first();

        if ($products->isEmpty() || $pelanggan->isEmpty()) {
            return;
        }

        $statuses = [
            Order::STATUS_SELESAI,
            Order::STATUS_SELESAI,
            Order::STATUS_DIPROSES,
            Order::STATUS_PENDING,
            Order::STATUS_DIBATALKAN,
        ];

        foreach (range(1, 25) as $i) {
            $status = $statuses[$i % count($statuses)];
            $createdAt = Carbon::now()->subDays(random_int(0, 29))->setTime(random_int(8, 20), random_int(0, 59));

            $order = Order::create([
                'user_id' => $pelanggan->random()->id,
                'processed_by' => $status === Order::STATUS_PENDING ? null : $kasir?->id,
                'status' => $status,
                'payment_method' => collect(['tunai', 'transfer', 'qris'])->random(),
                'is_paid' => $status === Order::STATUS_SELESAI,
                'shipping_cost' => 5000,
                'shipping_address' => 'Jl. Merdeka No. '.random_int(1, 99).', RT 02 / RW 05',
                'note' => $i % 5 === 0 ? 'Titip ke kasir ya, saya ambil sore.' : null,
                'processed_at' => $status !== Order::STATUS_PENDING ? $createdAt->copy()->addMinutes(10) : null,
                'completed_at' => $status === Order::STATUS_SELESAI ? $createdAt->copy()->addHour() : null,
                'cancelled_at' => $status === Order::STATUS_DIBATALKAN ? $createdAt->copy()->addMinutes(20) : null,
            ]);

            $order->forceFill(['created_at' => $createdAt, 'updated_at' => $createdAt])->save();

            $subtotal = 0;
            $picked = $products->random(random_int(1, 4));

            foreach ($picked as $product) {
                $qty = random_int(1, 5);
                $lineTotal = (float) $product->price_jual * $qty;

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'price' => $product->price_jual,
                    'price_modal' => $product->price_modal,
                    'qty' => $qty,
                    'subtotal' => $lineTotal,
                ]);

                $subtotal += $lineTotal;
            }

            $order->forceFill([
                'subtotal' => $subtotal,
                'total' => $subtotal + 5000,
            ])->save();
        }
    }

    private function seedDemoExpenses(): void
    {
        $kasir = User::whereIn('role', [User::ROLE_KASIR, User::ROLE_ADMIN])->first();

        $rows = [
            ['kulakan', 'Belanja stok 2 minggu', 1_850_000, 26],
            ['kulakan', 'Restock minuman & snack', 425_000, 18],
            ['sewa', 'Sewa kios bulan ini', 2_500_000, 25],
            ['listrik', 'Token listrik PLN', 350_000, 20],
            ['listrik', 'Listrik bulan ini', 480_000, 12],
            ['kulakan', 'Gula, garam, minyak goreng', 268_000, 9],
            ['transport', 'Ongkos angkut barang supplier', 75_000, 5],
            ['air', 'Tagihan PDAM', 145_000, 4],
            ['perawatan', 'Servis kulkas display', 200_000, 2],
            ['lainnya', 'Perlengkapan dapur (sapu,ember)', 95_000, 1],
        ];

        foreach ($rows as [$category, $description, $amount, $daysAgo]) {
            Expense::create([
                'user_id' => $kasir?->id,
                'category' => $category,
                'description' => $description,
                'amount' => $amount,
                'expense_date' => Carbon::now()->subDays($daysAgo)->toDateString(),
            ]);
        }
    }
}
