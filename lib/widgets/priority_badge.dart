import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool showLabel;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      switch (priority.toLowerCase()) {
        case 'high':
          return Colors.red;
        case 'medium':
          return Colors.orange;
        case 'low':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    String getLabel() {
      switch (priority.toLowerCase()) {
        case 'high':
          return 'HIGH';
        case 'medium':
          return 'MEDIUM';
        case 'low':
          return 'LOW';
        default:
          return priority.toUpperCase();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getColor().withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: showLabel
          ? Text(
        getLabel(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: getColor(),
        ),
      )
          : Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: getColor(),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
