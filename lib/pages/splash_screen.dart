import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../services/extension_server_service.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // AnimationController specifically for smoothly interpolating the percentage and progress bar
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  String _status = "Initializing...";
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    
    // Heartbeat pulse animation for the logo
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Smooth linear progress animation controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    _progressController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialization();
    });
  }

  void _animateProgressTo(double target, String newStatus, int durationMs) {
    if (!mounted) return;
    setState(() {
      _status = newStatus;
    });
    
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: target,
    ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic));
    
    _progressController.duration = Duration(milliseconds: durationMs);
    _progressController.forward(from: 0.0);
  }

  Future<void> _startInitialization() async {
    if (!mounted) return;

    // Step 1: Loading library
    _animateProgressTo(0.40, "Loading library data...", 400);
    final collection = context.read<MangaCollectionData>();
    final serverService = context.read<ExtensionServerService>();
    // Slight artificial delay to allow smooth bar transition to 40%
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    // Step 2: Starting server
    _animateProgressTo(0.85, "Starting extension sync server...", 400);
    await serverService.startServer(collection);
    // Slight artificial delay to allow smooth bar transition to 85%
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    // Step 3: Complete
    _animateProgressTo(1.0, "Ready!", 200);
    await Future.delayed(const Duration(milliseconds: 250));

    if (mounted && !_isNavigating) {
      _isNavigating = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double currentProgress = _progressAnimation.value;
    final int percent = (currentProgress * 100).toInt().clamp(0, 100);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/orange_cat.png',
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Manga Tracker",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFFF3F4F6),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Your Personal Manga Library",
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(height: 48),

              // Progress text indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _status,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "$percent%",
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Custom Smooth Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 8,
                  width: double.infinity,
                  color: const Color(0xFF1E1E28),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: currentProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withAlpha((255 * 0.5).round()),
                              blurRadius: 6,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
