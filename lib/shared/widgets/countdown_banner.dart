import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/models/app_config_model.dart';
import '../../core/theme/app_colors.dart';

class CountdownBanner extends StatefulWidget {
  final AppConfigModel config;

  const CountdownBanner({super.key, required this.config});

  @override
  State<CountdownBanner> createState() => _CountdownBannerState();
}

class _CountdownBannerState extends State<CountdownBanner> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant CountdownBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateTimeLeft();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeLeft() {
    try {
      final launchDate = DateTime.parse(widget.config.collectionLaunchDate);
      final now = DateTime.now();
      if (launchDate.isAfter(now)) {
        setState(() {
          _timeLeft = launchDate.difference(now);
          _isExpired = false;
        });
      } else {
        setState(() {
          _timeLeft = Duration.zero;
          _isExpired = true;
        });
      }
    } catch (_) {
      setState(() {
        _isExpired = true;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isExpired) {
        _timer?.cancel();
      } else {
        _calculateTimeLeft();
      }
    });
  }

  Widget _buildTimeBlock(String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpired) return const SizedBox.shrink();

    final days = _timeLeft.inDays.toString().padLeft(2, '0');
    final hours = (_timeLeft.inHours % 24).toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Teaser Background Image
            CachedNetworkImage(
              imageUrl: widget.config.collectionTeaserImage,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Glass overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'تشكيلة جديدة قادمة',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.config.collectionName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 28),
                    ],
                  ),
                  const Spacer(),
                  // Timer Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimeBlock('يوم', days),
                      const SizedBox(width: 8),
                      _buildTimeBlock('ساعة', hours),
                      const SizedBox(width: 8),
                      _buildTimeBlock('دقيقة', minutes),
                      const SizedBox(width: 8),
                      _buildTimeBlock('ثانية', seconds),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
