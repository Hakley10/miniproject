import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../domain/room.dart';
import '../domain/patient.dart';
import '../domain/bed.dart';
import '../domain/enums.dart';

class RoomRepository {
  final List<Room> _rooms = [];
  late final File _dataFile;

  RoomRepository._();

  static Future<RoomRepository> create({String? filePath}) async {
    final repo = RoomRepository._();
    repo._dataFile = File(filePath ?? p.join(Directory.current.path, 'rooms_data.json'));
    await repo._loadFromFile();
    return repo;
  }

  // ✅ Load rooms from {"rooms": [...]}
  Future<void> _loadFromFile() async {
    try {
      if (await _dataFile.exists()) {
        final content = await _dataFile.readAsString();
        if (content.trim().isEmpty) return;

        final Map<String, dynamic> data = json.decode(content);
        final List<dynamic> jsonList = data['rooms'] ?? [];

        _rooms.clear();
        _rooms.addAll(jsonList.map((json) => Room.fromJson(json)));

        print('📁 Loaded ${_rooms.length} rooms from ${_dataFile.path}');
      }
    } catch (e) {
      print('❌ Error loading room data: $e');
    }
  }

  // ✅ Save rooms as {"rooms": [...]}
  Future<void> _saveToFile() async {
    try {
      final data = {'rooms': _rooms.map((room) => room.toJson()).toList()};
      const encoder = JsonEncoder.withIndent('  ');
      await _dataFile.writeAsString(encoder.convert(data));
      print('💾 Saved ${_rooms.length} rooms to ${_dataFile.path}');
    } catch (e) {
      print('❌ Error saving rooms: $e');
    }
  }

  Future<void> addRoom(Room room) async {
    room.initializeBeds();
    _rooms.add(room);
    await _saveToFile(); // ✅ Instant save
    print('✅ Added room ${room.roomNumber}');
  }

  Room? findRoomByNumber(String roomNumber) {
    try {
      return _rooms.firstWhere((r) => r.roomNumber == roomNumber);
    } catch (_) {
      return null;
    }
  }

  List<Room> getAllRooms() => List.unmodifiable(_rooms);

  List<Bed> getAllAvailableBeds() {
    return _rooms
        .where((room) => !room.isUnderMaintenance)
        .expand((room) => room.getAvailableBeds())
        .toList();
  }

  Future<bool> assignPatientToBed(Patient patient) async {
    final suitableRooms = _getSuitableRooms(patient.priority)
        .where((r) => !r.isUnderMaintenance)
        .toList();

    for (final room in suitableRooms) {
      final availableBeds = room.getAvailableBeds();
      if (availableBeds.isNotEmpty) {
        final bed = availableBeds.first;
        bed.assignPatient(patient.id);
        patient.assignedBed = bed;
        await _saveToFile(); // ✅ Save instantly
        print('🛏️ Assigned ${patient.name} to ${bed.bedId}');
        return true;
      }
    }

    print('⚠️ No available beds found for ${patient.name}');
    return false;
  }

  Future<void> dischargePatient(Patient patient) async {
    if (patient.assignedBed != null) {
      final room = findRoomByNumber(patient.assignedBed!.roomNumber);
      if (room != null) {
        final bed = room.beds.firstWhere(
          (b) => b.bedId == patient.assignedBed!.bedId,
        );
        bed.removePatient();
        patient.assignedBed = null;
        await _saveToFile(); // ✅ Save instantly
        print('✅ Patient discharged successfully');
      }
    }
  }

  Future<void> updateRoomMaintenance(String roomNumber, bool status) async {
    final room = findRoomByNumber(roomNumber);
    if (room != null) {
      room.isUnderMaintenance = status;
      await _saveToFile();
      print('🧰 Room $roomNumber maintenance updated: $status');
    }
  }

  List<Room> _getSuitableRooms(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.critical:
        return _rooms.where((r) => r.type == RoomType.icu).toList();
      case PriorityLevel.serious:
        return _rooms
            .where((r) => r.type == RoomType.icu || r.type == RoomType.ward)
            .toList();
      case PriorityLevel.stable:
        return _rooms
            .where((r) => r.type == RoomType.general || r.type == RoomType.private)
            .toList();
    }
  }
}
