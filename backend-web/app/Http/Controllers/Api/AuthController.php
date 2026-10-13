<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Pendaftaran akun pelanggan.
     *
     * Sengaja TIDAK mengembalikan token. Akun baru berstatus `menunggu` dan
     * baru bisa login setelah admin menyetujuinya di panel admin, jadi
     * pendaftaran tidak bisa langsung jadi pesanan.
     */
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'phone' => ['nullable', 'string', 'max:20'],
            'address' => ['nullable', 'string', 'max:1000'],
        ]);

        $user = User::createWithRole([
            ...$validated,
            // Status tetap pending walau kolomnya default 'disetujui':
            // default itu untuk akun lama, bukan untuk pendaftaran baru.
            'status_verifikasi' => User::STATUS_MENUNGGU,
            'password' => Hash::make($validated['password']),
        ], User::ROLE_PELANGGAN);

        return response()->json([
            'message' => 'Pendaftaran berhasil. Akun kamu menunggu persetujuan admin sebelum bisa masuk.',
            'data' => [
                'user' => $this->userPayload($user),
            ],
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::where('email', $credentials['email'])->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password salah.'],
            ]);
        }

        // Password benar tapi akun belum diperiksa admin. Pesannya dipisahkan
        // dari "password salah" supaya pelanggan tahu harus menunggu, bukan
        // mengira mengetik ulang password akan menolong.
        if ($user->masihMenunggu()) {
            throw ValidationException::withMessages([
                'email' => ['Akun kamu belum disetujui admin. Tunggu verifikasi dulu, lalu coba masuk lagi.'],
            ]);
        }

        if ($user->ditolak()) {
            throw ValidationException::withMessages([
                'email' => ['Pendaftaran akun kamu ditolak admin. Hubungi warung kalau ini keliru.'],
            ]);
        }

        $user->tokens()->where('name', $credentials['device_name'] ?? 'flutter')->delete();

        return response()->json([
            'message' => 'Login berhasil.',
            'data' => [
                'user' => $this->userPayload($user),
                'token' => $user->createToken($credentials['device_name'] ?? 'flutter')->plainTextToken,
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'data' => $this->userPayload($request->user()),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'address' => ['sometimes', 'nullable', 'string', 'max:1000'],
        ]);

        $user->update($validated);

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'data' => $this->userPayload($user->fresh()),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logout berhasil.']);
    }

    private function userPayload(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'status_verifikasi' => $user->status_verifikasi,
            'phone' => $user->phone,
            'address' => $user->address,
        ];
    }
}