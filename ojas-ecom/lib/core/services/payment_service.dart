import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class PaymentService implements PayUCheckoutProProtocol {
  final Dio _dio = Dio();
  late PayUCheckoutProFlutter _payuCheckoutPro;

  PaymentService() {
    if (!kIsWeb) {
      _payuCheckoutPro = PayUCheckoutProFlutter(this);
    }
  }

  // Protocol methods (placeholders as we use .then() callback)
  @override
  generateHash(Map? value) {}
  @override
  onPaymentSuccess(dynamic response) {}
  @override
  onPaymentFailure(dynamic response) {}
  @override
  onPaymentCancel(Map? isCancelledByUser) {}
  @override
  onError(Map? error) {}
  @override
  void onPaymentTerminated(Map? response) {}


  // 1. Initiate PayU Payment
  Future<void> startPayment({
    required BuildContext context,
    required Map<String, dynamic> paymentPayload,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(Map<String, dynamic>) onFailure,
    required Function(Map<String, dynamic>) onCancel,
  }) async {
    if (kIsWeb) {
      final String checkoutUrl = "${ApiService.baseUrl}/payment/web-checkout?txnid=${paymentPayload['txnid']}";
      final Uri url = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        onFailure({"error": "Could not launch payment page"});
      }
      return;
    }

    try {
      // Configuration for PayU Checkout Pro
      Map<String, dynamic> payUPaymentParams = {
        "key": paymentPayload['key'],
        "transactionId": paymentPayload['txnid'],
        "amount": paymentPayload['amount'],
        "productInfo": paymentPayload['productinfo'],
        "firstName": paymentPayload['firstname'],
        "email": paymentPayload['email'],
        "phone": paymentPayload['phone'],
        "ios_surl": paymentPayload['surl'],
        "ios_furl": paymentPayload['furl'],
        "android_surl": paymentPayload['surl'],
        "android_furl": paymentPayload['furl'],
        "environment": "1", // 0 for Test, 1 for Production
        "userToken": "", // Optional
        "hash": paymentPayload['hash'], // Added here for version 1.4.3
      };

      Map<String, dynamic> payUCheckoutProConfig = {
        "primaryColor": "#462AD8",
        "secondaryColor": "#FF5722",
        "merchantName": "Ojas",
        "merchantLogo": "logo", 
        "showExitConfirmationOnCheckout": true,
        "showExitConfirmationOnPaymentPage": true,
        "cartDetails": [
          {"Order Amount": paymentPayload['amount']}
        ],
      };

      // Open PayU SDK
      _payuCheckoutPro.openCheckoutScreen(
        payUPaymentParams: payUPaymentParams,
        payUCheckoutProConfig: payUCheckoutProConfig,
      ).then((response) {
        // Handle result safely
        if (response == null) {
          onFailure({"error": "Payment cancelled or no response"});
          return;
        }
        
        final result = Map<dynamic, dynamic>.from(response);
        final status = result['status'];

        if (status == 'success') {
          onSuccess(Map<String, dynamic>.from(result));
        } else if (status == 'failure') {
          onFailure(Map<String, dynamic>.from(result));
        } else if (status == 'cancel') {
          onCancel(Map<String, dynamic>.from(result));
        }
      });
    } catch (e) {
      debugPrint("PayU Error: $e");
      onFailure({"error": e.toString()});
    }
  }

  // 2. Verify Payment with Backend
  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> response) async {
    try {
      final res = await _dio.post(
        '${ApiService.baseUrl}/payment/verify',
        data: response,
      );
      return res.data;
    } catch (e) {
      debugPrint("Verification Error: $e");
      return {"success": false, "message": "Verification failed"};
    }
  }
}
