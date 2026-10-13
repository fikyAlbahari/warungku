<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index(Request $request): View
    {
        [$from, $to, $label] = $this->resolvePeriod($request);

        $orders = Order::successful()->betweenDate($from, $to);

        $revenue = (float) (clone $orders)->sum('total');
        $orderCount = (clone $orders)->count();

        $itemSold = (int) DB::table('order_items')
            ->join('orders', 'orders.id', '=', 'order_items.order_id')
            ->whereIn('orders.status', Order::STATUS_BERHASIL)
            ->whereBetween('orders.created_at', [$from, $to])
            ->sum('order_items.qty');

        $cogs = (float) DB::table('order_items')
            ->join('orders', 'orders.id', '=', 'order_items.order_id')
            ->whereIn('orders.status', Order::STATUS_BERHASIL)
            ->whereBetween('orders.created_at', [$from, $to])
            ->selectRaw('COALESCE(SUM(order_items.price_modal * order_items.qty), 0) AS cogs')
            ->value('cogs');

        $expenseTotal = (float) Expense::betweenDate($from, $to)->sum('amount');

        $grossProfit = $revenue - $cogs;
        $netProfit = $grossProfit - $expenseTotal;

        return view('admin.dashboard', [
            'periodLabel' => $label,
            'from' => $from->toDateString(),
            'to' => $to->toDateString(),

            'revenue' => $revenue,
            'cogs' => $cogs,
            'grossProfit' => $grossProfit,
            'expenseTotal' => $expenseTotal,
            'netProfit' => $netProfit,
            'orderCount' => $orderCount,
            'itemSold' => $itemSold,
            'averageOrderValue' => $orderCount > 0 ? $revenue / $orderCount : 0.0,

            'pendingOrderCount' => Order::pending()->count(),
            'lowStockProducts' => Product::lowStock()->active()
                ->with('category')
                ->orderBy('stock')
                ->limit(10)
                ->get(),

            'dailyChart' => $this->dailyChart($from, $to),
            'expenseByCategory' => $this->expenseByCategory($from, $to),
            'latestOrders' => Order::with('user')->latest()->limit(10)->get(),
        ]);
    }

    /**
     * @return array{0: Carbon, 1: Carbon, 2: string}
     */
    private function resolvePeriod(Request $request): array
    {
        $preset = $request->query('periode', 'bulan-ini');

        $map = [
            'hari-ini' => ['from' => Carbon::today(), 'to' => Carbon::today(), 'label' => 'Hari Ini'],
            '7-hari' => ['from' => Carbon::today()->subDays(6), 'to' => Carbon::today(), 'label' => '7 Hari Terakhir'],
            'bulan-ini' => ['from' => Carbon::now()->startOfMonth(), 'to' => Carbon::now()->endOfMonth(), 'label' => 'Bulan Ini'],
            'tahun-ini' => ['from' => Carbon::now()->startOfYear(), 'to' => Carbon::now()->endOfYear(), 'label' => 'Tahun Ini'],
        ];

        if (isset($map[$preset])) {
            return [$map[$preset]['from'], $map[$preset]['to'], $map[$preset]['label']];
        }

        $from = Carbon::parse($request->query('dari', Carbon::now()->startOfMonth()->toDateString()));
        $to = Carbon::parse($request->query('sampai', Carbon::today()->toDateString()));

        if ($from->gt($to)) {
            [$from, $to] = [$to, $from];
        }

        return [$from->startOfDay(), $to->endOfDay(), 'Kustom'];
    }

    private function dailyChart(Carbon $from, Carbon $to): array
    {
        $rows = Order::successful()
            ->betweenDate($from, $to)
            ->selectRaw('DATE(created_at) as tanggal, SUM(total) as omzet, COUNT(*) as jumlah')
            ->groupBy('tanggal')
            ->pluck('omzet', 'tanggal');

        $maxDays = 31;
        if ($from->diffInDays($to) > $maxDays) {
            $from = $to->copy()->subDays($maxDays - 1);
        }

        $chart = [];
        for ($date = $from->copy()->startOfDay(); $date->lte($to); $date->addDay()) {
            $key = $date->toDateString();
            $chart[] = [
                'tanggal' => $key,
                'label' => $date->translatedFormat('d M'),
                'omzet' => (float) ($rows[$key] ?? 0),
            ];
        }

        return $chart;
    }

    private function expenseByCategory(Carbon $from, Carbon $to): array
    {
        return Expense::betweenDate($from, $to)
            ->selectRaw('category, COALESCE(SUM(amount), 0) as total')
            ->groupBy('category')
            ->orderByDesc('total')
            ->get()
            ->map(fn ($row) => [
                'category' => $row->category,
                'total' => (float) $row->total,
            ])
            ->all();
    }
}
