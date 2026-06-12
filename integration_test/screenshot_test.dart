import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_stripe_connect_marketplace/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shoot(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  testWidgets('capture marketplace flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MarketplaceApp()));
    await tester.pumpAndSettle();

    // 01 - Marketplace provider list (Stripe Connect accounts + statuses).
    await shoot(tester, '01-marketplace');

    // Open the first provider's detail (services + prices).
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await shoot(tester, '02-provider-detail');

    // Enter the price negotiation engine for the first service.
    await tester.tap(find.text('Negotiate & book').first);
    await tester.pumpAndSettle();
    await shoot(tester, '03-negotiation');

    // Make a counter offer; negotiation screen has a live countdown timer,
    // so use fixed pumps instead of pumpAndSettle (infinite animation).
    await tester.tap(find.text('Counter -8%'));
    await tester.pump(const Duration(milliseconds: 400));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump(const Duration(milliseconds: 400));
    await binding.takeScreenshot('04-counter-offer');

    // Let the provider respond and resolve, then move to checkout/fees.
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Navigate back to the home screen via the AppBar back buttons.
    while (find.text('Provider payout dashboard').evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();
    }

    // 05 - Provider payout dashboard (balance, fees, transactions).
    await tester.tap(find.text('Provider payout dashboard'));
    await tester.pumpAndSettle();
    await shoot(tester, '05-payout-dashboard');
  });
}
