// ignore_for_file: file_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order.dart';

class InvoicePage extends StatelessWidget {
  final Order order;

  const InvoicePage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Invoice ${order.id.substring(0, 8)}...'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => Printing.layoutPdf(onLayout: (format) => _generatePdf(order)),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(order),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: 'invoice-${order.id}.pdf',
      ),
    );
  }

  Future<Uint8List> _generatePdf(Order order) async {
    final pdf = pw.Document();
    final dateFormatted = DateFormat('yyyy-MM-dd – hh:mm a').format(order.createdAt.toDate());

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Order Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Order ID: ${order.id}'),
                pw.Text('Order Date: $dateFormatted'),
                pw.SizedBox(height: 20),

                pw.Text('Shipping Address:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Name: ${order.shippingAddress['name'] ?? 'N/A'}'),
                pw.Text('Address: ${order.shippingAddress['addressLine1'] ?? 'N/A'}'),
                pw.Text('City: ${order.shippingAddress['city'] ?? 'N/A'}'),
                pw.Text('Postal Code: ${order.shippingAddress['postalCode'] ?? 'N/A'}'),
                pw.Text('Phone: ${order.shippingAddress['phone'] ?? 'N/A'}'),

                pw.SizedBox(height: 20),
                pw.Text('Products Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),

                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Product')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Quantity')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Price')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total')),
                      ],
                    ),
                    ...order.items.map((item) {
                      final itemPrice = item.discountPrice ?? item.price;
                      final total = itemPrice * item.quantity;
                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.productName)),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.quantity}')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${itemPrice.toStringAsFixed(2)}')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${total.toStringAsFixed(2)}')),
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Products Total: ${order.totalAmount.toStringAsFixed(2)} SAR'),
                        pw.Text('Shipping Cost: ${order.shippingCost.toStringAsFixed(2)} SAR'),
                        pw.Text('Grand Total: ${order.grandTotal.toStringAsFixed(2)} SAR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
