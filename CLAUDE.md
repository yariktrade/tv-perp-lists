# watchlist-builder

Static page on GitHub Pages (yariktrade.github.io/watchlist-builder): live USDT- and USDC-quoted symbol lists (quote checkboxes, USDT on by default) of centralised crypto exchanges for TradingView watchlist import. The page is an exchange × market matrix (spot, perps, futures, TradFi) with select-all per row, per column and for the whole table.

- Everything lives in `index.html`, with no build step and no dependencies. The only data source is `scanner.tradingview.com/crypto/scan`, queried live from the browser. It allows cross-origin requests, and every symbol it returns is importable.
- A derivative with an empty `base_currency` counts as TradFi (stocks, ETFs, indices, commodities, FX). On 2026-10-22 this matched Bybit's and Binance's own classification for 1537 of 1540 symbols.
- Rows are a fixed list of exchange IDs (`EXCHANGES`). DEXes are left out on purpose.
- Output format is TradingView's import format: `EXCHANGE:SYMBOL`, comma-separated, at most 1000 per list. Settings sit behind the gear next to Generate: generation options (a dot marks non-default values) and an Auto/Light/Dark theme remembered in localStorage (`wb-theme`) for this site only. "Together" (default) packs every selected cell into one list, split into parts above the limit; "Separate" makes one list per cell. Copy gives the plain list; with "Sections in file" on (default) the downloaded .txt adds a `###Exchange Market` header before each cell, and headers count toward the 1000-entry limit.
- Publish only through the GitHub account `yariktrade`, never the owner's personal account.
- Verify: `./check.sh` must print `PASS`. It makes live requests in headless Chrome and selects the whole table.
