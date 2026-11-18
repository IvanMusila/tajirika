import 'package:flutter/foundation.dart';

/// A parsed M-Pesa SMS message, ready to send to POST /transactions/sync
class ParsedMpesaSms {
  final String receiptNo;
  final DateTime timestamp;
  final String merchantName;
  final String merchantId;
  final String transactionType;
  final double amount;
  final double balanceAfter;
  final bool isDebit;
  final String details;

  const ParsedMpesaSms({
    required this.receiptNo,
    required this.timestamp,
    required this.merchantName,
    required this.merchantId,
    required this.transactionType,
    required this.amount,
    required this.balanceAfter,
    required this.isDebit,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'receipt_no':       receiptNo,
        'timestamp':        timestamp.toIso8601String(),
        'merchant_name':    merchantName,
        'merchant_id':      merchantId,
        'transaction_type': transactionType,
        'amount':           amount,
        'balance_after':    balanceAfter,
        'is_debit':         isDebit,
        'details':          details,
      };
}

/// Pure Dart M-Pesa SMS parser.
/// Patterns confirmed from real Safaricom SMS samples (Nov 2026).
class MpesaSmsParser {
  MpesaSmsParser._();

  // ── Helpers ──────────────────────────────────────────────────────────

  static double _parseAmount(String s) {
    final cleaned = s.replaceAll(',', '').replaceAll('Ksh', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Parse "12/11/26" (DD/MM/YY) + "6:14 PM" → DateTime
  static DateTime _parseDateTime(String datePart, String timePart) {
    try {
      final dp = datePart.split('/');
      final day   = int.parse(dp[0]);
      final month = int.parse(dp[1]);
      final year  = 2000 + int.parse(dp[2]);

      final timeClean = timePart.trim().toUpperCase();
      final isPm = timeClean.contains('PM');
      final timeOnly = timeClean.replaceAll('AM', '').replaceAll('PM', '').trim();
      final tp = timeOnly.split(':');
      var hour   = int.parse(tp[0]);
      final min  = int.parse(tp[1]);
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, min);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Extract "on DD/MM/YY at H:MM AM/PM" from an SMS body.
  static DateTime _extractTimestamp(String body) {
    final m = RegExp(
      r'on (\d{1,2}/\d{1,2}/\d{2}) at (\d{1,2}:\d{2}\s*[APap][Mm])',
    ).firstMatch(body);
    if (m != null) {
      return _parseDateTime(m.group(1)!, m.group(2)!);
    }
    return DateTime.now();
  }

  /// Extract "New M-PESA balance is Ksh664.05"
  static double _extractBalance(String body) {
    final m = RegExp(
      r'New M-PESA balance is Ksh([\d,]+\.?\d*)',
    ).firstMatch(body);
    return m != null ? _parseAmount(m.group(1)!) : 0.0;
  }

  /// Extract the receipt number (first word before "Confirmed")
  static String _extractReceipt(String body) {
    final m = RegExp(r'^([A-Z0-9]+)\s+Confirmed', multiLine: true).firstMatch(body);
    return m?.group(1) ?? 'UNKNOWN${DateTime.now().millisecondsSinceEpoch}';
  }

  // ── Main parser ───────────────────────────────────────────────────────

  /// Returns null if the SMS is not an M-Pesa transaction message.
  static ParsedMpesaSms? parse(String body) {
    if (!body.contains('Confirmed') || !body.contains('M-PESA')) return null;

    final receiptNo = _extractReceipt(body);
    final timestamp = _extractTimestamp(body);
    final balance   = _extractBalance(body);

    // ── Receive money ────────────────────────────────────────────────────
    // "You have received Ksh1,795.00 from ROSE  MUSILA 0718***994 on"
    var m = RegExp(
      r'You have received Ksh([\d,]+\.?\d*) from (.+?) ([\d\*]+) on',
    ).firstMatch(body);
    if (m != null) {
      return ParsedMpesaSms(
        receiptNo:       receiptNo,
        timestamp:       timestamp,
        merchantName:    m.group(2)!.trim().split(RegExp(r'\s+')).take(3).join(' '),
        merchantId:      m.group(3)!.trim(),
        transactionType: 'receive_money',
        amount:          _parseAmount(m.group(1)!),
        balanceAfter:    balance,
        isDebit:         false,
        details:         body.substring(0, body.length.clamp(0, 80)),
      );
    }

    // Also handle: "You have received Ksh... from NAME TILL on" (business pay)
    m = RegExp(
      r'received Ksh([\d,]+\.?\d*) from (.+?) (\d{6,}) on',
    ).firstMatch(body);
    if (m != null) {
      return ParsedMpesaSms(
        receiptNo:       receiptNo,
        timestamp:       timestamp,
        merchantName:    m.group(2)!.trim(),
        merchantId:      m.group(3)!.trim(),
        transactionType: 'receive_money',
        amount:          _parseAmount(m.group(1)!),
        balanceAfter:    balance,
        isDebit:         false,
        details:         body.substring(0, body.length.clamp(0, 80)),
      );
    }

    // ── Buy goods (till payment) ─────────────────────────────────────────
    // "Ksh106.00 paid to NAIVAS LANG'ATA. on"
    m = RegExp(
      r'Ksh([\d,]+\.?\d*) paid to (.+?)\. on',
    ).firstMatch(body);
    if (m != null) {
      final merchantName = m.group(2)!.trim();
      return ParsedMpesaSms(
        receiptNo:       receiptNo,
        timestamp:       timestamp,
        merchantName:    merchantName,
        merchantId:      '',
        transactionType: 'buy_goods',
        amount:          _parseAmount(m.group(1)!),
        balanceAfter:    balance,
        isDebit:         true,
        details:         body.substring(0, body.length.clamp(0, 80)),
      );
    }

    // ── Savings deposit (Ziidi / M-Shwari) ──────────────────────────────
    // "Ksh3,900.00 sent to ZIIDI on"
    m = RegExp(r'Ksh([\d,]+\.?\d*) sent to (ZIIDI|M-Shwari) on').firstMatch(body);
    if (m != null) {
      return ParsedMpesaSms(
        receiptNo:       receiptNo,
        timestamp:       timestamp,
        merchantName:    m.group(2)!,
        merchantId:      m.group(2) == 'ZIIDI' ? '4145555' : 'mshwari',
        transactionType: 'savings_deposit',
        amount:          _parseAmount(m.group(1)!),
        balanceAfter:    balance,
        isDebit:         true,
        details:         body.substring(0, body.length.clamp(0, 80)),
      );
    }

    // ── Data bundles ─────────────────────────────────────────────────────
    // "Ksh20.00 sent to SAFARICOM DATA BUNDLES for account"
    m = RegExp(
      r'Ksh([\d,]+\.?\d*) sent to (SAFARICOM DATA BUNDLES|M-PESA CARD)',
    ).firstMatch(body);
    if (m != null) {
      final isMpesaCard = m.group(2)!.contains('CARD');
      return ParsedMpesaSms(
        receiptNo:       receiptNo,
        timestamp:       timestamp,
        merchantName:    m.group(2)!,
        merchantId:      isMpesaCard ? '903470' : '4093441',
        transactionType: isMpesaCard ? 'paybill' : 'data_bundle',
        amount:          _parseAmount(m.group(1)!),
        balanceAfter:    balance,
        isDebit:         true,
        details:         body.substring(0, body.length.clamp(0, 80)),
      );
    }

    // ── Paybill ──────────────────────────────────────────────────────────
    // "Ksh150.00 sent to Parklands Sports Club Subs for account M2626 on"
    // "Ksh200.00 sent to SPRINGREEN STIMA ACCOUNT for account 47001242420 on"
    m = RegExp(
      r'Ksh([\d,]+\.?\d*) sent to (.+?) for account (.+?) on',
    ).firstMatch(body);
    if (m != null) {
      return ParsedMpesaSms(
        receiptNo:       receiptNo,
        timestamp:       timestamp,
        merchantName:    m.group(2)!.trim(),
        merchantId:      m.group(3)!.trim(),
        transactionType: 'paybill',
        amount:          _parseAmount(m.group(1)!),
        balanceAfter:    balance,
        isDebit:         true,
        details:         body.substring(0, body.length.clamp(0, 80)),
      );
    }

    // ── Send money (person to person) ────────────────────────────────────
    // "Ksh170.00 sent to grace  amoi 0717542074 on"
    m = RegExp(
      r'Ksh([\d,]+\.?\d*) sent to (.+?) ([\d\*]{6,}) on',
    ).firstMatch(body);
    if (m != null) {
      return ParsedMpesaSms(
        receiptNo:       receiptNo,
        timestamp:       timestamp,
        merchantName:    m.group(2)!.trim().split(RegExp(r'\s+')).take(3).join(' '),
        merchantId:      m.group(3)!.trim(),
        transactionType: 'send_money',
        amount:          _parseAmount(m.group(1)!),
        balanceAfter:    balance,
        isDebit:         true,
        details:         body.substring(0, body.length.clamp(0, 80)),
      );
    }

    debugPrint('[SMS] Could not parse: ${body.substring(0, body.length.clamp(0, 60))}');
    return null;
  }

  /// Parse a list of SMS bodies and return successfully parsed ones.
  static List<ParsedMpesaSms> parseAll(List<String> bodies) {
    final results = <ParsedMpesaSms>[];
    for (final body in bodies) {
      final parsed = parse(body);
      if (parsed != null) results.add(parsed);
    }
    debugPrint('[SMS] Parsed ${results.length}/${bodies.length} messages');
    return results;
  }
}