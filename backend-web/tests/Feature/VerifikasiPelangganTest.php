<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class VerifikasiPelangganTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::createWithRole([
            'name' => 'Pak Budi',
            'email' => 'admin@mail.test',
            'password' => Hash::make('password123'),
        ], User::ROLE_ADMIN);
    }

    private function kasir(): User
    {
        return User::createWithRole([
            'name' => 'Kasir',
            'email' => 'kasir@mail.test',
            'password' => Hash::make('password123'),
        ], User::ROLE_KASIR);
    }

    private function menunggu(string $email = 'bunga@mail.test'): User
    {
        return User::createWithRole([
            'name' => 'Bunga',
            'email' => $email,
            'password' => Hash::make('password123'),
            'status_verifikasi' => User::STATUS_MENUNGGU,
        ], User::ROLE_PELANGGAN);
    }

    public function test_admin_melihat_antrean_pelanggan_menunggu(): void
    {
        $p = $this->menunggu();

        $this->actingAs($this->admin())
            ->get(route('admin.pelanggan.index'))
            ->assertOk()
            ->assertSee($p->name)
            ->assertSee($p->email)
            ->assertSee('Setujui');
    }

    public function test_kasir_tidak_bisa_membuka_halaman_verifikasi(): void
    {
        $this->actingAs($this->kasir())
            ->get(route('admin.pelanggan.index'))
            ->assertForbidden();
    }

    public function test_tamu_diarahkan_ke_login(): void
    {
        $this->get(route('admin.pelanggan.index'))->assertRedirect(route('login'));
    }

    public function test_admin_bisa_menyetujui_pelanggan(): void
    {
        $admin = $this->admin();
        $p = $this->menunggu();

        $this->actingAs($admin)
            ->post(route('admin.pelanggan.setujui', $p))
            ->assertRedirect();

        $this->assertDatabaseHas('users', [
            'id' => $p->id,
            'status_verifikasi' => User::STATUS_DISETUJUI,
            'disetujui_oleh' => $admin->id,
        ]);

        $this->assertNotNull($p->fresh()->disetujui_pada);
    }

    public function test_admin_bisa_menolak_pelanggan_dengan_alasan(): void
    {
        $admin = $this->admin();
        $p = $this->menunggu();

        $this->actingAs($admin)
            ->post(route('admin.pelanggan.tolak', $p), ['alasan' => 'nomor HP tidak aktif'])
            ->assertRedirect();

        $this->assertDatabaseHas('users', [
            'id' => $p->id,
            'status_verifikasi' => User::STATUS_DITOLAK,
            'disetujui_oleh' => null,
        ]);
    }

    public function test_menolak_tanpa_alasan_ditolak_server(): void
    {
        $p = $this->menunggu();

        $this->actingAs($this->admin())
            ->post(route('admin.pelanggan.tolak', $p))
            ->assertSessionHasErrors('alasan');

        $this->assertSame(User::STATUS_MENUNGGU, $p->fresh()->status_verifikasi);
    }

    public function test_kasir_tidak_bisa_menyetujui_akun(): void
    {
        $p = $this->menunggu();

        $this->actingAs($this->kasir())
            ->post(route('admin.pelanggan.setujui', $p))
            ->assertForbidden();

        $this->assertSame(User::STATUS_MENUNGGU, $p->fresh()->status_verifikasi);
    }

    /**
     * Route model binding menerima id apa pun, termasuk akun staff. Kalau tidak
     * dicegat, admin bisa mengetik /pelanggan/{id kasir}/setujui dan mengubah
     * status akun yang bukan pelanggan.
     */
    public function test_endpoint_verifikasi_menolak_akun_non_pelanggan(): void
    {
        $admin = $this->admin();
        $kasir = $this->kasir();

        $this->actingAs($admin)
            ->post(route('admin.pelanggan.setujui', $kasir))
            ->assertNotFound();
    }

    public function test_link_verifikasi_paling_ada_di_sidebar(): void
    {
        $this->actingAs($this->admin())
            ->get(route('admin.dashboard'))
            ->assertSee(route('admin.pelanggan.index'), false);

        $this->actingAs($this->kasir())
            ->get(route('admin.dashboard'))
            ->assertDontSee(route('admin.pelanggan.index'), false);
    }
}