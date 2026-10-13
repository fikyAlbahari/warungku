<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

class Order extends Model
{
    use HasFactory;

    public const STATUS_PENDING = 'pending';

    public const STATUS_DIPROSES = 'diproses';

    public const STATUS_SELESAI = 'selesai';

    public const STATUS_DIBATALKAN = 'dibatalkan';

    /** Status yang sudah masuk ke perhitungan omzet. */
    public const STATUS_BERHASIL = [self::STATUS_DIPROSES, self::STATUS_SELESAI];

    public const PAYMENT_TUNAI = 'tunai';

    public const PAYMENT_TRANSFER = 'transfer';

    public const PAYMENT_QRIS = 'qris';

    protected $fillable = [
        'order_number',
        'user_id',
        'processed_by',
        'status',
        'payment_method',
        'is_paid',
        'subtotal',
        'shipping_cost',
        'total',
        'shipping_address',
        'note',
        'processed_at',
        'completed_at',
        'cancelled_at',
    ];

    protected $casts = [
        'is_paid' => 'boolean',
        'subtotal' => 'decimal:2',
        'shipping_cost' => 'decimal:2',
        'total' => 'decimal:2',
        'processed_at' => 'datetime',
        'completed_at' => 'datetime',
        'cancelled_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (Order $order) {
            $order->order_number ??= static::generateOrderNumber();
        });
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function processedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'processed_by');
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    /** Hitung ulang subtotal & total dari item. Dipanggil setelah item berubah. */
    public function recalculateTotals(): void
    {
        $subtotal = (float) $this->items()->sum('subtotal');

        $this->forceFill([
            'subtotal' => $subtotal,
            'total' => $subtotal + (float) $this->shipping_cost,
        ])->save();
    }

    public static function generateOrderNumber(?Carbon $date = null): string
    {
        $date ??= Carbon::now();
        $prefix = 'WBRK-'.$date->format('Ymd').'-';

        do {
            $sequence = static::where('order_number', 'like', "{$prefix}%")->count() + 1;
            $number = $prefix.str_pad((string) $sequence, 4, '0', STR_PAD_LEFT);
        } while (static::where('order_number', $number)->exists());

        return $number;
    }

    public function scopeStatus(Builder $query, ?string $status): Builder
    {
        return $status ? $query->where('status', $status) : $query;
    }

    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    public function scopeSuccessful(Builder $query): Builder
    {
        return $query->whereIn('status', self::STATUS_BERHASIL);
    }

    public function scopeBetweenDate(Builder $query, ?Carbon $from, ?Carbon $to): Builder
    {
        if ($from) {
            $query->where('created_at', '>=', $from->startOfDay());
        }

        if ($to) {
            $query->where('created_at', '<=', $to->endOfDay());
        }

        return $query;
    }
}
