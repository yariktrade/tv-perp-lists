"""Daily snapshot of TradingView's USDT/USDC crypto symbols and a log of what was added or removed.

Run by .github/workflows/snapshot.yml once a day (and by hand: `python3 scripts/snapshot.py`).
Queries the public TradingView scanner anonymously, the same request the page makes.

data/symbols.json  the latest symbol set: {"date", "count", "symbols": [...]}
data/exchanges.json  {exchange: "cex" | "dex"} from TradingView's centralization tag (log.html filters by it).
data/log.json      {"since", "entries": [{"date", "added", "removed"[, "source"]}]}, newest first.
                   A symbol counts as present while TradingView lists it, so removals show up when
                   TradingView drops a delisted symbol (it does so within a month); the page's
                   "Hide stale" filter covers the gap. On the first run, additions of the last
                   30 days are backfilled from each symbol's first bar on TradingView and marked
                   "source": "first-bar"; removals before the first run are unknown.
"""

import json
import sys
import time
import urllib.request
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

SCANNER = "https://scanner.tradingview.com/crypto/scan"
DATA = Path(__file__).resolve().parent.parent / "data"
BACKFILL_DAYS = 30
MIN_SHARE = 0.8  # a response this much smaller than the last one is treated as an outage, not delistings


def fetch() -> list[dict]:
    body = {
        "columns": ["first_bar_time", "exchange", "centralization"],
        "range": [0, 300000],
        "filter": [
            {"left": "type", "operation": "in_range", "right": ["spot", "swap"]},
            {"left": "currency", "operation": "in_range", "right": ["USDT", "USDC"]},
        ],
    }
    req = urllib.request.Request(SCANNER, data=json.dumps(body).encode(), headers={"Content-Type": "text/plain"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return [{"s": x["s"], "first": x["d"][0], "ex": x["d"][1], "v": x["d"][2]} for x in json.load(r)["data"]]


def day(ts: float) -> str:
    return datetime.fromtimestamp(ts, timezone.utc).strftime("%Y-%m-%d")


def main() -> int:
    rows = fetch()
    today = day(time.time())
    current = sorted({r["s"] for r in rows})
    sym_path, log_path = DATA / "symbols.json", DATA / "log.json"
    DATA.mkdir(exist_ok=True)

    if sym_path.exists():
        prev = json.loads(sym_path.read_text())
        if len(current) < MIN_SHARE * prev["count"]:
            print(f"refusing: {len(current)} symbols vs {prev['count']} last time; looks like an outage", file=sys.stderr)
            return 1
        log = json.loads(log_path.read_text())
        before, now = set(prev["symbols"]), set(current)
        added, removed = now - before, before - now
        # A second run on the same day folds into that day's entry instead of replacing it.
        same = next((e for e in log["entries"] if e["date"] == today and "source" not in e), None)
        if same:
            added, removed = (set(same["added"]) - removed) | added, (set(same["removed"]) - added) | removed
            log["entries"].remove(same)
        if added or removed:
            log["entries"].insert(0, {"date": today, "added": sorted(added), "removed": sorted(removed)})
        print(f"{today}: +{len(added)} -{len(removed)} ({len(current)} symbols)")
    else:
        cutoff = time.time() - BACKFILL_DAYS * 86400
        by_day = defaultdict(list)
        for r in rows:
            if r["first"] and r["first"] >= cutoff:
                by_day[day(r["first"])].append(r["s"])
        log = {"since": today, "entries": [
            {"date": d, "added": sorted(s), "removed": [], "source": "first-bar"} for d, s in sorted(by_day.items(), reverse=True)
        ]}
        print(f"{today}: baseline of {len(current)} symbols, {sum(len(s) for s in by_day.values())} additions backfilled")

    tags = defaultdict(lambda: defaultdict(int))
    for r in rows:
        if r["v"]:
            tags[r["ex"]][r["v"]] += 1
    venues = {ex: ("dex" if tags[ex]["dex"] > tags[ex]["cex"] else "cex") for ex in sorted({r["ex"] for r in rows})}
    (DATA / "exchanges.json").write_text(json.dumps(venues, separators=(",", ":")))
    sym_path.write_text(json.dumps({"date": today, "count": len(current), "symbols": current}, separators=(",", ":")))
    log_path.write_text(json.dumps(log, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
