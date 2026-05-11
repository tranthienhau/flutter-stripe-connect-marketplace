import 'package:flutter/foundation.dart';

/// Possible states of a Stripe Connect Express account.
///
/// These mirror the `requirements` signals Stripe returns on the
/// `account.updated` webhook. We derive a simplified enum for UI.
enum ConnectAccountStatus {
  /// Account created but onboarding not started yet.
  created,

  /// Onboarding started but outstanding requirements remain (ID, bank, etc.).
  pending,

  /// Fully onboarded - charges and payouts enabled.
  verified,

  /// Stripe rejected the account or disabled payouts.
  rejected,
}

extension ConnectAccountStatusX on ConnectAccountStatus {
  String get label {
    switch (this) {
      case ConnectAccountStatus.created:
        return 'Not started';
      case ConnectAccountStatus.pending:
        return 'Pending verification';
      case ConnectAccountStatus.verified:
        return 'Verified';
      case ConnectAccountStatus.rejected:
        return 'Rejected';
    }
  }
}

@immutable
class ServiceProvider {
  const ServiceProvider({
    required this.id,
    required this.name,
    required this.tagline,
    required this.avatarColor,
    required this.stripeAccountId,
    required this.status,
    required this.services,
    required this.rating,
    required this.reviewCount,
  });

  final String id;
  final String name;
  final String tagline;
  final int avatarColor;
  final String stripeAccountId; // acct_xxx in Stripe
  final ConnectAccountStatus status;
  final List<Service> services;
  final double rating;
  final int reviewCount;

  ServiceProvider copyWith({
    ConnectAccountStatus? status,
    String? stripeAccountId,
  }) {
    return ServiceProvider(
      id: id,
      name: name,
      tagline: tagline,
      avatarColor: avatarColor,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      status: status ?? this.status,
      services: services,
      rating: rating,
      reviewCount: reviewCount,
    );
  }
}

@immutable
class Service {
  const Service({
    required this.id,
    required this.title,
    required this.description,
    required this.priceCents,
    required this.durationMinutes,
  });

  final String id;
  final String title;
  final String description;
  final int priceCents;
  final int durationMinutes;
}

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.providerId,
    required this.serviceTitle,
    required this.grossCents,
    required this.platformFeeCents,
    required this.netCents,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String providerId;
  final String serviceTitle;
  final int grossCents;
  final int platformFeeCents;
  final int netCents;
  final DateTime createdAt;
  final String status; // succeeded | pending | refunded
}

@immutable
class PayoutSummary {
  const PayoutSummary({
    required this.availableCents,
    required this.pendingCents,
    required this.nextPayoutDate,
  });

  final int availableCents;
  final int pendingCents;
  final DateTime nextPayoutDate;
}
