import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recognition.dart';
import '../screens/photo_batch_screen.dart';
import '../utils/location_helper.dart';

class ReportService {
  /// Draws bounding boxes and labels onto the raw image bytes using dart:ui
  /// so the annotated image can be embedded in the PDF.
  static Future<Uint8List> _annotateImage({
    required Uint8List imageBytes,
    required List<Recognition> detections,
  }) async {
    // Decode the image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;
    final imgW = srcImage.width.toDouble();
    final imgH = srcImage.height.toDouble();

    // Create a recorder at the same size as the image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgW, imgH));

    // Draw the original image
    canvas.drawImage(srcImage, Offset.zero, Paint());

    for (final rec in detections) {
      // Bounding box scaled to full image dimensions
      final rect = Rect.fromLTRB(
        rec.location.left * imgW,
        rec.location.top * imgH,
        rec.location.right * imgW,
        rec.location.bottom * imgH,
      );

      // Choose colour by severity
      final Color boxColor = rec.score > 0.7
          ? const Color(0xFFE53935)   // red  – high
          : (rec.score > 0.4
              ? const Color(0xFFFB8C00) // orange – medium
              : const Color(0xFF43A047)); // green – low

      // Draw bounding box
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..color = boxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = (imgW * 0.006).clamp(3.0, 10.0),
      );

      // Label text
      final label = '${rec.label.toUpperCase()}  ${(rec.score * 100).toStringAsFixed(1)}%';
      final fontSize = (imgW * 0.028).clamp(14.0, 36.0);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      // Label background pill
      final bgPadH = fontSize * 0.4;
      final bgPadV = fontSize * 0.25;
      final bgRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - bgPadV * 2,
        textPainter.width + bgPadH * 2,
        textPainter.height + bgPadV * 2,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
        Paint()..color = boxColor.withOpacity(0.88),
      );

      // Draw label
      textPainter.paint(
        canvas,
        Offset(rect.left + bgPadH, rect.top - textPainter.height - bgPadV),
      );
    }

    // Encode back to PNG
    final picture = recorder.endRecording();
    final annotated = await picture.toImage(srcImage.width, srcImage.height);
    final byteData = await annotated.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Future<String?> generateAndSaveSingleReport({
    required String projectTitle,
    required String location,
    required List<Recognition> detections,
    required String imagePath,
    String? inspectorName,
    String? projectSummary,
    double? lat,
    double? lng,
  }) async {
    final date = DateFormat('yyyy-MM-dd  HH:mm').format(DateTime.now());

    // Load Logo
    final logoBytes = (await rootBundle.load('assets/brand/logo.png')).buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    // Annotate the image
    final rawBytes = await File(imagePath).readAsBytes();
    final annotatedBytes = await _annotateImage(
      imageBytes: rawBytes,
      detections: detections,
    );

    final pdf = pw.Document();
    final image = pw.MemoryImage(annotatedBytes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ── Header with Logo ─────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(logoImage, height: 40),
                    pw.SizedBox(height: 4),
                    pw.Text('CITYSCAN INFRASTRUCTURE MONITOR', 
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, letterSpacing: 1.2)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('DAMAGE REPORT', 
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text(date, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 20),

            // ── Project & Inspector Details ──────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _labelValue('Project', projectTitle),
                      _labelValue('Location', location),
                      if (lat != null && lng != null)
                        _labelValue('GPS', LocationHelper.formatToProjectCoordinates(lat, lng)),
                    ],
                  ),
                ),
                pw.Container(width: 1, height: 60, color: PdfColors.grey300, margin: const pw.EdgeInsets.symmetric(horizontal: 20)),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _labelValue('Inspector', inspectorName ?? 'Authorized CityScan Official'),
                      _labelValue('Report ID', 'CS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 15),
            
            // ── One-line Summary ────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: const pw.Border(left: pw.BorderSide(color: PdfColors.blue900, width: 4)),
              ),
              child: pw.Text(
                projectSummary ?? 'AI-assisted structural integrity assessment for ${projectTitle.toLowerCase()} infrastructure.',
                style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic),
              ),
            ),

            pw.SizedBox(height: 25),

            // ── Visual Evidence ─────────────────────────────────────────────
            pw.Text('VISUAL ANALYSIS & ANNOTATIONS', 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Container(
                height: 320,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
            ),

            pw.SizedBox(height: 25),

            // ── Detection Summary Table ────────────────────────────────────
            pw.Text('FINDINGS SUMMARY', 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                  children: [
                    _cell('ANOMALY TYPE', bold: true),
                    _cell('CONFIDENCE', bold: true),
                    _cell('SEVERITY', bold: true),
                  ],
                ),
                ...detections.map((d) => pw.TableRow(
                  children: [
                    _cell(d.label.replaceAll('_', ' ').toUpperCase()),
                    _cell('${(d.score * 100).toStringAsFixed(1)}%'),
                    _cell(d.severity, color: d.severity == 'High' ? PdfColors.red800 : (d.severity == 'Medium' ? PdfColors.orange800 : PdfColors.green800)),
                  ],
                )),
              ],
            ),

            pw.SizedBox(height: 40),

            // ── Footer ────────────────────────────────────────────────────
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('This is an AI-generated official inspection report.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    // Save and Layout
    try {
      final dir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${dir.path}/reports');
      if (!await reportsDir.exists()) await reportsDir.create(recursive: true);
      
      final fileName = 'Report_${projectTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${reportsDir.path}/$fileName');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: fileName);
      return file.path;
    } catch (e) {
      print('Error saving report: $e');
      return null;
    }
  }

  static pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey800)),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(String text, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 9,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Batch Report — multiple photos each with their own annotated section
  // ────────────────────────────────────────────────────────────────────────────
  static Future<String?> generateAndSaveBatchReport({
    required String projectTitle,
    required String location,
    required List<PhotoResult> photoResults,
    String? inspectorName,
    String? projectSummary,
  }) async {
    final date = DateFormat('yyyy-MM-dd  HH:mm').format(DateTime.now());
    final pdf = pw.Document();

    // Load Logo
    final logoBytes = (await rootBundle.load('assets/brand/logo.png')).buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    // Pre-annotate all images
    final List<pw.MemoryImage> annotatedImages = [];
    for (final pr in photoResults) {
      final raw = await File(pr.imagePath).readAsBytes();
      final annotated = await _annotateImage(
        imageBytes: raw,
        detections: pr.detections,
      );
      annotatedImages.add(pw.MemoryImage(annotated));
    }

    final int totalDetections = photoResults.fold(0, (sum, pr) => sum + pr.detections.length);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];

          // ── Header with Logo ─────────────────────────────────────────────
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(logoImage, height: 40),
                    pw.SizedBox(height: 4),
                    pw.Text('CITYSCAN INFRASTRUCTURE MONITOR', 
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, letterSpacing: 1.2)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('BATCH INSPECTION REPORT', 
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text(date, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 10));
          widgets.add(pw.Divider(thickness: 2, color: PdfColors.blue900));
          widgets.add(pw.SizedBox(height: 20));

          // ── Project Summary Box ────────────────────────────────────────────
          widgets.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _labelValue('Project', projectTitle),
                      _labelValue('Location', location),
                      _labelValue('Photos Inspected', photoResults.length.toString()),
                    ],
                  ),
                ),
                pw.Container(width: 1, height: 60, color: PdfColors.grey300, margin: const pw.EdgeInsets.symmetric(horizontal: 20)),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _labelValue('Inspector', inspectorName ?? 'Authorized CityScan Official'),
                      _labelValue('Total Anomalies', totalDetections.toString()),
                    ],
                  ),
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 15));
          
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: const pw.Border(left: pw.BorderSide(color: PdfColors.blue900, width: 4)),
              ),
              child: pw.Text(
                projectSummary ?? 'AI-assisted batch structural assessment for $projectTitle. Compiled metadata and visual evidence follow.',
                style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic),
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 24));

          // ── Per-photo sections ─────────────────────────────────────────────
          for (int i = 0; i < photoResults.length; i++) {
            final pr = photoResults[ i];
            final detections = pr.detections;
            final note = pr.note;

            widgets.add(pw.Container(
              padding: const pw.EdgeInsets.all(14),
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('PHOTO ${i + 1}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text(
                      detections.isEmpty ? '✓ NO DAMAGE DETECTED' : '⚠ ${detections.length} ANOMALIE(S) IDENTIFIED',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: detections.isEmpty ? PdfColors.green800 : PdfColors.red800,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                if (pr.lat != null && pr.lng != null)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                    child: pw.Row(children: [
                      pw.Text('GPS: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text(LocationHelper.formatToProjectCoordinates(pr.lat!, pr.lng!), style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue900)),
                    ]),
                  ),

                pw.Center(
                  child: pw.Container(
                    height: 260,
                    child: pw.Image(annotatedImages[i], fit: pw.BoxFit.contain),
                  ),
                ),

                if (note.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(color: PdfColors.amber50),
                    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('Inspector Note: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Flexible(child: pw.Text(note, style: const pw.TextStyle(fontSize: 10))),
                    ]),
                  ),
                ],

                if (detections.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _cell('ANOMALY TYPE', bold: true),
                          _cell('CONFIDENCE', bold: true),
                          _cell('SEVERITY', bold: true),
                        ],
                      ),
                      ...detections.map((d) => pw.TableRow(children: [
                        _cell(d.label.replaceAll('_', ' ').toUpperCase()),
                        _cell('${(d.score * 100).toStringAsFixed(1)}%'),
                        _cell(d.severity, color: d.severity == 'High' ? PdfColors.red800 : (d.severity == 'Medium' ? PdfColors.orange800 : PdfColors.green800)),
                      ])),
                    ],
                  ),
                ],
              ]),
            ));
          }

          widgets.add(pw.Divider(color: PdfColors.grey300));
          widgets.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('CITYSCAN OFFICIAL BATCH INSPECTION RECORD', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Text('Generated by AI Infrastructure Monitor', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ));

          return widgets;
        },
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${dir.path}/reports');
      if (!await reportsDir.exists()) await reportsDir.create(recursive: true);
      
      final fileName = 'Batch_Report_${projectTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${reportsDir.path}/$fileName');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: fileName);
      return file.path;
    } catch (e) {
      print('Error saving report: $e');
      return null;
    }
  }
}
