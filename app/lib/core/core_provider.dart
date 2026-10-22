import 'charges_api.dart';

class NotImplementedTradebookParser implements TradebookParser {
  const NotImplementedTradebookParser();

  @override
  MappingProfile? suggestProfile(List<String> headerRow) {
    throw UnimplementedError(
      'TradebookParser is not yet implemented. '
      'Not implemented yet.',
    );
  }

  @override
  ImportReport parse(String csvText, {MappingProfile? profile}) {
    throw UnimplementedError(
      'TradebookParser is not yet implemented. '
      'Not implemented yet.',
    );
  }
}

class NotImplementedChargesEngine implements ChargesEngine {
  const NotImplementedChargesEngine();

  @override
  ChargeBreakdown chargesForOrder({
    required Side side,
    required double turnover,
    ChargesConfig? config,
  }) {
    throw UnimplementedError(
      'ChargesEngine is not yet implemented. '
      'Not implemented yet.',
    );
  }

  @override
  List<RoundTrip> buildRoundTrips(
    List<Fill> fills, {
    ChargesConfig? config,
  }) {
    throw UnimplementedError(
      'ChargesEngine is not yet implemented. '
      'Not implemented yet.',
    );
  }

  @override
  MirrorSummary summarize(
    List<Fill> fills, {
    ChargesConfig? config,
  }) {
    throw UnimplementedError(
      'ChargesEngine is not yet implemented. '
      'Not implemented yet.',
    );
  }
}

class CoreProvider {
  CoreProvider._();

  static TradebookParser get parser => const NotImplementedTradebookParser();
  static ChargesEngine get engine => const NotImplementedChargesEngine();
}
