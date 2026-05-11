import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'data/mock_data.dart';
import 'models/models.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MarketplaceApp()));
}

class MarketplaceApp extends ConsumerWidget {
  const MarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Stripe Connect Marketplace',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

final providersProvider =
    Provider<List<ServiceProvider>>((ref) => MockData.seedProviders());

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(providersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => _ProviderCard(provider: providers[i]),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: providers.length,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PayoutDashboard()),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Provider payout dashboard'),
          ),
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});
  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProviderDetail(provider: provider)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(provider.avatarColor),
                child: Text(
                  provider.name[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(provider.tagline,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusChip(status: provider.status),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(provider.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ConnectAccountStatus status;

  Color _bg() {
    switch (status) {
      case ConnectAccountStatus.verified:
        return const Color(0xFF0DB67B);
      case ConnectAccountStatus.pending:
        return const Color(0xFFF59E0B);
      case ConnectAccountStatus.rejected:
        return const Color(0xFFEF4444);
      case ConnectAccountStatus.created:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _bg().withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: _bg(), fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class ProviderDetail extends StatelessWidget {
  const ProviderDetail({super.key, required this.provider});
  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(provider.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(provider.tagline, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          for (final s in provider.services) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(s.description,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          NumberFormat.simpleCurrency().format(s.priceCents / 100),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NegotiationScreen(
                                  provider: provider, service: s),
                            ),
                          ),
                          child: const Text('Negotiate & book'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Price negotiation engine. Customer counters, provider responds. Max 2 rounds.
class NegotiationScreen extends StatefulWidget {
  const NegotiationScreen({super.key, required this.provider, required this.service});
  final ServiceProvider provider;
  final Service service;

  @override
  State<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends State<NegotiationScreen> {
  late int currentCents = widget.service.priceCents;
  int round = 0;
  final List<_Offer> history = [];
  bool resolved = false;
  bool accepted = false;
  Timer? expiry;
  int remainingSeconds = 30;

  @override
  void initState() {
    super.initState();
    history.add(_Offer(by: 'provider', cents: widget.service.priceCents));
  }

  void _startExpiry() {
    expiry?.cancel();
    remainingSeconds = 30;
    expiry = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => remainingSeconds--);
      if (remainingSeconds <= 0) {
        t.cancel();
        setState(() {
          resolved = true;
          accepted = false;
        });
      }
    });
  }

  void _counter(int cents) {
    if (round >= 2 || resolved) return;
    setState(() {
      history.add(_Offer(by: 'customer', cents: cents));
      currentCents = cents;
      round++;
    });
    _startExpiry();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      expiry?.cancel();
      final providerAccept = cents >= (widget.service.priceCents * 0.85).round();
      if (providerAccept) {
        setState(() {
          history.add(_Offer(by: 'provider', cents: cents, accepted: true));
          resolved = true;
          accepted = true;
        });
      } else if (round < 2) {
        final counter = ((cents + widget.service.priceCents) / 2).round();
        setState(() {
          history.add(_Offer(by: 'provider', cents: counter));
          currentCents = counter;
        });
      } else {
        setState(() {
          resolved = true;
          accepted = false;
        });
      }
    });
  }

  @override
  void dispose() {
    expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price negotiation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.service.title,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('with ${widget.provider.name}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('Round $round / 2 · ${resolved ? "Closed" : "Open"}',
                style: Theme.of(context).textTheme.bodySmall),
            if (expiry?.isActive ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Offer expires in ${remainingSeconds}s',
                    style: const TextStyle(color: Color(0xFFF59E0B))),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (_, i) => _OfferBubble(offer: history[i]),
              ),
            ),
            if (resolved)
              FilledButton(
                onPressed: accepted
                    ? () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CheckoutScreen(
                            provider: widget.provider,
                            service: widget.service,
                            agreedCents: currentCents)))
                    : null,
                child: Text(
                    accepted ? 'Checkout at \$${(currentCents / 100).toStringAsFixed(2)}' : 'Negotiation closed'),
              )
            else if (round < 2)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _counter((currentCents * 0.85).round()),
                      child: const Text('Counter -15%'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _counter((currentCents * 0.92).round()),
                      child: const Text('Counter -8%'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          history.add(_Offer(
                              by: 'customer',
                              cents: currentCents,
                              accepted: true));
                          resolved = true;
                          accepted = true;
                        });
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              )
            else
              const Text('Negotiation rounds exhausted.'),
          ],
        ),
      ),
    );
  }
}

class _Offer {
  _Offer({required this.by, required this.cents, this.accepted = false});
  final String by;
  final int cents;
  final bool accepted;
}

class _OfferBubble extends StatelessWidget {
  const _OfferBubble({required this.offer});
  final _Offer offer;

  @override
  Widget build(BuildContext context) {
    final isCustomer = offer.by == 'customer';
    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCustomer
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${offer.by[0].toUpperCase()}${offer.by.substring(1)}: \$${(offer.cents / 100).toStringAsFixed(2)}${offer.accepted ? " ✓ accepted" : ""}',
          style: TextStyle(
            color: isCustomer ? Colors.white : null,
            fontWeight: offer.accepted ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({
    super.key,
    required this.provider,
    required this.service,
    required this.agreedCents,
  });

  final ServiceProvider provider;
  final Service service;
  final int agreedCents;

  @override
  Widget build(BuildContext context) {
    final platformFee = (agreedCents * 0.10).round();
    final providerNet = agreedCents - platformFee;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Service', service.title),
            _row('Provider', provider.name),
            _row('Connect account', provider.stripeAccountId),
            const Divider(height: 32),
            _row('Agreed price', '\$${(agreedCents / 100).toStringAsFixed(2)}'),
            _row('Platform fee (10%)',
                '\$${(platformFee / 100).toStringAsFixed(2)}'),
            _row('Provider net (transfer)',
                '\$${(providerNet / 100).toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text(
              'PaymentIntent created with application_fee_amount and transfer_data[destination] = acct_xxx. Stripe routes platform fee to the platform balance and remainder to the connected account.',
              style: TextStyle(fontSize: 12),
            ),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.lock_outline),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PaymentIntent confirmed (mocked).')),
                );
              },
              label: const Text('Pay with card / Apple Pay / Google Pay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Flexible(child: Text(value, textAlign: TextAlign.right)),
          ],
        ),
      );
}

class PayoutDashboard extends StatelessWidget {
  const PayoutDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = MockData.seedPayoutSummary();
    final txns = MockData.seedTransactions('prov_001');
    final fmt = NumberFormat.simpleCurrency();
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings & payouts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available balance',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(fmt.format(summary.availableCents / 100),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                      'Pending ${fmt.format(summary.pendingCents / 100)} · Next payout ${DateFormat.MMMd().format(summary.nextPayoutDate)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Recent transactions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final t in txns)
            Card(
              child: ListTile(
                title: Text(t.serviceTitle),
                subtitle: Text(
                    '${DateFormat.MMMd().add_jm().format(t.createdAt)} · ${t.status}'),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(fmt.format(t.netCents / 100),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('fee ${fmt.format(t.platformFeeCents / 100)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
