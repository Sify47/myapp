import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم والمساعدة'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3366FF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة التواصل
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.support_agent, size: 50, color: Color(0xFF3366FF)),
                    const SizedBox(height: 16),
                    const Text(
                      'مركز الدعم',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'نحن هنا لمساعدتك على مدار الساعة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildContactButton(
                          'الاتصال',
                          Icons.phone,
                          Colors.green,
                          () => _launchUrl('tel:+201234567890'),
                        ),
                        _buildContactButton(
                          'واتساب',
                          Icons.chat,
                          Colors.green,
                          () => _launchUrl('https://wa.me/201234567890'),
                        ),
                        _buildContactButton(
                          'البريد',
                          Icons.email,
                          Colors.blue,
                          () => _launchUrl('mailto:support@example.com'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // الأسئلة الشائعة
            const Text(
              'الأسئلة الشائعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildFAQItem(
              'كيف يمكنني تتبع طلبي؟',
              'يمكنك تتبع حالة طلبك من خلال صفحة "طلباتي" في تطبيقنا.',
            ),
            _buildFAQItem(
              'ما هي طرق الدفع المتاحة؟',
              'نقبل الدفع نقداً عند الاستلام وبالبطاقات الائتمانية والمحافظ الإلكترونية.',
            ),
            _buildFAQItem(
              'كيف يمكنني إرجاع منتج؟',
              'يمكنك طلب إرجاع المنتج خلال 14 يومًا من خلال صفحة الطلبات.',
            ),
            _buildFAQItem(
              'ما هي مدة التوصيل؟',
              'مدة التوصيل من 2-5 أيام عمل حسب الموقع.',
            ),

            const SizedBox(height: 24),

            // معلومات الاتصال
            const Text(
              'معلومات الاتصال',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildContactInfo('العنوان', 'القاهرة، مصر', Icons.location_on),
            _buildContactInfo('الهاتف', '+201234567890', Icons.phone),
            _buildContactInfo('البريد', 'support@example.com', Icons.email),
            _buildContactInfo('الواتساب', '+201234567890', Icons.chat),

            const SizedBox(height: 24),

            // أوقات العمل
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أوقات العمل',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('السبت - الخميس: 9 ص - 11 م'),
                    Text('الجمعة: 1 م - 11 م'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(answer, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3366FF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }
}