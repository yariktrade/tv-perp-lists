# watchlist-builder

Static page on GitHub Pages (yariktrade.github.io/watchlist-builder): live USDT/USDC symbol lists of crypto exchanges for TradingView watchlist import.

- Everything lives in `index.html`; no build, no dependencies. The only data source is the public `scanner.tradingview.com/crypto/scan`, queried anonymously from the browser (CORS allowed, no cookies). Never use a TradingView account or the TradingView MCP for this project.
- Rows: every exchange in the response, tagged CEX/DEX by TradingView's `centralization` field. `KNOWN` only names CEXes and sets their order; DEX ids are split into protocol / version / chain for display. Rows and columns with nothing under the current choice are hidden.
- Columns: Spot, Perps, TradFi (dated futures are not requested: few under USDT/USDC, and they expire). TradFi is a derivative with an empty `base_currency`. On 2026-10-22 this matched the exchanges' own classification for 1537 of 1540 symbols. TradingView gives no TradFi subtype, so "Split TradFi by ticker" (a setting, off by default) guesses Stocks & ETF / Indices / Metals / Commodities / FX from the ticker (`TF_RULES`; 1167 of 1170 agreed with the exchanges' classes, misses IAU, SLV, H100).
- Output: `EXCHANGE:SYMBOL`, comma-separated, at most 1000 entries per list. "Together" (default) packs all cells into one list, split into parts; "Separate" gives one per cell. Copy gives the plain list; the .txt adds `###Exchange Market` sections (on by default, headers count toward the limit).
- Layout: pinned header (name; Venue and Quote chips; gear with settings). Column headers stick under it via `--head-h`. Settings: TradFi split, list mode, sections, theme. Venue, quote and settings persist in localStorage `wb-settings`; the cell selection does not.
- Publish only through the GitHub account `yariktrade`, never the owner's personal account.
- Verify: `./check.sh` must print `PASS` (live requests, headless Chrome, selects the whole table).
