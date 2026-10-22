import 'package:flutter_test/flutter_test.dart';
import 'package:trademirror/core/charges_api.dart';

void main() {
  group('ChargeBreakdown data class', () {
    test('total correctly sums all charge fields', () {
      const breakdown = ChargeBreakdown(
        brokerage: 20.0,
        stt: 12.5,
        exchangeTxn: 6.8,
        sebiFee: 0.15,
        stampDuty: 3.0,
        gst: 4.83,
      );

      expect(
        breakdown.total,
        closeTo(20.0 + 12.5 + 6.8 + 0.15 + 3.0 + 4.83, 1e-6),
      );
    });

    test('default total is zero', () {
      const breakdown = ChargeBreakdown();
      expect(breakdown.total, equals(0.0));
    });
  });
}
