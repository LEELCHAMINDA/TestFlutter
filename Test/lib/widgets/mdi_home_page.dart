import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'mdi_window_widget.dart';
import 'sidebar_widget.dart';

class _MDIWindow {
  _MDIWindow({
    required this.id,
    required this.title,
    required this.offset,
    this.child,
  })  : maximized = true,
        minimized = false,
        width = 700,
        height = 500;

  final int id;
  final String title;
  final Widget? child;
  Offset offset;
  double width;
  double height;
  bool maximized;
  bool minimized;
}

class _MenuItemData {
  _MenuItemData(this.label, this.icon, this.onTap, {this.isChecked = false});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isChecked;
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
      _windows
        ..removeWhere((w) => w.title == title)
        ..add(_MDIWindow(
          id: _windowIdCounter++,
          title: title,
          offset: _clampOffset(Offset(20 + (_windows.length * 20).toDouble(), 20 + (_windows.length * 20).toDouble()), 700, 500),
          child: child,
        ));
    });
  }

  /// Clamp a window offset so it stays fully visible within the MDI area.
  Offset _clampOffset(Offset offset, double winWidth, double winHeight) {
    final areaWidth = MediaQuery.sizeOf(context).width - (_isMenuVisible ? _menuWidth : 0);
    final areaHeight = MediaQuery.sizeOf(context).height - 28 - 26; // minus menubar + statusbar
    final maxX = (areaWidth - 40).clamp(0.0, double.infinity);
    final maxY = (areaHeight - 40).clamp(0.0, double.infinity);
    return Offset(
      offset.dx.clamp(0.0, maxX),
      offset.dy.clamp(0.0, maxY),
    );
  }

  /// Compute a tiled window size that fits within the MDI area.
  Size _tileSize(int count) {
    final areaWidth = MediaQuery.sizeOf(context).width - (_isMenuVisible ? _menuWidth : 0);
    final areaHeight = MediaQuery.sizeOf(context).height - 28 - 26;
    final rows = (count <= 2) ? 1 : (count <= 4 ? 2 : 3);
    final cols = (count / rows).ceil();
    final w = (areaWidth / cols).clamp(350.0, double.infinity);
    final h = (areaHeight / rows).clamp(250.0, double.infinity);
    return Size(w, h);
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
      win
        ..maximized = !win.maximized
        ..minimized = false;
      _activeWindowId = id;
    });
  }

  void _minimizeWindow(int id) {
    setState(() {
      _windows.firstWhere((w) => w.id == id).minimized = true;
      if (_activeWindowId == id) _activeWindowId = null;
    });
  }

  void _restoreWindow(int id) {
    setState(() {
      _windows.firstWhere((w) => w.id == id).minimized = false;
      _activeWindowId = id;
    });
  }

  void _cascadeWindows() {
    final visible = _windows.where((w) => !w.minimized).toList();
    if (visible.isEmpty) return;
    final size = _tileSize(visible.length);
    final w = size.width.clamp(350.0, 700.0);
    final h = size.height.clamp(250.0, 500.0);
    setState(() {
      int index = 0;
      for (final win in visible) {
        win
          ..maximized = false
          ..offset = _clampOffset(Offset(40.0 + index * 32, 40.0 + index * 32), w, h)
          ..width = w
          ..height = h;
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
      final size = _tileSize(visible.length);
      for (int i = 0; i < visible.length; i++) {
        final win = visible[i];
        final row = i ~/ cols;
        final col = i % cols;
        win
          ..maximized = false
          ..offset = _clampOffset(Offset(col * size.width, row * size.height), size.width, size.height)
          ..width = size.width
          ..height = size.height;
      }
    });
  }

  void _tileVertical() {
    final visible = _windows.where((w) => !w.minimized).toList();
    if (visible.isEmpty) return;
    setState(() {
      final cols = (visible.length <= 2) ? 1 : (visible.length <= 4 ? 2 : 3);
      final size = _tileSize(visible.length);
      for (int i = 0; i < visible.length; i++) {
        final win = visible[i];
        final row = i ~/ cols;
        final col = i % cols;
        win
          ..maximized = false
          ..offset = _clampOffset(Offset(col * size.width, row * size.height), size.width, size.height)
          ..width = size.width
          ..height = size.height;
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
    final minimizedWindows = _windows.where((w) => w.minimized).toList();

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
            null,
            _MenuItemData('Minimize All', Icons.minimize, hasWindows ? _minimizeAll : null),
            null,
            ..._windows.map((win) => _MenuItemData(
              win.title,
              win.minimized ? Icons.minimize : Icons.tab,
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
          const Spacer(),
          if (minimizedWindows.isNotEmpty) ...[
            Container(
              width: 1,
              height: 18,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            ...minimizedWindows.map((win) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _restoreWindow(win.id),
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.minimize, size: 13, color: Color(0xFF1565C0)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                win.title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _closeWindow(win.id),
                        borderRadius: BorderRadius.circular(4),
                        child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )),
          ],
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
            Flexible(
              child: Text(
                'Active: None',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 24),
            SizedBox(width: 10),
            Text(
              'Product Manager',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        actions: const [
          SizedBox(width: 8),
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
      child: MdiWindowWidget(
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
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isMenuVisible ? _menuWidth : 0,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: _isMenuVisible ? _buildSidebar() : const SizedBox.shrink(),
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

                return Column(
                  children: [
                    Expanded(
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
                                      child: MdiWindowWidget(
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
                                  top: win.offset.dy.clamp(0.0, (mdiAreaHeight - 50).clamp(0.0, double.infinity)),
                                  child: GestureDetector(
                                    onPanUpdate: (details) {
                                      setState(() {
                                        win.offset = Offset(
                                          (win.offset.dx + details.delta.dx).clamp(0.0, (constraints.maxWidth - 100).clamp(0.0, double.infinity)),
                                          (win.offset.dy + details.delta.dy).clamp(0.0, (mdiAreaHeight - 50).clamp(0.0, double.infinity)),
                                        );
                                      });
                                    },
                                    onTap: () => _bringToFront(win.id),
                                    child: MdiWindowWidget(
                                      title: win.title,
                                      maximized: false,
                                      isActive: isActive,
                                      width: win.width.clamp(350.0, constraints.maxWidth > 350.0 ? constraints.maxWidth : 350.0),
                                      height: win.height.clamp(250.0, mdiAreaHeight > 250.0 ? mdiAreaHeight : 250.0),
                                      onClose: () => _closeWindow(win.id),
                                      onMaximize: () => _toggleMaximize(win.id),
                                      onMinimize: () => _minimizeWindow(win.id),
                                      onBringToFront: () => _bringToFront(win.id),
                                      onResize: (newSize) {
                                        setState(() {
                                          win
                                            ..width = newSize.width
                                            ..height = newSize.height;
                                        });
                                      },
                                      child: win.child,
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
