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

  static Future<RoomRepository> create() async {
    final repo = RoomRepository._();
    final dir = Directory.current;
    repo._dataFile = File(p.join(dir.path, 'rooms_data.json'));

    // Create file only if it doesn't exist — don't overwrite
    if (!await repo._dataFile.exists()) {
      await repo._dataFile.writeAsString(json.encode({'rooms': []}));
      print('🆕 Created new empty rooms_data.json');
    }

    await repo._loadFromFile();
    return repo;
  }

  Future<void> _loadFromFile() async {
  try {
    if (await _dataFile.exists()) {
      final content = await _dataFile.readAsString();
      if (content.trim().isEmpty) return;

      final Map<String, dynamic> data = json.decode(content);
      final List<dynamic> roomList = data['rooms'] ?? [];
      _rooms
        ..clear()
        ..addAll(roomList.map((json) => Room.fromJson(json)));
    }
  } catch (e) {
    print('❌ Error loading room data: $e');
  }
  }


  Future<void> _saveToFile() async {
  try {
    final data = {'rooms': _rooms.map((r) => r.toJson()).toList()};
    final jsonContent = const JsonEncoder.withIndent('  ').convert(data);

    // ✅ Overwrite and truncate the file completely
    final raf = await _dataFile.open(mode: FileMode.write);
    await raf.truncate(0); // clear old content
    await raf.writeString(jsonContent);
    await raf.close();

    // Optional: ensure it's flushed immediately
    await _dataFile.writeAsString('', mode: FileMode.append, flush: true);
  } catch (e) {
    print('❌ Error saving rooms: $e');
  }
  }



  Future<void> addRoom(Room room) async {
    room.initializeBeds();
    if (findRoomByNumber(room.roomNumber) != null) {
      print('❌ Room ${room.roomNumber} already exists!');
      return;
    }
    _rooms.add(room);
    await _saveToFile();
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

  Future<bool> assignPatientToBed(Patient patient) async {
    final suitableRooms = _getSuitableRooms(patient.priority)
        .where((r) => !r.isUnderMaintenance)
        .toList();

    for (final room in suitableRooms) {
      final beds = room.getAvailableBeds();
      if (beds.isNotEmpty) {
        final bed = beds.first;
        bed.assignPatient(patient.id);
        patient.assignedBed = bed;
        await _saveToFile();
        print('🛏️ Assigned patient ${patient.name} to ${bed.bedId}');
        return true;
      }
    }
    print('⚠️ No available beds found for ${patient.name}');
    return false;
  }

  Future<void> dischargePatient(Patient patient) async {
    if (patient.assignedBed == null) return;
    final room = findRoomByNumber(patient.assignedBed!.roomNumber);
    if (room != null) {
      final bed = room.beds.firstWhere((b) => b.bedId == patient.assignedBed!.bedId);
      bed.removePatient();
      patient.assignedBed = null;
      await _saveToFile();
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
            .where((r) =>
                r.type == RoomType.general || r.type == RoomType.private)
            .toList();
    }
  }
}
