import 'bed.dart';
import 'enums.dart';

class Room {
  String roomNumber;
  RoomType type;
  int capacity;
  List<Bed> beds = [];
  bool isUnderMaintenance = false;
  
  Room({
    required this.roomNumber,
    required this.type,
    required this.capacity,
  });
  
  void initializeBeds() {
    beds.clear();
    for (int i = 1; i <= capacity; i++) {
      String bedId = '$roomNumber-${String.fromCharCode(64 + i)}';
      beds.add(Bed(bedId: bedId, roomNumber: roomNumber));
    }
  }
  
  bool canAcceptPriority(PriorityLevel priority) {
    if (isUnderMaintenance) return false;
    
    switch (priority) {
      case PriorityLevel.Critical:
        return type == RoomType.ICU;
      case PriorityLevel.Serious:
        return type == RoomType.ICU || type == RoomType.Ward;
      case PriorityLevel.Stable:
        return type == RoomType.General || type == RoomType.Private;
    }
  }
  
  List<Bed> getAvailableBeds() {
    return beds.where((bed) => bed.isAvailable()).toList();
  }
  
  Map<String, dynamic> toJson() {
    return {
      'roomNumber': roomNumber,
      'type': type.toString(),
      'capacity': capacity,
      'isUnderMaintenance': isUnderMaintenance,
      'beds': beds.map((bed) => bed.toJson()).toList(),
    };
  }
  
  factory Room.fromJson(Map<String, dynamic> json) {
    Room room = Room(
      roomNumber: json['roomNumber'],
      type: RoomType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => RoomType.General,
      ),
      capacity: json['capacity'],
    );
    room.isUnderMaintenance = json['isUnderMaintenance'] ?? false;
    
    // Initialize beds if none exist
    if (json['beds'] == null || (json['beds'] as List).isEmpty) {
      room.initializeBeds();
    } else {
      for (var bedData in json['beds']) {
        room.beds.add(Bed.fromJson(bedData));
      }
    }
    
    return room;
  }
  
  @override
  String toString() {
    return 'Room $roomNumber (${type.toString().split('.').last}) - Available: ${getAvailableBeds().length}/$capacity';
  }
}