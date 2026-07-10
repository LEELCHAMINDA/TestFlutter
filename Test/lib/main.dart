import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

String get apiBaseUrl {
  if (kIsWeb) return 'http://localhost:5148';
  if (Platform.isAndroid) return 'http://10.0.2.2:5148';
  return 'http://localhost:5148';
}

class Responsive {
  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < 600;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 1024;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= 1024;
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      home: const MDIHomePage(),
    );
  }
}

class MDIHomePage extends StatefulWidget {
  const MDIHomePage({super.key});

  @override
  State<MDIHomePage> createState() => _MDIHomePageState();
}

class _MDIHomePageState extends State<MDIHomePage> {
  final List<_MDIWindow> _windows = [];
  int _windowIdCounter = 0;
  double _menuWidth = 240;
  bool _isMenuVisible = true;
  double _previousMenuWidth = 240;
  int? _activeWindowId;

  void _toggleMenu() {
    setState(() {
      if (_isMenuVisible) {
        _previousMenuWidth = _menuWidth;
        _menuWidth = 0;
      } else {
        _menuWidth = _previousMenuWidth;
      }
      _isMenuVisible = !_isMenuVisible;
    });
  }

  void _addWindow(String title, {Widget? child}) {
    setState(() {
      _windows.removeWhere((w) => w.title == title);
      _windows.add(_MDIWindow(
        id: _windowIdCounter++,
        title: title,
        offset: Offset(20 + (_windows.length * 20).toDouble(), 20 + (_windows.length * 20).toDouble()),
        child: child,
        maximized: true,
        minimized: false,
      ));
    });
  }

  void _closeWindow(int id) {
    setState(() {
      _windows.removeWhere((w) => w.id == id);
    });
  }

  void _bringToFront(int id) {
    setState(() {
      final idx = _windows.indexWhere((w) => w.id == id);
      if (idx != -1) {
        final win = _windows.removeAt(idx);
        _windows.add(win);
        _activeWindowId = id;
      }
    });
  }

  void _toggleMaximize(int id) {
    setState(() {
      final win = _windows.firstWhere((w) => w.id == id);
      win.maximized = !win.maximized;
      win.minimized = false;
      _activeWindowId = id;
    });
  }

  void _minimizeWindow(int id) {
    setState(() {
      final win = _windows.firstWhere((w) => w.id == id);
      win.minimized = true;
      if (_activeWindowId == id) _activeWindowId = null;
    });
  }

  void _restoreWindow(int id) {
    setState(() {
      final win = _windows.firstWhere((w) => w.id == id);
      win.minimized = false;
      _activeWindowId = id;
    });
  }

  void _cascadeWindows() {
    setState(() {
      int index = 0;
      for (final win in _windows.where((w) => !w.minimized)) {
        win.maximized = false;
        win.offset = Offset(40.0 + index * 32, 40.0 + index * 32);
        win.width = 700;
        win.height = 500;
        index++;
      }
    });
  }

  void _tileHorizontal() {
    final visible = _windows.where((w) => !w.minimized).toList();
    if (visible.isEmpty) return;
    setState(() {
      final rows = (visible.length <= 2) ? 1 : (visible.length <= 4 ? 2 : 3);
      final cols = (visible.length / rows).ceil();
      for (int i = 0; i < visible.length; i++) {
        final win = visible[i];
        win.maximized = false;
        final row = i ~/ cols;
        final col = i % cols;
        win.offset = Offset(col * 400.0, row * 350.0);
        win.width = 700;
        win.height = 500;
      }
    });
  }

  void _tileVertical() {
    final visible = _windows.where((w) => !w.minimized).toList();
    if (visible.isEmpty) return;
    setState(() {
      final cols = (visible.length <= 2) ? 1 : (visible.length <= 4 ? 2 : 3);
      for (int i = 0; i < visible.length; i++) {
        final win = visible[i];
        win.maximized = false;
        final row = i ~/ cols;
        final col = i % cols;
        win.offset = Offset(col * 400.0, row * 350.0);
        win.width = 700;
        win.height = 500;
      }
    });
  }

  void _minimizeAll() {
    setState(() {
      for (final win in _windows) {
        win.minimized = true;
      }
      _activeWindowId = null;
    });
  }

  void _closeAll() {
    setState(() {
      _windows.clear();
      _activeWindowId = null;
    });
  }

  Widget _buildSidebar() {
    return Sidebar(
      onMenuTap: (title, {child}) {
        _addWindow(title, child: child);
        if (Responsive.isMobile(context)) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  Widget _buildMenuBar() {
    final hasWindows = _windows.isNotEmpty;

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _buildMenuDropdown('File', [
            _MenuItemData('Close All', Icons.close_fullscreen, hasWindows ? _closeAll : null),
          ]),
          _buildMenuDropdown('Window', [
            _MenuItemData('Cascade', Icons.view_carousel, hasWindows ? _cascadeWindows : null),
            _MenuItemData('Tile Horizontal', Icons.view_module, hasWindows ? _tileHorizontal : null),
            _MenuItemData('Tile Vertical', Icons.view_quilt, hasWindows ? _tileVertical : null),
            null, // separator
            _MenuItemData('Minimize All', Icons.minimize, hasWindows ? _minimizeAll : null),
            null, // separator
            ..._windows.map((win) => _MenuItemData(
              win.title,
              win.minimized ? Icons.open_in_new : Icons.tab,
              () {
                if (win.minimized) {
                  _restoreWindow(win.id);
                } else {
                  _bringToFront(win.id);
                }
              },
              isChecked: _activeWindowId == win.id && !win.minimized,
            )),
          ]),
        ],
      ),
    );
  }

  Widget _buildMenuDropdown(String label, List<_MenuItemData?> items) {
    return MenuAnchor(
      menuChildren: items.map<Widget>((item) {
        if (item == null) {
          return const Divider(height: 1, indent: 8, endIndent: 8);
        }
        return MenuItemButton(
          leadingIcon: Icon(item.icon, size: 18),
          trailingIcon: item.isChecked ? const Icon(Icons.check, size: 18) : null,
          onPressed: item.onTap,
          child: Text(item.label, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar() {
    final activeWindow = _activeWindowId != null
        ? _windows.where((w) => w.id == _activeWindowId).firstOrNull
        : null;

    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAED),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            'Windows: ${_windows.length}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 16),
          if (activeWindow != null) ...[
            Icon(Icons.tab, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Active: ${activeWindow.title}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
              ),
            ),
          ] else
            Text(
              'Active: None',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          const Spacer(),
          Text(
            '${_windows.where((w) => w.minimized).length} minimized',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleWindows = _windows.where((w) => !w.minimized).toList();
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: isMobile
            ? Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  tooltip: 'Menu',
                ),
              )
            : IconButton(
                icon: Icon(_isMenuVisible ? Icons.menu_open : Icons.menu),
                onPressed: _toggleMenu,
                tooltip: _isMenuVisible ? 'Hide Menu' : 'Show Menu',
              ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inventory_2, size: 24),
            SizedBox(width: 10),
            Text(
              'Product Manager',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 8),
        ],
      ),
      drawer: isMobile ? Drawer(child: _buildSidebar()) : null,
      body: isMobile
          ? _buildMobileBody(visibleWindows)
          : Column(
              children: [
                _buildMenuBar(),
                Expanded(
                  child: _buildDesktopBody(visibleWindows),
                ),
                _buildStatusBar(),
              ],
            ),
    );
  }

  Widget _buildMobileBody(List<_MDIWindow> visibleWindows) {
    if (visibleWindows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Tap the menu to get started',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final win = visibleWindows.last;
    return ClipRect(
      child: MDIWindowWidget(
        title: win.title,
        maximized: true,
        onClose: () => _closeWindow(win.id),
        onMaximize: () => _toggleMaximize(win.id),
        onMinimize: () => _minimizeWindow(win.id),
        child: win.child,
      ),
    );
  }

  Widget _buildDesktopBody(List<_MDIWindow> visibleWindows) {
    final minimizedWindows = _windows.where((w) => w.minimized).toList();

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isMenuVisible ? _menuWidth : 0,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: _buildSidebar(),
        ),
        if (_isMenuVisible)
          MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _menuWidth = (_menuWidth + details.delta.dx).clamp(180.0, 400.0);
                  _previousMenuWidth = _menuWidth;
                });
              },
              child: Container(
                width: 1,
                color: Colors.grey.shade300,
              ),
            ),
          ),
        Expanded(
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_windows.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Select a module from the sidebar',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                final mdiAreaHeight = constraints.maxHeight;
                final minimizedBarHeight = minimizedWindows.isNotEmpty ? 36.0 : 0.0;
                final mainAreaHeight = mdiAreaHeight - minimizedBarHeight;

                return Column(
                  children: [
                    // Main MDI client area with visible windows
                    SizedBox(
                      height: mainAreaHeight,
                      child: Stack(
                        children: visibleWindows.isEmpty
                            ? [
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      'All windows minimized',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                              ]
                            : visibleWindows.map((win) {
                                final isActive = _activeWindowId == win.id;
                                if (win.maximized) {
                                  return Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () => _bringToFront(win.id),
                                      child: MDIWindowWidget(
                                        title: win.title,
                                        maximized: true,
                                        isActive: isActive,
                                        onClose: () => _closeWindow(win.id),
                                        onMaximize: () => _toggleMaximize(win.id),
                                        onMinimize: () => _minimizeWindow(win.id),
                                        onBringToFront: () => _bringToFront(win.id),
                                        child: win.child,
                                      ),
                                    ),
                                  );
                                }
                                return Positioned(
                                  left: win.offset.dx.clamp(0.0, (constraints.maxWidth - 100).clamp(0.0, double.infinity)),
                                  top: win.offset.dy.clamp(0.0, (mainAreaHeight - 50).clamp(0.0, double.infinity)),
                                  child: GestureDetector(
                                    onPanUpdate: (details) {
                                      setState(() {
                                        win.offset = Offset(
                                          (win.offset.dx + details.delta.dx).clamp(0.0, (constraints.maxWidth - 100).clamp(0.0, double.infinity)),
                                          (win.offset.dy + details.delta.dy).clamp(0.0, (mainAreaHeight - 50).clamp(0.0, double.infinity)),
                                        );
                                      });
                                    },
                                    onTap: () => _bringToFront(win.id),
                                    child: MDIWindowWidget(
                                      title: win.title,
                                      maximized: false,
                                      isActive: isActive,
                                      width: win.width.clamp(350.0, constraints.maxWidth > 350.0 ? constraints.maxWidth : 350.0),
                                      height: win.height.clamp(250.0, mainAreaHeight > 250.0 ? mainAreaHeight : 250.0),
                                      onClose: () => _closeWindow(win.id),
                                      onMaximize: () => _toggleMaximize(win.id),
                                      onMinimize: () => _minimizeWindow(win.id),
                                      onBringToFront: () => _bringToFront(win.id),
                                      onResize: (newSize) {
                                        setState(() {
                                          win.width = newSize.width;
                                          win.height = newSize.height;
                                        });
                                      },
                                      child: win.child,
                                    ),
                                  ),
                                );
                              }).toList(),
                      ),
                    ),
                    // Minimized windows bar at bottom (classic .NET style)
                    if (minimizedWindows.isNotEmpty)
                      Container(
                        height: minimizedBarHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5),
                          border: Border(top: BorderSide(color: Colors.grey.shade300)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: minimizedWindows.map((win) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                child: InkWell(
                                  onTap: () => _restoreWindow(win.id),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.open_in_new, size: 13, color: Color(0xFF1565C0)),
                                        const SizedBox(width: 5),
                                        Text(
                                          win.title,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItemData {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isChecked;

  _MenuItemData(this.label, this.icon, this.onTap, {this.isChecked = false});
}

class _MDIWindow {
  final int id;
  final String title;
  final Widget? child;
  Offset offset;
  double width;
  double height;
  bool maximized;
  bool minimized;

  _MDIWindow({
    required this.id,
    required this.title,
    required this.offset,
    this.child,
    this.maximized = true,
    this.minimized = false,
  })  : width = 700,
        height = 500;
}

class MDIWindowWidget extends StatelessWidget {
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

  const MDIWindowWidget({
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

  @override
  Widget build(BuildContext context) {
    final titleBarColor = isActive
        ? const Color(0xFF0D47A1)
        : const Color(0xFF1565C0);

    return SizedBox(
      width: maximized ? double.infinity : width,
      height: maximized ? double.infinity : height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Material(
            elevation: maximized ? 0 : (isActive ? 16 : 8),
            borderRadius: maximized ? BorderRadius.zero : BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: maximized ? BorderRadius.zero : BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title bar with double-click and right-click support
                  GestureDetector(
                    onDoubleTap: onBringToFront != null ? onMaximize : null,
                    onSecondaryTap: onBringToFront != null
                        ? () => _showContextMenu(context)
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      height: 40,
                      decoration: BoxDecoration(
                        color: titleBarColor,
                        borderRadius: maximized
                            ? BorderRadius.zero
                            : const BorderRadius.vertical(top: Radius.circular(12)),
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
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isClose = false,
  });

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
  final double? width;
  final double? height;
  final MouseCursor cursor;
  final void Function(double dx, double dy) onResize;

  const _ResizeHandle({
    this.width,
    this.height,
    required this.cursor,
    required this.onResize,
  });

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

class Sidebar extends StatelessWidget {
  final void Function(String title, {Widget? child}) onMenuTap;

  const Sidebar({super.key, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      color: Colors.white,
      width: isMobile ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 12),
              child: Row(
                children: const [
                  Icon(Icons.inventory_2, color: Color(0xFF1565C0), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Product Manager',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Color(0xFF1565C0)),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'MODULES',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            title: 'Products',
            onTap: () => onMenuTap('Products', child: const ProductListWidget()),
          ),
          _SidebarItem(
            icon: Icons.print_outlined,
            title: 'Print Products',
            onTap: () => onMenuTap('Print Products', child: const PrintProductsWidget()),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'OTHERS',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          _SidebarItem(
            icon: Icons.article_outlined,
            title: 'Test',
            onTap: () => onMenuTap('Test'),
          ),
          _SidebarItem(
            icon: Icons.article_outlined,
            title: 'Test 1',
            onTap: () => onMenuTap('Test 1'),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Product {
  final int id;
  final String? name;
  final double price;
  final String? description;
  final int stock;
  final bool isActive;
  final DateTime createdDate;

  Product({
    required this.id,
    this.name,
    required this.price,
    this.description,
    required this.stock,
    required this.isActive,
    required this.createdDate,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      stock: json['stock'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdDate: DateTime.tryParse(json['createdDate'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'stock': stock,
      'isActive': isActive,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}

class ProductListWidget extends StatefulWidget {
  const ProductListWidget({super.key});

  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  bool _isEditing = false;
  bool _isNewRecord = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  bool _isActive = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();
    _descriptionController = TextEditingController();
    _fetchProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showTopNotification(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 16,
        right: 16,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8, minWidth: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade600 : Colors.green.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => entry.remove(),
                  child: const Icon(Icons.close, color: Colors.white70, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _products = data.map((json) => Product.fromJson(json)).toList();
          _isLoading = false;
          if (_products.isNotEmpty && _currentIndex >= _products.length) {
            _currentIndex = _products.length - 1;
          }
          if (_products.isNotEmpty) {
            _loadCurrentRecord();
          }
        });
      } else {
        setState(() {
          _error = 'Failed to load products (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadCurrentRecord() {
    if (_products.isEmpty) return;
    final product = _products[_currentIndex];
    _nameController.text = product.name ?? '';
    _priceController.text = product.price.toStringAsFixed(2);
    _stockController.text = product.stock.toString();
    _descriptionController.text = product.description ?? '';
    _isActive = product.isActive;
  }

  void _goToFirst() {
    if (_products.isEmpty) return;
    setState(() {
      _currentIndex = 0;
      _isEditing = false;
      _isNewRecord = false;
      _loadCurrentRecord();
    });
  }

  void _goToPrevious() {
    if (_products.isEmpty || _currentIndex == 0) return;
    setState(() {
      _currentIndex--;
      _isEditing = false;
      _isNewRecord = false;
      _loadCurrentRecord();
    });
  }

  void _goToNext() {
    if (_products.isEmpty || _currentIndex == _products.length - 1) return;
    setState(() {
      _currentIndex++;
      _isEditing = false;
      _isNewRecord = false;
      _loadCurrentRecord();
    });
  }

  void _goToLast() {
    if (_products.isEmpty) return;
    setState(() {
      _currentIndex = _products.length - 1;
      _isEditing = false;
      _isNewRecord = false;
      _loadCurrentRecord();
    });
  }

  void _addNew() {
    setState(() {
      _isNewRecord = true;
      _isEditing = true;
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      _descriptionController.clear();
      _isActive = true;
    });
  }

  void _editRecord() {
    setState(() {
      _isEditing = true;
      _isNewRecord = false;
    });
  }

  void _undoChanges() {
    setState(() {
      _isEditing = false;
      _isNewRecord = false;
      if (_products.isNotEmpty) {
        _loadCurrentRecord();
      }
    });
  }

  void _showSearchDialog() {
    String searchQuery = '';
    List<Product> filteredProducts = List.from(_products);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.85).clamp(300.0, 500.0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text('Search Products', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              content: SizedBox(
                width: dialogWidth,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (value) {
                        searchQuery = value.toLowerCase();
                        setDialogState(() {
                          filteredProducts = _products
                              .where((p) => (p.name ?? '').toLowerCase().contains(searchQuery))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text('No products found', style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredProducts.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                                    child: Text(
                                      (product.name?.isNotEmpty == true ? product.name![0] : '?').toUpperCase(),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
                                    ),
                                  ),
                                  title: Text(
                                    product.name ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: product.isActive ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Stock: ${product.stock}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: product.isActive ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    final originalIndex = _products.indexWhere((p) => p.id == product.id);
                                    if (originalIndex != -1) {
                                      setState(() {
                                        _currentIndex = originalIndex;
                                        _isEditing = false;
                                        _isNewRecord = false;
                                        _loadCurrentRecord();
                                      });
                                    }
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveRecord() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);

    try {
      final product = Product(
        id: _isNewRecord ? 0 : _products[_currentIndex].id,
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0,
        description: _descriptionController.text.trim(),
        stock: int.tryParse(_stockController.text) ?? 0,
        isActive: _isActive,
        createdDate: _isNewRecord ? DateTime.now() : _products[_currentIndex].createdDate,
      );

      http.Response response;
      if (_isNewRecord) {
        response = await http.post(
          Uri.parse('$apiBaseUrl/api/products'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(product.toJson()),
        );
      } else {
        response = await http.put(
          Uri.parse('$apiBaseUrl/api/products/${product.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(product.toJson()),
        );
      }

      if (response.statusCode == 201 || response.statusCode == 204) {
        final wasNew = _isNewRecord;
        setState(() {
          _isEditing = false;
          _isNewRecord = false;
          _isSaving = false;
        });
        if (mounted) {
          _showTopNotification(wasNew ? 'Product created successfully' : 'Product updated successfully');
        }
        await _fetchProducts();
      } else {
        if (mounted) {
          _showTopNotification('Error: ${response.statusCode}', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showTopNotification('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteRecord() async {
    if (_products.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Flexible(
              child: Text('Delete Product', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_products[_currentIndex].name}"? This action cannot be undone.',
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('$apiBaseUrl/api/products/${_products[_currentIndex].id}'),
        );
        if (response.statusCode == 204) {
          if (_currentIndex >= _products.length - 1 && _currentIndex > 0) {
            _currentIndex--;
          }
          if (mounted) {
            _showTopNotification('Product deleted successfully');
          }
          await _fetchProducts();
        }
      } catch (e) {
        if (mounted) {
          _showTopNotification('Error deleting product: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading products...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _fetchProducts();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(Responsive.isMobile(context) ? 24 : 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No Products Found',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get started by adding your first product.',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _addNew,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRect(
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildForm()),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final bool hasData = _products.isNotEmpty;
    final bool isFirst = _currentIndex == 0;
    final bool isLast = _currentIndex == _products.length - 1;
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _NavIconButton(Icons.first_page, _goToFirst, !hasData || isFirst || _isEditing, 'First'),
            _NavIconButton(Icons.chevron_left, _goToPrevious, !hasData || isFirst || _isEditing, 'Previous'),
            _NavIconButton(Icons.chevron_right, _goToNext, !hasData || isLast || _isEditing, 'Next'),
            _NavIconButton(Icons.last_page, _goToLast, !hasData || isLast || _isEditing, 'Last'),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.grey.shade300,
            ),
            _ActionChipButton(
              label: 'Add',
              icon: Icons.add,
              color: const Color(0xFF1565C0),
              onPressed: _isEditing ? null : _addNew,
            ),
            const SizedBox(width: 6),
            _ActionChipButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              color: Colors.grey.shade700,
              onPressed: (!hasData || _isEditing) ? null : _editRecord,
            ),
            const SizedBox(width: 6),
            _ActionChipButton(
              label: 'Delete',
              icon: Icons.delete_outline,
              color: Colors.red.shade600,
              onPressed: (!hasData || _isEditing) ? null : _deleteRecord,
            ),
            const SizedBox(width: 6),
            _ActionChipButton(
              label: _isSaving ? 'Saving...' : 'Save',
              icon: _isSaving ? Icons.hourglass_top : Icons.check,
              color: Colors.green.shade600,
              onPressed: (_isEditing && !_isSaving) ? _saveRecord : null,
            ),
            const SizedBox(width: 6),
            _ActionChipButton(
              label: 'Undo',
              icon: Icons.undo,
              color: Colors.orange.shade700,
              onPressed: _isEditing ? _undoChanges : null,
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(Icons.search, size: 20, color: Colors.grey.shade600),
              onPressed: _showSearchDialog,
              tooltip: 'Search',
              splashRadius: 18,
            ),
            if (!isMobile) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${_products.length}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 12.0 : 20.0;

    return SingleChildScrollView(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.all(padding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2, size: 20, color: Color(0xFF1565C0)),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Product Information',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isMobile) ...[
                      _buildField(
                        label: 'Name',
                        child: TextFormField(
                          controller: _nameController,
                          enabled: _isEditing,
                          validator: (value) {
                            if (_isEditing && (value == null || value.trim().isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(hintText: 'Enter product name'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: 'Price',
                        child: TextFormField(
                          controller: _priceController,
                          enabled: _isEditing,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (_isEditing && (value == null || value.trim().isEmpty)) {
                              return 'Required';
                            }
                            if (_isEditing) {
                              final num = double.tryParse(value!);
                              if (num == null) return 'Invalid number';
                              if (num < 0) return 'Must be positive';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixText: '\$ ',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: 'Stock',
                        child: TextFormField(
                          controller: _stockController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_isEditing && (value == null || value.trim().isEmpty)) {
                              return 'Required';
                            }
                            if (_isEditing) {
                              final num = int.tryParse(value!);
                              if (num == null) return 'Invalid integer';
                              if (num < 0) return 'Must be positive';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(hintText: '0'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: 'Status',
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isActive ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color: _isActive ? Colors.green.shade600 : Colors.red.shade400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const Spacer(),
                              if (_isEditing)
                                Switch(
                                  value: _isActive,
                                  onChanged: (value) => setState(() => _isActive = value),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Name',
                              child: TextFormField(
                                controller: _nameController,
                                enabled: _isEditing,
                                validator: (value) {
                                  if (_isEditing && (value == null || value.trim().isEmpty)) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(hintText: 'Enter product name'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Price',
                              child: TextFormField(
                                controller: _priceController,
                                enabled: _isEditing,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (_isEditing && (value == null || value.trim().isEmpty)) {
                                    return 'Required';
                                  }
                                  if (_isEditing) {
                                    final num = double.tryParse(value!);
                                    if (num == null) return 'Invalid number';
                                    if (num < 0) return 'Must be positive';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  prefixText: '\$ ',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Stock',
                              child: TextFormField(
                                controller: _stockController,
                                enabled: _isEditing,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_isEditing && (value == null || value.trim().isEmpty)) {
                                    return 'Required';
                                  }
                                  if (_isEditing) {
                                    final num = int.tryParse(value!);
                                    if (num == null) return 'Invalid integer';
                                    if (num < 0) return 'Must be positive';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(hintText: '0'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Status',
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isActive ? Icons.check_circle : Icons.cancel,
                                      size: 16,
                                      color: _isActive ? Colors.green.shade600 : Colors.red.shade400,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_isEditing)
                                      Switch(
                                        value: _isActive,
                                        onChanged: (value) => setState(() => _isActive = value),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Description',
                      child: TextFormField(
                        controller: _descriptionController,
                        enabled: _isEditing,
                        maxLines: isMobile ? 2 : 3,
                        decoration: const InputDecoration(hintText: 'Enter product description (optional)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class PrintProductsWidget extends StatefulWidget {
  const PrintProductsWidget({super.key});

  @override
  State<PrintProductsWidget> createState() => _PrintProductsWidgetState();
}

class _PrintProductsWidgetState extends State<PrintProductsWidget> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _products = data.map((json) => Product.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load products (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<pw.Document> _buildPdf() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final font = await PdfGoogleFonts.nunitoSansRegular();
    final fontBold = await PdfGoogleFonts.nunitoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Product Report',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 22,
                  color: PdfColor.fromHex('#1565C0'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on: ${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Text(
                'Total Products: ${_products.length}',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColor.fromHex('#1565C0'), thickness: 1.5),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1565C0'),
              ),
              headerAlignment: pw.Alignment.centerLeft,
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 28,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.centerLeft,
              },
              headerAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.centerLeft,
              },
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F7FA')),
              headers: ['#', 'Name', 'Price', 'Stock', 'Status', 'Created Date'],
              data: _products.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final p = entry.value;
                return [
                  '$index',
                  p.name ?? '-',
                  '\$${p.price.toStringAsFixed(2)}',
                  '${p.stock}',
                  p.isActive ? 'Active' : 'Inactive',
                  '${p.createdDate.day}/${p.createdDate.month}/${p.createdDate.year}',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  Future<void> _printPdf() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = await _buildPdf();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Product_Report_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = await _buildPdf();
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'Product_Report.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading products...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _fetchProducts();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print_disabled_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No Products to Print',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products first, then come back to print.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        _buildPrintToolbar(isMobile),
        Expanded(child: _buildPrintPreview(isMobile)),
      ],
    );
  }

  Widget _buildPrintToolbar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.print, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Print Preview — ${_products.length} product${_products.length == 1 ? '' : 's'}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            ),
          ),
          const Spacer(),
          _ActionChipButton(
            label: _isGenerating ? 'Generating...' : 'Download PDF',
            icon: Icons.download,
            color: Colors.orange.shade700,
            onPressed: _isGenerating ? null : _downloadPdf,
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _printPdf,
            icon: _isGenerating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.print, size: 18),
            label: const Text('Print'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintPreview(bool isMobile) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.print, size: 28, color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Report',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.blue.shade100, thickness: 2),
              const SizedBox(height: 6),
              Text(
                'Total Products: ${_products.length}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              _buildPreviewTable(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTable(bool isMobile) {
    final headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white);
    final cellStyle = TextStyle(fontSize: 11, color: Colors.grey.shade800);

    return Table(
      columnWidths: {
        0: const FlexColumnWidth(0.5),
        1: const FlexColumnWidth(3),
        2: const FlexColumnWidth(1.5),
        3: const FlexColumnWidth(1),
        4: const FlexColumnWidth(1.2),
        if (!isMobile) 5: const FlexColumnWidth(1.8),
      },
      border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
      children: [
        TableRow(
          decoration: BoxDecoration(color: const Color(0xFF1565C0)),
          children: [
            _headerCell('#', headerStyle),
            _headerCell('Name', headerStyle),
            _headerCell('Price', headerStyle),
            _headerCell('Stock', headerStyle),
            _headerCell('Status', headerStyle),
            if (!isMobile) _headerCell('Created Date', headerStyle),
          ],
        ),
        ..._products.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isOdd = i % 2 == 1;
          return TableRow(
            decoration: BoxDecoration(
              color: isOdd ? Colors.grey.shade50 : Colors.white,
            ),
            children: [
              _dataCell('${i + 1}', cellStyle, align: TextAlign.center),
              _dataCell(p.name ?? '-', cellStyle),
              _dataCell('\$${p.price.toStringAsFixed(2)}', cellStyle, align: TextAlign.right),
              _dataCell('${p.stock}', cellStyle, align: TextAlign.center),
              _statusCell(p.isActive),
              if (!isMobile)
                _dataCell(
                  '${p.createdDate.day}/${p.createdDate.month}/${p.createdDate.year}',
                  cellStyle,
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _headerCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(text, style: style),
    );
  }

  Widget _dataCell(String text, TextStyle style, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(text, style: style, textAlign: align),
    );
  }

  Widget _statusCell(bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isActive ? 'Active' : 'Inactive',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool disabled;
  final String tooltip;

  const _NavIconButton(this.icon, this.onPressed, this.disabled, this.tooltip);

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

class _ActionChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionChipButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

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
