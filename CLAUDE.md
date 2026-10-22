# tv-perp-lists

Static page on GitHub Pages: live USDT-quoted symbol lists of centralised crypto exchanges for TradingView watchlist import. The page is an exchange × market matrix (spot, perps, futures, TradFi) with select-all per row, per column and for the whole table.

- Everything lives in `index.html`, with no build step and no dependencies. The only data source is `scanner.tradingview.com/crypto/scan`, queried live from the browser. It allows cross-origin requests, and every symbol it returns is importable.
- A derivative with an empty `base_currency` counts as TradFi (stocks, ETFs, indices, commodities, FX). On 2026-10-22 this matched Bybit's and Binance's own classification for 1537 of 1540 symbols.
- Rows are a fixed list of exchange IDs (`EXCHANGES`). DEXes are left out on purpose.
- Output format is TradingView's import format: `EXCHANGE:SYMBOL`, comma-separated, at most 1000 per list. Larger selections become one list per cell, plus a zip of all lists.
- Publish only through the GitHub account `yariktrade`, never the owner's personal account.
- Verify: `./check.sh` must print `PASS`. It makes live requests in headless Chrome and selects the whole table.
