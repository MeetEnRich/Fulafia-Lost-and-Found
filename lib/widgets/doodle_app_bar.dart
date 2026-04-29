import 'package:flutter/material.dart';
import 'package:lost_and_found/config/theme.dart';

/// A reusable AppBar with the doodle gradient background pattern.
/// Use this across all screens for a consistent branded look.
class DoodleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  const DoodleAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      bottom: bottom,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryGreenLight, AppTheme.primaryGreen],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              child: Icon(Icons.lens_blur, size: 120, color: Colors.white.withValues(alpha: 0.12)),
            ),
            Positioned(
              left: -15,
              bottom: -15,
              child: Icon(Icons.lens_blur, size: 80, color: Colors.white.withValues(alpha: 0.08)),
            ),
          ],
        ),
      ),
    );
  }
}
