import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_strings.dart';
import '../../shared/widgets/permission_rationale_dialog.dart';

class PermissionService {
  /// Prompts user with rationale dialog before asking for Location permission
  static Future<bool> requestLocationPermission(BuildContext context) async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    if (!context.mounted) return false;

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PermissionRationaleDialog(
        title: 'Location Permission',
        icon: Icons.location_on_rounded,
        rationale: AppStrings.locationPermissionRationale,
      ),
    );

    if (proceed != true) return false;

    status = await Permission.locationWhenInUse.request();
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsPrompt(context, 'Location');
      }
      return false;
    }

    return status.isGranted;
  }

  /// Prompts user with rationale dialog before asking for Camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (!context.mounted) return false;

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PermissionRationaleDialog(
        title: 'Camera Access Needed',
        icon: Icons.qr_code_scanner_rounded,
        rationale: AppStrings.cameraPermissionRationale,
      ),
    );

    if (proceed != true) return false;

    status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsPrompt(context, 'Camera');
      }
      return false;
    }

    return status.isGranted;
  }

  /// Prompts user before accessing photo gallery
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    var status = await Permission.photos.status;
    if (status.isGranted) return true;

    if (!context.mounted) return false;

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PermissionRationaleDialog(
        title: 'Photo Library Access',
        icon: Icons.photo_library_rounded,
        rationale: AppStrings.photoPermissionRationale,
      ),
    );

    if (proceed != true) return false;

    status = await Permission.photos.request();
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsPrompt(context, 'Photos');
      }
      return false;
    }

    return status.isGranted;
  }

  static void _showSettingsPrompt(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          '$permissionName permission is permanently denied. Please enable it in the system app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
