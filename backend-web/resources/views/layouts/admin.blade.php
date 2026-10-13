<!DOCTYPE html>
<html lang="id">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Dashboard') — Warung Berkah</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body { font-family: Inter, system-ui, -apple-system, "Segoe UI", sans-serif; }

        #sidebar { transition: width .3s ease; }
        #sidebar.mini { width: 4.5rem; }
        #sidebar.mini .sidebar-teks,
        #sidebar.mini .sidebar-mini-hide { display: none; }
        #sidebar.mini .sidebar-kepala { justify-content: center; padding-left: 1rem; padding-right: 1rem; }
        #sidebar.mini nav a { justify-content: center; }
        #sidebar.mini .sidebar-profil { justify-content: center; }
        #sidebar.mini .sidebar-kaki { padding-left: .5rem; padding-right: .5rem; }
    </style>
</head>

<body class="bg-slate-100 text-slate-900">
    <div class="flex h-screen overflow-hidden">
        <aside id="sidebar" class="flex h-full w-64 shrink-0 flex-col bg-gradient-to-b from-teal-800 to-teal-900 text-white shadow-xl">
            <div class="sidebar-kepala flex items-center gap-3 border-b border-white/10 px-6 py-5">
                <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-amber-400 text-teal-900 shadow-sm">
                    <span class="text-lg font-bold">W</span>
                </div>
                <div class="sidebar-teks min-w-0">
                    <div class="truncate text-lg font-bold leading-tight">Warung Berkah</div>
                    <div class="text-xs text-teal-100/80">Admin Panel</div>
                </div>
                <button type="button" id="tombol-tutup-sidebar" title="Tutup sidebar"
                    class="sidebar-mini-hide ml-auto rounded-lg p-1.5 text-teal-100/80 transition hover:bg-white/10 hover:text-white focus:outline-none focus:ring-2 focus:ring-white/30">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
                    </svg>
                </button>
            </div>

            <nav class="mt-3 flex flex-1 flex-col gap-1 overflow-y-auto px-3 pb-4">
                <a href="{{ route('admin.dashboard') }}" title="Dashboard"
                    class="{{ request()->routeIs('admin.dashboard') ? 'bg-white/20 text-white shadow-sm ring-1 ring-white/20' : 'text-teal-100/90 hover:bg-white/10 hover:text-white' }} group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5 shrink-0">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" />
                    </svg>
                    <span class="sidebar-teks">Dashboard</span>
                </a>
                <a href="{{ route('admin.orders.index') }}" title="Pesanan Masuk"
                    class="{{ request()->routeIs('admin.orders.*') ? 'bg-white/20 text-white shadow-sm ring-1 ring-white/20' : 'text-teal-100/90 hover:bg-white/10 hover:text-white' }} group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5 shrink-0">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 3h1.386c.51 0 .955.343 1.087.835l.383 1.437M7.5 14.25a3 3 0 00-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 00-16.536-1.84M7.5 14.25L5.106 5.272M6 20.25a.75.75 0 11-1.5 0 .75.75 0 011.5 0zm12.75 0a.75.75 0 11-1.5 0 .75.75 0 011.5 0z" />
                    </svg>
                    <span class="sidebar-teks">Pesanan Masuk</span>
                </a>
                <a href="{{ route('admin.products.index') }}" title="Manajemen Stok"
                    class="{{ request()->routeIs('admin.products.*') ? 'bg-white/20 text-white shadow-sm ring-1 ring-white/20' : 'text-teal-100/90 hover:bg-white/10 hover:text-white' }} group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5 shrink-0">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
                    </svg>
                    <span class="sidebar-teks">Manajemen Stok</span>
                </a>
                <a href="{{ route('admin.categories.index') }}" title="Kategori Produk"
                    class="{{ request()->routeIs('admin.categories.*') ? 'bg-white/20 text-white shadow-sm ring-1 ring-white/20' : 'text-teal-100/90 hover:bg-white/10 hover:text-white' }} group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5 shrink-0">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9.568 3H5.25A2.25 2.25 0 003 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 005.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 009.568 3z" />
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 6h.008v.008H6V6z" />
                    </svg>
                    <span class="sidebar-teks">Kategori Produk</span>
                </a>
                <a href="{{ route('admin.expenses.index') }}" title="Pengeluaran"
                    class="{{ request()->routeIs('admin.expenses.*') ? 'bg-white/20 text-white shadow-sm ring-1 ring-white/20' : 'text-teal-100/90 hover:bg-white/10 hover:text-white' }} group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5 shrink-0">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75M15 10.5a3 3 0 11-6 0 3 3 0 016 0zm3 0h.008v.008H18V10.5zm-12 0h.008v.008H6V10.5z" />
                    </svg>
                    <span class="sidebar-teks">Pengeluaran</span>
                </a>
                @if (auth()->user()?->isAdmin())
                    <a href="{{ route('admin.pelanggan.index') }}" title="Pelanggan"
                        class="{{ request()->routeIs('admin.pelanggan.*') ? 'bg-white/20 text-white shadow-sm ring-1 ring-white/20' : 'text-teal-100/90 hover:bg-white/10 hover:text-white' }} group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5 shrink-0">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
                        </svg>
                        <span class="sidebar-teks">Pelanggan</span>
                        @if ($jumlahMenungguVerifikasi > 0)
                            <span class="sidebar-mini-hide ml-auto rounded-full bg-amber-400 px-2 py-0.5 text-xs font-semibold text-teal-900">{{ $jumlahMenungguVerifikasi }}</span>
                        @endif
                    </a>
                @endif
            </nav>

            <div class="sidebar-kaki border-t border-white/10 px-3 pb-4 pt-3">
                <a href="{{ route('admin.profil.edit') }}" title="Profil saya"
                    class="sidebar-profil flex items-center gap-3 rounded-xl bg-white/10 px-3 py-2.5 ring-1 ring-white/10 transition hover:bg-white/20">
                    @if (auth()->user()?->photo)
                        <img src="{{ asset('storage/'.auth()->user()->photo) }}" alt="Foto profil"
                            class="h-9 w-9 shrink-0 rounded-full object-cover">
                    @else
                        <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-amber-400 text-sm font-bold text-teal-900">
                            {{ strtoupper(substr(auth()->user()?->name ?? 'A', 0, 1)) }}
                        </div>
                    @endif
                    <div class="sidebar-teks min-w-0 flex-1">
                        <div class="truncate text-sm font-medium text-white">{{ auth()->user()?->name }}</div>
                        <div class="truncate text-xs capitalize text-teal-100/70">{{ auth()->user()?->role ?? '' }}</div>
                    </div>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                        stroke="currentColor" class="sidebar-teks h-4 w-4 shrink-0 text-teal-100/60">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
                    </svg>
                </a>
                <form method="POST" action="{{ route('logout') }}" class="mt-2">
                    @csrf
                    <button type="submit" title="Keluar"
                        class="flex w-full items-center justify-center gap-2 rounded-lg bg-white/10 px-3 py-2 text-sm font-medium text-white transition hover:bg-white/20 focus:outline-none focus:ring-2 focus:ring-white/30">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-4 w-4 shrink-0">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
                        </svg>
                        <span class="sidebar-teks">Keluar</span>
                    </button>
                </form>
            </div>
        </aside>

        <div class="flex min-w-0 flex-1 flex-col overflow-y-auto">
            <header class="border-b border-slate-200 bg-white shadow-sm">
                <div class="mx-auto flex w-full max-w-7xl items-center justify-between px-4 py-3.5 sm:px-6 lg:px-8">
                    <div class="flex items-center gap-3">
                        <button type="button" id="tombol-buka-sidebar" title="Buka sidebar"
                            class="hidden rounded-lg border border-slate-200 p-2 text-slate-600 shadow-sm transition hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-teal-500/30">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
                            </svg>
                        </button>
                        <div>
                            <nav class="flex items-center gap-1.5 text-xs text-slate-400">
                                <span>Admin</span>
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-3 w-3">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
                                </svg>
                                <span class="font-medium text-slate-600">@yield('title', 'Dashboard')</span>
                            </nav>
                            <h1 class="text-lg font-semibold tracking-tight text-slate-900 sm:text-xl">@yield('title', 'Dashboard')</h1>
                        </div>
                    </div>
                    <div class="hidden text-right sm:block">
                        <div class="text-xs text-slate-400">Masuk sebagai</div>
                        <div class="text-sm font-medium capitalize text-slate-700">{{ auth()->user()?->role ?? '' }}</div>
                    </div>
                </div>
            </header>

            <main class="mx-auto w-full max-w-7xl flex-1 px-4 py-6 sm:px-6 lg:px-8">
                @yield('content')
            </main>
        </div>
    </div>

    <script type="application/json" id="flash-notifikasi">{!! json_encode([
        'success' => session('success'),
        'error' => session('error'),
        'errors' => $errors->all(),
    ], JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_AMP | JSON_HEX_QUOT) !!}</script>
</body>

</html>
