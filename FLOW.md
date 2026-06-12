# Screenshot capture flow

Real captures from the iOS Simulator via an integration-test driver (no mockups).

## Steps

1. Boot the simulator:
   ```bash
   xcrun simctl boot "iPhone 17"
   open -a Simulator
   ```
2. Scaffold the iOS platform folder (lib-only project) and get dependencies:
   ```bash
   flutter create . --platforms=ios --project-name flutter_stripe_connect_marketplace
   flutter pub get
   ```
3. Drive the screenshot test:
   ```bash
   flutter drive \
     --driver test_driver/integration_test.dart \
     --target integration_test/screenshot_test.dart \
     -d "iPhone 17"
   ```
4. Build the demo GIF from the PNGs:
   ```bash
   cd screenshots
   ffmpeg -y -framerate 1 -pattern_type glob -i '*.png' \
     -vf "scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
     -loop 0 demo.gif
   ```

PNGs + `demo.gif` are written to `screenshots/` and embedded in `README.md`.

## How it works

- `test_driver/integration_test.dart` - `integrationDriver(onScreenshot:)` writes each PNG to `screenshots/<name>.png`.
- `integration_test/screenshot_test.dart` - pumps `MarketplaceApp` (seeded with mock Stripe Connect providers, services, and payout data), then walks the core flow:
  1. `01-marketplace` - the provider list with Connect onboarding statuses.
  2. Taps the first provider card to open the detail view -> `02-provider-detail`.
  3. Taps `Negotiate & book` to enter the price negotiation engine -> `03-negotiation`.
  4. Taps `Counter -8%` to fire a counter offer -> `04-counter-offer`. The negotiation screen runs a live countdown timer, so this step uses fixed `pump(Duration)` calls instead of `pumpAndSettle` (which would hang on the infinite animation).
  5. Pops back to the home screen via the AppBar back buttons and taps `Provider payout dashboard` -> `05-payout-dashboard` (available balance, platform fees, transactions).
- Each shot calls `binding.convertFlutterSurfaceToImage()` + `binding.takeScreenshot('NN-name')`.
