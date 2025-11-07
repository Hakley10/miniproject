import '../data/patient_repository.dart';
import '../data/room_repository.dart';
import 'patient.dart';
import 'room.dart';
import 'enums.dart';
import 'bed.dart';

class HospitalService {
  final PatientRepository patientRepo;
  final RoomRepository roomRepo;

  HospitalService(this.patientRepo, this.roomRepo);

  // Register a new patient
  Future<String> registerPatient(Patient patient) async {
    if (patientRepo.findPatientById(patient.id) != null) {
      return '❌ Patient ID already exists!';
    }
    await patientRepo.registerPatient(patient);
    return '✅ Patient ${patient.name} registered successfully!';
  }

  // Assign patient to bed
  Future<String> assignPatientToBed(String patientId) async {
  Patient? patient = patientRepo.findPatientById(patientId);
  if (patient == null) return '❌ Patient not found!';

  if (patient.assignedBed != null) {
    return '❌ Patient already assigned to bed ${patient.assignedBed!.bedId}';
  }

  bool success = await roomRepo.assignPatientToBed(patient); // ✅ await here
  if (success) {
    return '✅ Patient ${patient.name} assigned to bed ${patient.assignedBed!.bedId}';
  } else {
    return '❌ No suitable beds available for ${patient.priority.toString().split('.').last}';
  }
}


  // Discharge patient
  String dischargePatient(String patientId) {
    Patient? patient = patientRepo.findPatientById(patientId);
    if (patient == null) return '❌ Patient not found!';
    if (patient.assignedBed == null) return '❌ Patient not assigned to any bed!';

    roomRepo.dischargePatient(patient);
    return '✅ Patient ${patient.name} discharged successfully!';
  }

  // Add a new room
  String addRoom(String roomNumber, RoomType type, int capacity) {
    if (roomRepo.findRoomByNumber(roomNumber) != null) {
      return '❌ Room $roomNumber already exists!';
    }
    Room newRoom = Room(roomNumber: roomNumber, type: type, capacity: capacity);
    roomRepo.addRoom(newRoom);
    return '✅ Room $roomNumber (${type.toString().split('.').last}) created successfully with $capacity beds!';
  }

  // Put room under maintenance
  String putRoomUnderMaintenance(String roomNumber) {
    Room? room = roomRepo.findRoomByNumber(roomNumber);
    if (room == null) return '❌ Room not found!';
    if (room.isUnderMaintenance) return '❌ Room is already under maintenance!';

    var occupiedBeds = room.beds.where((b) => !b.isAvailable()).toList();
    if (occupiedBeds.isNotEmpty) {
      final occupiedList = occupiedBeds
          .map((b) => '- ${b.bedId} (patient ${b.patientId})')
          .join('\n');
      return '❌ Cannot put room under maintenance.\nOccupied beds:\n$occupiedList';
    }

    roomRepo.updateRoomMaintenance(roomNumber, true);
    return '✅ Room $roomNumber is now under maintenance 🚧';
  }

  // View patient bed info
  String viewPatientBedInfo(String patientId) {
    Patient? patient = patientRepo.findPatientById(patientId);
    if (patient == null) return '❌ Patient not found!';

    final details = StringBuffer();
    details.writeln('--- PATIENT DETAILS ---');
    details.writeln('ID: ${patient.id}');
    details.writeln('Name: ${patient.name}');
    details.writeln('Priority: ${patient.priority.toString().split('.').last}');
    details.writeln('Age: ${patient.age}');
    details.writeln('Phone: ${patient.phone}');

    if (patient.assignedBed != null) {
      var room = roomRepo.findRoomByNumber(patient.assignedBed!.roomNumber);
      details.writeln('\n--- BED ASSIGNMENT ---');
      details.writeln('Bed: ${patient.assignedBed!.bedId}');
      details.writeln('Room: ${room?.roomNumber} (${room?.type.toString().split('.').last})');
      details.writeln('Status: ${room?.isUnderMaintenance == true ? "🚧 Maintenance" : "✅ Operational"}');
    } else {
      details.writeln('\n--- BED ASSIGNMENT ---');
      details.writeln('❌ No bed assigned');
    }

    return details.toString();
  }

  // Helper to get all patients/rooms
  List<Patient> getAllPatients() => patientRepo.getAllPatients();
  List<Room> getAllRooms() => roomRepo.getAllRooms();
}
