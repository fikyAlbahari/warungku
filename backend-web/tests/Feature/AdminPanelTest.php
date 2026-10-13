<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminPanelTest extends TestCase
{
    use RefreshDatabase;

    private function staff(string $role): User
    {
        return User::createWithRole([
            'name' => 'Petugas',
            'email' => $role.'@warung.test',
            'password' => Hash::make('password123'),
            'status_verifikasi' => User::STATUS_DISETUJUI,
        ], $role);
    }

    public function test_halaman_admin_menolak_tamu(): void
    {
        $this->get('/admin')->assertRedirect('/login');
    }

    public function test_kasir_bisa_membuka_dashboard(): void
    {
        $this->actingAs($this->staff(User::ROLE_KASIR))->get('/admin')->assertOk();
    }

    public function test_pelanggan_ditolak_dari_panel_admin(): void
    {
        $this->actingAs($this->staff(User::ROLE_PELANGGAN))
            ->get('/admin')
            ->assertForbidden();
    }

    public function test_login_pelanggan_ditolak_di_panel_admin(): void
    {
        $user = $this->staff(User::ROLE_PELANGGAN);

        $this->post('/login', [
            'email' => $user->email,
            'password' => 'password123',
        ])->assertRedirect('/login')->assertSessionHasErrors('email');

        $this->assertGuest();
    }

    public function test_memproses_pesanan_mengurangi_stok(): void
    {
        $kasir = $this->staff(User::ROLE_KASIR);
        $pelanggan = $this->staff(User::ROLE_PELANGGAN);
        $category = Category::create(['name' => 'Sembako', 'slug' => 'sembako']);
        $product = Product::create([
            'category_id' => $category->id, 'name' => 'Beras', 'unit' => 'kg',
            'price_modal' => 13000, 'price_jual' => 15000, 'stock' => 10, 'min_stock' => 2,
        ]);

        $order = Order::create([
            'user_id' => $pelanggan->id, 'status' => Order::STATUS_PENDING,
            'shipping_cost' => 0, 'subtotal' => 15000, 'total' => 15000,
        ]);
        $order->items()->create([
            'product_id' => $product->id, 'product_name' => 'Beras',
            'price' => 15000, 'price_modal' => 13000, 'qty' => 1, 'subtotal' => 15000,
        ]);

        $this->actingAs($kasir)
            ->patch("/admin/orders/{$order->id}/status", ['status' => Order::STATUS_DIPROSES])
            ->assertRedirect();

        $this->assertSame(9, $product->fresh()->stock);
        $this->assertSame(Order::STATUS_DIPROSES, $order->fresh()->status);
    }

    public function test_memproses_pesanan_ditolak_bila_stok_tidak_cukup(): void
    {
        $kasir = $this->staff(User::ROLE_KASIR);
        $pelanggan = $this->staff(User::ROLE_PELANGGAN);
        $category = Category::create(['name' => 'Sembako', 'slug' => 'sembako']);
        $product = Product::create([
            'category_id' => $category->id, 'name' => 'Beras', 'unit' => 'kg',
            'price_modal' => 13000, 'price_jual' => 15000, 'stock' => 1, 'min_stock' => 2,
        ]);

        $order = Order::create([
            'user_id' => $pelanggan->id, 'status' => Order::STATUS_PENDING,
            'shipping_cost' => 0, 'subtotal' => 45000, 'total' => 45000,
        ]);
        $order->items()->create([
            'product_id' => $product->id, 'product_name' => 'Beras',
            'price' => 15000, 'price_modal' => 13000, 'qty' => 3, 'subtotal' => 45000,
        ]);

        $this->actingAs($kasir)
            ->patch("/admin/orders/{$order->id}/status", ['status' => Order::STATUS_DIPROSES])
            ->assertSessionHasErrors('status');

        $this->assertSame(1, $product->fresh()->stock);
        $this->assertSame(Order::STATUS_PENDING, $order->fresh()->status);
    }

    public function test_menyelesaikan_pesanan_ditolak_bila_stok_tidak_cukup(): void
    {
        $kasir = $this->staff(User::ROLE_KASIR);
        $pelanggan = $this->staff(User::ROLE_PELANGGAN);
        $category = Category::create(['name' => 'Sembako', 'slug' => 'sembako']);
        $product = Product::create([
            'category_id' => $category->id, 'name' => 'Gula', 'unit' => 'kg',
            'price_modal' => 14000, 'price_jual' => 16000, 'stock' => 0, 'min_stock' => 1,
        ]);

        $order = Order::create([
            'user_id' => $pelanggan->id, 'status' => Order::STATUS_PENDING,
            'shipping_cost' => 0, 'subtotal' => 16000, 'total' => 16000,
        ]);
        $order->items()->create([
            'product_id' => $product->id, 'product_name' => 'Gula',
            'price' => 16000, 'price_modal' => 14000, 'qty' => 1, 'subtotal' => 16000,
        ]);

        $this->actingAs($kasir)
            ->patch("/admin/orders/{$order->id}/status", ['status' => Order::STATUS_SELESAI])
            ->assertSessionHasErrors('status');

        $this->assertSame(0, $product->fresh()->stock);
        $this->assertSame(Order::STATUS_PENDING, $order->fresh()->status);
        $this->assertFalse($order->fresh()->is_paid);
    }

    public function test_kategori_yang_dipakai_produk_diarsipkan_tidak_bisa_dihapus(): void
    {
        $admin = $this->staff(User::ROLE_ADMIN);
        $category = Category::create(['name' => 'Sembako', 'slug' => 'sembako']);
        $product = Product::create([
            'category_id' => $category->id, 'name' => 'Beras', 'unit' => 'kg',
            'price_modal' => 13000, 'price_jual' => 15000, 'stock' => 5, 'min_stock' => 1,
        ]);

        $product->delete();
        $this->assertSoftDeleted($product);

        $this->actingAs($admin)
            ->delete("/admin/categories/{$category->id}")
            ->assertRedirect()
            ->assertSessionHas('error');

        $this->assertDatabaseHas('categories', ['id' => $category->id]);
    }

    public function test_kategori_tanpa_produk_bisa_dihapus(): void
    {
        $admin = $this->staff(User::ROLE_ADMIN);
        $category = Category::create(['name' => 'Kosong', 'slug' => 'kosong']);

        $this->actingAs($admin)
            ->delete("/admin/categories/{$category->id}")
            ->assertRedirect()
            ->assertSessionHas('success');

        $this->assertDatabaseMissing('categories', ['id' => $category->id]);
    }

    public function test_membatalkan_pesanan_mengembalikan_stok(): void
    {
        $kasir = $this->staff(User::ROLE_KASIR);
        $pelanggan = $this->staff(User::ROLE_PELANGGAN);
        $category = Category::create(['name' => 'Sembako', 'slug' => 'sembako']);
        $product = Product::create([
            'category_id' => $category->id, 'name' => 'Beras', 'unit' => 'kg',
            'price_modal' => 13000, 'price_jual' => 15000, 'stock' => 9, 'min_stock' => 2,
        ]);

        $order = Order::create([
            'user_id' => $pelanggan->id, 'status' => Order::STATUS_DIPROSES,
            'processed_by' => $kasir->id, 'shipping_cost' => 0, 'subtotal' => 15000, 'total' => 15000,
        ]);
        $order->items()->create([
            'product_id' => $product->id, 'product_name' => 'Beras',
            'price' => 15000, 'price_modal' => 13000, 'qty' => 1, 'subtotal' => 15000,
        ]);

        $this->actingAs($kasir)
            ->patch("/admin/orders/{$order->id}/status", ['status' => Order::STATUS_DIBATALKAN])
            ->assertRedirect();

        $this->assertSame(10, $product->fresh()->stock);
        $this->assertNotNull($order->fresh()->cancelled_at);
    }

    public function test_menyelesaikan_pesanan_menandai_lunas(): void
    {
        $kasir = $this->staff(User::ROLE_KASIR);
        $pelanggan = $this->staff(User::ROLE_PELANGGAN);

        $order = Order::create([
            'user_id' => $pelanggan->id, 'status' => Order::STATUS_DIPROSES,
            'processed_by' => $kasir->id, 'shipping_cost' => 0, 'subtotal' => 15000, 'total' => 15000,
        ]);

        $this->actingAs($kasir)
            ->patch("/admin/orders/{$order->id}/status", [
                'status' => Order::STATUS_SELESAI,
                'payment_method' => Order::PAYMENT_TUNAI,
            ])
            ->assertRedirect();

        $order->refresh();
        $this->assertSame(Order::STATUS_SELESAI, $order->status);
        $this->assertTrue($order->is_paid);
        $this->assertNotNull($order->completed_at);
    }

    public function test_hapus_produkyang_sudah_terjual_menggunakan_soft_delete(): void
    {
        $admin = $this->staff(User::ROLE_ADMIN);
        $category = Category::create(['name' => 'Sembako', 'slug' => 'sembako']);
        $product = Product::create([
            'category_id' => $category->id, 'name' => 'Gula', 'unit' => 'kg',
            'price_modal' => 14000, 'price_jual' => 15500, 'stock' => 5, 'min_stock' => 1,
        ]);

        $this->actingAs($admin)
            ->delete("/admin/products/{$product->id}")
            ->assertRedirect(route('admin.products.index'));

        $this->assertSoftDeleted($product);
    }

    public function test_validasi_produk_menolak_harga_jual_di_bawah_modal(): void
    {
        $admin = $this->staff(User::ROLE_ADMIN);
        $category = Category::create(['name' => 'Sembako', 'slug' => 'sembako']);

        $this->actingAs($admin)->post('/admin/products', [
            'category_id' => $category->id,
            'name' => 'Gula Buruk',
            'unit' => 'kg',
            'price_modal' => 15000,
            'price_jual' => 10000,
            'stock' => 5,
            'min_stock' => 1,
        ])->assertSessionHasErrors('price_jual');

        $this->assertDatabaseMissing('products', ['name' => 'Gula Buruk']);
    }

    public function test_kategori_yang_dipakai_produk_tidak_bisa_dihapus(): void
    {
        $admin = $this->staff(User::ROLE_ADMIN);
        $category = Category::create(['name' => 'Sembako', 'slug' => 'sembako']);
        Product::create([
            'category_id' => $category->id, 'name' => 'Beras', 'unit' => 'kg',
            'price_modal' => 13000, 'price_jual' => 15000, 'stock' => 5, 'min_stock' => 1,
        ]);

        $this->actingAs($admin)
            ->delete("/admin/categories/{$category->id}")
            ->assertSessionHas('error');

        $this->assertDatabaseHas('categories', ['id' => $category->id]);
    }

    public function test_halaman_kategori_menampilkan_daftar_kategori(): void
    {
        $admin = $this->staff(User::ROLE_ADMIN);
        $category = Category::create([
            'name' => 'Minuman',
            'slug' => 'minuman',
            'description' => 'Air mineral, teh, kopi.',
        ]);

        $this->actingAs($admin)
            ->get('/admin/categories')
            ->assertOk()
            ->assertViewIs('admin.categories.index')
            ->assertSee('Minuman')
            ->assertSee('minuman')
            ->assertSee('Air mineral, teh, kopi.');
    }

    public function test_halaman_kategori_menghitung_produk_arsip_dalam_jumlah_produk(): void
    {
        $admin = $this->staff(User::ROLE_ADMIN);
        $category = Category::create(['name' => 'Minuman', 'slug' => 'minuman']);

        $archived = Product::create([
            'category_id' => $category->id, 'name' => 'Teh Dingin', 'unit' => 'botol',
            'price_modal' => 4000, 'price_jual' => 6000, 'stock' => 5, 'min_stock' => 1,
        ]);
        $archived->delete();

        // Produk diarsipkan tetap menahan foreign key, jadi jumlahnya harus ikut
        // dihitung supaya tombol Hapus tampil nonaktif dan tidak mengecewakan.
        $this->actingAs($admin)
            ->get('/admin/categories')
            ->assertOk()
            ->assertSee('1 produk')
            ->assertSee('termasuk 1 arsip');
    }
}
