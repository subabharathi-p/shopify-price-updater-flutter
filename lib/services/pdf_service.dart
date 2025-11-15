import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../product.dart';

class PdfService {
  /// Exports a professional PDF report for price updates with flexible currency
  static Future<void> exportBeforeAfterPdf(
      List<Product> products, String currencySymbol) async {
    try {
      final headers = ['Product Title', 'Variant', 'Old Price', 'New Price'];

      final rows = <List<String>>[];
      for (final p in products) {
        for (final v in p.variants) {
          final before = v.beforePrice ?? v.price ?? 0.0;
          final after = v.afterPrice ?? v.price ?? 0.0;

          rows.add([
            p.title ?? '',
            v.title ?? '',
            '$currencySymbol${before.toStringAsFixed(2)}',
            '$currencySymbol${after.toStringAsFixed(2)}',
          ]);
        }
      }

      final title = "IJC Price Update Report";
      final exportDate = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

      final pdfBytes = await compute(
        _pdfWorker,
        {
          'headers': headers,
          'rows': rows,
          'title': title,
          'exportDate': exportDate,
        },
      );

      final directory = await getTemporaryDirectory();
      final filePath = "${directory.path}/price_update_report.pdf";
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'IJC Price Update Report',
      );
    } catch (e) {
      debugPrint("PDF build failed: $e");
    }
  }
}

Future<Uint8List> _pdfWorker(Map<String, dynamic> params) async {
  final pdf = pw.Document();
  final headers = params['headers'] as List<String>;
  final rows = params['rows'] as List<List<String>>;
  final title = params['title'] as String;
  final exportDate = params['exportDate'] as String;

  // IJC Logo path (add logo image to assets)
  final logoImagePath = 'assets/ijc_logo.png';
  Uint8List? logoBytes;
  try {
    final logoFile = File(logoImagePath);
    if (logoFile.existsSync()) {
      logoBytes = logoFile.readAsBytesSync();
    }
  } catch (_) {}

  const int rowsPerChunk = 40;
  final chunks = <List<List<String>>>[];
  for (int i = 0; i < rows.length; i += rowsPerChunk) {
    chunks.add(rows.sublist(
      i,
      i + rowsPerChunk > rows.length ? rows.length : i + rowsPerChunk,
    ));
  }

  for (int i = 0; i < chunks.length; i++) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (context) => [
          if (logoBytes != null)
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                width: 120,
                height: 60,
                fit: pw.BoxFit.contain,
              ),
            ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            "Export Date: $exportDate",
            style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: headers,
            data: chunks[i],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey800),
            cellStyle: pw.TextStyle(fontSize: 9, color: PdfColors.black),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  return pdf.save();
}
