<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CheckoutRequest;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['nullable', 'string', 'in:pending,diproses,selesai,dibatalkan'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $orders = $request->user()
            ->orders()
            ->status($validated['status'] ?? null)
            ->withCount('items')
            ->paginate($validated['per_page'] ?? 15);

        return response()->json([
            'data' => $orders->getCollection()->map(fn (Order $o) => $this->summary($o)),
            'meta' => [
                'current_page' => $orders->currentPage(),
                'last_page' => $orders->lastPage(),
                'total' => $orders->total(),
            ],
        ]);
    }

    public function store(CheckoutRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $user = $request->user();

        $order = DB::transaction(function () use ($validated, $user) {
            $productIds = collect($validated['items'])->pluck('product_id')->unique();

            $products = Product::active()
                ->whereIn('id', $productIds)
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            if ($products->count() !== $productIds->count()) {
                throw ValidationException::withMessages([
                    'items' => 'Salah satu produk sudah tidak tersedia.',
                ]);
            }

            $order = Order::create([
                'user_id' => $user->id,
                'status' => Order::STATUS_PENDING,
                'payment_method' => $validated['payment_method'] ?? Order::PAYMENT_TUNAI,
                'shipping_cost' => $validated['shipping_cost'] ?? 0,
                'shipping_address' => $validated['shipping_address'],
                'note' => $validated['note'] ?? null,
            ]);

            $subtotal = 0;

            foreach ($validated['items'] as $row) {
                $product = $products[$row['product_id']];
                $lineTotal = (float) $product->price_jual * $row['qty'];

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'price' => $product->price_jual,
                    'price_modal' => $product->price_modal,
                    'qty' => $row['qty'],
                    'subtotal' => $lineTotal,
                ]);

                $subtotal += $lineTotal;
            }

            $order->forceFill([
                'subtotal' => $subtotal,
                'total' => $subtotal + (float) $order->shipping_cost,
            ])->save();

            return $order;
        });

        return response()->json([
            'message' => 'Pesanan berhasil dibuat, menunggu diproses warung.',
            'data' => $this->detail($order->fresh()->load('items')),
        ], 201);
    }

    public function show(Order $order): JsonResponse
    {
        $this->authorizeOwnership($order);

        return response()->json([
            'data' => $this->detail($order->load('items')),
        ]);
    }

    public function cancel(Order $order): JsonResponse
    {
        $this->authorizeOwnership($order);

        if ($order->status !== Order::STATUS_PENDING) {
            throw ValidationException::withMessages([
                'status' => 'Pesanan hanya bisa dibatalkan selama status masih Menunggu.',
            ]);
        }

        $order->update([
            'status' => Order::STATUS_DIBATALKAN,
            'cancelled_at' => now(),
        ]);

        return response()->json([
            'message' => 'Pesanan dibatalkan.',
            'data' => $this->detail($order->fresh()->load('items')),
        ]);
    }

    private function authorizeOwnership(Order $order): void
    {
        abort_if($order->user_id !== request()->user()->id, 403, 'Pesanan ini bukan milik Anda.');
    }

    private function summary(Order $order): array
    {
        return [
            'id' => $order->id,
            'order_number' => $order->order_number,
            'status' => $order->status,
            'total' => (float) $order->total,
            'item_count' => $order->items_count ?? $order->items()->count(),
            'created_at' => $order->created_at?->toIso8601String(),
        ];
    }

    private function detail(Order $order): array
    {
        return [
            ...$this->summary($order),
            'payment_method' => $order->payment_method,
            'is_paid' => $order->is_paid,
            'subtotal' => (float) $order->subtotal,
            'shipping_cost' => (float) $order->shipping_cost,
            'shipping_address' => $order->shipping_address,
            'note' => $order->note,
            'items' => $order->items->map(fn (OrderItem $i) => [
                'product_id' => $i->product_id,
                'product_name' => $i->product_name,
                'price' => (float) $i->price,
                'qty' => $i->qty,
                'subtotal' => (float) $i->subtotal,
            ])->all(),
        ];
    }
}
