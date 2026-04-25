import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:agro_alchemy_ui/services/auth.dart';
import 'dart:ui';
import 'package:agro_alchemy_ui/flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  final List<Color> _gradientColors = [
    const Color(0xFF2E7D32), // Primary green
    const Color(0xFF66BB6A), // Light green
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Handle login with method
  Future<void> _login(String method) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (method == 'guest') {
        await AuthService().anonLogin();
      } else if (method == 'google') {
        await AuthService().googleLogin();
      } else if (method == 'apple') {
        await AuthService().appleLogin();
      }

      // On successful login, navigate to the dashboard (only if still mounted)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.loginFailed} ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 100,
              left: 20,
              right: 20,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background decoration
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/farm_background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          
          // Blurred overlay for content
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and app name
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // App logo
                              Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.eco_rounded,
                                    size: 60,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // App name
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: _gradientColors,
                                ).createShader(bounds),
                                child: Text(
                                  AppLocalizations.of(context)!.appTitle,
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Tagline
                              Text(
                                AppLocalizations.of(context)!.tagline,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Login buttons
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      (1 - _animationController.value) * 50,
                                    ),
                                    child: Opacity(
                                      opacity: _animationController.value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    LoginButton(
                                      text: "Continue with Google",
                                      icon: FontAwesomeIcons.google,
                                      color: const Color(0xFF4285F4),
                                      loginMethod: () => _login('google'),
                                      isLoading: _isLoading,
                                    ),
                                    LoginButton(
                                      text: "Continue with Apple",
                                      icon: FontAwesomeIcons.apple,
                                      color: Colors.black,
                                      loginMethod: () => _login('apple'),
                                      isLoading: _isLoading,
                                    ),
                                    LoginButton(
                                      text: "Explore as Guest",
                                      icon: FontAwesomeIcons.userAstronaut,
                                      color: const Color(0xFF673AB7),
                                      loginMethod: () => _login('guest'),
                                      isLoading: _isLoading,
                                      isOutlined: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Terms and privacy
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: Text(
                          "By continuing, you agree to our Terms of Service and Privacy Policy",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 5,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Future<void> Function() loginMethod;
  final bool isLoading;
  final bool isOutlined;

  const LoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.loginMethod,
    required this.isLoading,
    this.isOutlined = false,
  });

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: widget.isOutlined
                ? Colors.transparent
                : _isHovered
                    ? widget.color.withOpacity(0.9)
                    : widget.color,
            borderRadius: BorderRadius.circular(15),
            border: widget.isOutlined
                ? Border.all(
                    color: _isHovered ? widget.color : widget.color.withOpacity(0.7),
                    width: 2,
                  )
                : null,
            boxShadow: _isHovered && !widget.isOutlined
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ]
                : [
                    BoxShadow(
                      color: widget.color.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: widget.isLoading ? null : widget.loginMethod,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isOutlined ? widget.color : Colors.white,
                          ),
                        ),
                      )
                    else
                      Icon(
                        widget.icon,
                        size: 22,
                        color: widget.isOutlined ? widget.color : Colors.white,
                      ),
                    const SizedBox(width: 16),
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.isOutlined ? widget.color : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}