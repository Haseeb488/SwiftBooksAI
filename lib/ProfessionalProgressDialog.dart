import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ProfessionalProgressDialog extends StatefulWidget {
  final List<String> messages;

  const ProfessionalProgressDialog({
    super.key,
    this.messages = const [
      'Analyzing Receipt...',
      'Reading Prices...',
      'Reading Tax Info...',
      'Reading Address...',
      'Processing Other Details...',
      'Finalizing details...',
    ],
  });

  /// Static helper method to show the dialog
  static void show(
      BuildContext context, {
        List<String> messages = const [
          'Analyzing Receipt...',
          'Reading Prices...',
          'Reading Tax Info...',
          'Reading Address...',
          'Processing Other Details...',
          'Finalizing details...',
        ],
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => ProfessionalProgressDialog(messages: messages),
    );
  }

  /// Static helper method to hide the dialog
  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  State<ProfessionalProgressDialog> createState() =>
      _ProfessionalProgressDialogState();
}

class _ProfessionalProgressDialogState
    extends State<ProfessionalProgressDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  int _currentTextIndex = 0;

  @override
  void initState() {
    super.initState();
    // Continuous rotation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Timer to cycle through text messages every 3 seconds
    if (widget.messages.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {
            _currentTextIndex = (_currentTextIndex + 1) % widget.messages.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Always cancel timers on dispose
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.messages.isNotEmpty
        ? widget.messages[_currentTextIndex]
        : '';

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Revolving Search Icon Container
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer subtle spinning progress ring
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // Rotating Search Icon
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * 2 * math.pi,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -24),
                              child: const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Static Center Image Icon
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 28,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Dialog Text with subtle fade transition when text changes
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                currentText,
                key: ValueKey<int>(_currentTextIndex),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}