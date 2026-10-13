import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/api_config.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/checkout_draft_provider.dart';
import 'providers/checkout_provider.dart';
import 'screens/beranda_page.dart';
import 'services/api_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Alamat server harus siap sebelum provider pertama kali dipakai. Kalau
  // ditunda, halaman katalog akan menembak host default lalu gagal.
  await ApiConfig.load();

  final api = ApiService();

  // Satu ApiService di seluruh app: token di dalamnya jadi satu-satunya
  // sumber kebenaran, dan semua provider membaca instance yang sama.
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthProvider(api)..bootstrap()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider(api)),
        ChangeNotifierProvider(create: (_) => CheckoutDraftProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider(api)),
        ChangeNotifierProvider(create: (_) => OrderListProvider(api)),
      ],
      child: const WarungNaraApp(),
    ),
  );
}

class WarungNaraApp extends StatelessWidget {
  const WarungNaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warung Nara',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _RootGate(),
    );
  }
}

/// Menahan tampilan beranda sesaat saat token dari storage dibaca,
/// supaya pelanggan tidak sempat melihat halaman login lalu terlempar balik.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final isInitializing = context.select<AuthProvider, bool>(
      (auth) => auth.isInitializing,
    );

    if (isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront, size: 60, color: AppColors.primary),
              SizedBox(height: 20),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
    }

    return const BerandaPage();
  }
}
