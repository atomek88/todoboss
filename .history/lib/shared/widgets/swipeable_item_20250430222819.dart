import 'package:flutter/material.dart';

/// A reusable widget that provides swipe-to-delete functionality
/// Can be used for any content that needs to be dismissible
class SwipeableItem extends StatelessWidget {
  /// The content to display in the swipeable item
  final Widget child;

  /// Callback when the item is swiped to delete (left to right)
  final Function() onDelete;

  /// Optional callback when the item is swiped to complete (right to left)
  final Function()? onComplete;

  /// Whether to show the complete action
  final bool showCompleteAction;

  /// Background color for the delete action
  final Color deleteColor;

  /// Background color for the complete action
  final Color completeColor;

  /// Icon for the delete action
  final IconData deleteIcon;

  /// Icon for the complete action
  final IconData completeIcon;

  /// Optional key for the dismissible widget
  final Key? dismissibleKey;

  const SwipeableItem({
    Key? key,
    required this.child,
    required this.onDelete,
    this.onComplete,
    this.showCompleteAction = false,
    this.deleteColor = Colors.redAccent,
    this.completeColor = Colors.greenAccent,
    this.deleteIcon = Icons.delete,
    this.completeIcon = Icons.check_circle,
    this.dismissibleKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: dismissibleKey ?? UniqueKey(),
      // Background for swipe right (delete)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        color: deleteColor,
        child: Icon(
          deleteIcon,
          color: Colors.white,
        ),
      ),
      // Background for swipe left (complete)
      secondaryBackground: showCompleteAction
          ? Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              color: completeColor,
              child: Icon(
                completeIcon,
                color: Colors.white,
              ),
            )
          : Container(
              color: deleteColor,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(
                deleteIcon,
                color: Colors.white,
              ),
            ),
      // Allow both directions if complete action is enabled, otherwise just left-to-right
      direction: showCompleteAction
          ? DismissDirection.horizontal
          : DismissDirection.endToStart,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.4,
        DismissDirection.endToStart: 0.4,
      },
      confirmDismiss: (direction) async {
        if (showCompleteAction && direction == DismissDirection.startToEnd) {
          // Complete action (if enabled)
          if (onComplete != null) {
            onComplete!();
          }
          return false; // Don't actually dismiss
        } else if (direction == DismissDirection.endToStart) {
          // Delete action
          onDelete();
          return false; // Don't actually dismiss, we'll handle it in the parent
        }
        return false;
      },
      child: child,
    );
  }
}
