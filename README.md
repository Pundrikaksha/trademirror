# TradeMirror

**See what your F&O option trades really made after every charge, and which habits cost you money. Offline, on your device.**

TradeMirror is a Flutter app for Indian F&O index-option traders. Import a broker tradebook CSV and it:

1. matches your fills into round trips,
2. adds every charge (brokerage, STT, NSE transaction charge, SEBI fee, stamp duty, GST) to the paisa,
3. shows **Gross P&L vs Total charges vs Net P&L**, with a daily chart and a per-trade list, and
4. flags four money-losing habits: revenge trades, overtrading days, expiry-day trades and losers held longer than winners.

It has no login, no broker connection, no network calls, no AI, and it never places orders or tells you to buy or sell.

## Disclaimer

Educational only, not investment advice. TradeMirror and its authors are not SEBI-registered research analysts or investment advisers. Charges are estimates from published rates and may differ slightly from your contract note (for example in how a broker rounds STT). All sample data in this repo is **synthetic**.

## Screens

| Tab | What it shows |
|---|---|
| **Import CSV** | "Load sample (synthetic) tradebook" and "Pick CSV file" (works on web, desktop and mobile; the file is read as bytes in memory). Clear error card for empty files, wrong headers or a malformed row (with its line number). |
| **Dashboard** | Big cards for Gross P&L, Total charges and Net P&L; charges breakdown with a bar per charge; hand-drawn bar chart of daily net P&L; expandable list of every round trip with entry/exit, qty, gross, charges, net, habit chips and the reason for each tag. |
| **Habits** | One card per habit with the trade count, rupee impact (net P&L of the tagged trades), a one-line plain explanation and the trade IDs. |
| **Tips** | Plain observations generated from fixed text templates and the habit results. No network and no model. |

A yellow **SYNTHETIC DATA** banner appears on every screen while the sample is loaded.

## Run it

Requires Flutter 3.35+ (Dart 3.9+).

```bash
cd app
flutter pub get
flutter run -d chrome        # or any connected device
flutter test                 # unit + widget tests
flutter analyze
flutter build web --release  # output in app/build/web
```

## Try it with sample data

Tap **Load sample (synthetic) tradebook**. The bundled file is `app/assets/sample/sample_tradebook_kotak_neo_SYNTHETIC.csv`: 108 fills, 98 orders, 50 round trips of NIFTY and BANKNIFTY options between 5 and 16 Oct 2026, for a fictional trader. Every ID, price and timestamp is invented.

Expected headline result (checked to the paisa by `app/test/core_test.dart`):

| Item | Amount (₹) |
|---|---:|
| Gross P&L | −16,401.50 |
| Brokerage | 980.00 |
| STT | 949.79 |
| Exchange txn | 455.72 |
| SEBI fee | 1.25 |
| Stamp duty | 19.47 |
| GST | 258.62 |
| **Total charges** | **2,664.85** |
| **Net P&L** | **−19,066.35** |

## Import your own tradebook

The parser reads the Kotak Neo trade-report column set: `flDt, flTm, exTm, nOrdNo, exOrdId, flId, exSeg, sym, trdSym, expDt, stkPrc, optTp, trnsTp, fldQty, avgPrc, lotSz, prod, rptTp, usrId` (one row per fill, dates like `05-Oct-2026`). Other column orders work as long as these headers are present. Exports with different headers are rejected with a message listing the missing columns.

## How charges are calculated (NSE index options, Oct 2026)

| Charge | Rate |
|---|---|
| Brokerage | ₹10 per executed order (partial fills of one order count once) |
| STT | 0.15% of sell-side premium |
| NSE transaction charge (incl. IPFT) | 0.03553% of premium turnover |
| SEBI fee | 0.0001% of turnover |
| Stamp duty | 0.003% of buy-side premium |
| GST | 18% of (brokerage + exchange charge + SEBI fee) |

Each charge is rounded half-up to the paisa per round trip; totals are sums of the rounded values. All money is integer paise, so there is no floating-point drift. See [devpost/spec.md](devpost/spec.md) for full details.

## Privacy

- No accounts, no telemetry, no network requests.
- The CSV is parsed in memory and never saved or uploaded.
- The account-ID column (`usrId`) is skipped and never stored.

## Docs

- [devpost/scope.md](devpost/scope.md): what is in and out
- [devpost/prd.md](devpost/prd.md): problem, audience, features
- [devpost/spec.md](devpost/spec.md): architecture, data model, formulas, habit rules, tests

## How it was built

Pre-existing code: none; only open-source Flutter/pub packages (`go_router`, `file_picker`, `flutter_lints`). All application code, the CSV parser and the charges/habit engine were written for this project.

## License

MIT. See [LICENSE](LICENSE).
