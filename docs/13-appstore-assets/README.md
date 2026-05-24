# App Store Assets

This folder follows the fixed-canvas workflow used in `takken_ai_2026/docs/13-appstore-assets`.

- `appstore-*.html`: iPhone 6.9-inch canvases, exported at `1290x2796`.
- `appstore-ipad-*.html`: iPad 13-inch canvases, exported at `2048x2732`.
- `capture.mjs`: Playwright renderer that opens each HTML file and saves a matching PNG.

Current product message:

- No subscription.
- Launch offer: `¥3.8/张`; regular target: `¥9.9/张`.
- One purchase grants 3 AI generation attempts.
- User chooses the best result, then downloads HD photo and print layout.

Run:

```bash
npm install --save-dev @playwright/test
node docs/13-appstore-assets/capture.mjs
```

The visual copy is intentionally modular so real screenshots can replace the placeholder phone UI after the final App Store screenshot direction is decided.
