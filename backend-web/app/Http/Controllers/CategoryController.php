<?php

namespace App\Http\Controllers;

use App\Models\Category;
use Illuminate\Contracts\View\View;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index(): View
    {
        return view('admin.categories.index', [
            // archived_products_count ikut dihitung karena destroy() menolak kategori
            // yang produknya masih ada, termasuk yang sudah diarsipkan. Tanpa angka ini
            // tombol Hapus terlihat bisa diklik padahal server pasti menolak.
            'categories' => Category::withCount(['products' => fn (Builder $q) => $q->withTrashed()])
                ->withCount([
                    'products as archived_products_count' => fn (Builder $q) => $q->onlyTrashed(),
                ])
                ->orderBy('name')
                ->get(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100', 'unique:categories,name'],
            'description' => ['nullable', 'string', 'max:1000'],
        ]);

        Category::create([
            ...$validated,
            'slug' => Category::uniqueSlug($validated['name']),
        ]);

        return back()->with('success', "Kategori \"{$validated['name']}\" berhasil ditambahkan.");
    }

    public function update(Request $request, Category $category): RedirectResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100', 'unique:categories,name,'.$category->id],
            'description' => ['nullable', 'string', 'max:1000'],
        ]);

        $category->update([
            'name' => $validated['name'],
            'slug' => Category::uniqueSlug($validated['name'], $category->id),
            'description' => $validated['description'] ?? null,
        ]);

        return back()->with('success', 'Kategori berhasil diperbarui.');
    }

    public function destroy(Category $category): RedirectResponse
    {
        // withTrashed() wajib: produk diarsipkan tetap punya baris di tabel
        // products, jadi foreign key ON DELETE RESTRICT akan menolak penghapusan
        // kategori dan MySQL membalas error 1451 yang tampil sebagai 500.
        $usedCount = $category->products()->withTrashed()->count();

        if ($usedCount > 0) {
            return back()->with(
                'error',
                "Kategori \"{$category->name}\" masih dipakai {$usedCount} produk. Pindahkan atau hapus produknya dulu."
            );
        }

        $category->delete();

        return back()->with('success', 'Kategori berhasil dihapus.');
    }
}
