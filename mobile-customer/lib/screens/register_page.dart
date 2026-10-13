import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/app_card.dart';
import '../widgets/swal.dart';

/// Pendaftaran akun pelanggan baru.
///
/// Setelah submit, akun berstatus `menunggu` di server dan belum bisa login
/// sampai admin menyetujuinya. Karena itu halaman ini tidakperateh ke beranda:
/// [_BerhasilMendaftarkan] menjelaskan langkah berikutnya.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final message = await context.read<AuthProvider>().register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmController.text,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    if (!mounted) return;

    if (message == null) {
      Swal.gagal(
        context,
        judul: 'Pendaftaran Gagal',
        pesan: context.read<AuthProvider>().error ?? 'Coba lagi sebentar lagi.',
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => _BerhasilMendaftarkan(message: message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoBanner(
                icon: Icons.hourglass_top_rounded,
                color: AppColors.accent,
                background: AppColors.accentSoft,
                message:
                    'Akun baru diperiksa admin dulu sebelum bisa masuk. '
                    'Kamu tetap bisa melihat dan mencari produk meantime.',
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Email wajib diisi.';
                  if (!text.contains('@')) return 'Format email belum benar.';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP (opsional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  helperText: 'Dipakai admin untuk menghubungi kalau perlu',
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Alamat (opsional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  helperText: 'Bisa diisi nanti saat checkout',
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText: 'Minimal 8 karakter',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password wajib diisi.';
                  if (value.length < 8) return 'Password minimal 8 karakter.';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passwordConfirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Ulangi Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ulangi passwordnya.';
                  }
                  if (value != _passwordController.text) {
                    return 'Dua password tidak sama.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Daftar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: auth.isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Sudah Punya Akun'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu poin penjelasan berikon, dipakai di layar penutup pendaftaran.
///
/// Bentuknya beda dari DetailRow yang sudah ada: di sini nilai justru
/// penjelasan panjang di bawah judulnya, bukan label dan angka yang disejajarkan.
class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Layar penutup setelah pendaftaran sukses.
///
/// Sengaja bukan "langsung masuk": server belum memberi token. Kalau langsung
///replace dengan beranda, user akan mengira sudah login lalu gagal saat
/// menekan tombol yang butuh sesi.
class _BerhasilMendaftarkan extends StatelessWidget {
  const _BerhasilMendaftarkan({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pendaftaran Dikirim')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 44,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Menunggu Verifikasi Admin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Yang perlu kamu tahu',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 16),
                    _InfoItem(
                      icon: Icons.login_rounded,
                      title: 'Belum bisa masuk',
                      body: 'Sampai admin menyetujui akun kamu.',
                    ),
                    _InfoItem(
                      icon: Icons.storefront_rounded,
                      title: 'Katalog tetap terbuka',
                      body: 'Kamu masih bisa melihat dan mencari produk.',
                    ),
                    _InfoItem(
                      icon: Icons.refresh_rounded,
                      title: 'Coba lagi nanti',
                      body: 'Masuk dengan email dan password yang sama setelah disetujui.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((route) => route.isFirst),
                child: const Text('Kembali ke Katalog'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
                child: const Text('Daftar Akun Lain'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}