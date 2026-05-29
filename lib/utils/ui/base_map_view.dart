import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:arceituna/models/models.dart';

class BaseMapView extends StatelessWidget {
  final MapController? controller;
  final LatLng initialCenter;
  final double initialZoom;
  final Function(TapPosition, LatLng)? onTap;
  final Enclosure? enclosure;
  final List<Olive> olives;
  final LatLng? userLocation;
  final bool showOlives;
  final Function(Olive)? onOliveTap;
  final List<Marker> additionalMarkers;

  const BaseMapView({
    super.key,
    this.controller,
    required this.initialCenter,
    this.initialZoom = 18.0,
    this.onTap,
    this.enclosure,
    this.olives = const [],
    this.userLocation,
    this.showOlives = true,
    this.onOliveTap,
    this.additionalMarkers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        onTap: onTap,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://www.ign.es/wmts/pnoa-ma?layer=OI.OrthoimageCoverage&style=default&tilematrixset=GoogleMapsCompatible&Service=WMTS&Request=GetTile&Version=1.0.0&Format=image/jpeg&TileMatrix={z}&TileCol={x}&TileRow={y}',
          userAgentPackageName: 'com.example.arceituna',
        ),
        if (enclosure != null && enclosure!.coordinates.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: enclosure!.coordinates
                    .map((c) => LatLng(c.latitude, c.longitude))
                    .toList(),
                color: const Color.fromARGB(51, 250, 201, 3),
                borderStrokeWidth: 3,
                borderColor: const Color.fromARGB(255, 0, 255, 0),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (showOlives)
              ...olives.map((olive) => Marker(
                    point: LatLng(
                        olive.location.latitude, olive.location.longitude),
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: _buildOliveIcon(),
                      onPressed: () => onOliveTap?.call(olive),
                    ),
                  )),
            if (userLocation != null)
              Marker(
                point: userLocation!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 30,
                  shadows: [
                    Shadow(offset: Offset(-1, -1), color: Colors.black),
                    Shadow(offset: Offset(1, -1), color: Colors.black),
                    Shadow(offset: Offset(1, 1), color: Colors.black),
                    Shadow(offset: Offset(-1, 1), color: Colors.black),
                  ],
                ),
              ),
            ...additionalMarkers,
          ],
        ),
      ],
    );
  }

  Widget _buildOliveIcon() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...[
            const Offset(-1, -1),
            const Offset(1, -1),
            const Offset(1, 1),
            const Offset(-1, 1),
          ].map((offset) => Transform.translate(
                offset: offset,
                child: SvgPicture.asset(
                  'assets/olive.svg',
                  width: 30,
                  height: 30,
                  colorFilter:
                      const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
              )),
          SvgPicture.asset(
            'assets/olive.svg',
            width: 30,
            height: 30,
            colorFilter: const ColorFilter.mode(
                Color.fromARGB(255, 35, 87, 23), BlendMode.srcIn),
          ),
        ],
      ),
    );
  }
}
