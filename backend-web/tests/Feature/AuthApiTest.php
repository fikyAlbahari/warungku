<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    private function pelanggan(): User
    {
        return User::createWithRole([
            'name' => 'Andi',
            'email' => 'andi@mail.test',
            'password' => Hash::make('password123'),
            'status_verifikasi' => User::STATUS_DISETUJUI,
        ], User::ROLE_PELANGGAN);
    }

    /** Helper: `User::where(...)->tokens()` tidak ada, harus instance dulu. */
    private function carikanPelanggan(string $email): User
    {
        return User::where('email', $email)->firstOrFail();
    }

    public function test_register_menunggu_verifikasi_dan_tidak_dapat_token(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Bunga',
            'email' => 'bunga@mail.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.user.role', User::ROLE_PELANGGAN)
            ->assertJsonPath('data.user.status_verifikasi', User::STATUS_MENUNGGU)
            // Tidak ada `token` di respons: akun belum boleh masuk sebelum
            // admin menyetujuinya, jadi langsung memberi token berarti
            // pendaftaran bisa dipakai untuk membuat pesanan tanpa diperiksa.
            ->assertJsonMissingPath('data.token');

        $this->assertSame(0, $this->carikanPelanggan('bunga@mail.test')->tokens()->count());
    }

    public function test_login_ditolak_sampai_admin_setujui(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Bunga',
            'email' => 'bunga@mail.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertCreated();

        $response = $this->postJson('/api/login', [
            'email' => 'bunga@mail.test',
            'password' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('email')
            ->assertJsonFragment(['Akun kamu belum disetujui admin. Tunggu verifikasi dulu, lalu coba masuk lagi.']);

        $this->assertSame(0, $this->carikanPelanggan('bunga@mail.test')->tokens()->count());
    }

    public function test_login_berhasil_setelah_disetujui(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Bunga',
            'email' => 'bunga@mail.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertCreated();

        $user = User::where('email', 'bunga@mail.test')->firstOrFail();
        $user->update(['status_verifikasi' => User::STATUS_DISETUJUI]);

        $this->postJson('/api/login', [
            'email' => 'bunga@mail.test',
            'password' => 'password123',
        ])
            ->assertOk()
            ->assertJsonPath('data.user.status_verifikasi', User::STATUS_DISETUJUI)
            ->assertJsonStructure(['data' => ['user', 'token']]);
    }

    public function test_login_ditolak_untuk_akun_yang_ditolak_admin(): void
    {
        $user = $this->pelanggan();
        $user->update(['status_verifikasi' => User::STATUS_DITOLAK]);

        $this->postJson('/api/login', [
            'email' => 'andi@mail.test',
            'password' => 'password123',
        ])
            ->assertStatus(422)
            ->assertJsonFragment(['Pendaftaran akun kamu ditolak admin. Hubungi warung kalau ini keliru.']);
    }

    public function test_register_menolak_email_duplikat(): void
    {
        $this->pelanggan();

        $this->postJson('/api/register', [
            'name' => 'Duplikat',
            'email' => 'andi@mail.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertStatus(422)->assertJsonValidationErrors('email');
    }

    public function test_login_gagal_dengan_password_salah(): void
    {
        $this->pelanggan();

        $this->postJson('/api/login', [
            'email' => 'andi@mail.test',
            'password' => 'salah',
        ])->assertStatus(422)->assertJsonValidationErrors('email');
    }

    public function test_endpoint_terproteksi_menolak_tanpa_token(): void
    {
        $this->getJson('/api/orders')->assertUnauthorized();
    }

    public function test_checkout_membuat_pesanan_pending_dengan_stok_utuh(): void
    {
        $user = $this->pelanggan();
        $category = Category::create(['name' => 'Sembako', 'slug' => 'sembako']);
        $product = Product::create([
            'category_id' => $category->id,
            'name' => 'Beras',
            'unit' => 'kg',
            'price_modal' => 13000,
            'price_jual' => 15000,
            'stock' => 10,
            'min_stock' => 2,
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/orders', [
            'items' => [['product_id' => $product->id, 'qty' => 2]],
            'shipping_cost' => 5000,
            'shipping_address' => 'Jl. Test No. 1',
        ]);

        $response->assertCreated()->assertJsonPath('data.status', Order::STATUS_PENDING);

        $this->assertDatabaseHas('orders', [
            'user_id' => $user->id,
            'status' => Order::STATUS_PENDING,
            'subtotal' => 30000,
            'total' => 35000,
        ]);

        $this->assertDatabaseHas('order_items', [
            'product_id' => $product->id,
            'product_name' => 'Beras',
            'price' => 15000,
            'price_modal' => 13000,
            'qty' => 2,
            'subtotal' => 30000,
        ]);

        $this->assertSame(10, $product->fresh()->stock);
    }

    public function test_checkout_menolak_produk_tidak_ada(): void
    {
        $user = $this->pelanggan();

        $this->actingAs($user, 'sanctum')->postJson('/api/orders', [
            'items' => [['product_id' => 9999, 'qty' => 1]],
            'shipping_address' => 'Jl. Test No. 1',
        ])->assertStatus(422)->assertJsonValidationErrors('items.0.product_id');
    }

    public function test_pelanggan_tidak_bisa_akses_pesanan_milik_orang_lain(): void
    {
        $user = $this->pelanggan();
        $lain = User::createWithRole([
            'name' => 'Bunga',
            'email' => 'bunga@mail.test',
            'password' => Hash::make('password123'),
            'status_verifikasi' => User::STATUS_DISETUJUI,
        ], User::ROLE_PELANGGAN);

        $order = Order::create(['user_id' => $lain->id, 'status' => Order::STATUS_PENDING]);

        $this->actingAs($user, 'sanctum')
            ->getJson("/api/orders/{$order->id}")
            ->assertForbidden();
    }

    public function test_katalog_produk_terbuka_tanpa_login(): void
    {
        $category = Category::create(['name' => 'Minuman', 'slug' => 'minuman']);
        Product::create([
            'category_id' => $category->id,
            'name' => 'Air Mineral',
            'unit' => 'botol',
            'price_modal' => 2000,
            'price_jual' => 3500,
            'stock' => 10,
            'min_stock' => 2,
        ]);

        $this->getJson('/api/products')
            ->assertOk()
            ->assertJsonPath('data.0.name', 'Air Mineral')
            ->assertJsonPath('data.0.price_jual', 3500)
            ->assertJsonStructure(['data' => [['id', 'name', 'price_jual', 'stock', 'unit']], 'meta']);
    }
}
