import 'package:flutter/material.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import '../services/place_service.dart';

class PlaceSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? initialValue;
  final Function(Place) onPlaceSelected;

  const PlaceSearchField({
    super.key,
    required this.controller,
    required this.labelText,
    this.initialValue,
    required this.onPlaceSelected,
  });

  @override
  _PlaceSearchFieldState createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  final PlaceService _placeService = PlaceService();
  List<Place> _suggestions = [];
  bool _isLoading = false;
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      widget.controller.text = widget.initialValue!;
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final results = await _placeService.searchPlaces(query);
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching places: ${e.toString()}')),
      );
    }
  }

  void _selectPlace(Place place) {
    widget.controller.text = place.displayName;
    widget.onPlaceSelected(place);
    setState(() {
      _isSearchVisible = false;
      _suggestions = [];
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearchVisible = true);
                _searchPlaces(widget.controller.text);
              },
            ),
          ),
          onChanged: (value) {
            if (_isSearchVisible) {
              _searchPlaces(value);
            }
          },
          onTap: () {
            setState(() => _isSearchVisible = true);
            if (widget.controller.text.isNotEmpty) {
              _searchPlaces(widget.controller.text);
            }
          },
        ),
        if (_isSearchVisible)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _suggestions.isEmpty
                    ? ListTile(
                        title: const Text('No places found'),
                        onTap: () {
                          setState(() => _isSearchVisible = false);
                        },
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length > 5 ? 5 : _suggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_suggestions[index].displayName),
                            onTap: () => _selectPlace(_suggestions[index]),
                          );
                        },
                      ),
          ),
      ],
    );
  }
}
