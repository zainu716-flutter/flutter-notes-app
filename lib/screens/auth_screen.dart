import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as ap;

enum _AuthMode { login, signup, forgotPassword }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  _AuthMode _mode = _AuthMode.login;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _confirmCtrl.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: Stack(
        children: [
          // ── Animated background orbs ──────────────────────────────────────
          _AnimatedBackground(controller: _bgController),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(48),

                  // Logo & title
                  _buildHeader(),

                  const Gap(48),

                  // Form card
                  _buildFormCard(auth),

                  const Gap(24),

                  // Bottom link
                  _buildBottomLink(),

                  const Gap(40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8A87C), Color(0xFFE87C9A)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8A87C).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.notes_rounded, color: Colors.white, size: 28),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.5, 0.5)),

        const Gap(20),

        Text(
          _mode == _AuthMode.login
              ? 'Welcome\nback'
              : _mode == _AuthMode.signup
                  ? 'Create\naccount'
                  : 'Reset\npassword',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

        const Gap(8),

        Text(
          _mode == _AuthMode.login
              ? 'Sign in to access your notes'
              : _mode == _AuthMode.signup
                  ? 'Start organizing your thoughts'
                  : 'We\'ll send you a reset link',
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 15,
          ),
        ).animate().fadeIn(delay: 150.ms),
      ],
    );
  }

  Widget _buildFormCard(ap.AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field (signup only)
          if (_mode == _AuthMode.signup) ...[
            _buildField(
              controller: _nameCtrl,
              hint: 'Full Name',
              icon: Icons.person_rounded,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
            const Gap(14),
          ],

          // Email
          _buildField(
            controller: _emailCtrl,
            hint: 'Email address',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),

          // Password (not for forgot)
          if (_mode != _AuthMode.forgotPassword) ...[
            const Gap(14),
            _buildField(
              controller: _passwordCtrl,
              hint: 'Password',
              icon: Icons.lock_rounded,
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
          ],

          // Confirm password (signup only)
          if (_mode == _AuthMode.signup) ...[
            const Gap(14),
            _buildField(
              controller: _confirmCtrl,
              hint: 'Confirm Password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
          ],

          // Forgot password link (login only)
          if (_mode == _AuthMode.login) ...[
            const Gap(12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  auth.clearError();
                  setState(() => _mode = _AuthMode.forgotPassword);
                },
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE8A87C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          // Error message
          if (auth.errorMessage != null) ...[
            const Gap(16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 16),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      auth.errorMessage!,
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).shake(),
          ],

          // Success message (for forgot password)
          if (_mode == _AuthMode.forgotPassword &&
              auth.status == ap.AuthStatus.success) ...[
            const Gap(16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.greenAccent, size: 16),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'Reset link sent! Check your email.',
                      style: GoogleFonts.inter(
                        color: Colors.greenAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
          ],

          const Gap(24),

          // Submit button
          _buildSubmitButton(auth),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15);
  }

  Widget _buildSubmitButton(ap.AuthProvider auth) {
    final isLoading = auth.status == ap.AuthStatus.loading;

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: isLoading ? null : () => _handleSubmit(auth),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: isLoading
                ? LinearGradient(colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.1),
                  ])
                : const LinearGradient(
                    colors: [Color(0xFFE8A87C), Color(0xFFE87C9A)],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFFE8A87C).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : Text(
                    _mode == _AuthMode.login
                        ? 'Sign In'
                        : _mode == _AuthMode.signup
                            ? 'Create Account'
                            : 'Send Reset Link',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomLink() {
    if (_mode == _AuthMode.forgotPassword) {
      return Center(
        child: GestureDetector(
          onTap: () {
            context.read<ap.AuthProvider>().clearError();
            setState(() => _mode = _AuthMode.login);
          },
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
              children: [
                const TextSpan(text: 'Remember your password? '),
                TextSpan(
                  text: 'Sign In',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE8A87C),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 300.ms);
    }

    return Center(
      child: GestureDetector(
        onTap: () {
          context.read<ap.AuthProvider>().clearError();
          setState(() {
            _mode =
                _mode == _AuthMode.login ? _AuthMode.signup : _AuthMode.login;
            _passwordCtrl.clear();
            _confirmCtrl.clear();
          });
        },
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
            children: [
              TextSpan(
                text: _mode == _AuthMode.login
                    ? "Don't have an account? "
                    : 'Already have an account? ',
              ),
              TextSpan(
                text: _mode == _AuthMode.login ? 'Sign Up' : 'Sign In',
                style: GoogleFonts.inter(
                  color: const Color(0xFFE8A87C),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38),
        prefixIcon:
            Icon(icon, color: const Color(0xFFE8A87C).withOpacity(0.7), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8A87C), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Future<void> _handleSubmit(ap.AuthProvider auth) async {
    FocusScope.of(context).unfocus();

    if (_mode == _AuthMode.login) {
      if (_emailCtrl.text.trim().isEmpty ||
          _passwordCtrl.text.trim().isEmpty) {
        return;
      }
      await auth.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    } else if (_mode == _AuthMode.signup) {
      if (_nameCtrl.text.trim().isEmpty ||
          _emailCtrl.text.trim().isEmpty ||
          _passwordCtrl.text.trim().isEmpty) {
        return;
      }
      if (_passwordCtrl.text != _confirmCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passwords do not match',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
      await auth.signUp(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        name: _nameCtrl.text,
      );
    } else {
      if (_emailCtrl.text.trim().isEmpty) return;
      await auth.sendPasswordReset(email: _emailCtrl.text);
    }
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(
          children: [
            Positioned(
              right: -60 + (t * 30),
              top: -60 + (t * 20),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE8A87C).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -80 + (t * 20),
              bottom: 100 + (t * 40),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C83E8).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 40 + (t * 15),
              bottom: 200 + (t * 30),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE87C9A).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
