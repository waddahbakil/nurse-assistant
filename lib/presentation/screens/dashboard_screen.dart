import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/pdf_service.dart';
import '../../data/services/iv_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Controllers
  final _patientNameCtrl = TextEditingController();
  final _fileNumberCtrl = TextEditingController();
  String _selectedSaline = 'Normal Saline 0.9%';
  double _durationHours = 2.0;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isRunning = false;
  DateTime? _endTime;

  final _notificationService = NotificationService();
  final _pdfService = PdfService();
  final _ivService = IvService();

  final List<String> _salineTypes = [
    'Normal Saline 0.9%',
    'Dextrose 5% (D5W)',
    'Ringer Lactate',
    'Dextrose Saline (DNS)',
    'Half Normal Saline 0.45%',
    'Gelofusine',
  ];

  final _drug1Ctrl = TextEditingController();
  final _drug2Ctrl = TextEditingController();
  String? _ivCheckResult;
  bool _ivChecking = false;

  @override
  void dispose() {
    _timer?.cancel();
    _patientNameCtrl.dispose();
    _fileNumberCtrl.dispose();
    super.dispose();
  }

  void _scheduleInfusion() {
    if (_patientNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم المريض')));
      return;
    }
    final duration = Duration(minutes: (_durationHours * 60).toInt());
    _remaining = duration;
    _endTime = DateTime.now().add(duration);
    setState(() => _isRunning = true);

    // جدولة الإشعار
    _notificationService.scheduleInfusionEnd(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      patientName: _patientNameCtrl.text,
      salineType: _selectedSaline,
      after: duration,
    );

    // مؤقت عد تنازلي في الواجهة
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining.inSeconds <= 1) {
        t.cancel();
        setState(() { _isRunning = false; _remaining = Duration.zero; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('انتهى وقت محلول المريض ${_patientNameCtrl.text} 💧'), backgroundColor: const Color(0xFF0E7490)));
        }
      } else {
        setState(() => _remaining = _remaining - const Duration(seconds: 1));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم جدولة تنبيه بعد ${_formatDuration(duration)}')));
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() { _isRunning = false; _remaining = Duration.zero; _endTime = null; });
  }

  Future<void> _checkIv() async {
    if (_drug1Ctrl.text.isEmpty || _drug2Ctrl.text.isEmpty) return;
    setState(() { _ivChecking = true; _ivCheckResult = null; });
    try {
      final compatible = _ivService.isIvCompatible(_drug1Ctrl.text, _drug2Ctrl.text);
      final online = await _ivService.checkInteraction(_drug1Ctrl.text, _drug2Ctrl.text);
      setState(() {
        if (!compatible) {
          _ivCheckResult = '⛔ غير متوافق IV - لا تخلط ${_drug1Ctrl.text} مع ${_drug2Ctrl.text}';
        } else if (online.isNotEmpty) {
          _ivCheckResult = '⚠️ تحذير RxNav: ${online.first.description} [Severity: ${online.first.severity}]';
        } else {
          _ivCheckResult = '✅ لا يوجد تداخل معروف - آمن للخلط (تحقق دائماً من البروتوكول)';
        }
      });
    } catch (e) {
      setState(() => _ivCheckResult = 'خطأ في الفحص: $e');
    } finally {
      setState(() => _ivChecking = false);
    }
  }

  Future<void> _printAndShare() async {
    final record = PatientInfusionRecord(
      patientName: _patientNameCtrl.text.isEmpty ? 'Test Patient' : _patientNameCtrl.text,
      fileNumber: _fileNumberCtrl.text.isEmpty ? '0001' : _fileNumberCtrl.text,
      salineType: _selectedSaline,
      duration: _formatDuration(Duration(minutes: (_durationHours * 60).toInt())),
      startTime: DateTime.now().subtract(Duration(minutes: (_durationHours * 60).toInt())),
      endTime: _endTime ?? DateTime.now(),
      nurseName: 'Nurse User',
    );
    await _pdfService.sharePdfDirect(record);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('مساعد الممرض', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        actions: [
          IconButton(onPressed: _printAndShare, icon: const Icon(Icons.picture_as_pdf_outlined)),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.logout)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة المؤقت النشط
            if (_isRunning)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0E7490), Color(0xFF155E75)]), borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_patientNameCtrl.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_selectedSaline, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                  const SizedBox(height: 12),
                  Text(_formatDuration(_remaining), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _remaining.inSeconds / (_durationHours * 3600), backgroundColor: Colors.white24, color: Colors.white),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _cancelTimer, icon: const Icon(Icons.stop), label: const Text('إلغاء'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0E7490)))),
                ]),
              ),

            if (!_isRunning) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.06))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.water_drop, color: Color(0xFF0E7490)), SizedBox(width: 8), Text('مؤقت المحاليل الوريدية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                  const SizedBox(height: 20),
                  TextField(controller: _patientNameCtrl, decoration: InputDecoration(labelText: 'اسم المريض', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: _fileNumberCtrl, decoration: InputDecoration(labelText: 'رقم الملف (اختياري)', prefixIcon: const Icon(Icons.numbers), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedSaline,
                    items: _salineTypes.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _selectedSaline = v!),
                    decoration: InputDecoration(labelText: 'نوع المحلول', prefixIcon: const Icon(Icons.local_hospital_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('المدة', style: TextStyle(fontWeight: FontWeight.bold)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0E7490).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(_formatDuration(Duration(minutes: (_durationHours * 60).toInt())), style: const TextStyle(color: Color(0xFF0E7490), fontWeight: FontWeight.bold)))]),
                  Slider(value: _durationHours, min: 0.25, max: 12, divisions: 47, label: '${_durationHours.toStringAsFixed(1)}h', onChanged: (v) => setState(() => _durationHours = v), activeColor: const Color(0xFF0E7490)),
                  const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('15 دقيقة', style: TextStyle(fontSize: 11, color: Colors.black45)), Text('12 ساعة', style: TextStyle(fontSize: 11, color: Colors.black45))]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _scheduleInfusion,
                      icon: const Icon(Icons.alarm_add_rounded),
                      label: const Text('جدولة التنبيه وبدء المؤقت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E7490), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 16),

            // IV Checker
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.06))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.science_outlined, color: Color(0xFF7C3AED)), SizedBox(width: 8), Text('فحص تداخل المحاليل IV Checker Online', style: TextStyle(fontWeight: FontWeight.bold))]),
                const SizedBox(height: 6),
                const Text('يستخدم RxNav API للتحقق المباشر', style: TextStyle(fontSize: 11, color: Colors.black45)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextField(controller: _drug1Ctrl, decoration: InputDecoration(hintText: 'دواء 1 مثل Ceftriaxone', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _drug2Ctrl, decoration: InputDecoration(hintText: 'دواء 2 مثل Calcium', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true))),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _ivChecking ? null : _checkIv, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), elevation: 0), child: _ivChecking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('فحص الآن - RxNav')),
                ),
                if (_ivCheckResult != null) ...[
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _ivCheckResult!.startsWith('✅') ? Colors.green.shade50 : _ivCheckResult!.startsWith('⛔') ? Colors.red.shade50 : Colors.amber.shade50, borderRadius: BorderRadius.circular(12)), child: Text(_ivCheckResult!, style: const TextStyle(fontSize: 13))),
                ],
              ]),
            ),

            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _printAndShare, icon: const Icon(Icons.print), label: const Text('طباعة PDF'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: _printAndShare, icon: const Icon(Icons.share), label: const Text('واتساب'))),
            ]),
          ],
        ),
      ),
    );
  }
}

