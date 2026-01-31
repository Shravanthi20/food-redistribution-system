import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

// RBAC Middleware for protecting routes and widgets
class RBACMiddleware {
  static final UserService _userService = UserService();
  static final AuthService _authService = AuthService();

  // Route guard - check if user can access route
  static Future<bool> canAccessRoute(String routeName, UserRole? userRole) async {
    if (userRole == null) return false;

    // Admin routes
    if (routeName.startsWith('/admin/')) {
      return userRole == UserRole.admin;
    }

    // Role-specific routes
    switch (routeName) {
      case '/donor/dashboard':
        return userRole == UserRole.donor || userRole == UserRole.admin;
      case '/ngo/dashboard':
        return userRole == UserRole.ngo || userRole == UserRole.admin;
      case '/volunteer/dashboard':
        return userRole == UserRole.volunteer || userRole == UserRole.admin;
      default:
        return true; // Public routes
    }
  }

  // Widget-level access control
  static Future<Widget> protectedWidget({
    required Widget child,
    required List<UserRole> allowedRoles,
    Widget? fallback,
  }) async {
    final user = await _authService.getCurrentUser();
    if (user == null) {
      return fallback ?? const UnauthorizedWidget();
    }

    if (allowedRoles.contains(user.role) || user.role == UserRole.admin) {
      return child;
    }

    return fallback ?? const UnauthorizedWidget();
  }
}

// Protected Route Widget
class ProtectedRoute extends StatefulWidget {
  final Widget child;
  final List<UserRole> allowedRoles;
  final Widget? unauthorizedWidget;
  final String? routeName;

  const ProtectedRoute({
    Key? key,
    required this.child,
    required this.allowedRoles,
    this.unauthorizedWidget,
    this.routeName,
  }) : super(key: key);

  @override
  State<ProtectedRoute> createState() => _ProtectedRouteState();
}

class _ProtectedRouteState extends State<ProtectedRoute> {
  bool isLoading = true;
  bool isAuthorized = false;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user == null) {
        setState(() {
          isLoading = false;
          isAuthorized = false;
        });
        return;
      }

      // Check if user is suspended
      final isSuspended = await UserService().isUserSuspended(user.id);
      if (isSuspended) {
        setState(() {
          isLoading = false;
          isAuthorized = false;
          currentUser = user;
        });
        return;
      }

      // Check role authorization
      final hasAccess = widget.allowedRoles.contains(user.role) || user.role == UserRole.admin;
      
      setState(() {
        isLoading = false;
        isAuthorized = hasAccess;
        currentUser = user;
      });
    } catch (e) {
      print('Error checking authorization: $e');
      setState(() {
        isLoading = false;
        isAuthorized = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!isAuthorized) {
      return widget.unauthorizedWidget ?? 
        UnauthorizedWidget(
          currentUser: currentUser,
          requiredRoles: widget.allowedRoles,
        );
    }

    return widget.child;
  }
}

// Unauthorized access widget
class UnauthorizedWidget extends StatelessWidget {
  final User? currentUser;
  final List<UserRole>? requiredRoles;

  const UnauthorizedWidget({
    Key? key,
    this.currentUser,
    this.requiredRoles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String message = 'You are not authorized to access this page.';
    String? suggestion;

    if (currentUser == null) {
      message = 'Please log in to access this page.';
      suggestion = 'Log in to continue';
    } else if (currentUser!.status == UserStatus.suspended) {
      message = 'Your account has been suspended.';
      suggestion = 'Contact support for assistance';
    } else if (currentUser!.status != UserStatus.verified) {
      message = 'Your account needs to be verified to access this feature.';
      suggestion = 'Complete your verification process';
    } else if (requiredRoles != null) {
      final roleNames = requiredRoles!.map((r) => r.name).join(', ');
      message = 'This page requires $roleNames access.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: Colors.red.shade400,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (suggestion != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (currentUser == null) {
                      Navigator.pushReplacementNamed(context, '/login');
                    } else if (currentUser!.status != UserStatus.verified) {
                      Navigator.pushReplacementNamed(context, '/verification');
                    } else {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  child: Text(suggestion),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Role-based widget visibility
class RoleBasedWidget extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleBasedWidget({
    Key? key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: AuthService().getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return fallback ?? const SizedBox.shrink();
        }

        final user = snapshot.data;
        if (user == null) {
          return fallback ?? const SizedBox.shrink();
        }

        if (allowedRoles.contains(user.role) || user.role == UserRole.admin) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}