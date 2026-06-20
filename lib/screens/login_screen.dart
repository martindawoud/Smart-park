// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/parking_provider.dart';
import '../utils/app_theme.dart';
import 'student/student_shell.dart';
import 'admin/admin_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_idCtrl.text.trim(), _pwCtrl.text);
    if (!ok || !mounted) return;
    await context.read<ParkingProvider>().loadAll();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            auth.isAdmin ? const AdminShell() : const StudentShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FE),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Consumer<AuthProvider>(
                  builder: (_, auth, __) => Column(
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: const Icon(Icons.account_balance_rounded,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 24),
                      Text('Welcome Back',
                          style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in with your university credentials',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF546E7A)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Card
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Error banner
                                if (auth.error != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.error
                                              .withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: AppColors.error, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            auth.error!,
                                            style: const TextStyle(
                                                color: AppColors.error,
                                                fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Student ID
                                TextFormField(
                                  controller: _idCtrl,
                                  onChanged: (_) => auth.clearError(),
                                  decoration: const InputDecoration(
                                    labelText: 'Student ID',
                                    hintText: 'e.g. STU-2024001',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Student ID is required'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _pwCtrl,
                                  obscureText: _obscure,
                                  onChanged: (_) => auth.clearError(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Password is required'
                                          : null,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: 24),

                                // Sign In button
                                ElevatedButton(
                                  onPressed: auth.loading ? null : _submit,
                                  child: auth.loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5),
                                        )
                                      : const Text('Sign In'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Demo credentials
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text('Demo Credentials',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _credRow('Student', 'STU-2024001', 'pass123'),
                            const SizedBox(height: 4),
                            _credRow('Admin', 'ADM-0001', 'admin123'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Trouble signing in? Contact your administrator.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFF9E9E9E)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _credRow(String role, String id, String pw) => Row(
        children: [
          SizedBox(
              width: 56,
              child: Text(role,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF546E7A)))),
          const SizedBox(width: 8),
          Text('$id / $pw',
              style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ],
      );
}
