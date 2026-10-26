import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/money.dart';
import 'store.dart';

const profitColor = Color(0xFF15803D);
const lossColor = Color(0xFFB91C1C);

Color pnlColor(int paise) =>
    paise > 0 ? profitColor : (paise < 0 ? lossColor : Colors.grey);

/// Rebuilds [builder] whenever the imported tradebook changes.
class StoreBuilder extends StatelessWidget {
  const StoreBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, MirrorStore store) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: mirrorStore,
    builder: (context, _) => builder(context, mirrorStore),
  );
}

class SyntheticBanner extends StatelessWidget {
  const SyntheticBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF3C7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.science_outlined, size: 18, color: Color(0xFF92400E)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'SYNTHETIC DATA: fictional trader and invented trades, '
              'for demonstration only.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DisclaimerText extends StatelessWidget {
  const DisclaimerText({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Educational only, not investment advice. TradeMirror shows what '
        'already happened in your own file; it never recommends buying or '
        'selling anything. Charges are estimates and may differ slightly '
        'from your contract note.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing imported yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/import'),
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Go to Import'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rupee amount coloured by sign.
class PnlText extends StatelessWidget {
  const PnlText(this.paise, {super.key, this.style});
  final int paise;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
    formatInr(paise),
    style: (style ?? const TextStyle()).copyWith(
      color: pnlColor(paise),
      fontWeight: FontWeight.w600,
    ),
  );
}
