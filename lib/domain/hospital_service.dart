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

  // ✅ Register a new patient
  Future<String> registerPatient(Patient patient) async {
    if (patientRepo.findPatientById(patient.id) != null) {
      return '❌ Patient ID already exists!';
    }

    await patientRepo.registerPatient(patient);
    return '✅ Patient "${patient.name}" registered successfully!';
  }

  // ✅ Add a new room (instant save)
  Future<String> addRoom(String roomNumber, RoomType type, int capacity) async {
    if (roomRepo.findRoomByNumber(roomNumber) != null) {
      return '❌ Room $roomNumber already exists!';
    }

    final newRoom = Room(
      roomNumber: roomNumber,
      type: type,
      capacity: capacity,
    );

    await roomRepo.addRoom(newRoom);
    return '✅ Room $roomNumber (${type.toString().split('.').last}) created successfully with $capacity beds!';
  }

  // ✅ Assign patient to a bed (automatic best fit)
  Future<String> assignPatientToBed(String patientId) async {
    final patient = patientRepo.findPatientById(patientId);
    if (patient == null) return '❌ Patient not found!';
    if (patient.assignedBed != null) {
      return '❌ Patient already assigned to bed ${patient.assignedBed!.bedId}';
    }

    final success = await roomRepo.assignPatientToBed(patient);
    if (success) {
      return '✅ Patient ${patient.name} assigned to bed ${patient.assignedBed!.bedId}';
    } else {
      return '❌ No suitable beds available for ${patient.priority.toString().split('.').last} patients';
    }
  }

  // ✅ Discharge a patient (free their bed)
  Future<String> dischargePatient(String patientId) async {
    final patient = patientRepo.findPatientById(patientId);
    if (patient == null) return '❌ Patient not found!';
    if (patient.assignedBed == null) return '❌ Patient is not assigned to any bed.';

    await roomRepo.dischargePatient(patient);
    return '✅ Patient "${patient.name}" has been discharged successfully!';
  }

  // ✅ Update room maintenance status
  Future<String> putRoomUnderMaintenance(String roomNumber) async {
    final room = roomRepo.findRoomByNumber(roomNumber);
    if (room == null) return '❌ Room not found!';
    if (room.isUnderMaintenance) return '⚠️ Room $roomNumber is already under maintenance.';

    final occupiedBeds = room.beds.where((b) => !b.isAvailable()).toList();
    if (occupiedBeds.isNotEmpty) {
      final list = occupiedBeds
          .map((b) => '- ${b.bedId} (patient: ${b.patientId})')
          .join('\n');
      return '❌ Cannot put room $roomNumber under maintenance.\nOccupied beds:\n$list';
    }

    await roomRepo.updateRoomMaintenance(roomNumber, true);
    return '✅ Room $roomNumber is now under maintenance 🚧';
  }

  // ✅ View detailed bed info of a patient
  String viewPatientBedInfo(String patientId) {
    final patient = patientRepo.findPatientById(patientId);
    if (patient == null) return '❌ Patient not found!';

    final info = StringBuffer();
    info.writeln('--- PATIENT DETAILS ---');
    info.writeln('ID: ${patient.id}');
    info.writeln('Name: ${patient.name}');
    info.writeln('Priority: ${patient.priority.toString().split('.').last}');
    info.writeln('Age: ${patient.age}');
    info.writeln('Phone: ${patient.phone}');

    if (patient.assignedBed != null) {
      final room = roomRepo.findRoomByNumber(patient.assignedBed!.roomNumber);
      info.writeln('\n--- BED ASSIGNMENT ---');
      info.writeln('Bed: ${patient.assignedBed!.bedId}');
      info.writeln('Room: ${room?.roomNumber} (${room?.type.toString().split('.').last})');
      info.writeln('Status: ${room?.isUnderMaintenance == true ? "🚧 Maintenance" : "✅ Operational"}');
    } else {
      info.writeln('\n--- BED ASSIGNMENT ---');
      info.writeln('❌ No bed assigned');
    }

    return info.toString();
  }

  // ✅ Helpers
  List<Patient> getAllPatients() => patientRepo.getAllPatients();
  List<Room> getAllRooms() => roomRepo.getAllRooms();
}
