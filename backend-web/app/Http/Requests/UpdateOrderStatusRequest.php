<?php

namespace App\Http\Requests;

use App\Models\Order;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateOrderStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isStaff() ?? false;
    }

    public function rules(): array
    {
        return [
            'status' => ['required', Rule::in([
                Order::STATUS_DIPROSES,
                Order::STATUS_SELESAI,
                Order::STATUS_DIBATALKAN,
            ])],
            'payment_method' => ['sometimes', Rule::in([
                Order::PAYMENT_TUNAI,
                Order::PAYMENT_TRANSFER,
                Order::PAYMENT_QRIS,
            ])],
            'is_paid' => ['sometimes', 'boolean'],
        ];
    }
}
