import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _authService.signInNurse(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: const Color(0xFF0E7490), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                const Text('مساعد الممرض', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('للممرضين المعتمدين فقط • Nurses Only', style: TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))]),
                  child: Column(children: [
                    TextField(
                      controller: _emailCtrl,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: Row(children: [Icon(Icons.error_outline, color: Colors.red.shade700, size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)))])),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E7490), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('يجب أن يكون حسابك مسجل كممرض في Firebase\nالاشتراكات: 24 ساعة مجانية، شهري، نصف سنوي، سنوي', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

