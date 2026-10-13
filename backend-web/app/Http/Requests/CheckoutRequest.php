<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CheckoutRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'items' => ['required', 'array', 'min:1', 'max:100'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.qty' => ['required', 'integer', 'min:1', 'max:9999'],

            'shipping_cost' => ['nullable', 'numeric', 'min:0', 'max:99999999999.99'],
            'shipping_address' => ['required', 'string', 'max:1000'],
            'payment_method' => ['nullable', 'string', 'in:tunai,transfer,qris'],
            'note' => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'items.required' => 'Keranjang belanja masih kosong.',
            'items.*.product_id.exists' => 'Salah satu produk sudah tidak tersedia.',
            'items.*.qty.required' => 'Jumlah barang belum diisi.',
            'shipping_address.required' => 'Alamat pengiriman wajib diisi.',
            'shipping_address.max' => 'Alamat pengiriman maksimal 1000 karakter.',
            'note.max' => 'Catatan maksimal 1000 karakter.',
            'payment_method.in' => 'Metode pembayaran tidak dikenal.',
        ];
    }
}
