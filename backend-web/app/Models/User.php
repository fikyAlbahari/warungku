<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    public const ROLE_ADMIN = 'admin';
    public const ROLE_KASIR = 'kasir';
    public const ROLE_PELANGGAN = 'pelanggan';

    /** Status verifikasi pendaftaran, terpisah dari role. */
    public const STATUS_MENUNGGU = 'menunggu';
    public const STATUS_DISETUJUI = 'disetujui';
    public const STATUS_DITOLAK = 'ditolak';

    /**
     * `role` sengaja TIDAK ada di sini.
     *
     * Dulu ikutfillable, padahal peran hanya boleh diubah lewat panel admin.
     * Kalau tidak, `PUT /api/me` atau daftar dari aplikasi bisa membuat
     * dirinya admin hanya dengan mengirim `role=admin`.
     */
    protected $fillable = ['name', 'email', 'password', 'phone', 'address', 'photo', 'status_verifikasi'];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'disetujui_pada' => 'datetime',
        'password' => 'hashed',
    ];

    /**
     * Buat user dengan role tertentu.
     *
     * `role` tidak ada di $fillable, jadi harus lewat sini. Dipakai seeder,
     * console, dan test. Jangan dihapus proteksinya hanya supaya pemanggilan
     * `User::create(['role' => ...])` lebih ringkas: mass assignment dari
     * JSON permintaan berarti siapa pun yang punya akses token bisa mengetik
     * `role=admin` dan mendapat hak akses penuh.
     */
    public static function createWithRole(array $attributes, string $role): static
    {
        $user = new static($attributes);

        // Set langsung ke properti, bukan lewat fill(), supaya fillable tidak
        // jadi syarat di jalur ini.
        $user->role = $role;
        $user->save();

        return $user;
    }

    public function orders(): HasMany { return $this->hasMany(Order::class)->latest(); }
    public function processedOrders(): HasMany { return $this->hasMany(Order::class, 'processed_by'); }
    public function expenses(): HasMany { return $this->hasMany(Expense::class); }
    public function disetujuiOleh(): BelongsTo { return $this->belongsTo(self::class, 'disetujui_oleh'); }

    public function isAdmin(): bool { return $this->role === self::ROLE_ADMIN; }
    public function isKasir(): bool { return $this->role === self::ROLE_KASIR; }
    /** Admin dan kasir boleh masuk Web Admin. */
    public function isStaff(): bool { return in_array($this->role, [self::ROLE_ADMIN, self::ROLE_KASIR], true); }

    public function scopeStaff(Builder $query): Builder { return $query->whereIn('role', [self::ROLE_ADMIN, self::ROLE_KASIR]); }
    public function scopePelanggan(Builder $query): Builder { return $query->where('role', self::ROLE_PELANGGAN); }

    /**
     * Akun yang masih menunggu diperiksa admin.
     *
     * Hanya pelanggan yang bisa punya status ini; admin dan kasir dibuat dari
     * seeder atau console, bukan dari pendaftaran aplikasi.
     */
    public function scopeMenungguVerifikasi(Builder $query): Builder
    {
        return $query->where('status_verifikasi', self::STATUS_MENUNGGU);
    }

    public function sudahDisetujui(): bool
    {
        return $this->status_verifikasi === self::STATUS_DISETUJUI;
    }

    public function masihMenunggu(): bool
    {
        return $this->status_verifikasi === self::STATUS_MENUNGGU;
    }

    public function ditolak(): bool
    {
        return $this->status_verifikasi === self::STATUS_DITOLAK;
    }
}