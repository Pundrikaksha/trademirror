# TradeMirror: product requirements (as built)

## Problem

Most individual traders in Indian equity F&O lose money (SEBI's studies of FY22–FY25 put the share of loss-making individual traders at around nine in ten). Two things hide the true picture from a trader:

1. **Charges.** Broker apps show P&L per trade, but STT, exchange charges, SEBI fees, stamp duty, GST and per-order brokerage are spread over contract notes. On small, frequent option trades they are a large share of the result.
2. **Habits.** The same behaviours repeat: jumping back in right after a loss, piling trades onto one day, gambling on expiry day, cutting winners fast while letting losers run. A trade list doesn't show these.

## Audience

Retail traders of NSE index options (NIFTY, BANKNIFTY) who can export a tradebook CSV and want an honest after-cost view of what they did. No finance background is assumed; all text is plain English.

## Goals

- Show **gross P&L, total charges and net P&L** for an imported tradebook, correct to the paisa against published charge rates.
- Break charges down by type so the trader sees where the money went.
- Detect four habits and show the rupee impact of each on the trader's own trades.
- Work fully offline and keep the file private.

## Non-goals

No AI, no broker connection, no live data, no orders, no advice to buy or sell, no account, no cloud storage. See [scope.md](scope.md).

## Features

| Feature | Requirement | Status |
|---|---|---|
| Load sample | One tap loads a bundled synthetic tradebook and shows a SYNTHETIC DATA banner on every screen | Done |
| Import CSV | File picker reads bytes (web, desktop, mobile). Empty file, missing columns and malformed rows produce a clear error card naming the problem and the line | Done |
| Headline cards | Gross P&L vs Total charges vs Net P&L, coloured by sign | Done |
| Charges breakdown | Brokerage, STT, exchange, SEBI, stamp, GST with amounts, share bars and the rate used | Done |
| Daily chart | Bar chart of net P&L per exit date | Done |
| Trade list | Each round trip: contract, long/short, qty, entry/exit time and average price, gross, charges, net, habit chips; expands to per-charge amounts and the reasons for each tag | Done |
| Habits | Card per habit: count, net P&L of tagged trades, one-line explanation, trade IDs | Done |
| Tips | Fixed templates filled from the results; describe past behaviour only | Done |
| Disclaimer | "Educational only, not investment advice" on every data screen | Done |

## Success criteria

- On the synthetic sample: 108 fills, 98 orders, 50 round trips; gross −₹16,401.50, charges ₹2,664.85, net −₹19,066.35; every per-trade figure and habit tag equal to the reference file. **Met** (automated tests).
- `flutter analyze` clean, all tests pass, web release build succeeds. **Met.**

## Privacy

- The app makes no network requests and has no analytics.
- Files are parsed in memory and dropped when the app closes.
- The account-ID column is not stored.
- The bundled data is fully synthetic, with a fictional trader and invented IDs.
