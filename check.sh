#!/usr/bin/env bash
# Opens index.html in headless Chrome, ticks every exchange and asset class, presses
# "Сформировать" (live API calls) and checks the generated lists. Prints PASS or FAIL.
set -euo pipefail
cd "$(dirname "$0")"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp index.html "$tmp/probe.html"
cat >> "$tmp/probe.html" <<'JS'
<script>
document.querySelectorAll("input[type=checkbox]").forEach(i => { i.checked = true; });
document.getElementById("go").disabled = false;
document.getElementById("go").click();
const t0 = Date.now();
(function poll() {
  const out = document.getElementById("out");
  if (!out.hidden) {
    const lists = [...document.querySelectorAll(".list")].map(l => l.querySelector("textarea").value);
    const errors = [...document.querySelectorAll(".note.error")].map(n => n.textContent);
    const pre = document.createElement("pre"); pre.id = "check-result";
    pre.textContent = JSON.stringify({ lists, errors });
    document.body.append(pre);
  } else if (Date.now() - t0 < 30000) setTimeout(poll, 200);
})();
</script>
JS
"$CHROME" --headless=new --disable-gpu --user-data-dir="$tmp/profile" --virtual-time-budget=30000 \
  --dump-dom "file://$tmp/probe.html" 2>/dev/null > "$tmp/dom.html"
python3 -I - "$tmp/dom.html" <<'PY'
import html, json, re, sys
m = re.search(r'<pre id="check-result">(.*?)</pre>', open(sys.argv[1], encoding="utf-8").read(), re.S)
if not m: sys.exit("FAIL: no result within 30 s")
r = json.loads(html.unescape(m.group(1)))
if r["errors"]: sys.exit("FAIL: " + "; ".join(r["errors"]))
lists = [l.split(",") for l in r["lists"]]
syms = [s for l in lists for s in l]
bad = [s for s in syms if not re.fullmatch(r"(BYBIT|BINANCE):[A-Z0-9]+USDT\.P", s)]
if bad: sys.exit(f"FAIL: bad symbols {bad[:5]}")
if any(len(l) > 1000 for l in lists): sys.exit("FAIL: a list exceeds 1000 symbols")
by = sum(s.startswith("BYBIT:") for s in syms); bn = len(syms) - by
if by < 300 or bn < 300: sys.exit(f"FAIL: too few symbols (Bybit {by}, Binance {bn})")
print(f"PASS: {len(lists)} lists, Bybit {by}, Binance {bn}")
PY
