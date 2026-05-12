import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:athletehub_app/features/auth/presentation/providers/user_provider.dart';
import 'confirm_subscription_screen.dart';

class SubscriptionBillingScreen extends StatelessWidget {
  const SubscriptionBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The UI is built to exactly match the requested design mockups.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'الاشتراك والفوترة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          leading: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_forward, size: 16, color: Color(0xFF3B82F6)),
                SizedBox(width: 4),
                Text(
                  'رجوع',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          leadingWidth: 100,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentPlanCard(),
              const SizedBox(height: 16),
              _buildAutoRenewAlert(),
              const SizedBox(height: 32),
              const Text(
                'تغيير الخطة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              _buildOtherPlanCard(
                context: context,
                name: 'أساسي',
                price: '5',
                description: '٣ مجموعات مختارة أول شهر تجريبي مجاناً',
                iconWidget: const Icon(Icons.flash_on, color: Colors.deepOrange, size: 24),
                iconBgColor: const Color(0xFF64748B),
                isCurrent: false,
                targetScreen: const ConfirmSubscriptionScreen(
                  planName: 'أساسي',
                  planPrice: '5',
                  planDescription: '٣ مجموعات مختارة أول شهر تجريبي مجاناً',
                  planIconWidget: Icon(Icons.flash_on, color: Colors.deepOrange, size: 20),
                  planCardColor: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              _buildOtherPlanCard(
                context: context,
                name: 'مميّز',
                price: '15',
                description: 'جميع المجموعات الرياضية (٥ مجموعات)',
                iconWidget: const Icon(Icons.star, color: Colors.amber, size: 24),
                iconBgColor: const Color(0xFF3B82F6),
                isCurrent: true,
                targetScreen: const ConfirmSubscriptionScreen(
                  planName: 'مميّز',
                  planPrice: '15',
                  planDescription: 'جميع المجموعات الرياضية (٥ مجموعات)',
                  planIconWidget: Icon(Icons.star, color: Colors.amber, size: 20),
                  planCardColor: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 12),
              _buildOtherPlanCard(
                context: context,
                name: 'احترافي',
                price: '30',
                description: 'جميع المجموعات + احترافية (٨ مجموعات)',
                iconWidget: const Text('👑', style: TextStyle(fontSize: 20)),
                iconBgColor: const Color(0xFF0F172A),
                isCurrent: false,
                targetScreen: const ConfirmSubscriptionScreen(
                  planName: 'احترافي',
                  planPrice: '30',
                  planDescription: 'جميع المجموعات + احترافية (٨ مجموعات) أول شهر تجريبي مجاناً',
                  planIconWidget: Text('👑', style: TextStyle(fontSize: 18)),
                  planCardColor: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'طريقة الدفع',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethodCard(),
              const SizedBox(height: 16),
              _buildPaymentInfoAlert(),
              const SizedBox(height: 32),
              const Text(
                'الفواتير',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              _buildInvoicesList(),
              const SizedBox(height: 32),
              _buildCancelButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'خطتك الحالية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'مميّز',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '15 ر.ع',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ شهر',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'التجديد التلقائي ١٥ مايو جميع المجموعات\nالرياضية (٥ مجموعات)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoRenewAlert() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'التجديد التلقائي مفعّل • سيتم خصم 15 ر.ع في ١٥ مايو ٢٠٢٥',
              style: TextStyle(
                color: Color(0xFF059669),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherPlanCard({
    required BuildContext context,
    required String name,
    required String price,
    required String description,
    required Widget iconWidget,
    required Color iconBgColor,
    required bool isCurrent,
    Widget? targetScreen,
  }) {
    return InkWell(
      onTap: () {
        if (targetScreen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent ? const Color(0xFF3B82F6) : Colors.grey.shade200,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: iconWidget,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'الحالية',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$price ر.ع',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '/ شهر',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.apple, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Store',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يُدار من إعدادات الجهاز',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(
            Icons.arrow_back_ios,
            color: Colors.white54,
            size: 16,
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.blue[900], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'تتم إدارة جميع المدفوعات عبر متجر التطبيقات. لتغيير الخطة أو الإلغاء، توجّه لإعدادات الاشتراكات في حساب Apple ID أو Google Play.',
              style: TextStyle(
                color: Colors.blue[900],
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInvoiceItem('خطة مميّز', '١٥ أبريل ٢٠٢٥', '١٥ ر.ع'),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildInvoiceItem('خطة مميّز', '١٥ مارس ٢٠٢٥', '١٥ ر.ع'),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildInvoiceItem('خطة أساسي', '١٠ فبراير ٢٠٢٥', '٥ ر.ع'),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildInvoiceItem('خطة أساسي', '١٠ يناير ٢٠٢٥', '٥ ر.ع'),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(String plan, String date, String amount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 16),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Center(
        child: Text(
          'إلغاء الاشتراك من إعدادات الجهاز',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
