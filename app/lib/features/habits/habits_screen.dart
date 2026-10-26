import 'package:flutter/material.dart';

import '../../app/widgets.dart';
import '../../core/mirror.dart';
import '../../core/money.dart';

/// One habit as shown to the user: which trips it covers and why.
class HabitView {
  const HabitView({
    required this.title,
    required this.icon,
    required this.trips,
    required this.explanation,
    this.detail,
  });
  final String title;
  final IconData icon;
  final List<RoundTrip> trips;
  final String explanation;
  final String? detail;

  int get count => trips.length;
  int get netImpact => trips.fold(0, (s, t) => s + t.netPnl);
}

String _d(DateTime d) => '${d.day}-${d.month}-${d.year}';

List<HabitView> habitViews(MirrorResult r) {
  final revenge = [
    ...r.habit(Habit.revenge).trips,
    ...r.habit(Habit.revengeStrong).trips,
  ]..sort((a, b) => a.entryTime.compareTo(b.entryTime));
  final strong = r.habit(Habit.revengeStrong).count;
  final medW = r.medianWinnerHoldMin, medL = r.medianLoserHoldMin;
  return [
    HabitView(
      title: 'Revenge trades',
      icon: Icons.replay_circle_filled_outlined,
      trips: revenge,
      explanation:
          'A new trade opened within 10 minutes of closing a trade '
          'at a net loss.',
      detail:
          '$strong of these used at least 1.5x the quantity of the '
          'losing trade.',
    ),
    HabitView(
      title: 'Overtrading days',
      icon: Icons.speed,
      trips: r.habit(Habit.overtradingDay).trips,
      explanation:
          'Days with at least '
          '${r.overtradingThreshold.toStringAsFixed(0)} round trips opened '
          '(the larger of 8 or 2x your median day).',
      detail: r.overtradingDays.isEmpty
          ? 'No such days.'
          : 'Days: ${r.overtradingDays.map(_d).join(', ')}.',
    ),
    HabitView(
      title: 'Expiry-day trades',
      icon: Icons.event_busy,
      trips: r.habit(Habit.expiryDay).trips,
      explanation:
          'Trades opened on the expiry day of their own contract '
          '(0 days to expiry).',
      detail:
          '${r.trips.where((t) => t.expiredWorthless).length} expired '
          'worthless with no exit.',
    ),
    HabitView(
      title: 'Losers held longer than winners',
      icon: Icons.hourglass_bottom,
      trips: r.habit(Habit.loserHeldLong).trips,
      explanation: r.holdAsymmetryFlagged
          ? 'Your typical losing trade was held '
                '${medL!.toStringAsFixed(1)} min vs '
                '${medW!.toStringAsFixed(1)} min for a winner. Counted: losers '
                'held at least 2x the typical winner.'
          : 'Not flagged: typical losers were not held 2x longer than '
                'typical winners.',
    ),
  ];
}

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: StoreBuilder(
        builder: (context, store) {
          final r = store.result;
          if (r == null) {
            return const EmptyState(
              message: 'Import a tradebook to see which habits cost money.',
            );
          }
          return ListView(
            children: [
              if (store.isSample) const SyntheticBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Rupee impact is the combined net P&L (after charges) of the '
                  'trades with that habit. A trade can have more than one habit. '
                  '${r.normalTrips.length} of ${r.trips.length} trades had none.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              for (final h in habitViews(r)) _HabitCard(h: h),
              const DisclaimerText(),
            ],
          );
        },
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.h});
  final HabitView h;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(h.icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(h.title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${h.count}', style: theme.textTheme.headlineMedium),
                      const Text('trades'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PnlText(
                        h.netImpact,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const Text('net P&L of these trades'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(h.explanation),
            if (h.detail != null)
              Text(h.detail!, style: theme.textTheme.bodySmall),
            if (h.trips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Trades: ${h.trips.map((t) => t.id).join(', ')}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (h.count > 0)
              Text(
                'Charges on these trades: '
                '${formatInr(h.trips.fold(0, (s, t) => s + t.charges.total))}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
