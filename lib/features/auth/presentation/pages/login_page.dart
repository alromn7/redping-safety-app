import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/auth_user.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/app_service_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// Load saved credentials if remember me was enabled
  Future<void> _loadSavedCredentials() async {
    try {
      final savedEmail = await AuthService.instance.getSavedEmail();
      final rememberMe = await AuthService.instance.isRememberMeEnabled();

      if (savedEmail != null && mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = rememberMe;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      await AuthService.instance.signInWithEmailAndPassword(request);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Signed in successfully!'),
            backgroundColor: AppTheme.safeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate directly to main dashboard
        context.go('/main');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.message}'),
            backgroundColor: AppTheme.criticalRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ An unexpected error occurred: $e'),
            backgroundColor: AppTheme.criticalRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter your email address first'),
          backgroundColor: AppTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final request = PasswordResetRequest(email: _emailController.text.trim());

      await AuthService.instance.sendPasswordResetEmail(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Password reset email sent!'),
            backgroundColor: AppTheme.safeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.message}'),
            backgroundColor: AppTheme.criticalRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // cancelled
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final res = await FirebaseAuth.instance.signInWithCredential(credential);
      final fb = res.user;
      if (fb != null) {
        final adopted = AuthUser(
          id: fb.uid,
          email: fb.email ?? '',
          displayName: fb.displayName ?? (fb.email?.split('@').first ?? 'User'),
          photoUrl: fb.photoURL,
          phoneNumber: fb.phoneNumber,
          isEmailVerified: fb.emailVerified,
          createdAt: fb.metadata.creationTime ?? DateTime.now(),
          lastSignIn: fb.metadata.lastSignInTime ?? DateTime.now(),
        );
        await AuthService.instance.adoptExternalUser(
          adopted,
          rememberEmail: true,
        );
        // Ensure user profile is created/loaded and available app-wide
        try {
          await AppServiceManager().profileService.refreshFromAuth();
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Signed in with Google')),
          );
          context.go('/main');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Google sign-in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // If there's nothing to pop, go to home
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        bottom: true, // Ensure bottom safe area is respected
        child: SingleChildScrollView(
          // Add scrolling to handle overflow
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and title - Keep large logo size
                const SizedBox(height: 8), // Minimal top space
                Container(
                  height: 130, // Keep the large logo size as requested
                  width: double.infinity, // Full width to allow logo expansion
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/REDP!NG.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Minimal spacing

                Text(
                  'Sign in to your REDP!NG account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16), // Reduced from 20 to save space
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.darkSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ), // Reduced padding
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10), // Further reduced from 12
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.darkSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ), // Reduced padding
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6), // Further reduced from 8
                // Remember me and forgot password - Made more compact
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() => _rememberMe = value ?? false);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text('Remember me', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    TextButton(
                      onPressed: _handleForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Reduced from 16
                // Sign in button
                SizedBox(
                  height: 48, // Reduced from 56
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16), // Reduced spacing before divider
                // Divider - More compact
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),

                // Google Sign-In Button - Official Branding
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: const BorderSide(
                        color: Color(0xFFDDDDDD),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Logo - increased by 75% (20 -> 35)
                        Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          height: 35,
                          width: 35,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 35,
                              width: 35,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Icon(
                                Icons.g_mobiledata,
                                size: 35,
                                color: Color(0xFF4285F4),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3C4043),
                            letterSpacing: 0.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Sign up button - more compact
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => context.push('/signup'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryRed),
                      foregroundColor: AppTheme.primaryRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Signup Free',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ), // Increased bottom spacing to prevent cutoff
              ],
            ),
          ),
        ),
      ),
    );
  }
}
