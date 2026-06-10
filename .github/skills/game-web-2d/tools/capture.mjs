#!/usr/bin/env node
// Capture a screenshot + FPS sample + console/error log from a running web game.
//
// Optional helper — requires Playwright:  npm i -D playwright
// (For zero-install capture, use the chrome-devtools skill instead.)
//
// The game should expose `window.__debug = { booted, fps, ... }` (see
// references/templates.md). If it doesn't, the script still captures a screenshot
// and console errors, and falls back to waiting for a <canvas> element.
//
// Usage:
//   node capture.mjs --url http://localhost:5173 --out shot.png --seconds 5
//   node capture.mjs --url http://localhost:5173 --json
//
// Flags:
//   --url <url>        Game URL (default http://localhost:5173)
//   --out <path>       Screenshot path (default screenshot.png)
//   --seconds <n>      FPS sampling duration (default 5)
//   --target-fps <n>   FPS target for pass/fail (default 60)
//   --selector <css>   Element to wait for (default "canvas")
//   --json             Emit JSON result
//   --headed           Run with a visible browser (debug)

function parseArgs(argv) {
  const args = { url: "http://localhost:5173", out: "screenshot.png", seconds: 5,
                 targetFps: 60, selector: "canvas", json: false, headed: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--url") args.url = argv[++i];
    else if (a === "--out") args.out = argv[++i];
    else if (a === "--seconds") args.seconds = Number(argv[++i]);
    else if (a === "--target-fps") args.targetFps = Number(argv[++i]);
    else if (a === "--selector") args.selector = argv[++i];
    else if (a === "--json") args.json = true;
    else if (a === "--headed") args.headed = true;
    else if (a === "-h" || a === "--help") { printHelp(); process.exit(0); }
  }
  return args;
}

function printHelp() {
  console.log("Usage: node capture.mjs --url <url> --out <png> --seconds <n> [--json]");
  console.log("Requires Playwright: npm i -D playwright");
}

function stats(values) {
  if (values.length === 0) return null;
  const s = [...values].sort((a, b) => a - b);
  const at = (p) => s[Math.min(s.length - 1, Math.max(0, Math.round((p / 100) * s.length) - 1))];
  const mean = s.reduce((a, b) => a + b, 0) / s.length;
  return { samples: s.length, min: s[0], p5: at(5), median: at(50), max: s[s.length - 1],
           mean: Math.round(mean * 10) / 10 };
}

function emit(result, asJson) {
  if (asJson) { console.log(JSON.stringify(result, null, 2)); return; }
  const status = result.ok ? "PASS" : "FAIL";
  console.log(`[${status}] capture — ${result.reason ?? ""}`);
  if (result.screenshot) console.log(`  screenshot: ${result.screenshot}`);
  if (result.fps) {
    const f = result.fps;
    console.log(`  fps: median ${f.median}  p5 ${f.p5}  min ${f.min}  (${f.samples} samples)`);
  }
  if (result.consoleErrors?.length) {
    console.log(`  console errors: ${result.consoleErrors.length}`);
    result.consoleErrors.slice(0, 10).forEach((e) => console.log(`    - ${e}`));
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  let chromium;
  try {
    ({ chromium } = await import("playwright"));
  } catch {
    emit({ ok: false, reason: "Playwright not installed. Run: npm i -D playwright (or use the chrome-devtools skill)." },
         args.json);
    process.exit(2);
  }

  const browser = await chromium.launch({ headless: !args.headed });
  const page = await browser.newPage();
  const consoleErrors = [];
  page.on("console", (m) => { if (m.type() === "error") consoleErrors.push(m.text()); });
  page.on("pageerror", (e) => consoleErrors.push(String(e)));

  let reason = "captured";
  let ok = true;
  try {
    await page.goto(args.url, { waitUntil: "load", timeout: 15000 });
    // Prefer the __debug.booted signal; fall back to the canvas element.
    try {
      await page.waitForFunction(() => window.__debug?.booted === true, null, { timeout: 8000 });
    } catch {
      await page.waitForSelector(args.selector, { timeout: 8000 });
    }

    const fpsSamples = [];
    const iterations = Math.max(1, Math.round(args.seconds * 10)); // 100ms cadence
    for (let i = 0; i < iterations; i++) {
      const fps = await page.evaluate(() => (window.__debug && window.__debug.fps) || null);
      if (typeof fps === "number") fpsSamples.push(fps);
      await page.waitForTimeout(100);
    }

    await page.screenshot({ path: args.out });

    const fps = stats(fpsSamples);
    if (consoleErrors.length > 0) { ok = false; reason = `${consoleErrors.length} console error(s)`; }
    else if (fps && fps.p5 < args.targetFps) { ok = false; reason = `p5 FPS ${fps.p5} below ${args.targetFps} target`; }

    emit({ ok, reason, url: args.url, screenshot: args.out, fps, consoleErrors }, args.json);
  } catch (err) {
    emit({ ok: false, reason: `capture failed: ${err.message}`, url: args.url, consoleErrors }, args.json);
    ok = false;
  } finally {
    await browser.close();
  }
  process.exit(ok ? 0 : 1);
}

main();
