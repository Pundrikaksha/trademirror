# TradeMirror: scope (as built)

## In scope (done)

| # | Item | Where |
|---|---|---|
| 1 | Kotak Neo trade-report CSV parser (RFC 4180 quoting, BOM, CRLF), with line-numbered errors | `app/lib/core/csv.dart`, `app/lib/core/tradebook.dart` |
| 2 | Round-trip matching per contract: long and short (sell to open), partial fills, one order per `nOrdNo`, longs with no exit closed at ₹0 at 15:30 on expiry | `app/lib/core/mirror.dart` |
| 3 | Charges per round trip in integer paise: brokerage, STT, NSE txn, SEBI, stamp, GST, each rounded half-up | `app/lib/core/mirror.dart` |
| 4 | Habits: revenge (and strong revenge), overtrading day, expiry day, loser held long | `app/lib/core/mirror.dart` |
| 5 | Golden tests against `expected_results.json` (every trade, every total, habit counts, daily totals) plus bad-input tests | `app/test/core_test.dart` |
| 6 | Import screen: bundled synthetic sample, file picker (bytes, works on web), error card, synthetic banner | `app/lib/features/import/` |
| 7 | Dashboard: gross/charges/net cards, charges breakdown, daily net bar chart (CustomPainter), per-trade list with habit chips | `app/lib/features/dashboard/` |
| 8 | Habits screen: count, rupee impact and explanation per habit, disclaimer | `app/lib/features/habits/` |
| 9 | Tips screen: rule-based text templates from the habit results (replaces the planned AI coach) | `app/lib/features/tips/` |
| 10 | Web build | `app/web/` |

## Out of scope (non-goals)

- No AI coach, no LLM, no network calls of any kind.
- No broker login, API keys, live data or order placement.
- No buy/sell recommendations, targets or signals.
- No persistence: the imported file lives in memory for the session only.
- Futures, equity, commodity and currency segments (options only).
- Other brokers' CSV layouts and a generic column mapper.
- Alternative brokerage scenarios (Trade API ₹0 brokerage, min(₹10, 0.05%)); the reference data has them but the app shows only the headline ₹10/order case.

## Cut for time

- Android debug APK (no Android SDK on the build machine).
- Persisting imports between sessions and exporting a report.
