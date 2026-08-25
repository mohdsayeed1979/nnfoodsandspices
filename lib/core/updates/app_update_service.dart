import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Google Play in-app update prompt for already-installed Android users.
///
/// Uses the official Play Core "in-app updates" API via [InAppUpdate] — it
/// only ever routes through Google Play (no external APK download, no custom
/// updater). We use the **flexible** flow: the update downloads in the
/// background while the user keeps using the app, then we show a
/// "Restart to update" snackbar. Everything is wrapped so a missing/older
/// Play Store, no network, a sideloaded build, or a debug build simply
/// no-ops instead of crashing.
class AppUpdateService {
  AppUpdateService(this._messengerKey);

  final GlobalKey<ScaffoldMessengerState> _messengerKey;

  // Guards against launching a second check while one is already running
  // (e.g. app resumed repeatedly). Reset only after the flow settles.
  bool _inProgress = false;
  // Once we've shown "update ready to install" we stop re-prompting for the
  // life of the process, so a resumed app doesn't nag after downloading.
  bool _downloadedPromptShown = false;

  /// Checks Google Play for a newer version and, if one is available and the
  /// flexible flow is allowed, starts a background download. Safe to call on
  /// launch and on resume — never throws.
  Future<void> checkForUpdate() async {
    // Play in-app updates are Android-only. Skip web/iOS/desktop and debug
    // builds (the Play Store can't service a debug/sideloaded install).
    if (kIsWeb || !Platform.isAndroid || kDebugMode) return;
    if (_inProgress || _downloadedPromptShown) return;
    _inProgress = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        _inProgress = false;
        return;
      }
      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          _promptRestart();
        }
      } else if (info.immediateUpdateAllowed) {
        // Fallback if Play only permits the immediate (blocking) flow.
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      // No Play Store, no network, sideloaded build, API error — all benign.
      // Never surface an error to the user for an optional update check.
      debugPrint('In-app update check skipped: $e');
    } finally {
      _inProgress = false;
    }
  }

  void _promptRestart() {
    if (_downloadedPromptShown) return;
    _downloadedPromptShown = true;
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('A new version has been downloaded.'),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'RESTART',
          onPressed: () async {
            try {
              await InAppUpdate.completeFlexibleUpdate();
            } catch (e) {
              debugPrint('completeFlexibleUpdate failed: $e');
            }
          },
        ),
      ),
    );
  }
}
