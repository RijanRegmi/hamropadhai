import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hamropadhai/core/api/api_endpoints.dart';
import 'package:hamropadhai/features/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:hamropadhai/features/auth/presentation/pages/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1 — Auto-fetches logged-in user's email and sends reset code
// ─────────────────────────────────────────────────────────────────────────────
class ResetCurrentPasswordScreen extends ConsumerStatefulWidget {
  const ResetCurrentPasswordScreen({super.key});

  @override
  ConsumerState<ResetCurrentPasswordScreen> createState() =>
      _ResetCurrentPasswordScreenState();
}

class _ResetCurrentPasswordScreenState
    extends ConsumerState<ResetCurrentPasswordScreen> {
  String? _email;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndSend());
  }

  Future<void> _loadAndSend() async {
    try {
      // Get logged-in user's profile to fetch their email
      final profile = await ref.read(profileProvider.future);
      final email = profile['email'] as String?;
      if (email == null || email.isEmpty) {
        setState(() {
          _error = 'Could not find your email address.';
        });
        return;
      }
      setState(() => _email = email);
      await _sendCode(email);
    } catch (e) {
      setState(() {
        _error = 'Failed to load your profile. Please try again.';
      });
    }
  }

  Future<void> _sendCode(String email) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiEndpoints.baseUrl}/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => _VerifyCurrentCodeScreen(email: email),
            ),
          );
        }
      } else {
        setState(() => _error = body['message'] ?? 'Failed to send code');
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F8F8);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEDED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _error!,
                      style: TextStyle(color: textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadAndSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF7C3AED),
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sending reset code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_email != null)
                      Text(
                        'A 6-digit code is being sent to\n$_email',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        'Fetching your account details...',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2 — Enter 6-digit code
// ─────────────────────────────────────────────────────────────────────────────
class _VerifyCurrentCodeScreen extends StatefulWidget {
  final String email;
  const _VerifyCurrentCodeScreen({required this.email});

  @override
  State<_VerifyCurrentCodeScreen> createState() =>
      _VerifyCurrentCodeScreenState();
}

class _VerifyCurrentCodeScreenState extends State<_VerifyCurrentCodeScreen> {
  final List<TextEditingController> _ctrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resending = false;

  String get _code => _ctrls.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.length < 6) {
      _showError('Please enter the complete 6-digit code');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http
          .post(
            Uri.parse('${ApiEndpoints.baseUrl}/verify-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': widget.email, 'code': _code}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => _SetNewCurrentPasswordScreen(
                email: widget.email,
                code: _code,
              ),
            ),
          );
        }
      } else {
        _showError(body['message'] ?? 'Invalid code');
        _clearCode();
      }
    } catch (e) {
      _showError('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final res = await http
          .post(
            Uri.parse('${ApiEndpoints.baseUrl}/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': widget.email}),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['success'] == true
                  ? 'Code resent successfully!'
                  : body['message'] ?? 'Failed to resend',
            ),
            backgroundColor: body['success'] == true
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {}
  }

  void _clearCode() {
    for (final c in _ctrls) c.clear();
    _nodes[0].requestFocus();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F8F8);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Enter Code',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock_outlined,
                color: Color(0xFF7C3AED),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Check your email',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'We sent a 6-digit code to\n${widget.email}',
              style: TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            // 6 digit boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 48,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _ctrls[i].text.isNotEmpty
                          ? const Color(0xFF7C3AED)
                          : (isDark
                                ? const Color(0xFF3E3E3E)
                                : const Color(0xFFE0E0E0)),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _ctrls[i],
                    focusNode: _nodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (v) {
                      setState(() {});
                      if (v.isNotEmpty && i < 5) {
                        _nodes[i + 1].requestFocus();
                      } else if (v.isEmpty && i > 0) {
                        _nodes[i - 1].requestFocus();
                      }
                      if (_code.length == 6) _verify();
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive the code? ",
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                GestureDetector(
                  onTap: _resending ? null : _resend,
                  child: _resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Resend',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 3 — Set new password (validates it's different from old)
// ─────────────────────────────────────────────────────────────────────────────
class _SetNewCurrentPasswordScreen extends StatefulWidget {
  final String email;
  final String code;
  const _SetNewCurrentPasswordScreen({required this.email, required this.code});

  @override
  State<_SetNewCurrentPasswordScreen> createState() =>
      _SetNewCurrentPasswordScreenState();
}

class _SetNewCurrentPasswordScreenState
    extends State<_SetNewCurrentPasswordScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPassword = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (newPassword.isEmpty) {
      _showError('Please enter a new password');
      return;
    }
    if (newPassword.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (newPassword != confirm) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await http
          .post(
            Uri.parse('${ApiEndpoints.baseUrl}/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': widget.email,
              'code': widget.code,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset! Please log in again.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } else {
        _showError(body['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      _showError('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F8F8);
    final fieldBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Password',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_outlined,
                  color: Color(0xFF7C3AED),
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Create new password',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Your new password must be different\nfrom your previous password',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 36),

            // New password field
            Text(
              'New Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newCtrl,
              obscureText: !_showNew,
              style: TextStyle(color: textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter new password',
                hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                filled: true,
                fillColor: fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 1.5,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm password field
            Text(
              'Confirm Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmCtrl,
              obscureText: !_showConfirm,
              style: TextStyle(color: textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                filled: true,
                fillColor: fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 1.5,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
