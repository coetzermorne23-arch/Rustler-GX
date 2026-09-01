import 'package:flutter/material.dart';

import '../models/vehicle_warning.dart';
import '../services/vehicle_warning_service.dart';

class VehicleWarningOverlay extends StatelessWidget {
  final Widget child;

  const VehicleWarningOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final VehicleWarningService warnings = VehicleWarningService.instance;

    return Stack(
      children: [
        child,
        ValueListenableBuilder<VehicleWarning?>(
          valueListenable: warnings.activeWarning,
          builder: (
            context,
            warning,
            child,
          ) {
            if (warning == null) {
              return const SizedBox.shrink();
            }

            final bool critical =
                warning.severity == VehicleWarningSeverity.critical;

            return Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: SafeArea(
                child: Material(
                  elevation: 12,
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      8,
                      12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                      color: critical
                          ? const Color(
                              0xFF6D1717,
                            )
                          : const Color(
                              0xFF6A4B00,
                            ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          critical
                              ? Icons.error_rounded
                              : Icons.warning_amber_rounded,
                          size: 31,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                warning.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                warning.message,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dismiss',
                          onPressed: warnings.dismiss,
                          icon: const Icon(
                            Icons.close,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
