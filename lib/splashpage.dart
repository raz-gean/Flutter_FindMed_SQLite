import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'dart:async';
import 'pages/home.dart';
import 'auth/login_page.dart';
import 'services/auth_service.dart';
import 'widgets/findmed_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  bool _logoReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await precacheImage(
        const AssetImage('assets/imgs/findmed_logo.png'),
        context,
      );
      if (!mounted) return;
      setState(() => _logoReady = true);
      _controller.forward();
      Timer(const Duration(milliseconds: 1700), () {
        if (!mounted) return;

        // Check if user is logged in and determine navigation
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;

        if (currentUser != null) {
          // All users go to HomePage, they can access their panel from the drawer
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          // No user logged in - go to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.brandBlueDark;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [Colors.white, AppTheme.brandBlueLight],
                  center: Alignment(0, -0.2),
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedOpacity(
              opacity: _logoReady ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FindMedLogo(size: 130),
                      const SizedBox(height: 20),
                      Text(
                        'FindMed',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppTheme.brandBlueDark,
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
