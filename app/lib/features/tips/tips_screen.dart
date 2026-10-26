import 'package:flutter/material.dart';

import '../../app/widgets.dart';
import '../../core/mirror.dart';
import '../../core/money.dart';

class Tip {
  const Tip(this.title, this.body);
  final String title;
  final String body;
}

/// Fixed text templates filled in from the analysis. No network, no model:
/// the same file always gives the same tips. Tips describe the trader's own
/// past behaviour; none of them suggests buying or selling anything.
List<Tip> buildTips(MirrorResult r) {
  final tips = <Tip>[];
  final c = r.charges;
  final perTrip = r.trips.isEmpty ? 0 : c.total ~/ r.trips.length;
  tips.add(
    Tip(
      'Charges are part of every trade',
      'Across ${r.trips.length} round trips you paid ${formatInr(c.total)} in '
          'charges, about ${formatInr(perTrip)} per trip. Brokerage alone was '
          '${formatInr(c.brokerage)} for ${r.orderCount} orders. Gross P&L was '
          '${formatInr(r.grossPnl)}; net P&L was ${formatInr(r.netPnl)}.',
    ),
  );

  final revenge = [
    ...r.habit(Habit.revenge).trips,
    ...r.habit(Habit.revengeStrong).trips,
  ];
  if (revenge.isNotEmpty) {
    final net = revenge.fold(0, (s, t) => s + t.netPnl);
    tips.add(
      Tip(
        'Trades right after a loss',
        '${revenge.length} trades started within 10 minutes of a losing exit '
            '(${r.habit(Habit.revengeStrong).count} with a bigger size). '
            'Together they came to ${formatInr(net)} net. Some traders use a '
            'fixed cool-off period after a loss before deciding anything new.',
      ),
    );
  }

  final over = r.habit(Habit.overtradingDay);
  if (over.count > 0) {
    tips.add(
      Tip(
        'Busy days',
        'On ${r.overtradingDays.length} day(s) you opened '
            '${r.overtradingThreshold.toStringAsFixed(0)} or more round trips. '
            'Those ${over.count} trades came to ${formatInr(over.netImpact)} net '
            'and ${formatInr(over.trips.fold(0, (s, t) => s + t.charges.total))} '
            'in charges. A daily trade count you set in advance is one way '
            'people keep track of this.',
      ),
    );
  }

  final expiry = r.habit(Habit.expiryDay);
  if (expiry.count > 0) {
    final worthless = r.trips.where((t) => t.expiredWorthless).length;
    tips.add(
      Tip(
        'Expiry-day trades',
        '${expiry.count} trades were opened on their contract\'s expiry day, '
            'netting ${formatInr(expiry.netImpact)}. $worthless expired with no '
            'exit and lost the full premium. Prices of expiring options can '
            'move very fast on that day.',
      ),
    );
  }

  if (r.holdAsymmetryFlagged) {
    final held = r.habit(Habit.loserHeldLong);
    tips.add(
      Tip(
        'Losers held longer than winners',
        'Your typical losing trade stayed open '
            '${r.medianLoserHoldMin!.toStringAsFixed(1)} min, your typical '
            'winner ${r.medianWinnerHoldMin!.toStringAsFixed(1)} min. '
            '${held.count} losers were held at least twice as long as a typical '
            'winner, netting ${formatInr(held.netImpact)}. Writing down an exit '
            'plan before entering is a common way to notice this pattern.',
      ),
    );
  }

  if (r.trips.isNotEmpty && r.normalTrips.length == r.trips.length) {
    tips.add(
      const Tip(
        'No habit flags',
        'None of the habit rules triggered for this file.',
      ),
    );
  }
  return tips;
}

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tips')),
      body: StoreBuilder(
        builder: (context, store) {
          final r = store.result;
          if (r == null) {
            return const EmptyState(
              message: 'Tips are written from your own imported trades.',
            );
          }
          return ListView(
            children: [
              if (store.isSample) const SyntheticBanner(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Plain observations from fixed rules, computed on '
                  'this device. No AI, no internet.',
                ),
              ),
              for (final tip in buildTips(r))
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(
                      tip.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(tip.body),
                    ),
                  ),
                ),
              const DisclaimerText(),
            ],
          );
        },
      ),
    );
  }
}
