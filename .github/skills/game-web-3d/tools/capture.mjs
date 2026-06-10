#!/usr/bin/env node
// Capture a screenshot + FPS/draw-call sample + WebGL context-loss + console errors
// from a running 3D web game (Babylon.js or any WebGL/WebGPU app).
//
// Optional helper — requires Playwright:  npm i -D playwright
// (For zero-install capture, use the chrome-devtools skill instead.)
//
// The game should expose `window.__debug = { booted, fps, activeMeshes, drawCalls,
// contextLost }` (see references/templates.md). If absent, the script still captures a
// screenshot + console/page errors and falls back to waiting for a <canvas>.
//
// GPU CAVEAT: headless browsers often use software WebGL (SwiftShader) — FPS/timings are
// then NOT representative. Use --headed (or a GPU CI runner) for meaningful perf numbers.
//
// Usage:
//   node capture.mjs --url http://localhost:5173 --out shot.png --seconds 5 --headed
//   node capture.mjs --url http://localhost:5173 --json
//
// Flags:
//   --url <url>        Game URL (default http://localhost:5173)
//   --out <path>       Screenshot path (default screenshot.png)
//   --seconds <n>      FPS sampling duration (default 5)
//   --target-fps <n>   FPS target for pass/fail (default 60; ignored unless --gpu/--headed)
//   --selector <css>   Element to wait for (default "canvas")
//   --json             Emit JSON result
//   --headed           Run with a visible browser + GPU (recommended for perf)

function parseArgs(argv) {
  const a = { url: "http://localhost:5173", out: "screenshot.png", seconds: 5,
              targetFps: 60, selector: "canvas", json: false, headed: false };
  for (let i = 0; i < argv.length; i++) {
    const f = argv[i];
    if (f === "--url") a.url = argv[++i];
    else if (f === "--out") a.out = argv[++i];
    else if (f === "--seconds") a.seconds = Number(argv[++i]);
    else if (f === "--target-fps") a.targetFps = Number(argv[++i]);
    else if (f === "--selector") a.selector = argv[++i];
    else if (f === "--json") a.json = true;
    else if (f === "--headed") a.headed = true;
    else if (f === "-h" || f === "--help") { printHelp(); process.exit(0); }
  }
  return a;
}

function printHelp() {
  console.log("Usage: node capture.mjs --url <url> --out <png> --seconds <n> [--headed] [--json]");
  console.log("Requires Playwright: npm i -D playwright");
}

function stats(values) {
  if (values.length === 0) return null;
  const s = [...values].sort((x, y) => x - y);
  const at = (p) => s[Math.min(s.length - 1, Math.max(0, Math.round((p / 100) * s.length) - 1))];
  const mean = s.reduce((x, y) => x + y, 0) / s.length;
  return { samples: s.length, min: s[0], p5: at(5), median: at(50), max: s[s.length - 1],
           mean: Math.round(mean * 10) / 10 };
}

function emit(result, asJson) {
  if (asJson) { console.log(JSON.stringify(result, null, 2)); return; }
  const status = result.ok ? "PASS" : "FAIL";
  console.log(`[${status}] capture — ${result.reason ?? ""}`);
  if (result.screenshot) console.log(`  screenshot: ${result.screenshot}`);
  if (result.gpu === false) console.log("  GPU: software/headless — FPS not representative");
  if (result.fps) {
    const f = result.fps;
    console.log(`  fps: median ${f.median}  p5 ${f.p5}  min ${f.min}  (${f.samples} samples)`);
  }
  if (typeof result.drawCalls === "number") console.log(`  drawCalls: ${result.drawCalls}`);
  if (typeof result.activeMeshes === "number") console.log(`  activeMeshes: ${result.activeMeshes}`);
  if (result.contextLost) console.log("  ! WebGL context was lost during capture");
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

  // Request hardware GPU when headed; headless commonly falls back to software WebGL.
  const browser = await chromium.launch({
    headless: !args.headed,
    args: args.headed ? [] : ["--use-gl=angle", "--enable-unsafe-swiftshader"],
  });
  const page = await browser.newPage();
  const consoleErrors = [];
  page.on("console", (m) => { if (m.type() === "error") consoleErrors.push(m.text()); });
  page.on("pageerror", (e) => consoleErrors.push(String(e)));

  let ok = true;
  let reason = "captured";
  try {
    await page.goto(args.url, { waitUntil: "load", timeout: 20000 });
    try {
      await page.waitForFunction(() => window.__debug?.booted === true, null, { timeout: 12000 });
    } catch {
      await page.waitForSelector(args.selector, { timeout: 12000 });
    }

    // Detect whether a real GPU is in use (best-effort).
    const gpu = await page.evaluate(() => {
      try {
        const c = document.createElement("canvas");
        const gl = c.getContext("webgl2") || c.getContext("webgl");
        if (!gl) return null;
        const dbg = gl.getExtension("WEBGL_debug_renderer_info");
        const r = dbg ? gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL) : "";
        return /swiftshader|software|llvmpipe/i.test(String(r)) ? false : true;
      } catch { return null; }
    });

    const fpsSamples = [];
    let drawCalls, activeMeshes, contextLost = false;
    const iterations = Math.max(1, Math.round(args.seconds * 10));
    for (let i = 0; i < iterations; i++) {
      const d = await page.evaluate(() => window.__debug ?? null);
      if (d) {
        if (typeof d.fps === "number") fpsSamples.push(d.fps);
        drawCalls = d.drawCalls; activeMeshes = d.activeMeshes;
        if (d.contextLost) contextLost = true;
      }
      await page.waitForTimeout(100);
    }

    await page.screenshot({ path: args.out });

    const fps = stats(fpsSamples);
    if (consoleErrors.length > 0) { ok = false; reason = `${consoleErrors.length} console error(s)`; }
    else if (contextLost) { ok = false; reason = "WebGL context lost"; }
    else if (gpu === true && fps && fps.p5 < args.targetFps) { ok = false; reason = `p5 FPS ${fps.p5} below ${args.targetFps} target`; }
    else if (gpu === false) { reason = "captured (software WebGL — FPS not representative)"; }

    emit({ ok, reason, url: args.url, screenshot: args.out, gpu, fps, drawCalls, activeMeshes, contextLost, consoleErrors },
         args.json);
  } catch (err) {
    emit({ ok: false, reason: `capture failed: ${err.message}`, url: args.url, consoleErrors }, args.json);
    ok = false;
  } finally {
    await browser.close();
  }
  process.exit(ok ? 0 : 1);
}

main();
