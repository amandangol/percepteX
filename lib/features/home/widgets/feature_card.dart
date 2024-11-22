import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FeatureCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.gradientColors,
    this.onTap,
    this.height,
    this.width,
  }) : assert(gradientColors.length >= 2,
            'Must provide at least 2 gradient colors');

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Responsive calculations based on screen size
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Dynamic sizing
    final defaultHeight = isSmallScreen ? 150.0 : 180.0;
    final cardHeight = widget.height ?? defaultHeight;
    final cardWidth = widget.width ?? double.infinity;

    // Responsive measurements
    final padding = isSmallScreen ? 16.0 : 20.0;
    final iconSize = isSmallScreen ? 24.0 : 32.0;
    final borderRadius = isSmallScreen ? 20.0 : 24.0;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedScale(
        scale: isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            constraints: BoxConstraints(
              maxWidth: 600,
              minHeight: 120,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors.first
                      .withOpacity(isHovered ? 0.4 : 0.2),
                  blurRadius: isHovered ? 16 : 12,
                  offset: Offset(0, isHovered ? 8 : 6),
                  spreadRadius: isHovered ? 2 : 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background decoration elements
                _buildDecorationCircle(
                  right: -20,
                  top: -20,
                  size: isSmallScreen ? 80 : 100,
                ),
                _buildDecorationCircle(
                  left: -30,
                  bottom: -30,
                  size: isSmallScreen ? 100 : 120,
                  opacity: 0.05,
                ),

                // Main content
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withOpacity(isHovered ? 0.25 : 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          widget.icon,
                          size: iconSize,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),

                      // Title and description
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
          duration: 600.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildDecorationCircle({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    double opacity = 0.1,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(isHovered ? opacity * 1.2 : opacity),
        ),
      ),
    );
  }
}
