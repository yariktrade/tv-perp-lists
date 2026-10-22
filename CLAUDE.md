# tv-perp-lists

Static page on GitHub Pages: live lists of Bybit and Binance USDT perpetuals for TradingView watchlist import.

- Everything lives in `index.html`, with no build step and no dependencies. Each click queries the exchange APIs fresh, then drops symbols that `scanner.tradingview.com` does not resolve.
- Output format is TradingView's import format: `EXCHANGE:SYMBOL.P`, comma-separated, at most 1000 per list.
- Publish only through the GitHub account `yariktrade`, never the owner's personal account.
- Verify: `./check.sh` must print `PASS` (it makes live requests in headless Chrome).
