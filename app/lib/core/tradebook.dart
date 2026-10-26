/// Kotak Neo trade-report CSV -> list of [Fill]s.
library;

import 'csv.dart';
import 'money.dart';

enum Side { buy, sell }

/// One execution row from the tradebook. The account id column (usrId) is
/// read past and never stored.
class Fill {
  const Fill({
    required this.row,
    required this.time,
    required this.orderId,
    required this.fillId,
    required this.underlying,
    required this.symbol,
    required this.expiry,
    required this.strike,
    required this.optionType,
    required this.side,
    required this.qty,
    required this.pricePaise,
    required this.lotSize,
    required this.product,
  });

  /// 1-based line number in the source file (header is line 1).
  final int row;
  final DateTime time;
  final String orderId;
  final String fillId;
  final String underlying;
  final String symbol;
  final DateTime expiry;
  final String strike;
  final String optionType;
  final Side side;
  final int qty;
  final int pricePaise;
  final int lotSize;
  final String product;

  int get valuePaise => qty * pricePaise;
}

class TradebookException implements Exception {
  TradebookException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The Kotak Neo Trade API v2 trade-report columns this parser needs.
const kotakNeoColumns = <String>[
  'flDt', 'flTm', 'nOrdNo', 'flId', 'sym', 'trdSym', 'expDt', 'stkPrc', //
  'optTp', 'trnsTp', 'fldQty', 'avgPrc', 'lotSz', 'prod',
];

const _months = {
  'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6, //
  'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
};

/// Parses "05-Oct-2026" (also accepts "2026-10-05").
DateTime parseTradeDate(String raw) {
  final s = raw.trim();
  var m = RegExp(r'^(\d{1,2})-([A-Za-z]{3})-(\d{4})$').firstMatch(s);
  if (m != null) {
    final month = _months[m[2]!.toUpperCase()];
    if (month != null) {
      final d = DateTime(int.parse(m[3]!), month, int.parse(m[1]!));
      if (d.day == int.parse(m[1]!)) return d;
    }
  }
  m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m != null) {
    final d = DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    if (d.day == int.parse(m[3]!)) return d;
  }
  throw FormatException('bad date "$raw"');
}

DateTime _withTime(DateTime day, String raw) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(raw.trim());
  if (m == null) throw FormatException('bad time "$raw"');
  final h = int.parse(m[1]!), mi = int.parse(m[2]!), s = int.parse(m[3] ?? '0');
  if (h > 23 || mi > 59 || s > 59) throw FormatException('bad time "$raw"');
  return DateTime(day.year, day.month, day.day, h, mi, s);
}

Side _side(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'B':
    case 'BUY':
      return Side.buy;
    case 'S':
    case 'SELL':
      return Side.sell;
  }
  throw FormatException('buy/sell flag must be B or S, got "$raw"');
}

int _positiveInt(String raw, String what) {
  final v = int.tryParse(raw.trim());
  if (v == null || v <= 0) throw FormatException('bad $what "$raw"');
  return v;
}

/// Parses a whole tradebook. Throws [TradebookException] with a plain-English
/// message (and line number where relevant) if the file can't be used.
List<Fill> parseKotakNeoTradebook(String text) {
  if (text.trim().isEmpty) {
    throw TradebookException('The file is empty.');
  }
  final List<List<String>> rows;
  try {
    rows = parseCsv(text);
  } on CsvParseException catch (e) {
    throw TradebookException('Not a valid CSV file. ${e.message}.');
  }
  final header = rows.first;
  final idx = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    idx[header[i].trim()] = i;
  }
  final missing = kotakNeoColumns.where((c) => !idx.containsKey(c)).toList();
  if (missing.isNotEmpty) {
    throw TradebookException(
      'This does not look like a Kotak Neo tradebook. '
      'Missing column(s): ${missing.join(', ')}.',
    );
  }
  if (rows.length < 2) {
    throw TradebookException('The file has a header but no trades.');
  }

  final fills = <Fill>[];
  for (var r = 1; r < rows.length; r++) {
    final cells = rows[r];
    final line = r + 1;
    String col(String name) {
      final i = idx[name]!;
      if (i >= cells.length) {
        throw FormatException(
            'expected ${header.length} columns, found ${cells.length}');
      }
      return cells[i];
    }

    try {
      final day = parseTradeDate(col('flDt'));
      final orderId = col('nOrdNo').trim();
      if (orderId.isEmpty) throw const FormatException('order number is empty');
      final symbol = col('trdSym').trim();
      if (symbol.isEmpty) throw const FormatException('trading symbol is empty');
      final price = parsePaise(col('avgPrc'));
      if (price < 0) throw FormatException('negative price "${col('avgPrc')}"');
      fills.add(Fill(
        row: line,
        time: _withTime(day, col('flTm')),
        orderId: orderId,
        fillId: col('flId').trim(),
        underlying: col('sym').trim(),
        symbol: symbol,
        expiry: parseTradeDate(col('expDt')),
        strike: col('stkPrc').trim(),
        optionType: col('optTp').trim().toUpperCase(),
        side: _side(col('trnsTp')),
        qty: _positiveInt(col('fldQty'), 'quantity'),
        pricePaise: price,
        lotSize: _positiveInt(col('lotSz'), 'lot size'),
        product: col('prod').trim(),
      ));
    } on FormatException catch (e) {
      throw TradebookException('Line $line: ${e.message}.');
    }
  }
  return fills;
}
