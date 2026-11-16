import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double speed;
  final String address;

  // Componentes independientes de la dirección.
  final String street;
  final String sector;
  final String district;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.speed,
    required this.address,
    this.street = '',
    this.sector = '',
    this.district = '',
  });
}

class LocationService {
  final Geocoding _geocoding = Geocoding();

  Future<LocationData> getCurrentLocation() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'El servicio de ubicación está desactivado.',
      );
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'No se concedió el permiso de ubicación.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'El permiso de ubicación está denegado permanentemente. Actívalo desde los ajustes del teléfono.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    String address = 'Dirección no disponible';
    String street = '';
    String sector = '';
    String district = '';

    try {
      final placemarks =
          await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        String clean(String? value) {
          return value?.trim() ?? '';
        }

        // Vía: nombre de calle o avenida y número.
        street = clean(place.street);

        if (street.isEmpty) {
          street = clean(place.thoroughfare);
        }

        final streetNumber = clean(place.subThoroughfare);

        if (streetNumber.isNotEmpty &&
            !street.contains(streetNumber)) {
          street = '$street $streetNumber'.trim();
        }

        // Sector: urbanización, cooperativa o zona.
        sector = clean(place.subLocality);

        // Distrito: localidad o división administrativa.
        district = clean(place.locality);

        if (district.isEmpty) {
          district = clean(place.subAdministrativeArea);
        }

        if (district.isEmpty) {
          district = clean(place.administrativeArea);
        }

        final parts = <String>[
          street,
          sector,
          district,
          clean(place.administrativeArea),
          clean(place.country),
        ].where((part) => part.isNotEmpty).toList();

        if (parts.isNotEmpty) {
          address = parts.join(', ');
        }
      }
    } catch (_) {
      // Se conserva la ubicación GPS aunque no se obtenga
      // información de dirección.
    }

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed,
      address: address,
      street: street,
      sector: sector,
      district: district,
    );
  }
}
