<?php

namespace App\Http\Controllers;

use App\Http\Requests\ProductRequest;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    public function index(Request $request): View
    {
        $products = Product::with('category')
            ->search($request->query('cari'))
            ->when(
                $request->query('kategori'),
                fn ($q, $slug) => $q->whereHas(
                    'category',
                    fn ($c) => $c->where('slug', $slug)
                )
            )
            ->when(
                $request->query('status') === 'stok-menipis',
                fn ($q) => $q->lowStock()
            )
            ->when(
                $request->boolean('arsip'),
                fn ($q) => $q->onlyTrashed()
            )
            ->orderByDesc('is_active')
            ->orderBy('name')
            ->paginate(20)
            ->withQueryString();

        return view('admin.products.index', [
            'products' => $products,
            'categories' => Category::orderBy('name')->get(),
            'filters' => $request->only(['cari', 'kategori', 'status', 'arsip']),
        ]);
    }

    public function create(): View
    {
        return view('admin.products.form', [
            'product' => new Product(['is_active' => true, 'unit' => 'pcs', 'min_stock' => 0]),
            'categories' => Category::orderBy('name')->get(),
        ]);
    }

    public function store(ProductRequest $request): RedirectResponse
    {
        $data = $request->validated();
        $data['image'] = $this->handleImage($request);

        Product::create($data);

        return redirect()
            ->route('admin.products.index')
            ->with('success', "Produk \"{$data['name']}\" berhasil ditambahkan.");
    }

    public function edit(Product $product): View
    {
        $product->load('category');

        return view('admin.products.form', [
            'product' => $product,
            'categories' => Category::orderBy('name')->get(),
        ]);
    }

    public function update(ProductRequest $request, Product $product): RedirectResponse
    {
        $data = $request->validated();

        if ($request->hasFile('image')) {
            $this->deleteImage($product->image);
            $data['image'] = $request->file('image')->store('products', 'public');
        } else {
            unset($data['image']);
        }

        $product->update($data);

        return redirect()
            ->route('admin.products.index')
            ->with('success', "Produk \"{$product->name}\" berhasil diperbarui.");
    }

    public function destroy(Product $product): RedirectResponse
    {
        $usedInOrder = $product->orderItems()->exists();

        $product->delete();

        return redirect()
            ->route('admin.products.index')
            ->with(
                'success',
                $usedInOrder
                    ? "Produk \"{$product->name}\" diarsipkan. Riwayat nota lama tetap utuh."
                    : "Produk \"{$product->name}\" berhasil dihapus."
            );
    }

    public function restore(int $product): RedirectResponse
    {
        Product::onlyTrashed()->findOrFail($product)->restore();

        return back()->with('success', 'Produk berhasil dipulihkan.');
    }

    public function adjustStock(Request $request, Product $product): RedirectResponse
    {
        $validated = $request->validate([
            'type' => ['required', 'in:masuk,keluar,set'],
            'qty' => ['required', 'integer', 'min:0'],
            'reason' => ['nullable', 'string', 'max:255'],
        ]);

        $qty = (int) $validated['qty'];

        $product->stock = match ($validated['type']) {
            'masuk' => $product->stock + $qty,
            'keluar' => max(0, $product->stock - $qty),
            'set' => $qty,
        };

        $product->save();

        return back()->with('success', "Stok {$product->name} kini {$product->stock} {$product->unit}.");
    }

    private function handleImage(ProductRequest $request): ?string
    {
        return $request->hasFile('image')
            ? $request->file('image')->store('products', 'public')
            : null;
    }

    private function deleteImage(?string $path): void
    {
        if ($path && Storage::disk('public')->exists($path)) {
            Storage::disk('public')->delete($path);
        }
    }
}
