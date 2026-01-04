import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _captionController;
  late AnimationController _pageController;

  late Animation<Offset> _focusSlide;
  late Animation<Offset> _readSlide;
  late Animation<double> _fadeIn;
  late Animation<double> _letterSpacing;
  late Animation<double> _fadeOut;
  late Animation<double> _frFadeIn;
  late Animation<double> _frScale;
  late Animation<double> _pageTurn;

  bool showFR = false;
  String displayedCaption = '';
  final String fullCaption = 'Focus • Read • Grow';

  @override
  void initState() {
    super.initState();

    _textController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _captionController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _pageController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

    _focusSlide = Tween(begin: const Offset(-1.5, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic)),
    );

    _readSlide = Tween(begin: const Offset(1.5, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic)),
    );

    _fadeIn = CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.2));
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.65, 0.8)),
    );

    _letterSpacing = Tween(begin: 12.0, end: -8.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.35, 0.65, curve: Curves.easeInOutCubic)),
    );

    _frFadeIn = CurvedAnimation(parent: _textController, curve: const Interval(0.75, 0.95));
    _frScale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutBack),
    );

    _pageTurn = CurvedAnimation(parent: _pageController, curve: Curves.easeInOutQuart);

    _captionController.addListener(_updateCaption);
    _startSequence();
  }

  void _updateCaption() {
    final len = (fullCaption.length * _captionController.value).round();
    if (displayedCaption.length != len) {
      setState(() => displayedCaption = fullCaption.substring(0, len));
    }
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _captionController.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    setState(() => showFR = true);
    await Future.delayed(const Duration(milliseconds: 2000));
    _pageController.forward();

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFAF8F3), Color(0xFFF0E9DD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 180,
                  child: AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!showFR)
                            Opacity(
                              opacity: _fadeIn.value * _fadeOut.value,
                              child: FittedBox( // 🔥 FINAL OVERFLOW FIX
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SlideTransition(
                                      position: _focusSlide,
                                      child: Text(
                                        'Focus',
                                        style: TextStyle(
                                          fontSize: 48,
                                          letterSpacing: _letterSpacing.value,
                                          color: const Color(0xFF2C2416),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: (12 + _letterSpacing.value).clamp(4.0, 16.0),
                                    ),
                                    SlideTransition(
                                      position: _readSlide,
                                      child: Text(
                                        'Read',
                                        style: TextStyle(
                                          fontSize: 48,
                                          letterSpacing: _letterSpacing.value,
                                          color: const Color(0xFF2C2416),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (showFR)
                            FadeTransition(
                              opacity: _frFadeIn,
                              child: Transform.scale(
                                scale: _frScale.value,
                                child: const Text(
                                  'FR',
                                  style: TextStyle(
                                    fontSize: 110,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  displayedCaption,
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: 2.8,
                    color: Color(0xFF6B5D4F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
