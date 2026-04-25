abstract class ViviendaEvent {}

class FetchViviendas extends ViviendaEvent {}

class UpdateViviendaGPS extends ViviendaEvent {
  final int id;
  final double latitude;
  final double longitude;
  UpdateViviendaGPS({required this.id, required this.latitude, required this.longitude});
}

class CreateVivienda extends ViviendaEvent {
  final Map<String, dynamic> data;
  CreateVivienda(this.data);
}

class UpdateVivienda extends ViviendaEvent {
  final int id;
  final Map<String, dynamic> data;
  UpdateVivienda({required this.id, required this.data});
}

class DeleteVivienda extends ViviendaEvent {
  final int id;
  DeleteVivienda(this.id);
}
