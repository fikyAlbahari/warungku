<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'product_id',
        'product_name',
        'price',
        'price_modal',
        'qty',
        'subtotal',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'price_modal' => 'decimal:2',
        'qty' => 'integer',
        'subtotal' => 'decimal:2',
    ];

    public function getSubtotalModalAttribute(): float
    {
        return (float) $this->price_modal * $this->qty;
    }

    public function getProfitAttribute(): float
    {
        return ((float) $this->price - (float) $this->price_modal) * $this->qty;
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
