<?php

namespace App\Http\Controllers;

use App\Http\Requests\UpdateOrderStatusRequest;
use App\Models\Order;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class OrderController extends Controller
{
    public function index(Request $request): View
    {
        $orders = Order::with(['user', 'processedBy'])
            ->status($request->query('status'))
            ->betweenDate($this->from($request), $this->to($request))
            ->when($request->query('cari'), function ($q, $keyword) {
                $like = '%'.$keyword.'%';

                $q->where(function ($sub) use ($like) {
                    $sub->where('order_number', 'like', $like)
                        ->orWhereHas('user', fn ($u) => $u->where('name', 'like', $like));
                });
            })
            ->latest()
            ->paginate(20)
            ->withQueryString();

        $statusCounts = Order::selectRaw('status, COUNT(*) as jumlah')
            ->groupBy('status')
            ->pluck('jumlah', 'status');

        return view('admin.orders.index', [
            'orders' => $orders,
            'statusCounts' => $statusCounts,
            'filters' => $request->only(['status', 'cari', 'dari', 'sampai']),
        ]);
    }

    public function show(Order $order): View
    {
        $order->load(['user', 'processedBy', 'items.product']);

        return view('admin.orders.show', [
            'order' => $order,
        ]);
    }

    public function updateStatus(UpdateOrderStatusRequest $request, Order $order): RedirectResponse
    {
        $newStatus = $request->validated('status');

        DB::transaction(function () use ($order, $request, $newStatus) {
            $order = Order::query()->lockForUpdate()->findOrFail($order->id);

            $oldStatus = $order->status;

            if ($oldStatus === $newStatus) {
                return;
            }

            $wasCounted = in_array($oldStatus, Order::STATUS_BERHASIL, true);
            $willBeCounted = in_array($newStatus, Order::STATUS_BERHASIL, true);

            if ($newStatus === Order::STATUS_DIBATALKAN) {
                $this->assertStockRestorable($order);
            }

            if (! $wasCounted && $willBeCounted) {
                $this->assertStockAvailable($order);
            }

            if (! $wasCounted && $willBeCounted) {
                $this->deductStock($order);
            } elseif ($wasCounted && ! $willBeCounted) {
                $this->restoreStock($order);
            }

            $order->status = $newStatus;
            $order->processed_by ??= $request->user()->id;

            if ($newStatus === Order::STATUS_DIPROSES && ! $order->processed_at) {
                $order->processed_at = Carbon::now();
            }

            if ($newStatus === Order::STATUS_SELESAI) {
                $order->completed_at = Carbon::now();
                $order->processed_at ??= Carbon::now();
                $order->is_paid = true;
            }

            if ($newStatus === Order::STATUS_DIBATALKAN) {
                $order->cancelled_at = Carbon::now();
                $order->is_paid = false;
            }

            if ($request->filled('payment_method')) {
                $order->payment_method = $request->validated('payment_method');
            }

            if ($request->has('is_paid')) {
                $order->is_paid = $request->boolean('is_paid');
            }

            $order->save();
        });

        return back()->with('success', "Status pesanan {$order->order_number} diubah menjadi {$newStatus}.");
    }

    public function destroy(Order $order): RedirectResponse
    {
        abort_unless(
            $order->status === Order::STATUS_DIBATALKAN,
            403,
            'Hanya pesanan yang sudah dibatalkan yang boleh dihapus.'
        );

        $order->delete();

        return back()->with('success', "Pesanan {$order->order_number} dihapus.");
    }

    private function deductStock(Order $order): void
    {
        foreach ($order->items as $item) {
            if (! $item->product) {
                continue;
            }

            $product = $item->product;

            // max(0, ...) menjaga kolom products.stock yang bertipe
            // unsigned tetap aman walau ada balapan data. Pengecekan stok
            // sebenarnya sudah dilakukan assertStockAvailable() di atas.
            $product->update(['stock' => max(0, $product->stock - $item->qty)]);
        }
    }

    private function restoreStock(Order $order): void
    {
        foreach ($order->items as $item) {
            if (! $item->product) {
                continue;
            }

            $item->product->increment('stock', $item->qty);
        }
    }

    /**
     * Menolak pemrosesan bila stok tidak cukup.
     *
     * Tanpa pengecekan ini, decrement membuat kolom bertipe UNSIGNED
     * bernilai negatif dan MySQL membalas SQLSTATE[22003] yang muncul
     * sebagai halaman error 500, bukan pesan yang bisa dibaca kasir.
     */
    private function assertStockAvailable(Order $order): void
    {
        $shortages = [];

        foreach ($order->items as $item) {
            $product = $item->product;

            if (! $product) {
                continue;
            }

            if ($product->stock < $item->qty) {
                $shortages[] = "{$product->name} (butuh {$item->qty}, tersedia {$product->stock})";
            }
        }

        if ($shortages) {
            throw ValidationException::withMessages([
                'status' => 'Stok tidak cukup untuk memproses pesanan ini: '.implode('; ', $shortages),
            ]);
        }
    }

    /**
     * Menolak pembatalan bila produk di pesanan sudah tidak bisa dikembalikan
     * ke katalog, misalnya produknya diarsipkan.
     */
    private function assertStockRestorable(Order $order): void
    {
        $missing = [];

        foreach ($order->items as $item) {
            if (! $item->product) {
                $missing[] = $item->product_name;
            }
        }

        if ($missing) {
            throw ValidationException::withMessages([
                'status' => 'Stok tidak bisa dikembalikan karena produk sudah diarsipkan: '
                    .implode(', ', $missing).'. Pulihkan produknya di Manajemen Stok terlebih dulu.',
            ]);
        }
    }

    private function from(Request $request): ?Carbon
    {
        return $request->filled('dari') ? Carbon::parse($request->query('dari'))->startOfDay() : null;
    }

    private function to(Request $request): ?Carbon
    {
        return $request->filled('sampai') ? Carbon::parse($request->query('sampai'))->endOfDay() : null;
    }
}
