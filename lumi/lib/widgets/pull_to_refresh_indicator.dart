import 'package:flutter/material.dart';
import '../config/app_config.dart';

class PullToRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double triggerDistance;

  const PullToRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.triggerDistance = 80.0,
  });

  @override
  State<PullToRefreshIndicator> createState() => _PullToRefreshIndicatorState();
}

class _PullToRefreshIndicatorState extends State<PullToRefreshIndicator> {
  bool _isRefreshing = false;
  double _dragOffset = 0.0;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    await widget.onRefresh();
    setState(() {
      _isRefreshing = false;
      _dragOffset = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (!_isRefreshing && details.primaryDelta != null) {
          if (details.primaryDelta! > 0) {
            // 向下拖动
            setState(() {
              _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, widget.triggerDistance * 1.5);
            });
          } else {
            // 向上拖动，重置
            setState(() {
              _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, widget.triggerDistance * 1.5);
            });
          }
        }
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset >= widget.triggerDistance && !_isRefreshing) {
          _handleRefresh();
        } else {
          setState(() => _dragOffset = 0.0);
        }
      },
      child: Stack(
        children: [
          Transform.translate(
            offset: Offset(0, _dragOffset.clamp(0.0, widget.triggerDistance)),
            child: widget.child,
          ),
          if (_dragOffset > 0 || _isRefreshing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: (_dragOffset / widget.triggerDistance).clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _isRefreshing
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(AppConfig.primaryColor),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '刷新中...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : const Icon(
                            Icons.arrow_downward,
                            color: Color(AppConfig.primaryColor),
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

