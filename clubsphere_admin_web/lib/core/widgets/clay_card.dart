import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ClayCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color color;
  final VoidCallback? onTap;
  final double borderRadius;

  const ClayCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.color = AppColors.surface,
    this.onTap,
    this.borderRadius = 16.0,
  });

  @override
  State<ClayCard> createState() => _ClayCardState();
}

class _ClayCardState extends State<ClayCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (widget.onTap != null) {
          setState(() => _isHovered = false);
        }
      },
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isHovered && widget.onTap != null 
                ? AppColors.surfaceAlt 
                : widget.color == Colors.white ? AppColors.surface : widget.color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
