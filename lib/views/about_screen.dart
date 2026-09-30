import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';


/// Halaman Tentang aplikasi
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        // Header mirroring HomeScreen: icon and title
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: colorScheme.primary, size: 26),
            const SizedBox(width: 10),
            Text(l10n.appTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.2)),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // App logo & name (placeholder)
            Center(
              child: Column(
                children: const [
                  // TODO: replace with actual logo asset
                  Icon(Icons.account_balance_wallet_rounded, size: 80),
                  SizedBox(height: 12),
                  Text('Catatan Keuangan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Deskripsi singkat
            Text(
              'Aplikasi Catatan Keuangan membantu Anda mencatat, mengelola, dan menganalisis pengeluaran serta pemasukan secara mudah dan intuitif.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // Versi aplikasi (hard‑coded placeholder)
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Versi'),
              subtitle: const Text('1.0.0'),
            ),
            const Divider(),
            // Pengembang / kontak
            ListTile(
              leading: const Icon(Icons.developer_mode_rounded),
              title: const Text('Pengembang'),
              subtitle: Text('Leona Dev'),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: const Text('leona@example.com'),
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: const Text('Website'),
              subtitle: const Text('https://leona.dev'),
            ),
            const Divider(),
            // Legal / lisensi
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Lisensi'),
              subtitle: const Text('MIT License'),
            ),
            ListTile(
              leading: const Icon(Icons.copyright_rounded),
              title: const Text('Hak Cipta'),
              subtitle: const Text('© 2026 Leona'),
            ),
            const Divider(),
            // Acknowledgements
            Text(
              'Terima kasih kepada semua library dan framework open‑source yang digunakan dalam pengembangan aplikasi ini, termasuk Flutter, Provider, dan lainnya.',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            // Kebijakan privasi & syarat penggunaan (placeholder links)
            TextButton(
              onPressed: () {
                // TODO: navigate to privacy policy page or external URL
              },
              child: const Text('Kebijakan Privasi'),
            ),
            TextButton(
              onPressed: () {
                // TODO: navigate to terms of service page or external URL
              },
              child: const Text('Syarat Penggunaan'),
            ),
          ],
        ),
      ),
    );
  }
}
