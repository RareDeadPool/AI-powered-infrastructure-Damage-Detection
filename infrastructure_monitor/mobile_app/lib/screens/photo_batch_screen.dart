import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/constants.dart';
import '../services/detector_service.dart';
import '../services/report_service.dart';
import '../models/recognition.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model – one captured frame with its detections + optional note
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
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

  // Live inference state
  bool _isAnalysing = false;
  List<Recognition> _liveDetections = [];
  DateTime? _lastInferenceTime;

  // Captured batch
  final List<PhotoResult> _captures = [];
  bool _isCapturing = false;   // busy capturing a still frame
  bool _isGenerating = false;  // busy building the PDF

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

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    await _detector.init();
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cam = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);

    await _cam!.initialize();
    _cam!.startImageStream(_onFrame);

    if (mounted) setState(() => _cameraReady = true);
  }

  void _onFrame(CameraImage img) {
    if (_isCapturing) return;
    final now = DateTime.now();
    if (_lastInferenceTime != null &&
        now.difference(_lastInferenceTime!).inMilliseconds < 100) return;
    _lastInferenceTime = now;
    if (_isAnalysing) return;
    _isAnalysing = true;
    _detector.predictCameraFrame(img).then((results) {
      _isAnalysing = false;
      if (mounted) setState(() => _liveDetections = results);
    });
  }

  // ── Capture a frame ───────────────────────────────────────────────────────

  Future<void> _captureFrame() async {
    if (_cam == null || _isCapturing || _isGenerating) return;
    setState(() => _isCapturing = true);

    try {
      // Snapshot with current live detections (copy before anything changes)
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
              ? 'Frame captured — no damage detected.'
              : 'Captured! ${currentDetections.length} detection(s) saved.',
        ),
        backgroundColor:
            currentDetections.isEmpty ? Colors.green : AppColors.secondary,
        duration: const Duration(seconds: 1),
      ));
    } catch (e) {
      setState(() => _isCapturing = false);
    }
  }

  void _removeCapture(int index) {
    setState(() => _captures.removeAt(index));
  }

  // ── Confirm + generate PDF ────────────────────────────────────────────────

  Future<void> _confirmAndGenerate() async {
    if (_captures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Capture at least one frame first.'),
          backgroundColor: AppColors.severityHigh));
      return;
    }

    final totalDmg = _captures.fold(0, (s, c) => s + c.detections.length);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.picture_as_pdf, color: AppColors.primary),
          SizedBox(width: 10),
          Text('Generate Batch Report?'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(Icons.engineering, 'Project', widget.projectTitle),
            const SizedBox(height: 6),
            _row(Icons.location_on, 'Location', widget.location),
            const SizedBox(height: 6),
            _row(Icons.camera, 'Frames captured', '${_captures.length}'),
            const SizedBox(height: 6),
            _row(Icons.warning_amber, 'Total damages', '$totalDmg detected'),
            const SizedBox(height: 14),
            const Text(
              'Each captured frame will appear as an annotated section in the PDF with its detection table.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
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
          SnackBar(content: Text('Report failed: $e'),
              backgroundColor: AppColors.severityHigh));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.projectTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Text('Batch capture mode',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
          ],
        ),
        actions: [
          if (_captures.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _isGenerating ? null : _confirmAndGenerate,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                label: Text('Report (${_captures.length})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Camera viewport ─────────────────────────────────────────────
          Expanded(
            flex: 6,
            child: LayoutBuilder(builder: (ctx, constraints) {
              final size = constraints.maxWidth;
              return Container(
                width: size,
                height: size,
                color: Colors.black,
                child: Stack(
                  children: [
                    // Preview
                    if (_cameraReady)
                      Center(
                        child: AspectRatio(
                          aspectRatio: 1 / _cam!.value.aspectRatio,
                          child: CameraPreview(_cam!),
                        ),
                      )
                    else
                      const Center(
                          child: CircularProgressIndicator(color: AppColors.primary)),

                    // Live bounding boxes
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BatchDetectionPainter(recognitions: _liveDetections),
                      ),
                    ),

                    // Status badge
                    Positioned(
                      top: 14, right: 14,
                      child: _badge(
                        _isCapturing
                            ? '📷 CAPTURING…'
                            : '● LIVE SCANNING',
                        _isCapturing ? AppColors.secondary : Colors.red,
                      ),
                    ),

                    // Frame counter badge
                    if (_captures.isNotEmpty)
                      Positioned(
                        top: 14, left: 14,
                        child: _badge('${_captures.length} frames', AppColors.primary),
                      ),

                    // Capture button (centred at bottom of viewport)
                    Positioned(
                      bottom: 20, left: 0, right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _isCapturing || _isGenerating ? null : _captureFrame,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: _isCapturing ? 68 : 72,
                            height: _isCapturing ? 68 : 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCapturing
                                  ? AppColors.secondary
                                  : Colors.white,
                              border: Border.all(
                                  color: AppColors.secondary, width: 4),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 12)
                              ],
                            ),
                            child: Icon(
                              _isCapturing ? Icons.hourglass_top : Icons.camera,
                              color: _isCapturing ? Colors.white : AppColors.primary,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // ── Captured frames strip ────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey.shade100,
              child: _captures.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_enhance_outlined,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the shutter to capture frames.\nAll captures will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_captures.length} Frame(s) Captured',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (_isGenerating)
                                const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _captures.length,
                            itemBuilder: (ctx, i) =>
                                _FrameTile(
                                  index: i,
                                  result: _captures[i],
                                  onRemove: () => _removeCapture(i),
                                  onNoteChanged: (n) =>
                                      setState(() => _captures[i].note = n),
                                ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(children: [
    Icon(icon, size: 15, color: AppColors.primary),
    const SizedBox(width: 6),
    Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
  ]);

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.88),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal frame tile (captured frames strip)
// ─────────────────────────────────────────────────────────────────────────────
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
    if (score > 0.4) return AppColors.severityMedium;
    return AppColors.severityLow;
  }

  void _showDetail(BuildContext ctx) {
    final r = widget.result;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Frame ${widget.index + 1}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () { Navigator.pop(ctx); widget.onRemove(); },
            ),
          ]),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(File(r.imagePath), height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          if (r.detections.isEmpty)
            const Text('✅ No damage detected', style: TextStyle(color: Colors.green))
          else ...[
            Text('${r.detections.length} detection(s):',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...r.detections.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(Icons.circle, size: 8, color: _color(d.score)),
                const SizedBox(width: 6),
                Expanded(child: Text(d.label.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                Text('${(d.score * 100).toStringAsFixed(1)}% · ${d.severity}',
                    style: TextStyle(fontSize: 12, color: _color(d.score))),
              ]),
            )),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: r.note),
            decoration: InputDecoration(
              labelText: 'Inspector note',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: widget.onNoteChanged,
            maxLines: 2,
          ),
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
        width: 110,
        margin: const EdgeInsets.only(right: 10, bottom: 8, top: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasDmg
                ? AppColors.severityHigh.withOpacity(0.5)
                : Colors.green.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(r.imagePath), fit: BoxFit.cover),
              // Overlay
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Frame ${widget.index + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(
                      hasDmg ? '⚠ ${r.detections.length} dmg' : '✓ Clear',
                      style: TextStyle(
                        fontSize: 9,
                        color: hasDmg ? Colors.orangeAccent : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]),
                ),
              ),
              // Remove X
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 12),
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

// ─────────────────────────────────────────────────────────────────────────────
// Bounding box painter (reused from InspectionScreen)
// ─────────────────────────────────────────────────────────────────────────────
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
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3.0;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (final rec in recognitions) {
      final rect = Rect.fromLTRB(
        rec.location.left * size.width,
        rec.location.top * size.height,
        rec.location.right * size.width,
        rec.location.bottom * size.height,
      );
      paint.color = _col(rec.score);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);

      final label = '${rec.label.toUpperCase()}  ${(rec.score * 100).toStringAsFixed(0)}%';
      tp.text = TextSpan(text: label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold));
      tp.layout();

      final bg = Rect.fromLTWH(rect.left, rect.top - tp.height - 6,
          tp.width + 10, tp.height + 6);
      canvas.drawRRect(RRect.fromRectAndRadius(bg, const Radius.circular(4)),
          Paint()..color = paint.color);
      tp.paint(canvas, Offset(rect.left + 5, rect.top - tp.height - 3));
    }
  }

  @override
  bool shouldRepaint(covariant _BatchDetectionPainter old) => true;
}
