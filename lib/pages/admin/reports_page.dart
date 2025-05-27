import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';



class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int brandCount = 0;
  int offerCount = 0;
  // int userCount = 0;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    final brandSnapshot =
        await FirebaseFirestore.instance.collection('brands').get();
    final offerSnapshot =
        await FirebaseFirestore.instance.collection('offers').get();
    // final userSnapshot =
    //     await FirebaseFirestore.instance.collection('users').get();

    setState(() {
      brandCount = brandSnapshot.size;
      offerCount = offerSnapshot.size;
      // userCount = userSnapshot.size;
    });
  }
  Future<void> generatePDF() async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Reports', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('Number Of Brands : $brandCount'),
            pw.Text('Number Of Offers : $offerCount'),
            // pw.Text('عدد المستخدمين: $userCount'),
            pw.SizedBox(height: 20),
            pw.Text('Date: ${DateTime.now().toLocal()}'),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('التقارير'),
  centerTitle: true,
  
),
      body: RefreshIndicator(
        onRefresh: fetchCounts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            reportCard(Icons.store, 'عدد البراندات', brandCount, Colors.orange),
            const SizedBox(height: 16),
            reportCard(Icons.local_offer, 'عدد العروض', offerCount, Colors.green),
            // const SizedBox(height: 16),
            // reportCard(Icons.person, 'عدد المستخدمين', userCount, Colors.blue),
          ],
        ),
      ),
    );
  }
  

  Widget reportCard(IconData icon, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}
