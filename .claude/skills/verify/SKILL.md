---
name: verify
description: Pass/fail check for tv-perp-lists — run before every commit that touches index.html.
---
Run `./check.sh` from the project root. It needs network access and Google Chrome, so run it outside the Bash sandbox.
`PASS` means the matrix loaded (20+ exchanges), select-all ticked every cell, and the generated lists are well-formed `EXCHANGE:SYMBOL` with no duplicates, none over 1000 symbols, with a zip link. Anything else is a failure: report the printed reason.
