/// Round-trip matching, charges and habit detection. Pure Dart, no I/O.
library;

import 'money.dart';
import 'tradebook.dart';

/// NSE F&O option charge rates (Oct 2026). Each rate is num / den.
class ChargeRates {
  const ChargeRates({
    this.brokeragePerOrderPaise = 1000,
    this.sttSell = const (15, 10000), // 0.15% of option sell premium
    this.exchangeTxn = const (3553, 10000000), // 0.03553% of premium turnover
    this.sebiFee = const (1, 1000000), // 0.0001% of turnover
    this.stampBuy = const (3, 100000), // 0.003% of buy premium
    this.gst = const (18, 100), // 18% of brokerage + exchange + SEBI
  });

  final int brokeragePerOrderPaise;
  final (int, int) sttSell;
  final (int, int) exchangeTxn;
  final (int, int) sebiFee;
  final (int, int) stampBuy;
  final (int, int) gst;
}

/// Charges for one round trip, each already rounded half-up to the paisa.
class Charges {
  const Charges({
    this.brokerage = 0,
    this.stt = 0,
    this.exchangeTxn = 0,
    this.sebiFee = 0,
    this.stampDuty = 0,
    this.gst = 0,
  });

  final int brokerage, stt, exchangeTxn, sebiFee, stampDuty, gst;

  int get total => brokerage + stt + exchangeTxn + sebiFee + stampDuty + gst;

  Charges operator +(Charges o) => Charges(
        brokerage: brokerage + o.brokerage,
        stt: stt + o.stt,
        exchangeTxn: exchangeTxn + o.exchangeTxn,
        sebiFee: sebiFee + o.sebiFee,
        stampDuty: stampDuty + o.stampDuty,
        gst: gst + o.gst,
      );
}

Charges computeCharges({
  required int buyValue,
  required int sellValue,
  required int orders,
  ChargeRates rates = const ChargeRates(),
}) {
  int r((int, int) rate, int v) => mulRateHalfUp(v, rate.$1, rate.$2);
  final turnover = buyValue + sellValue;
  final brokerage = orders * rates.brokeragePerOrderPaise;
  final exchange = r(rates.exchangeTxn, turnover);
  final sebi = r(rates.sebiFee, turnover);
  return Charges(
    brokerage: brokerage,
    stt: r(rates.sttSell, sellValue),
    exchangeTxn: exchange,
    sebiFee: sebi,
    stampDuty: r(rates.stampBuy, buyValue),
    gst: r(rates.gst, brokerage + exchange + sebi),
  );
}

enum Habit {
  revenge('revenge', 'Revenge trade'),
  revengeStrong('revenge_strong', 'Revenge trade (bigger size)'),
  overtradingDay('overtrading_day', 'Overtrading day'),
  expiryDay('expiry_day', 'Expiry-day trade'),
  loserHeldLong('loser_held_long', 'Loser held long');

  const Habit(this.id, this.label);
  final String id;
  final String label;
}

class RoundTrip {
  RoundTrip({
    required this.symbol,
    required this.underlying,
    required this.expiry,
    required this.strike,
    required this.optionType,
    required this.isLong,
    required this.product,
    required this.entryTime,
  });

  String id = '';
  final String symbol;
  final String underlying;
  final DateTime expiry;
  final String strike;
  final String optionType;
  final bool isLong;
  final String product;
  final DateTime entryTime;
  late DateTime exitTime;
  int qty = 0;
  int buyValue = 0;
  int sellValue = 0;
  bool expiredWorthless = false;
  final List<String> entryOrders = [];
  final List<String> exitOrders = [];
  int chargedOrders = 0;
  Charges charges = const Charges();
  final Set<Habit> habits = {};
  final List<String> reasons = [];

  int get grossPnl => sellValue - buyValue;
  int get netPnl => grossPnl - charges.total;
  int get turnover => buyValue + sellValue;

  /// Average entry / exit price in paise (display only; P&L uses exact values).
  double get entryAvg => (isLong ? buyValue : sellValue) / qty;
  double get exitAvg => (isLong ? sellValue : buyValue) / qty;

  Duration get hold => exitTime.difference(entryTime);

  /// Hold time in hundredths of a minute, rounded half-up (e.g. 847 = 8.47).
  int get holdCentiMinutes => (hold.inSeconds * 200 + 60) ~/ 120;
}

class OpenPosition {
  const OpenPosition(this.symbol, this.qty, this.isLong);
  final String symbol;
  final int qty;
  final bool isLong;
}

class DaySummary {
  DaySummary(this.day);
  final DateTime day;
  int trips = 0;
  int gross = 0;
  int charges = 0;
  int get net => gross - charges;
}

class HabitSummary {
  const HabitSummary(this.habit, this.trips);
  final Habit habit;
  final List<RoundTrip> trips;
  int get count => trips.length;
  int get netImpact => trips.fold(0, (s, t) => s + t.netPnl);
}

class MirrorResult {
  MirrorResult({
    required this.fillCount,
    required this.orderCount,
    required this.trips,
    required this.openPositions,
    required this.overtradingDays,
    required this.overtradingThreshold,
    required this.medianWinnerHoldMin,
    required this.medianLoserHoldMin,
    required this.holdAsymmetryFlagged,
  });

  final int fillCount;
  final int orderCount;
  final List<RoundTrip> trips;
  final List<OpenPosition> openPositions;
  final List<DateTime> overtradingDays;
  final double overtradingThreshold;
  final double? medianWinnerHoldMin;
  final double? medianLoserHoldMin;
  final bool holdAsymmetryFlagged;

  int get grossPnl => trips.fold(0, (s, t) => s + t.grossPnl);
  Charges get charges => trips.fold(const Charges(), (s, t) => s + t.charges);
  int get netPnl => grossPnl - charges.total;
  int get winners => trips.where((t) => t.netPnl > 0).length;
  int get losers => trips.where((t) => t.netPnl < 0).length;

  /// Trips grouped by exit date, oldest first.
  List<DaySummary> get days {
    final map = <DateTime, DaySummary>{};
    for (final t in trips) {
      final d = _dateOnly(t.exitTime);
      final s = map.putIfAbsent(d, () => DaySummary(d));
      s.trips++;
      s.gross += t.grossPnl;
      s.charges += t.charges.total;
    }
    return map.values.toList()..sort((a, b) => a.day.compareTo(b.day));
  }

  HabitSummary habit(Habit h) =>
      HabitSummary(h, trips.where((t) => t.habits.contains(h)).toList());

  List<RoundTrip> get normalTrips =>
      trips.where((t) => t.habits.isEmpty).toList();
}

DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

class _Order {
  _Order(this.id, this.side, this.time);
  final String id;
  final Side side;
  final DateTime time;
  final List<Fill> fills = [];
}

double? _median(List<int> xs) {
  if (xs.isEmpty) return null;
  final s = [...xs]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2].toDouble() : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

String _min(num centi) {
  final v = centi / 100;
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
}

/// Builds round trips from fills, prices them and tags habits.
///
/// A round trip runs from a flat position in one contract back to flat
/// (FIFO within the contract). All fills sharing an order number are one
/// order. A position still open after its contract's expiry is closed at 0
/// at 15:30 on expiry day. "Expired" means the expiry date is on or before
/// [asOf] (default: the last fill date in the file).
MirrorResult analyse(
  List<Fill> fills, {
  ChargeRates rates = const ChargeRates(),
  DateTime? asOf,
  int revengeWindowMinutes = 10,
  int overtradingMinTrips = 8,
  double overtradingMedianMultiple = 2.0,
  double holdAsymmetryMultiple = 2.0,
}) {
  final ordered = [...fills]..sort((a, b) {
      final c = a.time.compareTo(b.time);
      return c != 0 ? c : a.row.compareTo(b.row);
    });
  final cutoff = _dateOnly(asOf ??
      (ordered.isEmpty ? DateTime.now() : ordered.last.time));

  // Group fills into orders per contract.
  final bySymbol = <String, Map<String, _Order>>{};
  for (final f in ordered) {
    final orders = bySymbol.putIfAbsent(f.symbol, () => {});
    final key = '${f.orderId}|${f.side.name}';
    orders.putIfAbsent(key, () => _Order(f.orderId, f.side, f.time)).fills.add(f);
  }
  final orderCount = {for (final f in fills) f.orderId}.length;

  final trips = <RoundTrip>[];
  final open = <OpenPosition>[];
  for (final entry in bySymbol.entries) {
    final orders = entry.value.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    RoundTrip? cur;
    var pos = 0; // signed quantity
    for (final o in orders) {
      for (final f in o.fills) {
        var q = f.qty;
        final signed = f.side == Side.buy ? 1 : -1;
        while (q > 0) {
          if (pos == 0 || pos.sign == signed) {
            cur ??= RoundTrip(
              symbol: f.symbol,
              underlying: f.underlying,
              expiry: f.expiry,
              strike: f.strike,
              optionType: f.optionType,
              isLong: f.side == Side.buy,
              product: f.product,
              entryTime: o.time,
            );
            if (!cur.entryOrders.contains(o.id)) cur.entryOrders.add(o.id);
            cur.qty += q;
            _addValue(cur, f.side, q * f.pricePaise);
            pos += signed * q;
            q = 0;
          } else {
            final close = q < pos.abs() ? q : pos.abs();
            if (!cur!.exitOrders.contains(o.id)) cur.exitOrders.add(o.id);
            cur.exitTime = o.time;
            _addValue(cur, f.side, close * f.pricePaise);
            pos += signed * close;
            q -= close;
            if (pos == 0) {
              trips.add(cur);
              cur = null;
            }
          }
        }
      }
    }
    if (cur != null) {
      if (!_dateOnly(cur.expiry).isAfter(cutoff)) {
        final e = cur.expiry;
        cur.exitTime = DateTime(e.year, e.month, e.day, 15, 30);
        cur.expiredWorthless = true;
        trips.add(cur);
      } else {
        open.add(OpenPosition(cur.symbol, pos.abs(), pos > 0));
      }
    }
  }

  trips.sort((a, b) => a.entryTime.compareTo(b.entryTime));
  final charged = <String>{};
  for (var i = 0; i < trips.length; i++) {
    final t = trips[i];
    t.id = 'T${(i + 1).toString().padLeft(2, '0')}';
    // An order that both closes one trip and opens the next is charged once.
    t.chargedOrders =
        [...t.entryOrders, ...t.exitOrders].where(charged.add).length;
    t.charges = computeCharges(
      buyValue: t.buyValue,
      sellValue: t.sellValue,
      orders: t.chargedOrders,
      rates: rates,
    );
  }

  // Habit: expiry day (opened on its own contract's expiry date).
  for (final t in trips) {
    if (_dateOnly(t.entryTime) == _dateOnly(t.expiry)) {
      t.habits.add(Habit.expiryDay);
      t.reasons.add('Opened on its own expiry day (0 DTE).');
    }
  }

  // Habit: revenge (opened soon after a net-losing exit).
  for (final t in trips) {
    RoundTrip? trigger;
    for (final p in trips) {
      if (identical(p, t) || p.netPnl >= 0) continue;
      if (p.exitTime.isAfter(t.entryTime)) continue;
      final gap = t.entryTime.difference(p.exitTime);
      if (gap.inSeconds > revengeWindowMinutes * 60) continue;
      if (trigger == null || p.exitTime.isAfter(trigger.exitTime)) trigger = p;
    }
    if (trigger != null) {
      final gapMin = t.entryTime.difference(trigger.exitTime).inSeconds / 60;
      final strong = t.qty * 2 >= trigger.qty * 3;
      t.habits.add(strong ? Habit.revengeStrong : Habit.revenge);
      t.reasons.add(
        'Opened ${gapMin.toStringAsFixed(1)} min after ${trigger.id} closed '
        'at a loss${strong ? ', with ${(t.qty / trigger.qty).toStringAsFixed(1)}x the quantity' : ''}.',
      );
    }
  }

  // Habit: overtrading day.
  final perDay = <DateTime, List<RoundTrip>>{};
  for (final t in trips) {
    perDay.putIfAbsent(_dateOnly(t.entryTime), () => []).add(t);
  }
  final medianDaily = _median(perDay.values.map((l) => l.length).toList()) ?? 0;
  final threshold = [
    overtradingMinTrips.toDouble(),
    overtradingMedianMultiple * medianDaily,
  ].reduce((a, b) => a > b ? a : b);
  final overDays = <DateTime>[];
  for (final e in perDay.entries) {
    if (e.value.length >= threshold) {
      overDays.add(e.key);
      for (final t in e.value) {
        t.habits.add(Habit.overtradingDay);
        t.reasons.add('One of ${e.value.length} trips opened that day '
            '(threshold ${threshold.toStringAsFixed(0)}).');
      }
    }
  }
  overDays.sort();

  // Habit: losers held longer than winners.
  final winHolds = [
    for (final t in trips)
      if (t.netPnl > 0) t.holdCentiMinutes
  ];
  final loseHolds = [
    for (final t in trips)
      if (t.netPnl < 0) t.holdCentiMinutes
  ];
  final medWin = _median(winHolds);
  final medLose = _median(loseHolds);
  final flagged = medWin != null &&
      medLose != null &&
      medLose >= holdAsymmetryMultiple * medWin;
  if (flagged) {
    final limit = holdAsymmetryMultiple * medWin;
    for (final t in trips) {
      if (t.netPnl < 0 && t.holdCentiMinutes >= limit) {
        t.habits.add(Habit.loserHeldLong);
        t.reasons.add('Loser held ${_min(t.holdCentiMinutes)} min; '
            'your typical winner is held ${_min(medWin)} min.');
      }
    }
  }

  for (final t in trips) {
    if (t.expiredWorthless) {
      t.reasons.add('No exit in the file; expired worthless at 15:30 on '
          '${t.expiry.day}-${t.expiry.month}-${t.expiry.year}.');
    }
    if (t.reasons.isEmpty) t.reasons.add('No habit rule triggered.');
  }

  return MirrorResult(
    fillCount: fills.length,
    orderCount: orderCount,
    trips: trips,
    openPositions: open,
    overtradingDays: overDays,
    overtradingThreshold: threshold,
    medianWinnerHoldMin: medWin == null ? null : medWin / 100,
    medianLoserHoldMin: medLose == null ? null : medLose / 100,
    holdAsymmetryFlagged: flagged,
  );
}

void _addValue(RoundTrip t, Side side, int value) {
  if (side == Side.buy) {
    t.buyValue += value;
  } else {
    t.sellValue += value;
  }
}
