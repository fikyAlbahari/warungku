<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ExpenseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isStaff() ?? false;
    }

    public function rules(): array
    {
        return [
            'category' => ['required', Rule::in(['kulakan', 'sewa', 'listrik', 'air', 'transport', 'gaji', 'perawatan', 'lainnya'])],
            'description' => ['required', 'string', 'max:255'],
            'amount' => ['required', 'numeric', 'min:0', 'max:99999999999.99'],
            'expense_date' => ['required', 'date', 'before_or_equal:today'],
            'receipt' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ];
    }

    public function messages(): array
    {
        return [
            'expense_date.before_or_equal' => 'Tanggal pengeluaran tidak boleh di masa depan.',
        ];
    }
}
