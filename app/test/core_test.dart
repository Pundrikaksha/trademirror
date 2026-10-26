import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trademirror/core/csv.dart';
import 'package:trademirror/core/mirror.dart';
import 'package:trademirror/core/money.dart';
import 'package:trademirror/core/tradebook.dart';

const _samplePath = 'assets/sample/sample_tradebook_kotak_neo_SYNTHETIC.csv';
const _header =
    'flDt,flTm,exTm,nOrdNo,exOrdId,flId,exSeg,sym,trdSym,expDt,stkPrc,optTp,'
    'trnsTp,fldQty,avgPrc,lotSz,prod,rptTp,usrId';

String _row(
  String order,
  String side,
  int qty,
  String price, {
  String date = '05-Oct-2026',
  String time = '09:30:00',
}) =>
    '$date,$time,$date $time,$order,X$order,F$order$time,nse_fo,NIFTY,'
    'NIFTY-13OCT26-25400-CE,13-Oct-2026,25400.00,CE,$side,$qty,$price,65,MIS,'
    'fill,SYNTH0001';

void main() {
  final expected =
      jsonDecode(File('test/fixtures/expected_results.json').readAsStringSync())
          as Map<String, dynamic>;
  final totals = expected['totals'] as Map<String, dynamic>;
  final habitCounts = expected['habit_counts'] as Map<String, dynamic>;
  final expectedTrades = (expected['trades'] as List)
      .cast<Map<String, dynamic>>();

  late MirrorResult result;
  setUpAll(() {
    final fills = parseKotakNeoTradebook(File(_samplePath).readAsStringSync());
    result = analyse(fills);
  });

  group('synthetic sample matches expected_results.json', () {
    test('counts', () {
      expect(result.fillCount, 108);
      expect(result.orderCount, 98);
      expect(result.trips.length, 50);
      expect(result.fillCount, totals['fills']);
      expect(result.orderCount, totals['orders']);
      expect(result.trips.length, totals['round_trips']);
      expect(result.openPositions, isEmpty);
    });

    test('totals match to the paisa', () {
      final c = result.charges;
      String s(int p) => paiseToDecimalString(p);
      expect(
        s(result.trips.fold(0, (a, t) => a + t.buyValue)),
        totals['buy_value'],
      );
      expect(
        s(result.trips.fold(0, (a, t) => a + t.sellValue)),
        totals['sell_value'],
      );
      expect(s(result.grossPnl), totals['gross_pnl']);
      expect(s(c.brokerage), totals['brokerage']);
      expect(s(c.stt), totals['stt']);
      expect(s(c.exchangeTxn), totals['exchange_txn']);
      expect(s(c.sebiFee), totals['sebi_fee']);
      expect(s(c.stampDuty), totals['stamp_duty']);
      expect(s(c.gst), totals['gst']);
      expect(s(c.total), totals['total_charges']);
      expect(s(result.netPnl), totals['net_pnl']);
      expect(s(result.netPnl), '-19066.35');
    });

    test('every trade matches (orders, values, each charge, net, tags)', () {
      expect(result.trips.length, expectedTrades.length);
      for (var i = 0; i < expectedTrades.length; i++) {
        final e = expectedTrades[i];
        final t = result.trips[i];
        final id = e['trade_id'];
        String s(int p) => paiseToDecimalString(p);
        expect(t.id, id);
        expect(t.symbol, e['trading_symbol'], reason: '$id');
        expect(t.entryOrders.first, e['entry_order'], reason: '$id');
        expect(
          t.exitOrders.isEmpty ? '' : t.exitOrders.first,
          e['exit_order'],
          reason: '$id',
        );
        expect(t.isLong, e['direction'] == 'long', reason: '$id');
        expect(t.qty, e['qty'], reason: '$id');
        expect(t.expiredWorthless, e['expired_worthless'], reason: '$id');
        expect(
          t.holdCentiMinutes / 100,
          closeTo((e['hold_minutes'] as num).toDouble(), 1e-9),
          reason: '$id',
        );
        expect(s(t.buyValue), e['buy_value'], reason: '$id');
        expect(s(t.sellValue), e['sell_value'], reason: '$id');
        expect(s(t.grossPnl), e['gross_pnl'], reason: '$id');
        expect(s(t.charges.brokerage), e['brokerage'], reason: '$id');
        expect(s(t.charges.stt), e['stt'], reason: '$id');
        expect(s(t.charges.exchangeTxn), e['exchange_txn'], reason: '$id');
        expect(s(t.charges.sebiFee), e['sebi_fee'], reason: '$id');
        expect(s(t.charges.stampDuty), e['stamp_duty'], reason: '$id');
        expect(s(t.charges.gst), e['gst'], reason: '$id');
        expect(s(t.charges.total), e['total_charges'], reason: '$id');
        expect(s(t.netPnl), e['net_pnl'], reason: '$id');
        final tags = (e['tags'] as List).cast<String>().toSet()
          ..remove('normal');
        expect(t.habits.map((h) => h.id).toSet(), tags, reason: '$id');
      }
    });

    test('habit counts', () {
      int n(Habit h) => result.habit(h).count;
      expect(
        n(Habit.revenge) + n(Habit.revengeStrong),
        habitCounts['revenge_total'],
      );
      expect(n(Habit.revengeStrong), habitCounts['revenge_strong']);
      expect(result.overtradingDays.length, habitCounts['overtrading_days']);
      expect(
        result.overtradingDays
            .map((d) => d.toIso8601String().substring(0, 10))
            .toList(),
        habitCounts['overtrading_day_dates'],
      );
      expect(
        n(Habit.overtradingDay),
        habitCounts['trades_on_overtrading_days'],
      );
      expect(n(Habit.expiryDay), habitCounts['expiry_day_trades']);
      expect(
        result.trips.where((t) => t.expiredWorthless).length,
        habitCounts['expired_worthless'],
      );
      expect(n(Habit.loserHeldLong), habitCounts['loser_held_long_trades']);
      expect(result.normalTrips.length, habitCounts['normal_only']);
      expect(
        result.trips.where((t) => !t.isLong).length,
        habitCounts['short_trades'],
      );
      expect(result.winners, habitCounts['winners_net']);
      expect(result.losers, habitCounts['losers_net']);
      final hold = expected['hold_asymmetry'] as Map<String, dynamic>;
      expect(result.holdAsymmetryFlagged, hold['flagged']);
      expect(
        result.medianWinnerHoldMin,
        closeTo((hold['median_winner_hold_min'] as num).toDouble(), 1e-9),
      );
      expect(
        result.medianLoserHoldMin,
        closeTo((hold['median_loser_hold_min'] as num).toDouble(), 1e-9),
      );
    });

    test('daily totals by exit date', () {
      final perDay = expected['per_day_by_exit_date'] as Map<String, dynamic>;
      final days = result.days;
      expect(days.length, perDay.length);
      for (final d in days) {
        final e =
            perDay[d.day.toIso8601String().substring(0, 10)]
                as Map<String, dynamic>;
        expect(d.trips, e['round_trips_closed']);
        expect(paiseToDecimalString(d.net), e['net_pnl']);
      }
    });
  });

  group('bad input', () {
    test('empty file', () {
      expect(
        () => parseKotakNeoTradebook(''),
        throwsA(
          isA<TradebookException>().having(
            (e) => e.message,
            'message',
            contains('empty'),
          ),
        ),
      );
      expect(
        () => parseKotakNeoTradebook('  \n\n'),
        throwsA(isA<TradebookException>()),
      );
    });

    test('header only', () {
      expect(
        () => parseKotakNeoTradebook('$_header\n'),
        throwsA(
          isA<TradebookException>().having(
            (e) => e.message,
            'message',
            contains('no trades'),
          ),
        ),
      );
    });

    test('wrong headers', () {
      expect(
        () => parseKotakNeoTradebook(
          'Date,Symbol,Qty,Price\n05-Oct-2026,NIFTY,65,100.00\n',
        ),
        throwsA(
          isA<TradebookException>().having(
            (e) => e.message,
            'message',
            contains('Missing column'),
          ),
        ),
      );
    });

    test('malformed row reports its line', () {
      final csv =
          '$_header\n${_row('A1', 'B', 65, '100.00')}\n'
          '${_row('A2', 'S', 65, 'abc')}\n';
      expect(
        () => parseKotakNeoTradebook(csv),
        throwsA(
          isA<TradebookException>().having(
            (e) => e.message,
            'message',
            startsWith('Line 3'),
          ),
        ),
      );
    });

    test('short row and bad side', () {
      expect(
        () => parseKotakNeoTradebook('$_header\n05-Oct-2026,09:30:00\n'),
        throwsA(isA<TradebookException>()),
      );
      expect(
        () => parseKotakNeoTradebook(
          '$_header\n${_row('A1', 'X', 65, '100.00')}\n',
        ),
        throwsA(
          isA<TradebookException>().having(
            (e) => e.message,
            'message',
            contains('B or S'),
          ),
        ),
      );
    });

    test('unterminated quote', () {
      expect(
        () => parseKotakNeoTradebook('$_header\n"oops,1\n'),
        throwsA(isA<TradebookException>()),
      );
    });
  });

  group('csv', () {
    test('RFC 4180 quoting, CRLF and BOM', () {
      final rows = parseCsv('﻿a,"b,c","say ""hi"""\r\n1,"multi\nline",3\r\n');
      expect(rows, [
        ['a', 'b,c', 'say "hi"'],
        ['1', 'multi\nline', '3'],
      ]);
    });
  });

  group('matching and charges', () {
    test('short (sell to open) closed by a buy, partial fills = one order', () {
      final csv = [
        _header,
        _row('S1', 'S', 65, '120.00', time: '10:00:00'),
        _row('S1', 'S', 65, '120.50', time: '10:00:01'),
        _row('B1', 'B', 130, '100.00', time: '10:05:00'),
      ].join('\n');
      final r = analyse(parseKotakNeoTradebook(csv));
      expect(r.trips.length, 1);
      final t = r.trips.single;
      expect(t.isLong, isFalse);
      expect(t.chargedOrders, 2);
      expect(t.grossPnl, (65 * 12000 + 65 * 12050) - 130 * 10000);
      expect(t.charges.brokerage, 2000);
    });

    test('open long before expiry stays open', () {
      final csv = [_header, _row('B1', 'B', 65, '100.00')].join('\n');
      final r = analyse(parseKotakNeoTradebook(csv));
      expect(r.trips, isEmpty);
      expect(r.openPositions.single.qty, 65);
    });

    test('long with no exit after expiry closes at zero', () {
      final csv = [_header, _row('B1', 'B', 65, '100.00')].join('\n');
      final r = analyse(
        parseKotakNeoTradebook(csv),
        asOf: DateTime(2026, 10, 14),
      );
      final t = r.trips.single;
      expect(t.expiredWorthless, isTrue);
      expect(t.sellValue, 0);
      expect(t.charges.stt, 0);
      expect(t.charges.brokerage, 1000);
      expect(t.exitTime, DateTime(2026, 10, 13, 15, 30));
    });

    test('rounding is half-up to the paisa', () {
      expect(mulRateHalfUp(50, 1, 100), 1); // 0.5 paise -> 1
      expect(mulRateHalfUp(49, 1, 100), 0);
      expect(formatInr(-1906635), '-₹19,066.35');
      expect(formatInr(1234567890), '₹1,23,45,678.90');
      expect(parsePaise('118.4'), 11840);
      expect(() => parsePaise('1.005'), throwsFormatException);
    });
  });
}
