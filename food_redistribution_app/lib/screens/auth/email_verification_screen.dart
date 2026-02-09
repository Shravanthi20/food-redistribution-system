import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/app_router.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isCheckingVerification = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (await authProvider.isEmailVerified) {
      Navigator.pushReplacementNamed(context, AppRouter.splash);
    }
  }

  Future<void> _resendVerification() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.resendEmailVerification();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isCheckingVerification = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (await authProvider.isEmailVerified) {
      Navigator.pushReplacementNamed(context, AppRouter.splash);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet. Please check your email.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    setState(() => _isCheckingVerification = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading || _isCheckingVerification,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Verify Your Email',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'We\'ve sent a verification email to:',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    authProvider.firebaseUser?.email ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Please check your email and click the verification link to continue.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _checkVerification,
                    child: const Text('I\'ve Verified My Email'),
                  ),
                  const SizedBox(height: 16),
                  
                  OutlinedButton(
                    onPressed: _resendVerification,
                    child: const Text('Resend Verification Email'),
                  ),
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () async {
                      await authProvider.signOut();
                      Navigator.pushReplacementNamed(context, AppRouter.login);
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
