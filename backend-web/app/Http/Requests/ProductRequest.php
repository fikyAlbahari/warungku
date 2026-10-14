<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isStaff() ?? false;
    }

    public function rules(): array
    {
        $productId = $this->route('product')?->id;

        return [
            'category_id' => ['nullable', 'integer', 'exists:categories,id', 'required_without:new_category'],
            'new_category' => ['nullable', 'string', 'max:100'],
            'name' => ['required', 'string', 'max:255'],
            'sku' => ['nullable', 'string', 'max:50', Rule::unique('products', 'sku')->ignore($productId)],
            'barcode' => ['nullable', 'string', 'max:50', Rule::unique('products', 'barcode')->ignore($productId)],
            'unit' => ['required', Rule::in(['pcs', 'pack', 'box', 'kg', 'gram', 'liter', 'botol', 'biji', 'renteng', 'sachet'])],
            'price_modal' => ['required', 'numeric', 'min:0', 'max:99999999999.99'],
            'price_jual' => ['required', 'numeric', 'min:0', 'max:99999999999.99', 'gte:price_modal'],
            'stock' => ['required', 'integer', 'min:0'],
            'min_stock' => ['required', 'integer', 'min:0'],
            'description' => ['nullable', 'string', 'max:1000'],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'is_active' => ['boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'category_id.required_without' => 'Pilih kategori atau isi nama kategori baru.',
            'price_jual.gte' => 'Harga jual harus lebih besar atau sama dengan harga modal.',
            'image.max' => 'Ukuran foto produk maksimal 2 MB.',
        ];
    }

    protected function prepareForValidation(): void
    {
        $newCategory = $this->input('new_category');
        $categoryId = $this->input('category_id');

        $this->merge([
            'category_id' => ($categoryId === '__baru__' || blank($categoryId)) ? null : $categoryId,
            'new_category' => blank($newCategory) ? null : $newCategory,
            'is_active' => $this->boolean('is_active'),
        ]);
    }
}
