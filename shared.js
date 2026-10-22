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
