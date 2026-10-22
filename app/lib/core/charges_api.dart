
enum Side { buy, sell }

enum OptionType { ce, pe }

class Fill {
  final String? orderId;
  final String? fillId;
  final DateTime tradeTime;
  final String underlying;
  final DateTime expiry;
  final double strike;
  final OptionType optionType;
  final Side side;
  final int qty;
  final double price;
  final int? lotSize;
  final String? product;

  const Fill({
    this.orderId,
    this.fillId,
    required this.tradeTime,
    required this.underlying,
    required this.expiry,
    required this.strike,
    required this.optionType,
    required this.side,
    required this.qty,
    required this.price,
    this.lotSize,
    this.product,
  });
}

class ImportReport {
  final String profileId;
  final List<Fill> fills;
  final int rowsRead, rowsSkipped, duplicatesDropped;
  final List<String> warnings;

  const ImportReport({
    required this.profileId,
    required this.fills,
    required this.rowsRead,
    required this.rowsSkipped,
    required this.duplicatesDropped,
    required this.warnings,
  });
}

class MappingProfile {
  final String id;
  final Map<String, String> columns;

  const MappingProfile({
    required this.id,
    required this.columns,
  });

  factory MappingProfile.fromJson(Map<String, dynamic> json) {
    return MappingProfile(
      id: json['id'] as String? ?? json['profile'] as String? ?? '',
      columns: (json['columns'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'columns': columns,
      };
}

class ChargesConfig {
  final String version;

  const ChargesConfig({
    required this.version,
  });

  factory ChargesConfig.fromJson(Map<String, dynamic> json) {
    return ChargesConfig(
      version: json['version'] as String? ?? '2026-10-21',
    );
  }

  static ChargesConfig defaults() {
    return const ChargesConfig(version: '2026-10-21');
  }
}

class ChargeBreakdown {
  final double brokerage, stt, exchangeTxn, sebiFee, stampDuty, gst;

  const ChargeBreakdown({
    this.brokerage = 0.0,
    this.stt = 0.0,
    this.exchangeTxn = 0.0,
    this.sebiFee = 0.0,
    this.stampDuty = 0.0,
    this.gst = 0.0,
  });

  double get total =>
      brokerage + stt + exchangeTxn + sebiFee + stampDuty + gst;
}

class RoundTrip {
  final String underlying;
  final DateTime expiry;
  final double strike;
  final OptionType optionType;
  final bool isLong;
  final int qty;
  final DateTime entryTime, exitTime;
  final double entryAvg, exitAvg;
  final double grossPnl;
  final ChargeBreakdown charges;
  double get netPnl => grossPnl - charges.total;
  final bool expiredWorthless;

  const RoundTrip({
    required this.underlying,
    required this.expiry,
    required this.strike,
    required this.optionType,
    required this.isLong,
    required this.qty,
    required this.entryTime,
    required this.exitTime,
    required this.entryAvg,
    required this.exitAvg,
    required this.grossPnl,
    required this.charges,
    required this.expiredWorthless,
  });
}

class DaySummary {
  final DateTime day;
  final int roundTrips;
  final double gross, charges, net;

  const DaySummary({
    required this.day,
    required this.roundTrips,
    required this.gross,
    required this.charges,
    required this.net,
  });
}

class MirrorSummary {
  final int roundTripCount;
  final double grossPnl, totalCharges, netPnl;
  final ChargeBreakdown chargesByType;
  final List<DaySummary> days;
  final List<RoundTrip> roundTrips;
  final List<Fill> openFills;

  const MirrorSummary({
    required this.roundTripCount,
    required this.grossPnl,
    required this.totalCharges,
    required this.netPnl,
    required this.chargesByType,
    required this.days,
    required this.roundTrips,
    required this.openFills,
  });
}

abstract class TradebookParser {
  MappingProfile? suggestProfile(List<String> headerRow);
  ImportReport parse(String csvText, {MappingProfile? profile});
}

abstract class ChargesEngine {
  ChargeBreakdown chargesForOrder({
    required Side side,
    required double turnover,
    ChargesConfig? config,
  });
  List<RoundTrip> buildRoundTrips(
    List<Fill> fills, {
    ChargesConfig? config,
  });
  MirrorSummary summarize(
    List<Fill> fills, {
    ChargesConfig? config,
  });
}
