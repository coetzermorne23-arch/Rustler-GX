import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../models/navigation_route.dart';
import '../models/road_graph_models.dart';
import '../models/route_instruction.dart';
import '../models/route_point.dart';
import 'road_graph_service.dart';

class OfflineRoutingService {
  OfflineRoutingService._();

  static final OfflineRoutingService instance =
      OfflineRoutingService._();

  final RoadGraphService graph =
      RoadGraphService.instance;

  Future<void> initialise() async {
    await graph.initialise();
  }

  Future<NavigationRoute?> calculateRoute({
    required double startLatitude,
    required double startLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    await initialise();

    if (!graph.hasRoadData) {
      return null;
    }

    final RoadNode? start =
        graph.findNearestNode(
      startLatitude,
      startLongitude,
    );

    final RoadNode? destination =
        graph.findNearestNode(
      destinationLatitude,
      destinationLongitude,
    );

    if (start == null ||
        destination == null) {
      return null;
    }

    if (start.id ==
        destination.id) {
      return NavigationRoute(
        points: <RoutePoint>[
          RoutePoint(
            latitude:
                startLatitude,
            longitude:
                startLongitude,
          ),
          RoutePoint(
            latitude:
                destinationLatitude,
            longitude:
                destinationLongitude,
          ),
        ],
        instructions: <RouteInstruction>[
          RouteInstruction(
            type:
                RouteInstructionType.start,
            text:
                'Start navigation',
            distanceMetres:
                0,
            latitude:
                startLatitude,
            longitude:
                startLongitude,
          ),
          RouteInstruction(
            type:
                RouteInstructionType.arrive,
            text:
                'Arrive at destination',
            distanceMetres:
                0,
            latitude:
                destinationLatitude,
            longitude:
                destinationLongitude,
          ),
        ],
        distanceMetres:
            _distanceMetres(
          startLatitude,
          startLongitude,
          destinationLatitude,
          destinationLongitude,
        ),
        estimatedDuration:
            Duration.zero,
      );
    }

    final _SearchResult? result =
        _aStar(
      start,
      destination,
    );

    if (result == null) {
      return null;
    }

    return _buildNavigationRoute(
      result,
      startLatitude:
          startLatitude,
      startLongitude:
          startLongitude,
      destinationLatitude:
          destinationLatitude,
      destinationLongitude:
          destinationLongitude,
    );
  }

  _SearchResult? _aStar(
    RoadNode start,
    RoadNode destination,
  ) {
    final HeapPriorityQueue<_QueueNode>
        open =
        HeapPriorityQueue<_QueueNode>(
      (
        _QueueNode a,
        _QueueNode b,
      ) =>
          a.priority.compareTo(
        b.priority,
      ),
    );

    final Map<int, double> gScore =
        <int, double>{
      start.id: 0,
    };

    final Map<int, int> cameFrom =
        <int, int>{};

    final Map<int, RoadEdge> edgeFrom =
        <int, RoadEdge>{};

    final Set<int> closed =
        <int>{};

    open.add(
      _QueueNode(
        nodeId:
            start.id,
        priority:
            _heuristicSeconds(
          start,
          destination,
        ),
      ),
    );

    while (open.isNotEmpty) {
      final _QueueNode currentQueue =
          open.removeFirst();

      final int currentId =
          currentQueue.nodeId;

      if (closed.contains(
        currentId,
      )) {
        continue;
      }

      if (currentId ==
          destination.id) {
        return _reconstruct(
          start.id,
          destination.id,
          cameFrom,
          edgeFrom,
        );
      }

      closed.add(
        currentId,
      );

      final RoadNode? currentNode =
          graph.getNode(
        currentId,
      );

      if (currentNode == null) {
        continue;
      }

      final List<RoadEdge> edges =
          graph.getOutgoingEdges(
        currentId,
      );

      for (final RoadEdge edge
          in edges) {
        final int neighbourId =
            edge.toNode;

        if (closed.contains(
          neighbourId,
        )) {
          continue;
        }

        final double currentScore =
            gScore[currentId] ??
                double.infinity;

        final double tentative =
            currentScore +
                edge.travelSeconds;

        final double previous =
            gScore[neighbourId] ??
                double.infinity;

        if (tentative >= previous) {
          continue;
        }

        final RoadNode? neighbour =
            graph.getNode(
          neighbourId,
        );

        if (neighbour == null) {
          continue;
        }

        cameFrom[neighbourId] =
            currentId;

        edgeFrom[neighbourId] =
            edge;

        gScore[neighbourId] =
            tentative;

        final double priority =
            tentative +
                _heuristicSeconds(
                  neighbour,
                  destination,
                );

        open.add(
          _QueueNode(
            nodeId:
                neighbourId,
            priority:
                priority,
          ),
        );
      }
    }

    return null;
  }

  _SearchResult _reconstruct(
    int startId,
    int destinationId,
    Map<int, int> cameFrom,
    Map<int, RoadEdge> edgeFrom,
  ) {
    final List<int> nodeIds =
        <int>[
      destinationId,
    ];

    final List<RoadEdge> edges =
        <RoadEdge>[];

    int current =
        destinationId;

    while (current !=
        startId) {
      final int? previous =
          cameFrom[current];

      final RoadEdge? edge =
          edgeFrom[current];

      if (previous == null ||
          edge == null) {
        break;
      }

      edges.add(
        edge,
      );

      current =
          previous;

      nodeIds.add(
        current,
      );
    }

    return _SearchResult(
      nodeIds:
          nodeIds.reversed.toList(),
      edges:
          edges.reversed.toList(),
    );
  }

  NavigationRoute _buildNavigationRoute(
    _SearchResult result, {
    required double startLatitude,
    required double startLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) {
    final Map<int, RoadNode> nodes =
        graph.getNodes(
      result.nodeIds,
    );

    final List<RoutePoint> points =
        <RoutePoint>[
      RoutePoint(
        latitude:
            startLatitude,
        longitude:
            startLongitude,
      ),
    ];

    for (final int id
        in result.nodeIds) {
      final RoadNode? node =
          nodes[id];

      if (node == null) {
        continue;
      }

      points.add(
        RoutePoint(
          latitude:
              node.latitude,
          longitude:
              node.longitude,
        ),
      );
    }

    points.add(
      RoutePoint(
        latitude:
            destinationLatitude,
        longitude:
            destinationLongitude,
      ),
    );

    double totalDistance =
        0;

    double totalSeconds =
        0;

    for (final RoadEdge edge
        in result.edges) {
      totalDistance +=
          edge.distanceMetres;

      totalSeconds +=
          edge.travelSeconds;
    }

    final List<RouteInstruction>
        instructions =
        _buildInstructions(
      result,
      nodes,
    );

    instructions.insert(
      0,
      RouteInstruction(
        type:
            RouteInstructionType.start,
        text:
            'Start navigation',
        distanceMetres:
            0,
        latitude:
            startLatitude,
        longitude:
            startLongitude,
      ),
    );

    instructions.add(
      RouteInstruction(
        type:
            RouteInstructionType.arrive,
        text:
            'Arrive at destination',
        distanceMetres:
            0,
        latitude:
            destinationLatitude,
        longitude:
            destinationLongitude,
      ),
    );

    return NavigationRoute(
      points:
          points,
      instructions:
          instructions,
      distanceMetres:
          totalDistance,
      estimatedDuration:
          Duration(
        seconds:
            totalSeconds.round(),
      ),
    );
  }

  List<RouteInstruction>
      _buildInstructions(
    _SearchResult result,
    Map<int, RoadNode> nodes,
  ) {
    final List<RouteInstruction>
        instructions =
        <RouteInstruction>[];

    if (result.nodeIds.length <
        3) {
      return instructions;
    }

    double distanceSinceTurn =
        0;

    for (int i = 0;
        i < result.edges.length;
        i++) {
      distanceSinceTurn +=
          result.edges[i]
              .distanceMetres;

      if (i + 2 >=
          result.nodeIds.length) {
        continue;
      }

      final RoadNode? a =
          nodes[
              result.nodeIds[i]];

      final RoadNode? b =
          nodes[
              result.nodeIds[
                  i + 1]];

      final RoadNode? c =
          nodes[
              result.nodeIds[
                  i + 2]];

      if (a == null ||
          b == null ||
          c == null) {
        continue;
      }

      final double bearing1 =
          _bearing(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );

      final double bearing2 =
          _bearing(
        b.latitude,
        b.longitude,
        c.latitude,
        c.longitude,
      );

      final double change =
          _normaliseAngle(
        bearing2 -
            bearing1,
      );

      final RouteInstructionType
          type =
          _instructionType(
        change,
      );

      if (type ==
          RouteInstructionType
              .straight) {
        continue;
      }

      final RoadEdge edge =
          result.edges[
              math.min(
        i + 1,
        result.edges.length - 1,
      )];

      final String? roadName =
          edge.roadName;

      instructions.add(
        RouteInstruction(
          type:
              type,
          text:
              _instructionText(
            type,
            roadName,
          ),
          roadName:
              roadName,
          distanceMetres:
              distanceSinceTurn,
          latitude:
              b.latitude,
          longitude:
              b.longitude,
        ),
      );

      distanceSinceTurn =
          0;
    }

    return instructions;
  }

  RouteInstructionType
      _instructionType(
    double change,
  ) {
    final double absolute =
        change.abs();

    if (absolute < 20) {
      return RouteInstructionType
          .straight;
    }

    if (absolute >= 150) {
      return RouteInstructionType
          .uTurn;
    }

    if (change < 0) {
      if (absolute < 45) {
        return RouteInstructionType
            .slightLeft;
      }

      if (absolute < 110) {
        return RouteInstructionType
            .left;
      }

      return RouteInstructionType
          .sharpLeft;
    }

    if (absolute < 45) {
      return RouteInstructionType
          .slightRight;
    }

    if (absolute < 110) {
      return RouteInstructionType
          .right;
    }

    return RouteInstructionType
        .sharpRight;
  }

  String _instructionText(
    RouteInstructionType type,
    String? roadName,
  ) {
    final String road =
        roadName == null ||
                roadName.trim().isEmpty
            ? ''
            : ' onto $roadName';

    switch (type) {
      case RouteInstructionType.start:
        return 'Start navigation';

      case RouteInstructionType.straight:
        return 'Continue straight$road';

      case RouteInstructionType.slightLeft:
        return 'Keep slightly left$road';

      case RouteInstructionType.left:
        return 'Turn left$road';

      case RouteInstructionType.sharpLeft:
        return 'Turn sharp left$road';

      case RouteInstructionType.slightRight:
        return 'Keep slightly right$road';

      case RouteInstructionType.right:
        return 'Turn right$road';

      case RouteInstructionType.sharpRight:
        return 'Turn sharp right$road';

      case RouteInstructionType.uTurn:
        return 'Make a U-turn';

      case RouteInstructionType.arrive:
        return 'Arrive at destination';
    }
  }

  double _heuristicSeconds(
    RoadNode a,
    RoadNode b,
  ) {
    final double metres =
        _distanceMetres(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );

    // Optimistic 130 km/h heuristic.
    //
    // Keeping the heuristic optimistic means
    // A* does not incorrectly penalise a potentially
    // faster route.
    const double metresPerSecond =
        130 / 3.6;

    return metres /
        metresPerSecond;
  }

  double _distanceMetres(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius =
        6371000;

    final double phi1 =
        _degreesToRadians(
      lat1,
    );

    final double phi2 =
        _degreesToRadians(
      lat2,
    );

    final double deltaPhi =
        _degreesToRadians(
      lat2 - lat1,
    );

    final double deltaLambda =
        _degreesToRadians(
      lon2 - lon1,
    );

    final double a =
        math.sin(
              deltaPhi / 2,
            ) *
            math.sin(
              deltaPhi / 2,
            ) +
        math.cos(
              phi1,
            ) *
            math.cos(
              phi2,
            ) *
            math.sin(
              deltaLambda / 2,
            ) *
            math.sin(
              deltaLambda / 2,
            );

    final double c =
        2 *
            math.atan2(
              math.sqrt(a),
              math.sqrt(
                1 - a,
              ),
            );

    return earthRadius * c;
  }

  double _bearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double phi1 =
        _degreesToRadians(
      lat1,
    );

    final double phi2 =
        _degreesToRadians(
      lat2,
    );

    final double lambda =
        _degreesToRadians(
      lon2 - lon1,
    );

    final double y =
        math.sin(lambda) *
            math.cos(phi2);

    final double x =
        math.cos(phi1) *
                math.sin(phi2) -
            math.sin(phi1) *
                math.cos(phi2) *
                math.cos(lambda);

    final double degrees =
        math.atan2(
              y,
              x,
            ) *
            180 /
            math.pi;

    return (
      degrees + 360
    ) %
        360;
  }

  double _normaliseAngle(
    double angle,
  ) {
    double value =
        angle;

    while (value > 180) {
      value -= 360;
    }

    while (value < -180) {
      value += 360;
    }

    return value;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees *
        math.pi /
        180;
  }
}

class _QueueNode {
  final int nodeId;
  final double priority;

  const _QueueNode({
    required this.nodeId,
    required this.priority,
  });
}

class _SearchResult {
  final List<int> nodeIds;
  final List<RoadEdge> edges;

  const _SearchResult({
    required this.nodeIds,
    required this.edges,
  });
}