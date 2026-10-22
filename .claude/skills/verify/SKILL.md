---
name: verify
description: Pass/fail check for tv-perp-lists — run before every commit that touches index.html.
---
Run `./check.sh` from the project root. It needs network access and Google Chrome, so run it outside the Bash sandbox.
`PASS` means both exchanges answered, every symbol is `BYBIT:` or `BINANCE:` + `…USDT.P`, and no list exceeds 1000 symbols. Anything else is a failure: report the printed reason.
