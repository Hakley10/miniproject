import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/room.dart';
import '../domain/patient.dart';
import '../domain/bed.dart';
import '../domain/enums.dart';

class RoomRepository {
  final List<Room> _rooms = [];
  late final File _dataFile;

  RoomRepository._();

  static Future<RoomRepository> create() async {
    final repo = RoomRepository._();
    final dir = await getApplicationDocumentsDirectory();
    repo._dataFile = File(p.join(dir.path, 'rooms_data.json'));
    await repo._loadFromFile();
    return repo;
  }

  Future<void> _loadFromFile() async {
    try {
      if (await _dataFile.exists()) {
        final content = await _dataFile.readAsString();
        if (content.trim().isEmpty) return;
        final List<dynamic> jsonList = json.decode(content);
        _rooms.clear();
        _rooms.addAll(jsonList.map((json) => Room.fromJson(json)));
      }
    } catch (e) {
      print('Error loading rooms: $e');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final jsonList = _rooms.map((room) => room.toJson()).toList();
      await _dataFile.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving rooms: $e');
    }
  }

  void addRoom(Room room) {
    room.initializeBeds(); // Ensure beds are initialized
    _rooms.add(room);
    _saveToFile();
  }

  Room? findRoomByNumber(String roomNumber) {
    try {
      return _rooms.firstWhere((room) => room.roomNumber == roomNumber);
    } catch (e) {
      return null;
    }
  }

  List<Room> getAllRooms() {
    return List.unmodifiable(_rooms);
  }

  List<Bed> getAllAvailableBeds() {
    return _rooms
        .where((room) => !room.isUnderMaintenance)
        .expand((room) => room.getAvailableBeds())
        .toList();
  }

  bool assignPatientToBed(Patient patient) {
    // Find suitable rooms based on patient priority
    List<Room> suitableRooms = _getSuitableRooms(patient.priority)
        .where((room) => !room.isUnderMaintenance)
        .toList();

    // Try to find an available bed in suitable rooms
    for (var room in suitableRooms) {
      var availableBeds = room.getAvailableBeds();
      if (availableBeds.isNotEmpty) {
        var availableBed = availableBeds.first;
        availableBed.assignPatient(patient.id);
        patient.assignedBed = availableBed;
        _saveToFile();
        return true;
      }
    }
    
    return false;
  }

  void dischargePatient(Patient patient) {
    if (patient.assignedBed != null) {
      var room = findRoomByNumber(patient.assignedBed!.roomNumber);
      if (room != null) {
        var bed = room.beds.firstWhere((b) => b.bedId == patient.assignedBed!.bedId);
        bed.removePatient();
        patient.assignedBed = null;
        _saveToFile();
      }
    }
  }

  void updateRoomMaintenance(String roomNumber, bool maintenanceStatus) {
    var room = findRoomByNumber(roomNumber);
    if (room != null) {
      room.isUnderMaintenance = maintenanceStatus;
      _saveToFile();
    }
  }

  List<Room> _getSuitableRooms(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.Critical:
        return _rooms.where((room) => room.type == RoomType.ICU).toList();
      case PriorityLevel.Serious:
        return _rooms
            .where((room) => room.type == RoomType.ICU || room.type == RoomType.Ward)
            .toList();
      case PriorityLevel.Stable:
        return _rooms
            .where((room) => 
                room.type == RoomType.General || room.type == RoomType.Private)
            .toList();
      default:
        return [];
    }
  }
}