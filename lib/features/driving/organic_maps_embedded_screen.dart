import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/organic_maps_service.dart';

class OrganicMapsEmbeddedScreen extends StatefulWidget {
  const OrganicMapsEmbeddedScreen({
    super.key,
  });

  @override
  State<OrganicMapsEmbeddedScreen> createState() =>
      _OrganicMapsEmbeddedScreenState();
}

class _OrganicMapsEmbeddedScreenState extends State<OrganicMapsEmbeddedScreen> {
  final OrganicMapsService service = OrganicMapsService.instance;

  bool checking = true;
  bool available = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final bool ready = await service.embeddedAvailable();

    if (!mounted) {
      return;
    }

    setState(() {
      available = ready;
      checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!available) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('RANGER GX MAPS'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.map_outlined,
                    size: 72,
                  ),
                  SizedBox(
                    height: 18,
                  ),
                  Text(
                    'ORGANIC MAPS SDK NOT BUNDLED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Build the local Organic Maps SDK with '
                    'tools/build_and_install_organic_maps_sdk.sh. '
                    'The current Ranger offline map remains available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Embedded Organic Maps is Android-only.',
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AndroidView(
            viewType: OrganicMapsService.embeddedViewType,
            creationParams: const <String, Object>{
              'display': 'device',
            },
            creationParamsCodec: const StandardMessageCodec(),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: Material(
                color: const Color(0xCC11171A),
                borderRadius: BorderRadius.circular(14),
                child: IconButton(
                  tooltip: 'Back to RigOS',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: _AttributionBadge(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributionBadge extends StatelessWidget {
  const _AttributionBadge();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC11171A),
      borderRadius: BorderRadius.circular(10),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        child: Text(
          'Map engine: Organic Maps Project • Data: OpenStreetMap',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
