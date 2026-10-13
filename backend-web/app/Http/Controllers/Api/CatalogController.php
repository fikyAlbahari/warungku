<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    public function categories(): JsonResponse
    {
        return response()->json([
            'data' => Category::orderBy('name')->get(['id', 'name', 'slug']),
        ]);
    }

    public function products(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'cari' => ['nullable', 'string', 'max:100'],
            'kategori' => ['nullable', 'string', 'max:100'],
            'stok_tersedia' => ['nullable', 'boolean'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $products = Product::active()
            ->with('category:id,name,slug')
            ->search($validated['cari'] ?? null)
            ->when(
                $validated['kategori'] ?? null,
                fn ($q, $slug) => $q->whereHas('category', fn ($c) => $c->where('slug', $slug))
            )
            ->when(
                $request->boolean('stok_tersedia'),
                fn ($q) => $q->where('stock', '>', 0)
            )
            ->orderBy('name')
            ->paginate($validated['per_page'] ?? 20);

        return response()->json([
            'data' => $products->getCollection()->map(fn (Product $p) => [
                'id' => $p->id,
                'name' => $p->name,
                'sku' => $p->sku,
                'price_jual' => (float) $p->price_jual,
                'stock' => $p->stock,
                'unit' => $p->unit,
                'image_url' => $p->image ? asset('storage/'.$p->image) : null,
                'category' => $p->category ? [
                    'id' => $p->category->id,
                    'name' => $p->category->name,
                    'slug' => $p->category->slug,
                ] : null,
            ]),
            'meta' => [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'per_page' => $products->perPage(),
                'total' => $products->total(),
            ],
        ]);
    }

    public function showProduct(Product $product): JsonResponse
    {
        abort_if(! $product->is_active || $product->trashed(), 404);

        $product->load('category:id,name,slug');

        return response()->json([
            'data' => [
                'id' => $product->id,
                'name' => $product->name,
                'sku' => $product->sku,
                'description' => $product->description,
                'price_jual' => (float) $product->price_jual,
                'stock' => $product->stock,
                'unit' => $product->unit,
                'image_url' => $product->image ? asset('storage/'.$product->image) : null,
                'category' => $product->category,
            ],
        ]);
    }
}
