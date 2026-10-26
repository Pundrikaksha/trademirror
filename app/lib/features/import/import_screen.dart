import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/store.dart';
import '../../app/widgets.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  Future<void> _loadSample(BuildContext context) async {
    final ok = await mirrorStore.loadSample();
    if (ok && context.mounted) context.go('/dashboard');
  }

  Future<void> _pickFile(BuildContext context) async {
    mirrorStore.setLoading(true);
    try {
      // withData gives bytes on every platform, including web.
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        mirrorStore.showError('Could not read "${file.name}".');
        return;
      }
      final text = utf8.decode(bytes, allowMalformed: true);
      final ok = mirrorStore.importText(text, name: file.name);
      if (ok && context.mounted) context.go('/dashboard');
    } catch (e) {
      mirrorStore.showError('Could not open the file: $e');
    } finally {
      mirrorStore.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV')),
      body: StoreBuilder(
        builder: (context, store) => ListView(
          children: [
            if (store.isSample && store.result != null) const SyntheticBanner(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.file_upload_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'See your true F&O P&L',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import a Kotak Neo tradebook CSV (trade report columns '
                    'flDt, flTm, nOrdNo, trdSym, trnsTp, fldQty, avgPrc ...). '
                    'TradeMirror matches your fills into round trips, adds '
                    'every charge and shows your net P&L and habits. The file '
                    'is read on this device only; nothing is uploaded.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: store.loading
                            ? null
                            : () => _loadSample(context),
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('Load sample (synthetic) tradebook'),
                      ),
                      OutlinedButton.icon(
                        onPressed: store.loading
                            ? null
                            : () => _pickFile(context),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Pick CSV file'),
                      ),
                    ],
                  ),
                  if (store.loading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
            if (store.error != null) _ErrorCard(message: store.error!),
            if (store.result != null) _LoadedCard(store: store),
            const DisclaimerText(),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.error_outline, color: scheme.onErrorContainer),
        title: Text(
          "Couldn't import this file",
          style: TextStyle(
            color: scheme.onErrorContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          message,
          style: TextStyle(color: scheme.onErrorContainer),
        ),
      ),
    );
  }
}

class _LoadedCard extends StatelessWidget {
  const _LoadedCard({required this.store});
  final MirrorStore store;

  @override
  Widget build(BuildContext context) {
    final r = store.result!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loaded: ${store.sourceName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${r.fillCount} fills · ${r.orderCount} orders · '
              '${r.trips.length} round trips'
              '${r.openPositions.isEmpty ? '' : ' · ${r.openPositions.length} still open (not counted)'}',
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Net P&L after charges: '),
                PnlText(r.netPnl),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Open dashboard'),
                ),
                TextButton(
                  onPressed: mirrorStore.clear,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
