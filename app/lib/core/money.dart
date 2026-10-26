/// Exact money helpers. All amounts are integer paise (1 rupee = 100 paise),
/// so sums and comparisons never drift the way floating point does.
library;

/// Parses a decimal string such as "118.45", "-3", "0.5" into paise.
/// Throws [FormatException] for anything that is not a plain decimal with at
/// most two significant decimal places.
int parsePaise(String raw) {
  final s = raw.trim();
  final m = RegExp(r'^(-?)(\d*)(?:\.(\d*))?$').firstMatch(s);
  if (s.isEmpty || m == null || (m[2]!.isEmpty && (m[3] ?? '').isEmpty)) {
    throw FormatException('not a number: "$raw"');
  }
  final whole = m[2]!.isEmpty ? 0 : int.parse(m[2]!);
  var frac = m[3] ?? '';
  // Allow trailing zeros beyond paise ("118.4500") but nothing finer.
  if (frac.length > 2) {
    if (frac.substring(2).replaceAll('0', '').isNotEmpty) {
      throw FormatException('more precise than one paisa: "$raw"');
    }
    frac = frac.substring(0, 2);
  }
  final paise =
      whole * 100 + (frac.isEmpty ? 0 : int.parse(frac.padRight(2, '0')));
  return m[1] == '-' ? -paise : paise;
}

/// value * num / den, rounded half-up to a whole paisa. [value] must be >= 0.
int mulRateHalfUp(int value, int num, int den) {
  assert(value >= 0 && num >= 0 && den > 0);
  return (value * num * 2 + den) ~/ (den * 2);
}

/// Formats paise as rupees with Indian digit grouping, e.g. -1906635 ->
/// "-₹19,066.35".
String formatInr(int paise, {bool symbol = true, bool plusSign = false}) {
  final neg = paise < 0;
  final abs = paise.abs();
  final rupees = (abs ~/ 100).toString();
  final p = (abs % 100).toString().padLeft(2, '0');
  String grouped;
  if (rupees.length <= 3) {
    grouped = rupees;
  } else {
    final last3 = rupees.substring(rupees.length - 3);
    var rest = rupees.substring(0, rupees.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  final sign = neg ? '-' : (plusSign && paise > 0 ? '+' : '');
  return '$sign${symbol ? '₹' : ''}$grouped.$p';
}

/// Plain "-16401.50" form, used to compare against fixture files.
String paiseToDecimalString(int paise) {
  final neg = paise < 0;
  final abs = paise.abs();
  return '${neg ? '-' : ''}${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
}
