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
let staleHidden = 0, listed30 = 0;
const report = o => { const pre = document.createElement("pre"); pre.id = "check-result"; pre.textContent = JSON.stringify(o); document.body.append(pre); };
(function waitTable() {
  const corner = document.querySelector("#head input");
  if (corner) {
    const shown = id => getComputedStyle(document.getElementById(id)).display !== "none";
    if (shown("settings") || shown("out")) return report({ errors: ["settings panel or output is visible on load"] });
  }
  if (corner) {
    // Default quote (USDT only): no visible exchange row may be empty.
    const empty = [...document.querySelectorAll("#body tr:not([hidden])")].filter(tr => !tr.querySelector("td input:not([disabled])")).length;
    if (empty) return report({ errors: [`${empty} visible exchange rows have no USDT symbols`] });
  }
  const cexRows = document.querySelectorAll("#body tr:not([hidden])").length;
  if (corner) {
    // Split TradFi: the sub-columns of every exchange must add up to its TradFi cell, and nothing else may move.
    const numbers = () => Object.fromEntries([...document.querySelectorAll("#body tr:not([hidden])")].map(tr =>
      [tr.querySelector("th").textContent.trim(), [...tr.querySelectorAll("td:not([hidden]) .n")].map(n => +n.textContent || 0)]));
    const before = numbers();
    document.getElementById("split").click();
    const after = numbers(), cols = document.querySelectorAll("#head th:not([hidden])").length;
    document.getElementById("split").click();
    const bad = Object.keys(before).filter(ex => { const b = before[ex], a = after[ex] || [];
      return b.slice(0, -1).join() !== a.slice(0, b.length - 1).join() || b.at(-1) !== a.slice(b.length - 1).reduce((x, y) => x + y, 0); });
    if (cols < 7 || bad.length) return report({ errors: [`split TradFi: ${cols} visible columns, mismatched rows: ${bad.slice(0, 5).join(", ")}`] });
    // Hide stale (on by default): switching it off may only add symbols.
    const total = () => [...document.querySelectorAll("#body tr:not([hidden]) td:not([hidden]) .n")].reduce((x, n) => x + (+n.textContent || 0), 0);
    const withFilter = total(); document.getElementById("fresh").click(); const without = total(); document.getElementById("fresh").click();
    if (without < withFilter || !document.getElementById("fresh").checked) return report({ errors: [`stale filter: ${withFilter} with, ${without} without`] });
    staleHidden = without - withFilter;
    // Listed 30d: only symbols whose first bar is recent, so fewer than all, but not none.
    document.querySelector('input[name=age][value="30"]').click(); const recent = total();
    document.querySelector('input[name=age][value="0"]').click();
    if (!(recent > 0 && recent < withFilter) || total() !== withFilter) return report({ errors: [`listed 30d: ${recent} of ${withFilter}`] });
    listed30 = recent;
  }
  if (corner) document.querySelectorAll("#quotes input, #venues input").forEach(i => { if (!i.checked) i.click(); });
  if (!corner) { if (Date.now() - t0 < 30000) return setTimeout(waitTable, 200); return report({ errors: ["matrix did not load"] }); }
  const cells = document.querySelectorAll("#body td input:not([disabled])").length;
  document.querySelector("#head input").click(); // re-query: the split toggle rebuilt the table
  const checked = document.querySelectorAll("#body td input:checked").length;
  const rows = document.querySelectorAll("#body tr:not([hidden])").length;
  document.getElementById("go").click();
  (function waitLists() {
    const out = document.getElementById("out"), go = document.getElementById("go");
    if (!out.hidden && go.textContent === "Generate") finish();
    else if (Date.now() - t0 < 60000) setTimeout(waitLists, 200);
    else report({ errors: ["lists did not appear"] });
  })();
  async function finish() {
    const errors = [...document.querySelectorAll(".note.error:not([hidden])")].map(n => n.textContent);
    const plain = [...document.querySelectorAll(".list textarea")].map(t => t.value);
    const files = await Promise.all([...document.querySelectorAll(".list a[download]")].map(a => fetch(a.href).then(r => r.text())));
    const zip = !!document.querySelector('a[download="tradingview-watchlists.zip"]');
    document.querySelector('input[name=mode][value=separate]').click();
    const separate = document.querySelectorAll(".list").length;
    document.getElementById("sections").click();
    const sepFiles = await Promise.all([...document.querySelectorAll(".list a[download]")].slice(0, 3).map(a => fetch(a.href).then(r => r.text())));
    report({ rows, cexRows, staleHidden, listed30, cells, checked, plain, files, zip, separate, sepFiles, errors });
  }
})();
</script>
JS
cp -R base.css shared.js log.html data "$tmp/"
port=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmp" >/dev/null 2>&1 & server=$!; disown
trap 'kill $server 2>/dev/null; rm -rf "$tmp"' EXIT
sleep 1
"$CHROME" --headless=new --disable-gpu --user-data-dir="$tmp/profile" --virtual-time-budget=60000 \
  --dump-dom "http://127.0.0.1:$port/probe.html" 2>/dev/null > "$tmp/dom.html"
CHECK_TMP="$tmp" CHECK_PORT="$port" CHROME="$CHROME" python3 -I - "$tmp/dom.html" <<'PY'
import html, json, re, sys
m = re.search(r'<pre id="check-result">(.*?)</pre>', open(sys.argv[1], encoding="utf-8").read(), re.S)
if not m: sys.exit("FAIL: no result within 60 s")
r = json.loads(html.unescape(m.group(1)))
if r["errors"]: sys.exit("FAIL: " + "; ".join(r["errors"]))
if r["cexRows"] < 20: sys.exit(f"FAIL: only {r['cexRows']} CEX rows by default")
if r["rows"] < r["cexRows"] + 30: sys.exit(f"FAIL: ticking DEX added only {r['rows'] - r['cexRows']} rows")
if r["checked"] != r["cells"]: sys.exit(f"FAIL: select-all ticked {r['checked']} of {r['cells']} cells")
lists = [l.split(",") for l in r["plain"]]
syms = [s for l in lists for s in l]
bad = [s for s in syms if not re.fullmatch(r"[A-Z0-9_]+:[^,\s]+", s)]
if bad: sys.exit(f"FAIL: bad symbols {bad[:5]}")
if any(len(l) > 1000 for l in lists): sys.exit("FAIL: a list exceeds 1000 symbols")
if len(syms) != len(set(syms)): sys.exit("FAIL: duplicate symbols")
if len(syms) < 10000: sys.exit(f"FAIL: too few symbols ({len(syms)})")
if len(lists) > 1 and not r["zip"]: sys.exit("FAIL: no zip link for several lists")
files = [f.split(",") for f in r["files"]]
if not all(f[0].startswith("###") for f in files): sys.exit("FAIL: downloaded file does not start with a ###section")
if any(len(f) > 1000 for f in files): sys.exit("FAIL: a downloaded file exceeds 1000 entries")
if sorted(s for f in files for s in f if not s.startswith("###")) != sorted(syms): sys.exit("FAIL: file symbols differ from the copied list")
if r["separate"] < r["checked"]: sys.exit(f"FAIL: separate mode gave {r['separate']} lists for {r['checked']} cells")
if any("###" in f for f in r["sepFiles"]): sys.exit("FAIL: sections still present with the option off")
# --- log.html: default filters (CEX, USDT, added + removed, 30 days) must show exactly what the data files hold
import datetime, os, subprocess
tmp, port = os.environ["CHECK_TMP"], os.environ["CHECK_PORT"]
probe = open(f"{tmp}/log.html").read() + """<script>
(function wait() {
  if (document.getElementById("count").textContent.includes("changes")) {
    const pre = document.createElement("pre"); pre.id = "check-result";
    const first = document.getElementById("count").textContent;
    const boxes = [...document.querySelectorAll("#exlist input[name=ex]")];
    boxes.forEach(i => { i.checked = i.value === "BINANCE"; });
    document.getElementById("exlist").dispatchEvent(new Event("change", { bubbles: true }));
    pre.textContent = JSON.stringify({ first, binance: document.getElementById("count").textContent,
      options: boxes.length, rows: document.querySelectorAll("#rows tr").length });
    document.body.append(pre);
  } else setTimeout(wait, 100);
})();
</script>"""
open(f"{tmp}/logprobe.html", "w").write(probe)
dom = subprocess.run([os.environ["CHROME"], "--headless=new", "--disable-gpu", f"--user-data-dir={tmp}/profile2", "--virtual-time-budget=20000",
  "--dump-dom", f"http://127.0.0.1:{port}/logprobe.html"], capture_output=True, text=True).stdout
m = re.search(r'<pre id="check-result">(.*?)</pre>', dom, re.S)
if not m: sys.exit("FAIL: log.html did not render")
lr = json.loads(html.unescape(m.group(1)))
log = json.load(open(f"{tmp}/data/log.json")); venue = json.load(open(f"{tmp}/data/exchanges.json"))
start = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=30)).strftime("%Y-%m-%d")
rows = [s for e in log["entries"] if e["date"] >= start for s in e["added"] + e["removed"]
        if venue.get(s.split(":")[0], "cex") == "cex" and "USDC" not in s.split(":")[1]]
want = len(rows)
got = int(lr["first"].split(" changes")[0].replace(",", ""))
if got != want: sys.exit(f"FAIL: log.html shows {got} changes, data holds {want}")
bn = int(lr["binance"].split(" changes")[0].replace(",", ""))
if not (0 < bn < got) or lr["options"] < 10: sys.exit(f"FAIL: log.html exchange filter: {bn} of {got}, {lr['options']} options")
print(f"PASS: stale hidden by default {r['staleHidden']}, listed in 30d {r['listed30']}, {r['cexRows']} CEX, {r['rows']} CEX+DEX exchanges, {r['cells']} cells, together {len(lists)} lists, separate {r['separate']} lists, {len(syms)} symbols; log.html {got} changes in 30d (Binance {bn})")
PY
