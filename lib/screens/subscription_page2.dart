// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import 'info_page.dart';
//
// class SubscriptionPage extends StatefulWidget {
//   const SubscriptionPage({Key? key}) : super(key: key);
//
//   @override
//   State<SubscriptionPage> createState() => _SubscriptionPageState();
// }
//
// class _SubscriptionPageState extends State<SubscriptionPage> {
//   late Razorpay _razorpay;
//   final User? user = FirebaseAuth.instance.currentUser;
//
//   final Map<String, dynamic> planDetails = {
//     "Basic": {"price": 49, "messages": 70, "days": 7},
//     "Starter": {"price": 99, "messages": 220, "days": 15},
//     "Standard": {"price": 199, "messages": 550, "days": 30},
//     "Pro": {"price": 299, "messages": 1000, "days": 30},
//     "Premium": {"price": 499, "messages": 5000, "days": 90},
//   };
//
//   String? _activePlan;
//   bool _isLoading = true;
//   String selectedPlan = "";
//   bool useLive = false; // switch to true when going live
//   final String razorpayTestKey = "rzp_test_R5taaqOyZYI1yT";
//
//   @override
//   void initState() {
//     super.initState();
//     _razorpay = Razorpay();
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//     _checkActiveSubscription();
//   }
//
//   @override
//   void dispose() {
//     _razorpay.clear();
//     super.dispose();
//   }
//
//   Future<void> _checkActiveSubscription() async {
//     if (user == null) {
//       setState(() => _isLoading = false);
//       return;
//     }
//     final doc = await FirebaseFirestore.instance
//         .collection('subscriptions')
//         .doc(user!.uid)
//         .get();
//
//     if (doc.exists) {
//       final data = doc.data();
//       if (data != null &&
//           data['active'] == true &&
//           data['endDate'].toDate().isAfter(DateTime.now())) {
//         setState(() => _activePlan = data['plan']);
//       }
//     }
//     setState(() => _isLoading = false);
//   }
//
//   Future<Map<String, dynamic>> _createOrder(int amount) async {
//     // call Firebase Cloud Function
//     final url = Uri.parse(
//         'https://us-central1-YOUR_PROJECT.cloudfunctions.net/createOrder');
//     final response = await http.post(url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'amount': amount}));
//     return jsonDecode(response.body);
//   }
//
//   Future<bool> _verifyPayment(Map<String, String> paymentData) async {
//     final url = Uri.parse(
//         'https://us-central1-YOUR_PROJECT.cloudfunctions.net/verifyPayment');
//     final response = await http.post(url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(paymentData));
//     final result = jsonDecode(response.body);
//     return result['verified'] ?? false;
//   }
//
//   void _openCheckout(String title) async {
//     final plan = planDetails[title]!;
//     selectedPlan = title;
//
//     try {
//       final orderData = await _createOrder(plan['price']);
//       final options = {
//         'key': useLive ? 'rzp_live_xxxxx' : razorpayTestKey,
//         'amount': plan['price'] * 100,
//         'name': 'TextHer',
//         'description': '$title Subscription',
//         'order_id': orderData['id'],
//         'prefill': {
//           'contact': user?.phoneNumber ?? '',
//           'email': user?.email ?? '',
//         },
//         'external': {
//           'wallets': ['paytm'],
//         }
//       };
//
//       _razorpay.open(options);
//     } catch (e) {
//       debugPrint("Error creating order: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to create order: $e")),
//       );
//     }
//   }
//
//   void _handlePaymentSuccess(PaymentSuccessResponse response) async {
//     try {
//       final verified = await _verifyPayment({
//         'razorpay_order_id': response.orderId ?? '',
//         'razorpay_payment_id': response.paymentId ?? '',
//         'razorpay_signature': response.signature ?? '',
//       });
//
//       if (!verified) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Payment verification failed.")),
//         );
//         return;
//       }
//
//       final plan = planDetails[selectedPlan]!;
//
//       await FirebaseFirestore.instance
//           .collection("subscriptions")
//           .doc(user!.uid)
//           .set({
//         "plan": selectedPlan,
//         "paymentId": response.paymentId,
//         "startDate": DateTime.now(),
//         "endDate": DateTime.now().add(Duration(days: plan['days'])),
//         "maxMessages": plan['messages'],
//         "messagesUsed": 0,
//         "active": true,
//       });
//
//       setState(() => _activePlan = selectedPlan);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Subscribed to $selectedPlan successfully!")),
//       );
//     } catch (e) {
//       debugPrint("Payment success handling failed: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     }
//   }
//
//   void _handlePaymentError(PaymentFailureResponse response) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Payment failed. Please try again.")),
//     );
//   }
//
//   void _handleExternalWallet(ExternalWalletResponse response) {
//     debugPrint("External wallet selected: ${response.walletName}");
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: const Text(
//           'Packages',
//           style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Urbanist'),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.help_outline, color: Colors.white),
//             onPressed: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (context) => const InfoPage(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Stack(
//         alignment: Alignment.bottomCenter,
//         children: [
//           _activePlan != null
//               ? _buildPlanContainer(
//               context,
//               _activePlan!,
//               '₹${planDetails[_activePlan]!['price']}',
//               '${planDetails[_activePlan]!['messages']} messages',
//               '${planDetails[_activePlan]!['days']} days validity',
//               'Subscribed',
//               true)
//               : PageView(
//             children: planDetails.keys.map((planName) {
//               final plan = planDetails[planName]!;
//               return _buildPlanContainer(
//                 context,
//                 planName,
//                 '₹${plan['price']}',
//                 '${plan['messages']} messages',
//                 '${plan['days']} days validity',
//                 planName,
//                 false,
//               );
//             }).toList(),
//           ),
//           if (_activePlan == null)
//             const Padding(
//               padding: EdgeInsets.only(bottom: 20.0),
//               child: Text(
//                 'Swipe to see different plans',
//                 style: TextStyle(color: Colors.white70, fontSize: 14),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPlanContainer(BuildContext context, String title, String price,
//       String messages, String validity, String labelText, bool isSubscribed) {
//     return SingleChildScrollView(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//         alignment: Alignment.center,
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: isSubscribed ? Colors.green : Colors.grey[850],
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 labelText,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1C1C1E),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(24.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Text(
//                           title,
//                           style: const TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           price,
//                           style: const TextStyle(
//                               fontSize: 48,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Divider(color: Colors.grey),
//                   _buildFeatureRow(messages),
//                   _buildFeatureRow(validity),
//                   _buildFeatureRow('Secure Chat'),
//                   _buildFeatureRow('24/7 Access'),
//                   _buildFeatureRow('Perfect Replies'),
//                   const SizedBox(height: 20),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                     child: ElevatedButton(
//                       onPressed: isSubscribed ? null : () => _openCheckout(title),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor:
//                         isSubscribed ? Colors.grey[700] : Colors.grey[800],
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: Text(
//                         isSubscribed ? 'Subscribed' : 'Subscribe',
//                         style: TextStyle(
//                           color: isSubscribed ? Colors.white54 : Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Payment Notice',
//               style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Your subscription benefits will begin once your payment has been processed.',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFeatureRow(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
//       child: Row(
//         children: [
//           const Icon(Icons.check_circle_outline,
//               color: Color(0xFF4CAF50), size: 20),
//           const SizedBox(width: 12),
//           Text(
//             text,
//             style: const TextStyle(color: Colors.white, fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }
// }
