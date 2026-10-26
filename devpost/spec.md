# TradeMirror: technical spec (as built)

## Architecture

```
app/lib/
  main.dart                  MaterialApp.router
  app/router.dart            go_router shell with 4 tabs: Import, Dashboard, Habits, Tips
  app/theme.dart             Material 3 light/dark theme
  app/store.dart             MirrorStore (ChangeNotifier): current result, source, error
  app/widgets.dart           banner, disclaimer, empty state, P&L text
  core/                      pure Dart, no Flutter imports
    money.dart               paise parsing, half-up rate maths, Indian number formatting
    csv.dart                 RFC 4180 reader
    tradebook.dart           Kotak Neo CSV -> List<Fill>
    mirror.dart              round trips, charges, habits -> MirrorResult
  features/{import,dashboard,habits,tips}/   one screen each
```

Data flow: CSV text → `parseKotakNeoTradebook` → `List<Fill>` → `analyse` → `MirrorResult` → `MirrorStore` → screens rebuild through `ListenableBuilder`. There is no persistence and no network code.

Dependencies: Flutter SDK, `go_router`, `file_picker` (dev: `flutter_lints`). No other packages.

## Input format

Header row must contain: `flDt, flTm, nOrdNo, flId, sym, trdSym, expDt, stkPrc, optTp, trnsTp, fldQty, avgPrc, lotSz, prod` (the full Kotak Neo trade report also has `exTm, exOrdId, exSeg, rptTp, usrId`; these are ignored). One row per fill.

- Dates `dd-MMM-yyyy` (also `yyyy-MM-dd`), times `HH:mm[:ss]`.
- `trnsTp` is `B`/`S` (or `BUY`/`SELL`).
- `fldQty`, `lotSz` positive integers; `avgPrc` decimal with at most 2 significant decimals.
- Errors (`TradebookException`): empty file; header only; missing columns (listed); any bad cell, reported as `Line N: ...`. A file is either imported in full or rejected; there is no silent row skipping.

## Data model

| Type | Fields |
|---|---|
| `Fill` | line number, fill time, order id, fill id, underlying, trading symbol, expiry, strike, CE/PE, side, qty, price (paise), lot size, product |
| `RoundTrip` | id (T01…, by entry time), contract fields, long/short, qty, entry/exit time, buy value, sell value (paise), entry/exit order ids, charged order count, `Charges`, habit set, reasons; derived gross, net, hold time |
| `Charges` | brokerage, STT, exchange txn, SEBI fee, stamp duty, GST (paise); total |
| `MirrorResult` | fill count, order count, trips, open positions, overtrading days and threshold, median winner/loser hold, hold-asymmetry flag; derived gross, charges, net, per-day summaries, per-habit summaries |

All money is `int` paise. Values stay below 2^53, so the maths is exact on the web too.

## Round-trip matching

Per trading symbol, fills are grouped into orders by `nOrdNo` and processed in time order with a signed position:

- From flat, an order opens a trip: long if it buys, short if it sells (sell to open).
- Fills on the same side add to the trip; opposite fills close it (FIFO). When the position returns to 0 the trip is complete.
- An order that more than closes the position splits: the remainder opens a new trip. Its brokerage is charged once, to the first trip.
- Entry time is the first fill of the first entry order; exit time is the first fill of the last exit order.
- A position still open whose expiry date is on or before the last fill date in the file is closed at price 0 at 15:30 on expiry day (`expiredWorthless`). Otherwise it is listed as open and left out of the totals.

Gross P&L = sell value − buy value, using each fill's own quantity × price (no rounded averages).

## Charges (per round trip)

| Charge | Formula |
|---|---|
| Brokerage | ₹10 × distinct orders in the trip (expired-worthless: entry order only) |
| STT | 0.15% × sell value |
| Exchange txn | 0.03553% × (buy value + sell value) |
| SEBI fee | 0.0001% × (buy value + sell value) |
| Stamp duty | 0.003% × buy value |
| GST | 18% × (brokerage + exchange txn + SEBI fee), using the rounded components |

Each line is `round_half_up(value × num / den)` to the paisa, computed with integers as `(v·num·2 + den) ÷ (2·den)`. Totals are sums of the rounded per-trip values. Rates live in `ChargeRates` and can be changed in one place.

## Habit rules

Winners and losers are judged on **net** P&L.

| Habit | Rule |
|---|---|
| `revenge` | Trip opened ≤ 10 min after a net-losing trip's exit (the latest such exit is the trigger) |
| `revenge_strong` | As above and qty ≥ 1.5 × the losing trip's qty (replaces `revenge`) |
| `overtrading_day` | Every trip opened on a day where trips opened ≥ max(8, 2 × median trips per active day) |
| `expiry_day` | Trip opened on its own contract's expiry date (0 DTE) |
| `loser_held_long` | Only if median loser hold ≥ 2 × median winner hold; then each loser held ≥ 2 × median winner hold. Holds use minutes rounded half-up to 0.01 |

A trip with no tags counts as normal. Habit impact shown in the app = sum of net P&L of the tagged trips.

## Tips

`buildTips` fills fixed templates (charges overview, revenge, busy days, expiry day, hold asymmetry) with numbers from `MirrorResult`. Tips describe past behaviour and never contain the words buy or sell (a test checks this).

## Testing

`flutter test` runs 21 tests:

- `test/core_test.dart` (16): parses the bundled sample and compares with `test/fixtures/expected_results.json`: counts (108 fills, 98 orders, 50 trips); buy/sell value, gross, each charge, total charges and net totals as exact strings; every trip's orders, qty, hold, values, each charge, net and tag set; habit counts, overtrading dates, medians; daily totals. Bad input: empty, header only, wrong headers, malformed row (line number), short row, bad side, unterminated quote. CSV quoting, short trades with partial fills, open vs expired positions, rounding and formatting.
- `test/widget_test.dart` (5): tabs present, dashboard empty state then the three headline numbers after import, habits screen and disclaimer, error card for a bad file, tips contain no buy/sell wording.

## Privacy

No network access, no storage, no analytics. The account-ID column is never read into the model. The only data in the repository is the synthetic sample and its expected results.
