// Custom notification service
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:todoApp/core/globals.dart';

// Import talker for logging

class NotificationService {
  static void showNotification(String message) {
    // Log the notification message
    talker.info('[NotificationService] Showing notification: $message');

    if (Platform.isIOS) {
      _showIOSNotification(message);
    } else {
      AppGlobals.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  static void _showIOSNotification(String message) {
    // Get the overlay context from navigator
    final overlay = AppGlobals.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final notification = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: CupertinoColors.systemGrey.withOpacity(0.9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                message,
                style: const TextStyle(color: CupertinoColors.white),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(notification);

    // Remove after delay
    Future.delayed(const Duration(seconds: 2), () {
      notification.remove();
    });
  }
}
