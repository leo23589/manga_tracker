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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  double _progress = 0.0;
  String _status = "Initializing...";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialization();
    });
  }

  Future<void> _startInitialization() async {
    if (!mounted) return;
    setState(() {
      _progress = 0.35;
      _status = "Loading library data...";
    });
    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;
    final collection = context.read<MangaCollectionData>();
    final serverService = context.read<ExtensionServerService>();

    setState(() {
      _progress = 0.75;
      _status = "Starting extension sync server...";
    });

    await serverService.startServer(collection);
    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;
    setState(() {
      _progress = 1.0;
      _status = "Ready!";
    });

    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int percent = (_progress * 100).toInt();

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
              const SizedBox(height: 36),

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
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AnimatedLinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF1E1E28),
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedLinearProgressIndicator extends StatelessWidget {
  final double value;
  final double minHeight;
  final Color backgroundColor;
  final Color color;

  const AnimatedLinearProgressIndicator({
    super.key,
    required this.value,
    required this.minHeight,
    required this.backgroundColor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: minHeight,
          color: backgroundColor,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: constraints.maxWidth * value,
              height: minHeight,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
