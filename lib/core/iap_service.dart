import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'constants.dart';

/// Wraps `in_app_purchase` for the 3 consumable coin packages. The app has
/// no Play Console listing yet, so `isAvailable` will correctly report
/// false until the build is uploaded and the SKUs are created — the whole
/// flow below is fully wired and will start working the moment that happens.
class IapService {
  IapService._();
  static final instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  List<ProductDetails> products = [];
  bool available = false;

  void Function(String productId)? onPurchaseSuccess;
  void Function(String productId, String error)? onPurchaseError;

  Future<void> init() async {
    try {
      available = await _iap.isAvailable();
      if (!available) return;

      _sub = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (e) {
        debugPrint('IAP stream error: $e');
      });

      final response = await _iap.queryProductDetails(AppConstants.iapProductIds);
      products = response.productDetails;
    } catch (e) {
      debugPrint('IAP init failed: $e');
      available = false;
    }
  }

  ProductDetails? productFor(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> buy(String productId) async {
    final product = productFor(productId);
    if (product == null) {
      onPurchaseError?.call(productId, 'Product not available yet');
      return;
    }
    final param = PurchaseParam(productDetails: product);
    try {
      await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      onPurchaseError?.call(productId, e.toString());
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          onPurchaseError?.call(purchase.productID, purchase.error?.message ?? 'unknown error');
          break;
        case PurchaseStatus.canceled:
          onPurchaseError?.call(purchase.productID, 'canceled');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          onPurchaseSuccess?.call(purchase.productID);
          try {
            final androidAddition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
            await androidAddition.consumePurchase(purchase);
          } catch (_) {}
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
