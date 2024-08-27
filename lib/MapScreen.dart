import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:map1/marker_data.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen ({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _State();
}



class _State extends State<MapScreen> {
  final MapController _mapController= MapController();
  List <MarkerData> _markerData = [];
  List <Marker> _markers = [];
  LatLng? _selectedPosition;
  LatLng? _mylocation;
  LatLng? _draggedPosition;
  bool _isDragging = false;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults =[];
  bool _isSearching = false;

  Future<Position> _determinePosition() async{
     bool serviceEnabled;
     LocationPermission permission;


     serviceEnabled =  await Geolocator. isLocationServiceEnabled();
     if(!serviceEnabled){
       return Future.error("Location services are  disabled");
     }

     permission = await Geolocator.checkPermission();
     if(permission == LocationPermission.denied){
       permission = await Geolocator.requestPermission();
       if(permission == LocationPermission.denied){
         return Future.error("Location permissions are denied");
       }
     }
     if(permission == LocationPermission.deniedForever){
       return Future.error("Location permissions are deniedforver");
     }

     return await Geolocator.getCurrentPosition();

  }


  void _showCurrentLocation() async {
    try{
      Position position = await _determinePosition();
      LatLng currrenLatlng = LatLng(position.latitude, position.longitude);
      _mapController.move(currrenLatlng, 15.0);
      setState(() {
        _mylocation = currrenLatlng;
      });
    }catch(e){
     print(e);
    }
  }

   void _addMarker(LatLng position,String title, String description){
    setState(() {
      final markerData = MarkerData(position: (position), title: title, description: description);
      _markerData.add(markerData);
      _markers.add(Marker(point: position, width: 80,height: 80, child: GestureDetector(
      onTap: (){},
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4 ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow:[
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0,2),
                )
                ],
              ),
              child: Text(title, style : TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold
              )),
            ),
            Icon(
              Icons.location_on,
              color: Colors.redAccent,
              size: 40,
            )
          ],
        ),
      )));
    });
   }
   void _showMarkerDialog(BuildContext context, LatLng position){
    final TextEditingController titleController = TextEditingController();
    final TextEditingController desController =  TextEditingController();


    showDialog(context: context, builder: (context) => AlertDialog(
      title:  Text("Add Marker"),
      content:  Column(
      mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText : "Title"),
          ),
          TextField(
            controller: desController,
            decoration: InputDecoration(labelText: "description"),
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () {
          Navigator.pop(context);
        },
        child: Text("Cancel"),
        ),
           TextButton(onPressed: () {
               _addMarker(position, titleController.text, desController.text);
             },
           child: Text("Save"),)
      ],

    ),);
   }

   void _showMrkerInfo(MarkerData markerData){
    showDialog(context: (context), builder: (context) => AlertDialog(
      title: Text(markerData.title),
      content: Text(markerData.description),
      actions: [
        IconButton(onPressed: (){
          Navigator.pop(context);
        },
         icon: Icon(Icons.close))
      ],
    ),);
   }


   Future<void> _searchPlaces(String query) async{
    if(query.isEmpty){
      setState(() {
        _searchResults =[];
      });
      return;
    }
    final url = "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if(data.isNotEmpty){
      setState(() {
        _searchResults = data;
      });
    }else{
      setState(() {
        _searchResults = [];
      });
    }


   }

   void _moveToLocation(double lat, double lon){
    LatLng location = LatLng(lat, lon);
    _mapController.move(location, 15.0);
    setState(() {
      _selectedPosition = location;
      _searchResults = [];
      _isSearching = false;
      _searchController.clear();
    });
   }
   
   void initState(){
    super.initState();
    _searchController.addListener(() {
      _searchPlaces(_searchController.text);
    });
   }









  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // initialCenter: LatLng(51.5,-0.09),
             initialZoom: 13.0,
              onTap: (tapPosition , LatLng){
                _selectedPosition = LatLng;
                _draggedPosition = _selectedPosition;
              }
            ), children: [
              TileLayer(
                urlTemplate: "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
            MarkerLayer(markers: _markers),
            if(_isDragging && _draggedPosition != null)
              MarkerLayer(markers: [
                Marker(point: _draggedPosition!,width: 80, height: 80,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.indigo,
                      size: 40,
                    ))
              ]

              ),
            if(_mylocation != null)
              MarkerLayer(markers:[
                Marker(point: _mylocation!, width: 80, height: 80,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.indigo,
                      size: 40,
                    ))
              ])
                 
          ],
          ),
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Column(
            children: [
                  SizedBox(
                       height: 55,
                     child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "search place ...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                        prefixIcon : Icon(Icons.search),
                        suffixIcon: _isSearching?IconButton(onPressed: (){
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                            _searchResults = [];

                          });

                        }, icon: Icon(Icons.clear)): null
                    ),
                    onTap: (){
                      setState(() {
                        _isSearching = true;
                      });
                    },
                    ),
                  ),
                if(_isSearching && _searchResults.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child:  ListView.builder(shrinkWrap: true,itemCount: _searchResults.length,itemBuilder: (ctx,index){
                      final place = _searchResults[index];
                      return ListTile(
                        title: Text(place['display_name'],),
                        onTap: (){
                          final lat = double.parse(place['lat']);
                          final lon = double.parse(place['lon']);
                          _moveToLocation(lat, lon);
                        },
                      );
                    }),
                  )
              ],
            ),

          ),
          _isDragging == false ? Positioned (
            left: 20,
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              onPressed: (){
                setState(() {
                  _isDragging = true;
                });
              },
              child: Icon(Icons.add_location),
            ),
          ):    Positioned (
            left: 20,
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              onPressed: (){
                setState(() {
                  _isDragging = false;
                });
              },
              child: Icon(Icons.wrong_location),
            ),
          ),
          Positioned (
            right: 20,
            bottom: 20,
            child: Column
              (children:[
                FloatingActionButton(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  onPressed: _showCurrentLocation,
                   child: Icon(Icons.location_searching_rounded),
            ),

            ] ),

          ),


      ]
      ) ,
    );
  }
}
