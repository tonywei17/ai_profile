/**
 * Render App Store screenshot canvases to PNG.
 *
 * Usage:
 *   npm install --save-dev @playwright/test
 *   node docs/13-appstore-assets/capture.mjs
 *   node docs/13-appstore-assets/capture.mjs --file appstore-01.html
 */
import { chromium } from "@playwright/test";
import { dirname, join } from "path";
import { readdirSync } from "fs";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const fileFlag = process.argv.indexOf("--file");
const targets =
  fileFlag !== -1
    ? [process.argv[fileFlag + 1]]
    : readdirSync(__dirname).filter((file) =>
        /^appstore(-ipad)?-\d+\.html$/.test(file)
      );

const IPHONE_69 = { w: 1290, h: 2796 };
const IPAD_13 = { w: 2048, h: 2732 };

function sizeFor(file) {
  return file.includes("ipad") ? IPAD_13 : IPHONE_69;
}

const browser = await chromium.launch();

for (const file of targets) {
  const { w, h } = sizeFor(file);
  const context = await browser.newContext({
    viewport: { width: w, height: h },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();
  const htmlPath = join(__dirname, file);
  const outPath = join(__dirname, file.replace(".html", ".png"));

  await page.goto(`file://${htmlPath}`, { waitUntil: "networkidle" });
  await page.waitForTimeout(800);
  await page.evaluate(({ w, h }) => {
    const stage = document.querySelector(".stage");
    if (stage) {
      stage.style.transform = "none";
      stage.style.transformOrigin = "top left";
    }
    document.body.style.width = `${w}px`;
    document.body.style.height = `${h}px`;
    document.body.style.margin = "0";
    document.body.style.overflow = "hidden";
  }, { w, h });

  await page.screenshot({
    path: outPath,
    clip: { x: 0, y: 0, width: w, height: h },
  });

  console.log(`saved ${outPath} (${w}x${h})`);
  await page.close();
  await context.close();
}

await browser.close();
