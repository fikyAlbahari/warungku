<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProfilTest extends TestCase
{
    use RefreshDatabase;

    private function user(): User
    {
        return User::createWithRole([
            'name' => 'Pak Budi',
            'email' => 'admin@mail.test',
            'password' => Hash::make('password123'),
        ], User::ROLE_ADMIN);
    }

    public function test_halaman_profil_tampil(): void
    {
        $this->actingAs($this->user())
            ->get(route('admin.profil.edit'))
            ->assertOk()
            ->assertSee('Data Akun')
            ->assertSee('Ganti Password');
    }

    public function test_update_nama_dan_email(): void
    {
        $user = $this->user();

        $this->actingAs($user)
            ->put(route('admin.profil.update'), [
                'name' => 'Budi Baru',
                'email' => 'budi@mail.test',
            ])
            ->assertRedirect(route('admin.profil.edit'));

        $user->refresh();
        $this->assertSame('Budi Baru', $user->name);
        $this->assertSame('budi@mail.test', $user->email);
    }

    public function test_ganti_password_butuh_password_lama(): void
    {
        $user = $this->user();

        $this->actingAs($user)
            ->put(route('admin.profil.update'), [
                'name' => 'Pak Budi',
                'email' => 'admin@mail.test',
                'current_password' => 'salah',
                'password' => 'rahasia123',
                'password_confirmation' => 'rahasia123',
            ])
            ->assertSessionHasErrors('current_password');

        $this->assertTrue(Hash::check('password123', $user->refresh()->password));
    }

    public function test_ganti_password_berhasil(): void
    {
        $user = $this->user();

        $this->actingAs($user)
            ->put(route('admin.profil.update'), [
                'name' => 'Pak Budi',
                'email' => 'admin@mail.test',
                'current_password' => 'password123',
                'password' => 'rahasia123',
                'password_confirmation' => 'rahasia123',
            ])
            ->assertSessionHasNoErrors();

        $this->assertTrue(Hash::check('rahasia123', $user->refresh()->password));
    }

    public function test_upload_foto(): void
    {
        Storage::fake('public');
        $user = $this->user();

        $this->actingAs($user)
            ->put(route('admin.profil.update'), [
                'name' => 'Pak Budi',
                'email' => 'admin@mail.test',
                'photo' => UploadedFile::fake()->image('foto.jpg', 200, 200),
            ])
            ->assertSessionHasNoErrors();

        $user->refresh();
        $this->assertNotNull($user->photo);
        Storage::disk('public')->assertExists($user->photo);
    }

    public function test_email_duplikat_ditolak(): void
    {
        $user = $this->user();
        User::createWithRole([
            'name' => 'Kasir',
            'email' => 'kasir@mail.test',
            'password' => Hash::make('password123'),
        ], User::ROLE_KASIR);

        $this->actingAs($user)
            ->put(route('admin.profil.update'), [
                'name' => 'Pak Budi',
                'email' => 'kasir@mail.test',
            ])
            ->assertSessionHasErrors('email');
    }
}
