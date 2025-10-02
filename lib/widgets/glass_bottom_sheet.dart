import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/quick_action_item.dart';

class GlassBottomSheet extends StatefulWidget {
  final List<QuickActionItem> items;

  const GlassBottomSheet({super.key, required this.items});

  @override
  State<GlassBottomSheet> createState() => _GlassBottomSheetState();
}

class _GlassBottomSheetState extends State<GlassBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Give more space - increase item height and base height
    final itemHeight = 85.0; // Increased from 70.0
    final baseHeight = 120.0; // Increased from 100.0
    final contentHeight = baseHeight + (widget.items.length * itemHeight);
    final maxHeight = screenHeight * 0.5; // Increased from 0.4 to 0.5
    final finalHeight = contentHeight.clamp(200.0, maxHeight); // Increased min from 180

    return SlideTransition(
      position: _slideAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(20),
          width: screenWidth - 40,
          height: finalHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18), // Increased from 16
                    // Title
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20), // Increased from 16
                    // Action items with more space
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16), // Reduced padding
                        itemCount: widget.items.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return Container(
                            height: itemHeight,
                            margin: const EdgeInsets.only(bottom: 12), // Increased spacing
                            child: _buildActionItem(widget.items[index]),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12), // Increased bottom padding
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(QuickActionItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: item.onTap,
        child: Container(
          height: 75.0, // Fixed height to prevent overflow
          padding: const EdgeInsets.all(14), // Slightly reduced padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 45, // Slightly smaller
                height: 45, // Slightly smaller
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Icon(
                  item.icon,
                  color: Colors.white,
                  size: 22, // Slightly smaller
                ),
              ),
              const SizedBox(width: 14), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Important: prevent overflow
                  children: [
                    Flexible( // Wrap title in Flexible
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15, // Slightly smaller
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Flexible( // Wrap subtitle in Flexible
                      child: Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 13, // Slightly smaller
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.5),
                size: 14, // Slightly smaller
              ),
            ],
          ),
        ),
      ),
    );
  }
}
