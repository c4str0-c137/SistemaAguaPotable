abstract class ViviendaEvent {}

class FetchViviendas extends ViviendaEvent {}

class UpdateViviendaGPS extends ViviendaEvent {
  final int id;
  final double latitude;
  final double longitude;
  UpdateViviendaGPS({required this.id, required this.latitude, required this.longitude});
}
