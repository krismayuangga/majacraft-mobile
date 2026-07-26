import 'package:flutter/material.dart';

class Balance {
  final double grossRevenue;
  final double shippingTotal;
  final double feePercent;
  final double feeAmount;
  final double netRevenue;
  final double totalWithdrawn;
  final double availableBalance;
  final List<Withdrawal> withdrawals;

  Balance({
    required this.grossRevenue,
    required this.shippingTotal,
    required this.feePercent,
    required this.feeAmount,
    required this.netRevenue,
    required this.totalWithdrawn,
    required this.availableBalance,
    required this.withdrawals,
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      grossRevenue: (json['grossRevenue'] as num?)?.toDouble() ?? 0.0,
      shippingTotal: (json['shippingTotal'] as num?)?.toDouble() ?? 0.0,
      feePercent: (json['feePercent'] as num?)?.toDouble() ?? 0.0,
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 0.0,
      netRevenue: (json['netRevenue'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0.0,
      withdrawals:
          (json['withdrawals'] as List<dynamic>?)
              ?.map((w) => Withdrawal.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Withdrawal {
  final String id;
  final double amount;
  final double fee;
  final double netAmount;
  final String status;
  final String bankName;
  final String bankAccount;
  final String bankHolder;
  final DateTime createdAt;

  Withdrawal({
    required this.id,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.status,
    required this.bankName,
    required this.bankAccount,
    required this.bankHolder,
    required this.createdAt,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['netAmount'] as num).toDouble(),
      status: json['status'] as String,
      bankName: json['bankName'] as String,
      bankAccount: json['bankAccount'] as String,
      bankHolder: json['bankHolder'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Helper untuk badge status
  String get statusText {
    switch (status) {
      case 'PENDING':
        return 'Menunggu';
      case 'APPROVED':
        return 'Disetujui';
      case 'REJECTED':
        return 'Ditolak';
      case 'TRANSFERRED':
        return 'Ditransfer';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFF59E0B); // amber-500
      case 'APPROVED':
        return const Color(0xFF10B981); // green-500
      case 'REJECTED':
        return const Color(0xFFEF4444); // red-500
      case 'TRANSFERRED':
        return const Color(0xFF3B82F6); // blue-500
      default:
        return const Color(0xFF6B7280); // gray-500
    }
  }
}
