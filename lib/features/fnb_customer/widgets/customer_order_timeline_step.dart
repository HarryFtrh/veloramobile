import '../../../core/design/tokens.dart';
import 'package:flutter/material.dart';

class CustomerOrderTimelineStep extends StatelessWidget {
  const CustomerOrderTimelineStep({
    super.key,
    this.isDone = false,
    this.isActive = false,
    this.isLast = false,
    required this.title,
    required this.time,
    required this.desc,
    this.badge,
  });

  final bool isDone;
  final bool isActive;
  final bool isLast;
  final String title;
  final String time;
  final String desc;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Icon & Line
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? p.tertiary
                      : (isActive
                            ? p.secondary
                            : p.line),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : (isActive
                            ? const Icon(
                                Icons.timelapse_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : Icon(
                                Icons.circle_outlined,
                                size: 14,
                                color: p.textSecondary,
                              )),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone
                        ? p.tertiary
                        : p.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: isActive ? const EdgeInsets.all(12) : EdgeInsets.zero,
              decoration: isActive
                  ? BoxDecoration(
                      color: p.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: p.secondary.withValues(alpha: 0.3),
                      ),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isActive
                                ? p.secondary
                                : p.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? p.secondary
                              : p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: p.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: p.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: p.secondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
