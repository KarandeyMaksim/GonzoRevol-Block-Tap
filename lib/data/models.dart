import 'dart:convert';

import '../core/constants.dart';

enum BetRisk { low, medium, high }

extension BetRiskX on BetRisk {
  String get label => switch (this) {
        BetRisk.low => 'Low',
        BetRisk.medium => 'Medium',
        BetRisk.high => 'High',
      };

  /// Multiplier range applied to a winning clear.
  (double min, double max) get multiplierRange => switch (this) {
        BetRisk.low => (1.2, 2.0),
        BetRisk.medium => (1.8, 3.5),
        BetRisk.high => (2.5, 6.0),
      };

  static BetRisk fromName(String name) =>
      BetRisk.values.firstWhere((e) => e.name == name, orElse: () => BetRisk.low);
}

class ShopPackage {
  const ShopPackage({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.coins,
    required this.freeSpins,
    required this.bonusPercent,
    required this.bonusDays,
    this.exclusive = false,
    this.priorityWithdrawal = false,
  });

  final String id;
  final String title;
  final String priceLabel;
  final int coins;
  final int freeSpins;
  final int bonusPercent;
  final int bonusDays;
  final bool exclusive;
  final bool priorityWithdrawal;

  static const starter = ShopPackage(
    id: 'gonzotokrevo_1500',
    title: 'Starter Pack',
    priceLabel: '\$2.99',
    coins: 1500,
    freeSpins: 3,
    bonusPercent: 10,
    bonusDays: 3,
  );

  static const premium = ShopPackage(
    id: 'gonzotokrevo_4500',
    title: 'Premium Pack',
    priceLabel: '\$5.99',
    coins: 4500,
    freeSpins: 6,
    bonusPercent: 15,
    bonusDays: 7,
  );

  static const vip = ShopPackage(
    id: 'gonzotokrevo_10000',
    title: 'VIP Pack',
    priceLabel: '\$9.99',
    coins: 10000,
    freeSpins: 10,
    bonusPercent: 25,
    bonusDays: 7,
    exclusive: true,
    priorityWithdrawal: true,
  );

  static const all = [starter, premium, vip];
}

class PayoutMethodDef {
  const PayoutMethodDef(this.id, this.label, {this.singleField = false, this.hint = 'Card number / address'});

  final String id;
  final String label;
  final bool singleField;
  final String hint;

  // `singleField` mirrors the two Figma popup variants ("Exchange, 1v.png" —
  // Name + detail, vs "2v.png" — just a wallet/card field): pure crypto
  // wallets and code-style methods only ever need one field.
  static const all = <PayoutMethodDef>[
    // Field counts/hints for PayPal, Google Pay, Samsung Pay, BTC, ETH,
    // Trc20, Payeer and Skrill follow the exact lookup table from
    // "Инструкция для разработчиков-2.md" (one/two-field list).
    PayoutMethodDef('paypal', 'PayPal', singleField: true, hint: 'Email or PayPal username'),
    PayoutMethodDef('visa', 'Visa', hint: 'Card number'),
    PayoutMethodDef('mastercard', 'MasterCard', hint: 'Card number'),
    PayoutMethodDef('usdt_trc20', 'USDT (Trc20)', singleField: true, hint: 'Wallet address'),
    PayoutMethodDef('google_pay', 'Google Pay', singleField: true, hint: 'Card number'),
    PayoutMethodDef('samsung_pay', 'Samsung Pay', singleField: true, hint: 'Card number'),
    PayoutMethodDef('payeer', 'Payeer', singleField: true, hint: 'Card number'),
    PayoutMethodDef('btc', 'BTC', singleField: true, hint: 'Wallet address'),
    PayoutMethodDef('mir', 'MIR', hint: 'Card number'),
    PayoutMethodDef('qiwi', 'QIWI', singleField: true, hint: 'Wallet number'),
    PayoutMethodDef('webmoney', 'WebMoney', singleField: true, hint: 'WMID'),
    PayoutMethodDef('skrill', 'Skrill', singleField: true, hint: 'Card number'),
    PayoutMethodDef('neteller', 'Neteller', hint: 'Account e-mail'),
    PayoutMethodDef('perfect_money', 'Perfect Money', hint: 'Account number'),
    PayoutMethodDef('advcash', 'AdvCash', singleField: true, hint: 'Wallet number'),
    PayoutMethodDef('eth', 'Ethereum', singleField: true, hint: 'Wallet address'),
    PayoutMethodDef('usdt_erc20', 'USDT (Erc20)', singleField: true, hint: 'Wallet address'),
    PayoutMethodDef('litecoin', 'Litecoin', singleField: true, hint: 'Wallet address'),
    PayoutMethodDef('tron', 'TRON', singleField: true, hint: 'Wallet address'),
    PayoutMethodDef('bank_transfer', 'Bank Transfer', hint: 'IBAN / account number'),
    PayoutMethodDef('apple_pay', 'Apple Pay', hint: 'Account e-mail'),
    PayoutMethodDef('applepay_cash', 'Cash App', hint: '\$Cashtag'),
    PayoutMethodDef('paysafecard', 'Paysafecard', singleField: true, hint: 'Code'),
    PayoutMethodDef('unionpay', 'UnionPay', hint: 'Card number'),
    PayoutMethodDef('jeton', 'Jeton Wallet', singleField: true, hint: 'Wallet number'),
    PayoutMethodDef('astropay', 'AstroPay', hint: 'Card number'),
  ];
}

class GameSettings {
  const GameSettings({
    this.soundVolume = 0.7,
    this.musicVolume = 0.7,
    this.vibrationEnabled = true,
    this.notificationsEnabled = false,
  });

  final double soundVolume;
  final double musicVolume;
  final bool vibrationEnabled;
  final bool notificationsEnabled;

  GameSettings copyWith({
    double? soundVolume,
    double? musicVolume,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
  }) {
    return GameSettings(
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'soundVolume': soundVolume,
        'musicVolume': musicVolume,
        'vibrationEnabled': vibrationEnabled,
        'notificationsEnabled': notificationsEnabled,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        soundVolume: (json['soundVolume'] as num?)?.toDouble() ?? 0.7,
        musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 0.7,
        vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      );
}

class LeaderboardEntry {
  const LeaderboardEntry(this.rank, this.name, this.score, {this.isPlayer = false});
  final int rank;
  final String name;
  final int score;
  final bool isPlayer;
}

class GameData {
  GameData({
    this.balance = 500,
    this.usdBalance = 0,
    this.bet = 2,
    this.betRisk = BetRisk.low,
    this.bonusPercent = 0,
    this.bonusExpiry,
    this.freeSpins = 0,
    this.wheelCooldownUntil,
    this.connectedPayoutMethods = const {},
    this.settings = const GameSettings(),
    this.lastDailyBonusClaim,
    this.totalWinnings = 0,
  });

  int balance;
  double usdBalance;
  int bet;
  BetRisk betRisk;
  int bonusPercent;
  DateTime? bonusExpiry;
  int freeSpins;
  DateTime? wheelCooldownUntil;
  Map<String, String> connectedPayoutMethods;
  GameSettings settings;
  DateTime? lastDailyBonusClaim;
  int totalWinnings;

  bool get hasActiveBonus => bonusPercent > 0 && bonusExpiry != null && bonusExpiry!.isAfter(DateTime.now());

  bool get isWheelReady => wheelCooldownUntil == null || wheelCooldownUntil!.isBefore(DateTime.now());

  /// The exchange conversion slider tracks the live coin balance itself
  /// (per "Инструкция для разработчиков.md" §13), not a separate wagering
  /// counter: "1/10000", then once the user has more than 10 000 it shows
  /// the *next* multiple of 10 000 as the target — e.g. "12300/20000".
  int get exchangeTarget => ((balance ~/ AppConstants.exchangeStep) + 1) * AppConstants.exchangeStep;

  bool get canExchange => balance >= AppConstants.exchangeStep;

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'usdBalance': usdBalance,
        'bet': bet,
        'betRisk': betRisk.name,
        'bonusPercent': bonusPercent,
        'bonusExpiry': bonusExpiry?.toIso8601String(),
        'freeSpins': freeSpins,
        'wheelCooldownUntil': wheelCooldownUntil?.toIso8601String(),
        'connectedPayoutMethods': connectedPayoutMethods,
        'settings': settings.toJson(),
        'lastDailyBonusClaim': lastDailyBonusClaim?.toIso8601String(),
        'totalWinnings': totalWinnings,
      };

  factory GameData.fromJson(Map<String, dynamic> json) => GameData(
        balance: json['balance'] as int? ?? 500,
        usdBalance: (json['usdBalance'] as num?)?.toDouble() ?? 0,
        bet: json['bet'] as int? ?? 2,
        betRisk: BetRiskX.fromName(json['betRisk'] as String? ?? 'low'),
        bonusPercent: json['bonusPercent'] as int? ?? 0,
        bonusExpiry: json['bonusExpiry'] != null ? DateTime.tryParse(json['bonusExpiry'] as String) : null,
        freeSpins: json['freeSpins'] as int? ?? 0,
        wheelCooldownUntil:
            json['wheelCooldownUntil'] != null ? DateTime.tryParse(json['wheelCooldownUntil'] as String) : null,
        connectedPayoutMethods: (json['connectedPayoutMethods'] as Map?)?.cast<String, String>() ?? {},
        settings: json['settings'] != null
            ? GameSettings.fromJson((json['settings'] as Map).cast<String, dynamic>())
            : const GameSettings(),
        lastDailyBonusClaim:
            json['lastDailyBonusClaim'] != null ? DateTime.tryParse(json['lastDailyBonusClaim'] as String) : null,
        totalWinnings: json['totalWinnings'] as int? ?? 0,
      );

  String encode() => jsonEncode(toJson());
  static GameData decode(String source) => GameData.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
