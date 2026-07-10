import 'package:flutter/material.dart';

class MdiWindowWidget extends StatelessWidget {
  const MdiWindowWidget({
    super.key,
    required this.title,
    required this.maximized,
    required this.onClose,
    required this.onMaximize,
    required this.onMinimize,
    this.isActive = false,
    this.onBringToFront,
    this.onResize,
    this.width = 700,
    this.height = 500,
    this.child,
  });

  final String title;
  final bool maximized;
  final bool isActive;
  final double width;
  final double height;
  final VoidCallback onClose;
  final VoidCallback onMaximize;
  final VoidCallback onMinimize;
  final VoidCallback? onBringToFront;
  final ValueChanged<Size>? onResize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final titleBarColor = isActive
        ? const Color(0xFF0D47A1)
        : const Color(0xFF1565C0);

    return SizedBox(
      width: maximized ? double.infinity : width,
      height: maximized ? double.infinity : height,
      child: Stack(
        children: [
          Material(
            elevation: maximized ? 0 : (isActive ? 16 : 8),
            borderRadius: maximized ? BorderRadius.zero : BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: maximized ? BorderRadius.zero : const BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onDoubleTap: onBringToFront != null ? onMaximize : null,
                    onSecondaryTap: onBringToFront != null
                        ? () => _showContextMenu(context)
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 40,
                      decoration: BoxDecoration(
                        color: titleBarColor,
            borderRadius: maximized ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tab,
                            color: isActive ? Colors.white : Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          _WindowButton(
                            icon: Icons.minimize,
                            onTap: onMinimize,
                            tooltip: 'Minimize',
                          ),
                          _WindowButton(
                            icon: maximized ? Icons.filter_none : Icons.crop_square,
                            onTap: onMaximize,
                            tooltip: maximized ? 'Restore' : 'Maximize',
                          ),
                          _WindowButton(
                            icon: Icons.close,
                            onTap: onClose,
                            tooltip: 'Close',
                            isClose: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: child ?? Center(
                      child: Text(
                        'Content of $title',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!maximized && onResize != null) ..._buildResizeHandles(),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fill,
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          enabled: false,
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: onMinimize,
          child: const Row(
            children: [
              Icon(Icons.minimize, size: 18),
              SizedBox(width: 8),
              Text('Minimize', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: onMaximize,
          child: Row(
            children: [
              Icon(maximized ? Icons.filter_none : Icons.crop_square, size: 18),
              const SizedBox(width: 8),
              Text(maximized ? 'Restore' : 'Maximize', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: onClose,
          child: const Row(
            children: [
              Icon(Icons.close, size: 18),
              SizedBox(width: 8),
              Text('Close', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: onBringToFront,
          child: const Row(
            children: [
              Icon(Icons.open_in_full, size: 18),
              SizedBox(width: 8),
              Text('Bring to Front', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildResizeHandles() {
    const double corner = 12;
    const double edge = 6;
    const double minW = 350;
    const double minH = 250;
    return [
      Positioned(
        right: 0,
        top: corner,
        bottom: corner,
        child: _ResizeHandle(
          width: edge,
          cursor: SystemMouseCursors.resizeLeftRight,
          onResize: (dx, dy) => onResize!(Size((width + dx).clamp(minW, 1920.0), height)),
        ),
      ),
      Positioned(
        bottom: 0,
        left: corner,
        right: corner,
        child: _ResizeHandle(
          height: edge,
          cursor: SystemMouseCursors.resizeUpDown,
          onResize: (dx, dy) => onResize!(Size(width, (height + dy).clamp(minH, 1080.0))),
        ),
      ),
      Positioned(
        left: 0,
        top: corner,
        bottom: corner,
        child: _ResizeHandle(
          width: edge,
          cursor: SystemMouseCursors.resizeLeftRight,
          onResize: (dx, dy) => onResize!(Size((width - dx).clamp(minW, 1920.0), height)),
        ),
      ),
      Positioned(
        top: 0,
        left: corner,
        right: corner,
        child: _ResizeHandle(
          height: edge,
          cursor: SystemMouseCursors.resizeUpDown,
          onResize: (dx, dy) => onResize!(Size(width, (height - dy).clamp(minH, 1080.0))),
        ),
      ),
      Positioned(
        left: 0,
        top: 0,
        child: _ResizeHandle(
          width: corner,
          height: corner,
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
          onResize: (dx, dy) => onResize!(Size((width - dx).clamp(minW, 1920.0), (height - dy).clamp(minH, 1080.0))),
        ),
      ),
      Positioned(
        right: 0,
        top: 0,
        child: _ResizeHandle(
          width: corner,
          height: corner,
          cursor: SystemMouseCursors.resizeUpRightDownLeft,
          onResize: (dx, dy) => onResize!(Size((width + dx).clamp(minW, 1920.0), (height - dy).clamp(minH, 1080.0))),
        ),
      ),
      Positioned(
        left: 0,
        bottom: 0,
        child: _ResizeHandle(
          width: corner,
          height: corner,
          cursor: SystemMouseCursors.resizeUpRightDownLeft,
          onResize: (dx, dy) => onResize!(Size((width - dx).clamp(minW, 1920.0), (height + dy).clamp(minH, 1080.0))),
        ),
      ),
      Positioned(
        right: 0,
        bottom: 0,
        child: _ResizeHandle(
          width: corner,
          height: corner,
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
          onResize: (dx, dy) => onResize!(Size((width + dx).clamp(minW, 1920.0), (height + dy).clamp(minH, 1080.0))),
        ),
      ),
    ];
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isClose;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 16),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    this.width,
    this.height,
    required this.cursor,
    required this.onResize,
  });

  final double? width;
  final double? height;
  final MouseCursor cursor;
  final void Function(double dx, double dy) onResize;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onPanUpdate: (details) {
          onResize(details.delta.dx, details.delta.dy);
        },
        child: Container(
          width: width,
          height: height,
          color: Colors.transparent,
        ),
      ),
    );
  }
}
