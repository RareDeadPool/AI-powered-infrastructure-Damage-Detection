import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/detector_service.dart';
import '../services/report_service.dart';
import '../models/recognition.dart';

class PhotoResult {
  final String imagePath;
  final List<Recognition> detections;
  String note;

  PhotoResult({
    required this.imagePath,
    required this.detections,
    this.note = '',
  });
}

class PhotoBatchScreen extends StatefulWidget {
  final String projectTitle;
  final String location;

  const PhotoBatchScreen({
    super.key,
    required this.projectTitle,
    required this.location,
  });

  @override
  State<PhotoBatchScreen> createState() => _PhotoBatchScreenState();
}

class _PhotoBatchScreenState extends State<PhotoBatchScreen> {
  final DetectorService _detector = DetectorService();
  CameraController? _cam;
  bool _cameraReady = false;

  bool _isAnalysing = false;
  List<Recognition> _liveDetections = [];
  DateTime? _lastInferenceTime;

  final List<PhotoResult> _captures = [];
  bool _isCapturing = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cam?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    await _detector.init();
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cam = CameraController(cameras[0], ResolutionPreset.high,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);

    await _cam!.initialize();
    _cam!.startImageStream(_onFrame);

    if (mounted) setState(() => _cameraReady = true);
  }

  void _onFrame(CameraImage img) {
    if (_isCapturing) return;
    final now = DateTime.now();
    if (_lastInferenceTime != null &&
        now.difference(_lastInferenceTime!).inMilliseconds < 120) return;
    _lastInferenceTime = now;
    if (_isAnalysing) return;
    _isAnalysing = true;
    _detector.predictCameraFrame(img).then((results) {
      _isAnalysing = false;
      if (mounted) setState(() => _liveDetections = results);
    });
  }

  Future<void> _captureFrame() async {
    if (_cam == null || _isCapturing || _isGenerating) return;
    setState(() => _isCapturing = true);

    try {
      final currentDetections = List<Recognition>.from(_liveDetections);
      final xFile = await _cam!.takePicture();

      setState(() {
        _captures.add(PhotoResult(
          imagePath: xFile.path,
          detections: currentDetections,
        ));
        _isCapturing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          currentDetections.isEmpty
              ? 'Frame captured — no damage found.'
              : 'Detection saved: ${currentDetections.length} anomaly types identified.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ));
    } catch (e) {
      setState(() => _isCapturing = false);
    }
  }

  void _removeCapture(int index) {
    setState(() => _captures.removeAt(index));
  }

  Future<void> _confirmAndGenerate() async {
    if (_captures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add at least one capture to generate a report.'),
          backgroundColor: AppColors.severityHigh));
      return;
    }

    final totalDmg = _captures.fold(0, (s, c) => s + c.detections.length);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2D5096)),
          const SizedBox(width: 12),
          Text('Batch Report Export', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(Icons.engineering_rounded, 'Project', widget.projectTitle),
            const SizedBox(height: 8),
            _row(Icons.location_on_rounded, 'Location', widget.location),
            const SizedBox(height: 8),
            _row(Icons.camera_alt_rounded, 'Total Captures', '${_captures.length}'),
            const SizedBox(height: 8),
            _row(Icons.warning_amber_rounded, 'Total Anomalies', '$totalDmg detected'),
            const SizedBox(height: 16),
            Text(
              'A batch PDF will be generated containing all annotated frames and detailed detection logs.',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6E7C91), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Keep Editing', style: GoogleFonts.outfit(color: const Color(0xFF7B8EA7)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5096),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Generate PDF', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isGenerating = true);
    try {
      await ReportService.generateBatchReport(
        projectTitle: widget.projectTitle,
        location: widget.location,
        photoResults: _captures,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e'),
              backgroundColor: AppColors.severityHigh));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.projectTitle,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Text('Project-Based Batch Scanning',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          if (_captures.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _isGenerating 
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : TextButton.icon(
                    onPressed: _confirmAndGenerate,
                    icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 20),
                    label: Text('EXPORT (${_captures.length})',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 7,
            child: LayoutBuilder(builder: (ctx, constraints) {
              return Stack(
                children: [
                  if (_cameraReady)
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1 / _cam!.value.aspectRatio,
                        child: CameraPreview(_cam!),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator(color: Colors.white)),

                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BatchDetectionPainter(recognitions: _liveDetections),
                    ),
                  ),

                  Positioned(
                    top: 16, right: 16,
                    child: _badge(
                      _isCapturing ? '📷 SAVING...' : '● AI SCANNING LIVE',
                      _isCapturing ? const Color(0xFFF38020) : Colors.redAccent,
                    ),
                  ),

                  if (_captures.isNotEmpty)
                    Positioned(
                      top: 16, left: 16,
                      child: _badge('${_captures.length} captures', const Color(0xFF2D5096)),
                    ),

                  Positioned(
                    bottom: 30, left: 0, right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _isCapturing || _isGenerating ? null : _captureFrame,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: _isCapturing ? 65 : 75,
                          height: _isCapturing ? 65 : 75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFF38020), width: 5),
                            boxShadow: [
                              BoxShadow(color: Colors.black45, blurRadius: 15, spreadRadius: 2)
                            ],
                          ),
                          child: Icon(
                            _isCapturing ? Icons.hourglass_empty_rounded : Icons.camera_rounded,
                            color: const Color(0xFF2D5096),
                            size: 35,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),

          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: _captures.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, size: 48, color: Color(0xFFCBD5E0)),
                        const SizedBox(height: 12),
                        Text(
                          'Scan infrastructure and capture frames.\nEach detection will be added to the report.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: const Color(0xFF7B8EA7), fontSize: 13, height: 1.5),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SESSION CAPTURES',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF1D2B40), letterSpacing: 1),
                              ),
                              Text('${_captures.length} items', style: GoogleFonts.outfit(color: const Color(0xFF7B8EA7), fontSize: 12)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _captures.length,
                            itemBuilder: (ctx, i) => _FrameTile(
                              index: i,
                              result: _captures[i],
                              onRemove: () => _removeCapture(i),
                              onNoteChanged: (n) => setState(() => _captures[i].note = n),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(children: [
    Icon(icon, size: 16, color: const Color(0xFF2D5096)),
    const SizedBox(width: 8),
    Text('$label: ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1D2B40))),
    Expanded(child: Text(value, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6E7C91)), overflow: TextOverflow.ellipsis)),
  ]);

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
  );
}

class _FrameTile extends StatefulWidget {
  final int index;
  final PhotoResult result;
  final VoidCallback onRemove;
  final ValueChanged<String> onNoteChanged;

  const _FrameTile({
    required this.index,
    required this.result,
    required this.onRemove,
    required this.onNoteChanged,
  });

  @override
  State<_FrameTile> createState() => _FrameTileState();
}

class _FrameTileState extends State<_FrameTile> {
  Color _color(double score) {
    if (score > 0.7) return AppColors.severityHigh;
    if (score > 4.0) return AppColors.severityMedium;
    return AppColors.severityLow;
  }

  void _showDetail(BuildContext ctx) {
    final r = widget.result;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Capture Detail', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Photo #${widget.index + 1}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: () { Navigator.pop(ctx); widget.onRemove(); },
            ),
          ]),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(File(r.imagePath), height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          Text('AI ANALYSIS RESULTS', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFF38020), letterSpacing: 1)),
          const SizedBox(height: 12),
          if (r.detections.isEmpty)
            Text('No anomalies detected in this frame.', style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.w500))
          else
            ...r.detections.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.warning_rounded, size: 18, color: _color(d.score)),
                const SizedBox(width: 12),
                Expanded(child: Text(d.label.toUpperCase().replaceAll('_',' '),
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40)))),
                Text('${(d.score * 100).toStringAsFixed(0)}% CONFIDENCE',
                    style: GoogleFonts.outfit(fontSize: 11, color: _color(d.score), fontWeight: FontWeight.bold)),
              ]),
            )),
          const SizedBox(height: 24),
          TextField(
            controller: TextEditingController(text: r.note),
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Inspector Annotations',
              labelStyle: GoogleFonts.outfit(color: const Color(0xFF2D5096)),
              hintText: 'Add manual observation details here...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: widget.onNoteChanged,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final hasDmg = r.detections.isNotEmpty;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12, bottom: 12, top: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(r.imagePath), fit: BoxFit.cover),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Capture #${widget.index + 1}',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      hasDmg ? '${r.detections.length} ANOMALIES' : 'CLEAR FRAME',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: hasDmg ? const Color(0xFFF38020) : const Color(0xFF4ED39A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]),
                ),
              ),
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchDetectionPainter extends CustomPainter {
  final List<Recognition> recognitions;
  _BatchDetectionPainter({required this.recognitions});

  Color _col(double score) {
    if (score > 0.7) return AppColors.severityHigh;
    if (score > 0.4) return AppColors.severityMedium;
    return AppColors.severityLow;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3.5;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (final rec in recognitions) {
      final rect = Rect.fromLTRB(
        rec.location.left * size.width,
        rec.location.top * size.height,
        rec.location.right * size.width,
        rec.location.bottom * size.height,
      );
      paint.color = _col(rec.score);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);

      final label = '${rec.label.toUpperCase()}  ${(rec.score * 100).toStringAsFixed(0)}%';
      tp.text = TextSpan(text: label,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold));
      tp.layout();

      final bg = Rect.fromLTWH(rect.left, rect.top - tp.height - 8,
          tp.width + 12, tp.height + 8);
      canvas.drawRRect(RRect.fromRectAndRadius(bg, const Radius.circular(6)),
          Paint()..color = paint.color.withOpacity(0.9));
      tp.paint(canvas, Offset(rect.left + 6, rect.top - tp.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant _BatchDetectionPainter old) => true;
}
