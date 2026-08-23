import '../models/rustler_gx_mode.dart';
import 'capability_runtime_service.dart';
import 'rustler_gx_config_service.dart';

class RuntimeCapabilityController {
  RuntimeCapabilityController._();

  static final RuntimeCapabilityController instance =
      RuntimeCapabilityController._();

  final RustlerGxConfigService _config =
      RustlerGxConfigService.instance;

  final CapabilityRuntimeService _runtime =
      CapabilityRuntimeService.instance;

  Future<Set<RustlerGxCapability>>
      getCapabilities() async {
    return _config.getCapabilities();
  }

  Future<void> setCapability(
    RustlerGxCapability capability,
    bool enabled,
  ) async {
    final Set<RustlerGxCapability> capabilities =
        await _config.getCapabilities();

    if (enabled) {
      capabilities.add(capability);
    } else {
      capabilities.remove(capability);
    }

    await _config.setCapabilities(
      capabilities,
    );

    await _runtime.applyCapabilities(
      capabilities,
    );
  }

  Future<void> setCapabilities(
    Set<RustlerGxCapability> capabilities,
  ) async {
    await _config.setCapabilities(
      capabilities,
    );

    await _runtime.applyCapabilities(
      capabilities,
    );
  }

  Future<void> refresh() async {
    await _runtime.applySavedCapabilities();
  }
}