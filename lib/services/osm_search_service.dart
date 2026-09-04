import 'dart:convert';
import 'dart:io';

import '../models/navigation_place.dart';

class OsmSearchService {
  OsmSearchService._();
  static final OsmSearchService instance = OsmSearchService._();

  Future<List<NavigationPlace>> search(String query,
      {double? latitude, double? longitude, int limit = 30}) async {
    final q = query.trim();
    if (q.length < 2) return const <NavigationPlace>[];
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final params = <String, String>{
        'q': q,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '$limit',
        'countrycodes': 'za',
      };
      if (latitude != null && longitude != null) {
        params['viewbox'] =
            '${longitude - 1.5},${latitude + 1.5},${longitude + 1.5},${latitude - 1.5}';
      }
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader,
          'RigOS/1.0 Android local-first navigation');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response =
          await request.close().timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return const <NavigationPlace>[];
      final body = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(body);
      if (decoded is! List) return const <NavigationPlace>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final lat = double.tryParse('${row['lat']}');
            final lon = double.tryParse('${row['lon']}');
            if (lat == null || lon == null) return null;
            return NavigationPlace(
              name: (row['display_name'] as String?)?.trim().isNotEmpty == true
                  ? row['display_name'] as String
                  : q,
              latitude: lat,
              longitude: lon,
            );
          })
          .whereType<NavigationPlace>()
          .toList(growable: false);
    } catch (_) {
      return const <NavigationPlace>[];
    } finally {
      client.close(force: true);
    }
  }
}
