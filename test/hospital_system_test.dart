import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../lib/data/patient_repository.dart';
import '../lib/data/room_repository.dart';
import '../lib/domain/patient.dart';
import '../lib/domain/enums.dart';
import '../lib/domain/hospital_service.dart';
import '../lib/domain/room.dart';

void main() {
  late HospitalService hospitalService;
  late PatientRepository patientRepo;
  late RoomRepository roomRepo;

  setUp(() async {
  final dir = Directory.current;
  final patientFile = File(p.join(dir.path, 'patients_data.json'));
  final roomFile = File(p.join(dir.path, 'rooms_data.json'));

  // Keep old data structure, only clear content
  if (await patientFile.exists()) await patientFile.writeAsString(json.encode({'patients': []}));
  if (await roomFile.exists()) await roomFile.writeAsString(json.encode({'rooms': []}));

  patientRepo = await PatientRepository.create();
  roomRepo = await RoomRepository.create();
  hospitalService = HospitalService(patientRepo, roomRepo);
});

  test('Hospital Management System Register new patient successfully', () async {
    final patient = Patient(
      id: 'P001',
      name: 'Hourt',
      gender: 'M',
      email: 'hourt@example.com',
      age: 21,
      phone: '0123456789',
      address: 'Phnom Penh',
      priority: PriorityLevel.stable,
    );

    final message = await hospitalService.registerPatient(patient);

    expect(message.contains('registered successfully'), true);
    expect(patientRepo.getAllPatients().length, 1);
  });

  test('Hospital Management System Add new room and initialize beds', () async {
    final message = await hospitalService.addRoom('R101', RoomType.icu, 2);
    expect(message.contains('created successfully'), true);

    final addedRoom = roomRepo.findRoomByNumber('R101');
    expect(addedRoom, isNotNull);
    expect(addedRoom!.beds.length, 2);
  });

  test('Hospital Management System Assign patient to available bed', () async {
    final patient = Patient(
      id: 'P002',
      name: 'Alex',
      gender: 'M',
      email: 'alex@example.com',
      age: 30,
      phone: '0987654321',
      address: 'Siem Reap',
      priority: PriorityLevel.serious,
    );
    await hospitalService.registerPatient(patient);
    await hospitalService.addRoom('R201', RoomType.ward, 2);

    final success = await roomRepo.assignPatientToBed(patient);
    expect(success, true);
    expect(patient.assignedBed, isNotNull);
  });

  test('Hospital Management System Discharge patient frees up bed', () async {
    final patient = Patient(
      id: 'P003',
      name: 'Chan',
      gender: 'F',
      email: 'chan@example.com',
      age: 26,
      phone: '0888888888',
      address: 'Battambang',
      priority: PriorityLevel.stable,
    );

    await hospitalService.registerPatient(patient);
    await hospitalService.addRoom('R301', RoomType.general, 1);
    await roomRepo.assignPatientToBed(patient);

    // Before discharge
    expect(patient.assignedBed, isNotNull);

    // Discharge
    await roomRepo.dischargePatient(patient);
    expect(patient.assignedBed, isNull);
  });

  test('Hospital Management System Room under maintenance should reject patients', () async {
    final patient = Patient(
      id: 'P004',
      name: 'Sok',
      gender: 'M',
      email: 'sok@example.com',
      age: 24,
      phone: '0999999999',
      address: 'Kampot',
      priority: PriorityLevel.serious,
    );

    await hospitalService.registerPatient(patient);
    await hospitalService.addRoom('R401', RoomType.ward, 1);

    // Put room under maintenance
    await roomRepo.updateRoomMaintenance('R401', true);

    // Try assigning to bed
    final result = await roomRepo.assignPatientToBed(patient);
    expect(result, false);
  });
}
