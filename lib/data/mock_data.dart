import '../models/models.dart';

/// Seeded mock data so the POC renders without a real Stripe backend.
class MockData {
  static List<ServiceProvider> seedProviders() {
    return [
      ServiceProvider(
        id: 'prov_001',
        name: 'Nova Studio',
        tagline: 'Brand design & visual identity',
        avatarColor: 0xFF635BFF,
        stripeAccountId: 'acct_1NovaStudioExample',
        status: ConnectAccountStatus.verified,
        rating: 4.9,
        reviewCount: 128,
        services: const [
          Service(
            id: 'svc_nova_1',
            title: 'Logo design sprint',
            description: '3-day sprint delivering logo concepts, type exploration, and brand marks.',
            priceCents: 45000,
            durationMinutes: 4320,
          ),
          Service(
            id: 'svc_nova_2',
            title: 'Brand identity package',
            description: 'Full identity system: logo, palette, type, guidelines PDF.',
            priceCents: 120000,
            durationMinutes: 20160,
          ),
        ],
      ),
      ServiceProvider(
        id: 'prov_002',
        name: 'Kai Fitness',
        tagline: 'Certified strength coach, in-person & remote',
        avatarColor: 0xFF0DB67B,
        stripeAccountId: 'acct_1KaiFitnessExample',
        status: ConnectAccountStatus.verified,
        rating: 4.8,
        reviewCount: 72,
        services: const [
          Service(
            id: 'svc_kai_1',
            title: '1:1 strength coaching (60m)',
            description: 'Virtual session with tailored program, recorded for playback.',
            priceCents: 8500,
            durationMinutes: 60,
          ),
          Service(
            id: 'svc_kai_2',
            title: '4-week remote program',
            description: 'Custom 4-week plan, weekly video reviews, messaging support.',
            priceCents: 24000,
            durationMinutes: 40320,
          ),
        ],
      ),
      ServiceProvider(
        id: 'prov_003',
        name: 'Atlas Legal',
        tagline: 'Startup contracts & advisory',
        avatarColor: 0xFFF59E0B,
        stripeAccountId: 'acct_1AtlasLegalExample',
        status: ConnectAccountStatus.pending,
        rating: 4.7,
        reviewCount: 34,
        services: const [
          Service(
            id: 'svc_atlas_1',
            title: 'Founder consultation',
            description: '30-minute advisory call, follow-up notes and action items.',
            priceCents: 15000,
            durationMinutes: 30,
          ),
        ],
      ),
      ServiceProvider(
        id: 'prov_004',
        name: 'Lumen Photo',
        tagline: 'Product & lifestyle photography',
        avatarColor: 0xFFEF4444,
        stripeAccountId: 'acct_1LumenPhotoExample',
        status: ConnectAccountStatus.created,
        rating: 0,
        reviewCount: 0,
        services: const [
          Service(
            id: 'svc_lumen_1',
            title: 'Product photo set (10 images)',
            description: 'Studio session delivering 10 edited product images.',
            priceCents: 30000,
            durationMinutes: 240,
          ),
        ],
      ),
    ];
  }

  /// Transactions for the provider dashboard (mocked platform-fee splits).
  static List<Transaction> seedTransactions(String providerId) {
    final now = DateTime.now();
    return [
      Transaction(
        id: 'pi_001',
        providerId: providerId,
        serviceTitle: 'Logo design sprint',
        grossCents: 45000,
        platformFeeCents: 4500,
        netCents: 40500,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        status: 'succeeded',
      ),
      Transaction(
        id: 'pi_002',
        providerId: providerId,
        serviceTitle: 'Brand identity package',
        grossCents: 120000,
        platformFeeCents: 12000,
        netCents: 108000,
        createdAt: now.subtract(const Duration(days: 3, hours: 8)),
        status: 'succeeded',
      ),
      Transaction(
        id: 'pi_003',
        providerId: providerId,
        serviceTitle: 'Logo design sprint',
        grossCents: 45000,
        platformFeeCents: 4500,
        netCents: 40500,
        createdAt: now.subtract(const Duration(days: 6)),
        status: 'pending',
      ),
    ];
  }

  static PayoutSummary seedPayoutSummary() {
    return PayoutSummary(
      availableCents: 148500,
      pendingCents: 40500,
      nextPayoutDate: DateTime.now().add(const Duration(days: 2)),
    );
  }
}
