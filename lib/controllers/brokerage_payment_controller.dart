import 'package:get/get.dart';
import 'package:brokkerspot/models/brokerage_payment_model.dart';

class BrokeragePaymentController extends GetxController {
  var deals = <DealModel>[].obs;
  var payments = <BrokerPaymentModel>[].obs;
  var selectedPaymentIndex = 0.obs;
  var selectedDeal = Rx<DealModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadMockData();
  }

  void _loadMockData() {
    deals.value = [
      DealModel(
        id: 'deal_1',
        projectName: 'AVANTI',
        propertyType: 'Studio',
        referenceId: 'ZADA_ZAD/25/5',
        status: 'inprocess',
        totalAmount: 40000,
      ),
      DealModel(
        id: 'deal_2',
        projectName: 'ZADA',
        propertyType: '1 Bedroom',
        referenceId: 'ZADA_ZAD/25/5',
        status: 'successfully',
        totalAmount: 50000,
      ),
    ];

    payments.value = [
      BrokerPaymentModel(
        id: '1',
        brokerName: 'John',
        projectName: 'AVANTI',
        amount: 40000,
        dealId: 'deal_1',
      ),
      BrokerPaymentModel(
        id: '2',
        brokerName: 'Rachid',
        projectName: 'ZADA',
        amount: 50000,
        dealId: 'deal_2',
      ),
      BrokerPaymentModel(
        id: '3',
        brokerName: 'Aman',
        projectName: 'SAFA / TWO',
        amount: 12000,
        dealId: 'deal_1',
      ),
      BrokerPaymentModel(
        id: '4',
        brokerName: 'Aman',
        projectName: 'SAFA / TWO',
        amount: 12000,
        dealId: 'deal_1',
      ),
    ];

    selectedDeal.value = deals.first;
  }

  void selectPayment(int index) {
    selectedPaymentIndex.value = index;
    final payment = payments[index];
    final deal = deals.firstWhereOrNull((d) => d.id == payment.dealId);
    if (deal != null) {
      selectedDeal.value = deal;
    }
  }

  double get selectedAmount {
    if (payments.isEmpty) return 0;
    return payments[selectedPaymentIndex.value].amount ?? 0;
  }

  double get progressFraction {
    final deal = selectedDeal.value;
    if (deal == null || deal.totalAmount == null || deal.totalAmount == 0) {
      return 0;
    }
    return (selectedAmount / deal.totalAmount!).clamp(0.0, 1.0);
  }

  String formatAmount(double amount) {
    String str = amount.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}
