<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

class Expense extends Model
{
    use HasFactory;

    public const CATEGORY_KULAKAN = 'kulakan';

    public const CATEGORY_LAINNYA = 'lainnya';

    protected $fillable = [
        'user_id',
        'category',
        'description',
        'amount',
        'expense_date',
        'receipt',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'expense_date' => 'date',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeBetweenDate(Builder $query, ?Carbon $from, ?Carbon $to): Builder
    {
        if ($from) {
            $query->where('expense_date', '>=', $from->toDateString());
        }

        if ($to) {
            $query->where('expense_date', '<=', $to->toDateString());
        }

        return $query;
    }

    public function scopeCategory(Builder $query, ?string $category): Builder
    {
        return $category ? $query->where('category', $category) : $query;
    }
}
