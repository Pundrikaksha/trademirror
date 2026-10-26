import 'package:flutter/material.dart';

import '../../app/widgets.dart';
import '../../core/mirror.dart';
import '../../core/money.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: StoreBuilder(
        builder: (context, store) {
          final r = store.result;
          if (r == null) {
            return const EmptyState(
              message:
                  'Import a tradebook or load the synthetic sample to '
                  'see gross vs net P&L and every charge.',
            );
          }
          return ListView(
            children: [
              if (store.isSample) const SyntheticBanner(),
              _HeadlineCards(r: r),
              _ChargesCard(c: r.charges),
              _DailyChartCard(days: r.days),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  '${r.trips.length} round trips · ${r.winners} winners · '
                  '${r.losers} losers (on net P&L)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final t in r.trips) _TripTile(t: t),
              const DisclaimerText(),
            ],
          );
        },
      ),
    );
  }
}

class _HeadlineCards extends StatelessWidget {
  const _HeadlineCards({required this.r});
  final MirrorResult r;

  @override
  Widget build(BuildContext context) {
    Widget card(String label, int paise, Color color, String note) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatInr(paise),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(note, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );

    final cards = [
      card('Gross P&L', r.grossPnl, pnlColor(r.grossPnl), 'before charges'),
      card(
        'Total charges',
        r.charges.total,
        lossColor,
        'brokerage, taxes and fees',
      ),
      card('Net P&L', r.netPnl, pnlColor(r.netPnl), 'what you actually made'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 700) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [for (final w in cards) Expanded(child: w)]),
          );
        }
        return Column(children: cards);
      },
    );
  }
}

class _ChargesCard extends StatelessWidget {
  const _ChargesCard({required this.c});
  final Charges c;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Brokerage', c.brokerage, '₹10 per executed order'),
      ('STT', c.stt, '0.15% of option sell premium'),
      ('Exchange txn (NSE)', c.exchangeTxn, '0.03553% of premium turnover'),
      ('SEBI fee', c.sebiFee, '0.0001% of turnover'),
      ('Stamp duty', c.stampDuty, '0.003% of buy premium'),
      ('GST', c.gst, '18% of brokerage + exchange + SEBI'),
    ];
    final total = c.total == 0 ? 1 : c.total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Where the charges went',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final (label, amount, note) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(label)),
                        Text(
                          formatInr(amount),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: amount / total,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    Text(note, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  formatInr(c.total),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyChartCard extends StatelessWidget {
  const _DailyChartCard({required this.days});
  final List<DaySummary> days;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily net P&L (by exit date)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: Size.infinite,
                painter: DailyBarPainter(
                  days,
                  axisColor: Theme.of(context).colorScheme.outline,
                  labelStyle: Theme.of(context).textTheme.labelSmall!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hand-drawn bar chart: one bar per day, green above zero, red below.
class DailyBarPainter extends CustomPainter {
  DailyBarPainter(
    this.days, {
    required this.axisColor,
    required this.labelStyle,
  });
  final List<DaySummary> days;
  final Color axisColor;
  final TextStyle labelStyle;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    const labelH = 18.0;
    final chartH = size.height - labelH;
    var maxV = 0, minV = 0;
    for (final d in days) {
      if (d.net > maxV) maxV = d.net;
      if (d.net < minV) minV = d.net;
    }
    final span = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final zeroY = chartH * maxV / span;
    final slot = size.width / days.length;
    final barW = slot * 0.6;

    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final h = chartH * d.net.abs() / span;
      final x = i * slot + (slot - barW) / 2;
      final rect = d.net >= 0
          ? Rect.fromLTWH(x, zeroY - h, barW, h)
          : Rect.fromLTWH(x, zeroY, barW, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = pnlColor(d.net),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${d.day.day} ${_months[d.day.month - 1]}',
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slot);
      tp.paint(canvas, Offset(i * slot + (slot - tp.width) / 2, chartH + 4));
    }
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(DailyBarPainter old) => old.days != days;
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.t});
  final RoundTrip t;

  String _time(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _price(double paise) => (paise / 100).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${t.id}  ${t.symbol}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            PnlText(t.netPnl),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t.isLong ? 'Long' : 'Short'} ${t.qty} · '
              '${_time(t.entryTime)} @ ${_price(t.entryAvg)} → '
              '${_time(t.exitTime)} @ ${_price(t.exitAvg)}'
              '${t.expiredWorthless ? ' (expired)' : ''}',
              style: small,
            ),
            Text(
              'Gross ${formatInr(t.grossPnl)} · '
              'Charges ${formatInr(t.charges.total)} · '
              'Net ${formatInr(t.netPnl)}',
              style: small,
            ),
            if (t.habits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [for (final h in t.habits) HabitChip(habit: h)],
                ),
              ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brokerage ${formatInr(t.charges.brokerage)} '
            '(${t.chargedOrders} orders) · STT ${formatInr(t.charges.stt)} · '
            'Exchange ${formatInr(t.charges.exchangeTxn)} · '
            'SEBI ${formatInr(t.charges.sebiFee)} · '
            'Stamp ${formatInr(t.charges.stampDuty)} · '
            'GST ${formatInr(t.charges.gst)}',
            style: small,
          ),
          const SizedBox(height: 4),
          for (final reason in t.reasons) Text('• $reason', style: small),
        ],
      ),
    );
  }
}

class HabitChip extends StatelessWidget {
  const HabitChip({super.key, required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        habit.label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}
