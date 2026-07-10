import 'package:flutter/material.dart';

class NavIconButton extends StatelessWidget {
  const NavIconButton(this.icon, this.onPressed, this.disabled, this.tooltip, {super.key});

  final IconData icon;
  final VoidCallback onPressed;
  final bool disabled;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: disabled ? null : onPressed,
        splashRadius: 16,
        visualDensity: VisualDensity.compact,
        color: Colors.grey.shade700,
        disabledColor: Colors.grey.shade300,
      ),
    );
  }
}

class ActionChipButton extends StatelessWidget {
  const ActionChipButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Material(
      color: enabled ? color.withValues(alpha: 0.08) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: enabled ? color : Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
