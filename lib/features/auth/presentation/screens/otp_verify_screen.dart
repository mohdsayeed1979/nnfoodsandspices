import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _sentCode;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid phone number')));
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(authRepositoryProvider).sendOtp(_phoneController.text.trim());
    setState(() => _loading = false);
    result.when(
      success: (code) {
        setState(() => _sentCode = code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demo mode — no SMS gateway configured. Your OTP is: $code')),
        );
      },
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  Future<void> _verify() async {
    if (_sentCode == null) return;
    setState(() => _loading = true);
    final result = await ref.read(authRepositoryProvider).verifyOtp(
          phone: _phoneController.text.trim(),
          code: _codeController.text.trim(),
          expectedCode: _sentCode!,
        );
    setState(() => _loading = false);
    if (!mounted) return;
    result.when(
      success: (_) => context.go(AppRoutes.home),
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.phone_android_rounded, size: 48, color: AppColors.primaryGreen),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: _sentCode == null,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 14),
              if (_sentCode == null)
                ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send OTP'),
                )
              else ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Enter 6-digit OTP', prefixIcon: Icon(Icons.password_rounded)),
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify & Continue'),
                ),
                TextButton(onPressed: () => setState(() => _sentCode = null), child: const Text('Change Number')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
