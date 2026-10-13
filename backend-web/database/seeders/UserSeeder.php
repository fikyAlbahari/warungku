<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            ['name' => 'Pak Hadi', 'email' => 'admin@warungberkah.test', 'role' => User::ROLE_ADMIN, 'phone' => '081234567890'],
            ['name' => 'Bu Sari', 'email' => 'kasir@warungberkah.test', 'role' => User::ROLE_KASIR, 'phone' => '081298765432'],
            ['name' => 'Andi', 'email' => 'andi@mail.test', 'role' => User::ROLE_PELANGGAN, 'phone' => '081111111111', 'address' => 'Jl. Kenanga No. 12, Bandung'],
            ['name' => 'Bunga', 'email' => 'bunga@mail.test', 'role' => User::ROLE_PELANGGAN, 'phone' => '082222222222', 'address' => 'Jl. Melati No. 7, Bandung'],
            ['name' => 'Candra', 'email' => 'candra@mail.test', 'role' => User::ROLE_PELANGGAN, 'phone' => '083333333333', 'address' => 'Jl. Anggrek No. 3, Cimahi'],
        ];

        foreach ($users as $user) {
            $attributes = [...$user, 'password' => Hash::make('password123')];
            $role = $attributes['role'];
            unset($attributes['role']);

            $created = User::firstOrCreate(
                ['email' => $user['email']],
                $attributes
            );

            // firstOrCreate hanya mengisi kolom yang belum ada, jadi role
            // perlu dipasang ulang di sini: kalau admin di-seed ulang, akunnya
            // tidak berubah jadi role lain.
            $created->forceFill([
                'role' => $role,
                'status_verifikasi' => User::STATUS_DISETUJUI,
            ])->save();
        }
    }
}
