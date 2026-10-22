// Shared by index.html and log.html, loaded in <head> so the theme applies before first paint.
// Settings are remembered for this site in this browser only (localStorage "wb-settings"); "auto" follows the system.
try { const t = (JSON.parse(localStorage.getItem("wb-settings")) || {}).theme; if (t === "light" || t === "dark") document.documentElement.dataset.theme = t; } catch (_) {}

const KNOWN = [ // display names; these CEXes lead in this order, every other exchange follows by symbol count
  ["BINANCE", "Binance"], ["BYBIT", "Bybit"], ["OKX", "OKX"], ["BITGET", "Bitget"], ["GATE", "Gate"], ["MEXC", "MEXC"],
  ["KUCOIN", "KuCoin"], ["BINGX", "BingX"], ["HTX", "HTX"], ["COINBASE", "Coinbase"], ["KRAKEN", "Kraken"],
  ["CRYPTOCOM", "Crypto.com"], ["UPBIT", "Upbit"], ["BITHUMB", "Bithumb"], ["BITFINEX", "Bitfinex"], ["WHITEBIT", "WhiteBIT"],
  ["COINEX", "CoinEx"], ["LBANK", "LBank"], ["XTCOM", "XT.com"], ["PHEMEX", "Phemex"], ["BLOFIN", "BloFin"],
  ["BITUNIX", "Bitunix"], ["WEEX", "WEEX"], ["TOOBIT", "Toobit"], ["ZOOMEX", "Zoomex"], ["KCEX", "KCEX"],
  ["PIONEX", "Pionex"], ["DERIBIT", "Deribit"], ["WOONETWORK", "WOO X"], ["BTSE", "BTSE"], ["BYDFI", "BYDFi"],
  ["BTCC", "BTCC"], ["COINW", "CoinW"], ["DEEPCOIN", "Deepcoin"], ["DELTAIN", "Delta India"], ["COINSWITCH", "CoinSwitch"],
  ["POLONIEX", "Poloniex"], ["BITVAVO", "Bitvavo"], ["BITKUB", "Bitkub"], ["GEMINI", "Gemini"], ["BINANCEUS", "Binance.US"],
  ["BITRUE", "Bitrue"], ["BITSTAMP", "Bitstamp"], ["COINJAR", "CoinJar"], ["BITAZZA", "Bitazza"], ["BITSO", "Bitso"],
  ["BITFLYER", "bitFlyer"],
];
const NAME = Object.fromEntries(KNOWN), RANK = Object.fromEntries(KNOWN.map(([id], i) => [id, i]));
// DEX ids glue protocol, version and chain together (PANCAKESWAP3BSC); split them for display.
// Unknown parts fall back to the raw id, so a new DEX still shows up, just less prettily.
const DEX_PROTOCOLS = [["PANCAKESWAP", "PancakeSwap"], ["UNISWAP", "Uniswap"], ["RAYDIUM", "Raydium"], ["CURVE", "Curve"],
  ["CAMELOT", "Camelot"], ["PULSEX", "PulseX"], ["KATANA", "Katana"], ["STONFI", "STON.fi"], ["QUICKSWAP", "QuickSwap"],
  ["SUSHISWAP", "SushiSwap"], ["VELODROME", "Velodrome"], ["AERODROME", "Aerodrome"], ["METEORA", "Meteora"], ["TRADERJOE", "Trader Joe"],
  ["SPOOKYSWAP", "SpookySwap"], ["SUNSWAP", "SunSwap"], ["ORCA", "Orca"], ["CETUS", "Cetus"], ["BLUEFIN", "Bluefin"], ["DEDUST", "DeDust"],
  ["BISWAP", "Biswap"], ["BASESWAP", "BaseSwap"], ["PANGOLIN", "Pangolin"], ["PHARAOH", "Pharaoh"], ["HONEYSWAP", "Honeyswap"],
  ["MMFINANCE", "MM Finance"], ["VVSFINANCE", "VVS Finance"], ["VVS", "VVS Finance"], ["SYNCSWAP", "SyncSwap"], ["BLACKHOLE", "Blackhole"],
  ["LFJ", "LFJ"], ["TURBOSFINANCE", "Turbos Finance"], ["RAMSES", "Ramses"], ["ZKSWAP", "ZKSwap"]];
const DEX_CHAINS = [["ETH", "Ethereum"], ["BSC", "BNB Chain"], ["BASE", "Base"], ["ARBITRUM", "Arbitrum"], ["POLYGON", "Polygon"],
  ["OPTIMISM", "Optimism"], ["AVALANCHE", "Avalanche"], ["ZKSYNC", "zkSync"], ["UNICHAIN", "Unichain"]];
const DEX_VARIANTS = { "2DOT2": "v2.2", CLMM: "CLMM", CPMM: "CPMM", DLMM: "DLMM", DYN: "Dynamic", SLIPSTREAM: "Slipstream" };
function exParts(ex) {
  if (NAME[ex]) return { title: NAME[ex], sub: "" };
  const p = DEX_PROTOCOLS.find(([id]) => ex.startsWith(id));
  if (!p) return { title: ex, sub: "" };
  let rest = ex.slice(p[0].length);
  const c = DEX_CHAINS.find(([id]) => rest.endsWith(id));
  if (c) rest = rest.slice(0, -c[0].length);
  const variant = /^\d+$/.test(rest) ? `v${rest}` : DEX_VARIANTS[rest] ?? rest;
  return { title: p[1], sub: [variant, c && c[1]].filter(Boolean).join(" · ") };
}
const exName = ex => { const { title, sub } = exParts(ex); return sub ? `${title} ${sub}` : title; };

// ---- Range picker: preset chips over a Monday-first month calendar (used by the log's Date and the builder's Listed).
// Two clicks on days pick a custom range (either order); a preset shows as a range too. Days outside [min, max] are
// disabled, days in `busy` carry a dot. range() gives inclusive YYYY-MM-DD bounds, "" meaning open.
const isoDay = t => new Date(t).toISOString().slice(0, 10);
const fmtDay = d => new Date(d + "T00:00:00Z").toLocaleDateString("en-US", { month: "short", day: "numeric", timeZone: "UTC" });
function rangePicker(el, { name, presets, preset, from = "", to = "", onChange }) {
  const st = { preset, from, to }, b = { min: "", max: isoDay(Date.now()), busy: new Set() };
  let month = "";
  el.classList.add("rp");
  el.innerHTML = `<div class="seg presets" role="radiogroup" aria-label="Period">${presets.map(([v, l]) =>
      `<label><input type="radio" name="${name}" value="${v}"><span>${l}</span></label>`).join("")}</div>
    <div class="cal"><div class="cal-head"><button type="button" class="cal-nav" data-step="-1" aria-label="Previous month">‹</button>
      <span class="cal-month"></span><button type="button" class="cal-nav" data-step="1" aria-label="Next month">›</button></div>
      <div class="cal-grid"></div><div class="cal-foot"></div></div>`;
  const q = sel => el.querySelector(sel);
  const range = () => {
    if (st.preset === "custom") return [st.from, st.to || st.from];
    return [+st.preset ? isoDay(Date.now() - +st.preset * 86400000) : "", ""];
  };
  const shift = (m, n) => { const [y, mo] = m.split("-").map(Number); return new Date(Date.UTC(y, mo - 1 + n, 1)).toISOString().slice(0, 7); };
  function draw() {
    for (const i of el.querySelectorAll(`input[name=${name}]`)) i.checked = i.value === st.preset;
    if (!month) month = (st.preset === "custom" ? st.to || st.from : b.max).slice(0, 7);
    const [from, to] = range(), end = to || b.max, [y, m] = month.split("-").map(Number);
    q(".cal-month").textContent = new Date(Date.UTC(y, m - 1, 1)).toLocaleDateString("en-US", { month: "long", year: "numeric", timeZone: "UTC" });
    q('[data-step="-1"]').disabled = !!b.min && month <= b.min.slice(0, 7);
    q('[data-step="1"]').disabled = month >= b.max.slice(0, 7);
    const cells = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"].map(w => Object.assign(document.createElement("span"), { className: "wd", textContent: w }));
    const lead = (new Date(Date.UTC(y, m - 1, 1)).getUTCDay() + 6) % 7, days = new Date(Date.UTC(y, m, 0)).getUTCDate();
    for (let i = 0; i < lead; i++) cells.push(document.createElement("span"));
    for (let d = 1; d <= days; d++) {
      const day = `${month}-${String(d).padStart(2, "0")}`, btn = document.createElement("button");
      btn.type = "button"; btn.textContent = d; btn.dataset.date = day;
      btn.disabled = (!!b.min && day < b.min) || day > b.max;
      btn.classList.toggle("in", !btn.disabled && (from ? day >= from : true) && day <= end && (!!from || st.preset === "0"));
      btn.classList.toggle("start", !!from && day === from);
      btn.classList.toggle("end", (!!from || st.preset === "0") && day === end);
      btn.classList.toggle("today", day === b.max);
      btn.classList.toggle("has", b.busy.has(day));
      cells.push(btn);
    }
    q(".cal-grid").replaceChildren(...cells);
    q(".cal-foot").textContent = st.preset === "custom" && !st.to ? `${fmtDay(st.from)} · pick the end date`
      : from ? (from === end ? fmtDay(from) : `${fmtDay(from)} – ${fmtDay(end)}`) : "All dates";
  }
  el.addEventListener("change", e => {
    if (e.target.name !== name) return;
    st.preset = e.target.value; month = ""; draw(); onChange?.();
  });
  q(".cal-head").addEventListener("click", e => {
    const step = +e.target.dataset?.step;
    if (step && !e.target.disabled) { month = shift(month, step); draw(); }
  });
  q(".cal-grid").addEventListener("click", e => {
    const day = e.target.dataset?.date;
    if (!day || e.target.disabled) return;
    if (st.preset !== "custom" || st.to) { st.from = day; st.to = ""; }   // first click starts a range
    else if (day < st.from) { st.to = st.from; st.from = day; }           // second click ends it, either direction
    else st.to = day;
    st.preset = "custom"; draw(); onChange?.();
  });
  return {
    range, draw,
    state: () => ({ ...st }),
    set(s) { if (s && presets.some(([v]) => v === s.preset) || s?.preset === "custom" && s.from) Object.assign(st, s); month = ""; draw(); },
    bounds(min, max, busy) { b.min = min || ""; b.max = max || b.max; b.busy = busy || b.busy; month = ""; draw(); },
    label() { // short: "Oct 15", "Oct 15–20", "Sep 28 – Oct 3", "≤ 7d"
      const [f, t] = range();
      if (!f) return "";
      if (st.preset !== "custom") return `≤ ${st.preset}d`;
      if (f === t) return fmtDay(f);
      return f.slice(0, 7) === t.slice(0, 7) ? `${fmtDay(f)}–${+t.slice(8)}` : `${fmtDay(f)} – ${fmtDay(t)}`;
    },
  };
}
