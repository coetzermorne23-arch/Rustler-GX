import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/navigation_place.dart';
import '../models/navigation_route.dart';
import '../models/route_instruction.dart';
import '../models/route_point.dart';

import 'gps_service.dart';
import 'navigation_place_service.dart';
import 'offline_routing_service.dart';

class NavigationService {
  NavigationService._();

  static final NavigationService instance =
      NavigationService._();

  final NavigationPlaceService places =
      NavigationPlaceService.instance;

  final OfflineRoutingService routing =
      OfflineRoutingService.instance;

  final GpsService gps =
      GpsService.instance;

  final ValueNotifier<NavigationPlace?>
      destination =
      ValueNotifier<NavigationPlace?>(
    null,
  );

  final ValueNotifier<NavigationRoute?>
      route =
      ValueNotifier<NavigationRoute?>(
    null,
  );

  final ValueNotifier<RouteInstruction?>
      currentInstruction =
      ValueNotifier<RouteInstruction?>(
    null,
  );

  final ValueNotifier<bool> navigating =
      ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> calculating =
      ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> offRoute =
      ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<String?> error =
      ValueNotifier<String?>(
    null,
  );

  DateTime? _lastReroute;

  bool _initialised =
      false;

  Future<void> initialise() async {
    if (_initialised) {
      return;
    }

    await places.initialise();

    await routing.initialise();

    gps.position.addListener(
      _gpsChanged,
    );

    _initialised =
        true;
  }

  Future<void> selectDestination(
    NavigationPlace place,
  ) async {
    destination.value =
        place;

    route.value =
        null;

    currentInstruction.value =
        null;

    navigating.value =
        false;

    offRoute.value =
        false;

    error.value =
        null;

    if (place.id != null) {
      await places.markVisited(
        place,
      );
    }
  }

  Future<bool> startNavigation() async {
    final NavigationPlace? target =
        destination.value;

    final Position? position =
        gps.position.value;

    if (target == null) {
      error.value =
          'No destination selected.';

      return false;
    }

    if (position == null) {
      error.value =
          'Waiting for GPS position.';

      return false;
    }

    calculating.value =
        true;

    error.value =
        null;

    try {
      final NavigationRoute?
          calculated =
          await routing.calculateRoute(
        startLatitude:
            position.latitude,
        startLongitude:
            position.longitude,
        destinationLatitude:
            target.latitude,
        destinationLongitude:
            target.longitude,
      );

      if (calculated == null) {
        error.value =
            routing.graph.hasRoadData
                ? 'No road route found.'
                : 'No offline road graph installed.';

        navigating.value =
            false;

        return false;
      }

      route.value =
          calculated;

      navigating.value =
          true;

      offRoute.value =
          false;

      if (calculated.instructions
          .isNotEmpty) {
        currentInstruction.value =
            calculated.instructions.first;
      }

      return true;
    } catch (exception) {
      error.value =
          'Routing error: $exception';

      navigating.value =
          false;

      return false;
    } finally {
      calculating.value =
          false;
    }
  }

  void stopNavigation() {
    navigating.value =
        false;

    route.value =
        null;

    destination.value =
        null;

    currentInstruction.value =
        null;

    offRoute.value =
        false;

    error.value =
        null;
  }

  void _gpsChanged() {
    if (!navigating.value) {
      return;
    }

    final Position? position =
        gps.position.value;

    final NavigationRoute? activeRoute =
        route.value;

    if (position == null ||
        activeRoute == null ||
        activeRoute.points.isEmpty) {
      return;
    }

    _updateInstruction(
      position,
      activeRoute,
    );

    final double distance =
        _distanceFromRoute(
      position,
      activeRoute,
    );

    const double offRouteThreshold =
        60;

    final bool nowOffRoute =
        distance >
            offRouteThreshold;

    offRoute.value =
        nowOffRoute;

    if (nowOffRoute) {
      _requestReroute();
    }
  }

  void _updateInstruction(
    Position position,
    NavigationRoute activeRoute,
  ) {
    if (activeRoute.instructions
        .isEmpty) {
      return;
    }

    RouteInstruction? closest;

    double closestDistance =
        double.infinity;

    for (final RouteInstruction instruction
        in activeRoute.instructions) {
      final double distance =
          Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        instruction.latitude,
        instruction.longitude,
      );

      if (distance <
          closestDistance) {
        closestDistance =
            distance;

        closest =
            instruction;
      }
    }

    if (closest != null) {
      currentInstruction.value =
          closest;
    }
  }

  double _distanceFromRoute(
    Position position,
    NavigationRoute activeRoute,
  ) {
    double closest =
        double.infinity;

    for (final RoutePoint point
        in activeRoute.points) {
      final double distance =
          Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance <
          closest) {
        closest =
            distance;
      }
    }

    return closest;
  }

  Future<void> _requestReroute() async {
    final DateTime now =
        DateTime.now();

    if (_lastReroute != null &&
        now.difference(
              _lastReroute!,
            ) <
            const Duration(
              seconds: 15,
            )) {
      return;
    }

    if (calculating.value) {
      return;
    }

    _lastReroute =
        now;

    await startNavigation();
  }
}