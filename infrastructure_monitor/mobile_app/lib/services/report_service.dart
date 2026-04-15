import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
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

  static Future<void> generateAndShareReport({
    required String projectTitle,
    required String location,
    required List<Recognition> detections,
    required String imagePath,
    double? lat,
    double? lng,
  }) async {
    final date = DateFormat('yyyy-MM-dd  HH:mm').format(DateTime.now());

    // Annotate the image before building the PDF
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
            // ── Header ──────────────────────────────────────────────────────
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Infrastructure Damage Report',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    date,
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ── Project Info ─────────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(children: [
                    pw.Text('Project: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(projectTitle),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    pw.Text('Location: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(location),
                  ]),
                  pw.SizedBox(height: 4),
                  if (lat != null && lng != null) ...[
                    pw.Row(children: [
                      pw.Text('GPS Coordinates: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(LocationHelper.formatToCardinal(lat, lng), style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue700)),
                    ]),
                    pw.SizedBox(height: 4),
                  ],
                  pw.Row(children: [
                    pw.Text('Detections: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${detections.length} damage type(s) found'),
                  ]),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ── Annotated Evidence Image ────────────────────────────────────
            pw.Text(
              'Visual Evidence  (detections annotated)',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Container(
                height: 310,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ),
            ),

            pw.SizedBox(height: 24),

            // ── Detection Summary Table ────────────────────────────────────
            pw.Text(
              'Detection Summary',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                  children: [
                    _cell('Damage Type', bold: true),
                    _cell('Confidence', bold: true),
                    _cell('Severity', bold: true),
                  ],
                ),
                // Data rows
                ...detections.map((d) => pw.TableRow(
                  children: [
                    _cell(d.label.replaceAll('_', ' ').toUpperCase()),
                    _cell('${(d.score * 100).toStringAsFixed(1)}%'),
                    _cell(d.severity),
                  ],
                )),
              ],
            ),

            pw.SizedBox(height: 36),

            // ── Footer ────────────────────────────────────────────────────
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated by AI Infrastructure Monitor  •  $date',
              style: pw.TextStyle(
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Damage_Report_${projectTitle.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : const pw.TextStyle(),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Batch Report — multiple photos each with their own annotated section
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> generateBatchReport({
    required String projectTitle,
    required String location,
    required List<PhotoResult> photoResults,
  }) async {
    final date = DateFormat('yyyy-MM-dd  HH:mm').format(DateTime.now());
    final pdf = pw.Document();

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

          // ── Report Header ──────────────────────────────────────────────────
          widgets.add(pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Infrastructure Batch Inspection Report',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text(date,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ));

          widgets.add(pw.SizedBox(height: 14));

          // ── Project Summary Box ────────────────────────────────────────────
          widgets.add(pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(children: [
                pw.Text('Project: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(projectTitle),
              ]),
              pw.SizedBox(height: 4),
              pw.Row(children: [
                pw.Text('Location: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(location),
              ]),
              pw.SizedBox(height: 4),
              pw.Row(children: [
                pw.Text('Photos inspected: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('${photoResults.length}'),
              ]),
              pw.SizedBox(height: 4),
              pw.Row(children: [
                pw.Text('Total damages found: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('$totalDetections'),
              ]),
            ]),
          ));

          widgets.add(pw.SizedBox(height: 24));

          // ── Per-photo sections ─────────────────────────────────────────────
          for (int i = 0; i < photoResults.length; i++) {
            final pr = photoResults[i];
            final detections = pr.detections;
            final note = pr.note;

            widgets.add(pw.Container(
              padding: const pw.EdgeInsets.all(14),
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [

                // Section title
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Photo ${i + 1}',
                        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      detections.isEmpty ? '✓ No damage' : '⚠ ${detections.length} damage(s)',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: detections.isEmpty ? PdfColors.green700 : PdfColors.red700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // Geo-Tag (North, East, West, South format)
                if (pr.lat != null && pr.lng != null)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey50,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Row(children: [
                      pw.Text('GPS Coordinates: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(LocationHelper.formatToCardinal(pr.lat!, pr.lng!), style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue900)),
                    ]),
                  ),

                // Annotated image
                pw.Center(
                  child: pw.Container(
                    height: 260,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 6,
                      verticalRadius: 6,
                      child: pw.Image(annotatedImages[i], fit: pw.BoxFit.contain),
                    ),
                  ),
                ),

                // Inspector note
                if (note.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Row(children: [
                      pw.Text('Note: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Flexible(child: pw.Text(note, style: const pw.TextStyle(fontSize: 11))),
                    ]),
                  ),
                ],

                // Detection table
                if (detections.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Text('Detections',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                        children: [
                          _cell('Damage Type', bold: true),
                          _cell('Confidence', bold: true),
                          _cell('Severity', bold: true),
                        ],
                      ),
                      ...detections.map((d) => pw.TableRow(children: [
                        _cell(d.label.replaceAll('_', ' ').toUpperCase()),
                        _cell('${(d.score * 100).toStringAsFixed(1)}%'),
                        _cell(d.severity),
                      ])),
                    ],
                  ),
                ],
              ]),
            ));
          }

          // ── Footer ─────────────────────────────────────────────────────────
          widgets.add(pw.Divider(color: PdfColors.grey300));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(pw.Text(
            'Generated by AI Infrastructure Monitor  •  $date',
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
          ));

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Batch_Report_${projectTitle.replaceAll(' ', '_')}.pdf',
    );
  }
}
