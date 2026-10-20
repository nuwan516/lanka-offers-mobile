import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.onBeforeFlipToBack,
  });

  final Widget front;
  final Widget back;

  /// Return false to cancel (e.g. biometric auth failed).
  final Future<bool> Function()? onBeforeFlipToBack;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool _showBack = false;

  Future<void> _toggle() async {
    if (!_showBack && widget.onBeforeFlipToBack != null) {
      final ok = await widget.onBeforeFlipToBack!();
      if (!ok) return;
    }
    HapticFeedback.mediumImpact();
    _showBack ? await _c.reverse() : await _c.forward();
    setState(() => _showBack = !_showBack);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final angle = Curves.easeInOutCubic.transform(_c.value) * math.pi;
            final isBack = angle > math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
              child:
                  isBack
                      ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi),
                        child: widget.back,
                      )
                      : widget.front,
            );
          },
        ),
      ),
    );
  }
}

/// A ready-to-use virtual credit / debit card front
class VirtualCardFront extends StatelessWidget {
  const VirtualCardFront({
    super.key,
    required this.bankName,
    required this.cardType,
    required this.network,
    this.maskedNumber = '•••• 4821',
    this.expiry = '12/28',
    this.accentGradient,
  });

  final String bankName;
  final String cardType;
  final String network;
  final String maskedNumber;
  final String expiry;
  final Gradient? accentGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xl),
        gradient:
            accentGradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E2429), Color(0xFF101417), Color(0xFF0C0E11)],
            ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    bankName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.contactless_rounded,
                color: Colors.white70,
                size: 24,
              ),
            ],
          ),
          Row(
            children: [
              // Chip representation
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF996515)),
                ),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF805500)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maskedNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cardType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Text(
                network.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A ready-to-use virtual card back
class VirtualCardBack extends StatelessWidget {
  const VirtualCardBack({
    super.key,
    required this.bankName,
    this.securityNotice = 'Sri Lanka Bank Offers Wallet • 100% Staged Verification',
  });

  final String bankName;
  final String securityNotice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xl),
        color: const Color(0xFF14171A),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Container(
            height: 40,
            width: double.infinity,
            color: const Color(0xFF090A0C),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 32,
                    color: Colors.white12,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: const Text(
                      'CVV •••',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    securityNotice,
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ),
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.positive,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
