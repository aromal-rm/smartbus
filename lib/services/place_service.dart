import 'package:osm_nominatim/osm_nominatim.dart';

class PlaceService {
  // Search for places using OpenStreetMap Nominatim
  Future<List<Place>> searchPlaces(
    String query, {
    List<String>? countryCodes,
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      final places = await Nominatim.searchByName(
        query: query,
        limit: limit,
        addressDetails: true,
        countryCodes: countryCodes, // Now optional
      );
      return places;
    } catch (e) {
      print('Error searching places: $e');
      throw Exception('Failed to search places: $e');
    }
  }

  // Get details of a place by its name (since searchByOSMId is not available)
  Future<Place> getPlaceDetails(String placeName) async {
    try {
      final places = await Nominatim.searchByName(
        query: placeName,
        limit: 1,
        addressDetails: true,
      );
      
      if (places.isNotEmpty) {
        return places.first;
      } else {
        throw Exception('Place not found');
      }
    } catch (e) {
      print('Error getting place details: $e');
      throw Exception('Failed to get place details: $e');
    }
  }
}
