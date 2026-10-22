#!/usr/bin/env bash
# Opens index.html in headless Chrome, waits for the live exchange matrix, ticks the
# whole table, presses "Generate" and checks the generated lists. Prints PASS or FAIL.
set -euo pipefail
cd "$(dirname "$0")"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp index.html "$tmp/probe.html"
cat >> "$tmp/probe.html" <<'JS'
<script>
const t0 = Date.now();
const report = o => { const pre = document.createElement("pre"); pre.id = "check-result"; pre.textContent = JSON.stringify(o); document.body.append(pre); };
(function waitTable() {
  const corner = document.querySelector("#head input");
  if (corner) document.querySelectorAll("#quotes input").forEach(i => { if (!i.checked) i.click(); });
  if (!corner) { if (Date.now() - t0 < 30000) return setTimeout(waitTable, 200); return report({ errors: ["matrix did not load"] }); }
  const cells = document.querySelectorAll("#body td input:not([disabled])").length;
  corner.click();
  const checked = document.querySelectorAll("#body td input:checked").length;
  const rows = document.querySelectorAll("#body tr").length;
  document.getElementById("go").click();
  (function waitLists() {
    const out = document.getElementById("out"), go = document.getElementById("go");
    if (!out.hidden && go.textContent === "Generate") report({
      rows, cells, checked,
      lists: [...document.querySelectorAll(".list textarea")].map(t => t.value),
      zip: !!document.querySelector('a[download="tradingview-watchlists.zip"]'),
      errors: [...document.querySelectorAll(".note.error:not([hidden])")].map(n => n.textContent) });
    else if (Date.now() - t0 < 60000) setTimeout(waitLists, 200);
    else report({ errors: ["lists did not appear"] });
  })();
})();
</script>
JS
"$CHROME" --headless=new --disable-gpu --user-data-dir="$tmp/profile" --virtual-time-budget=60000 \
  --dump-dom "file://$tmp/probe.html" 2>/dev/null > "$tmp/dom.html"
python3 -I - "$tmp/dom.html" <<'PY'
import html, json, re, sys
m = re.search(r'<pre id="check-result">(.*?)</pre>', open(sys.argv[1], encoding="utf-8").read(), re.S)
if not m: sys.exit("FAIL: no result within 60 s")
r = json.loads(html.unescape(m.group(1)))
if r["errors"]: sys.exit("FAIL: " + "; ".join(r["errors"]))
if r["rows"] < 20: sys.exit(f"FAIL: only {r['rows']} exchanges in the matrix")
if r["checked"] != r["cells"]: sys.exit(f"FAIL: select-all ticked {r['checked']} of {r['cells']} cells")
lists = [l.split(",") for l in r["lists"]]
syms = [s for l in lists for s in l]
bad = [s for s in syms if not re.fullmatch(r"[A-Z0-9_]+:[^,\s]+", s)]
if bad: sys.exit(f"FAIL: bad symbols {bad[:5]}")
if any(len(l) > 1000 for l in lists): sys.exit("FAIL: a list exceeds 1000 symbols")
if len(syms) != len(set(syms)): sys.exit("FAIL: duplicate symbols")
if len(syms) < 10000: sys.exit(f"FAIL: too few symbols ({len(syms)})")
if len(lists) > 1 and not r["zip"]: sys.exit("FAIL: no zip link for several lists")
print(f"PASS: {r['rows']} exchanges, {r['cells']} cells, {len(lists)} lists, {len(syms)} symbols")
PY
