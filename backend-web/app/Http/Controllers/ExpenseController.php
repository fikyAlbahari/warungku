<?php

namespace App\Http\Controllers;

use App\Http\Requests\ExpenseRequest;
use App\Models\Expense;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;

class ExpenseController extends Controller
{
    public function index(Request $request): View
    {
        $from = $request->filled('dari')
            ? Carbon::parse($request->query('dari'))->startOfDay()
            : Carbon::now()->startOfMonth();

        $to = $request->filled('sampai')
            ? Carbon::parse($request->query('sampai'))->endOfDay()
            : Carbon::now()->endOfMonth();

        $expenses = Expense::with('user')
            ->betweenDate($from, $to)
            ->category($request->query('kategori'))
            ->when($request->query('cari'), function ($q, $keyword) {
                $q->where('description', 'like', '%'.$keyword.'%');
            })
            ->orderByDesc('expense_date')
            ->orderByDesc('id')
            ->paginate(20)
            ->withQueryString();

        $total = (float) (clone Expense::betweenDate($from, $to)->category($request->query('kategori')))
            ->sum('amount');

        return view('admin.expenses.index', [
            'expenses' => $expenses,
            'total' => $total,
            'from' => $from->toDateString(),
            'to' => $to->toDateString(),
            'byCategory' => $this->breakdown($from, $to),
            'filters' => $request->only(['cari', 'kategori', 'dari', 'sampai']),
        ]);
    }

    public function create(): View
    {
        return view('admin.expenses.form', [
            'expense' => new Expense([
                'expense_date' => Carbon::today(),
                'category' => Expense::CATEGORY_KULAKAN,
            ]),
        ]);
    }

    public function store(ExpenseRequest $request): RedirectResponse
    {
        $data = $request->validated();
        $data['user_id'] = $request->user()->id;

        if ($request->hasFile('receipt')) {
            $data['receipt'] = $request->file('receipt')->store('receipts', 'public');
        }

        Expense::create($data);

        return redirect()
            ->route('admin.expenses.index')
            ->with('success', 'Pengeluaran berhasil dicatat.');
    }

    public function edit(Expense $expense): View
    {
        return view('admin.expenses.form', ['expense' => $expense]);
    }

    public function update(ExpenseRequest $request, Expense $expense): RedirectResponse
    {
        $data = $request->validated();

        if ($request->hasFile('receipt')) {
            $this->deleteReceipt($expense->receipt);
            $data['receipt'] = $request->file('receipt')->store('receipts', 'public');
        } else {
            unset($data['receipt']);
        }

        $expense->update($data);

        return redirect()
            ->route('admin.expenses.index')
            ->with('success', 'Pengeluaran berhasil diperbarui.');
    }

    public function destroy(Expense $expense): RedirectResponse
    {
        $this->deleteReceipt($expense->receipt);
        $expense->delete();

        return back()->with('success', 'Pengeluaran berhasil dihapus.');
    }

    private function breakdown(Carbon $from, Carbon $to): array
    {
        return Expense::betweenDate($from, $to)
            ->selectRaw('category, COALESCE(SUM(amount), 0) as total, COUNT(*) as jumlah')
            ->groupBy('category')
            ->orderByDesc('total')
            ->get()
            ->map(fn ($row) => [
                'category' => $row->category,
                'total' => (float) $row->total,
                'jumlah' => (int) $row->jumlah,
            ])
            ->all();
    }

    private function deleteReceipt(?string $path): void
    {
        if ($path && Storage::disk('public')->exists($path)) {
            Storage::disk('public')->delete($path);
        }
    }
}
