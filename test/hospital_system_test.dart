import 'dart:async';
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

  // 🧹 Hide print() output during testing
  runZoned(() {
    setUpAll(() async {
      final patientFile = File(p.join('lib', 'data', 'test_patients.json'));
      final roomFile = File(p.join('lib', 'data', 'test_rooms.json'));

      // ✅ Ensure files exist
      if (!await patientFile.exists()) {
        await patientFile.create(recursive: true);
      }
      if (!await roomFile.exists()) {
        await roomFile.create(recursive: true);
      }

      // ✅ Clear previous data before each full test run
      await patientFile.writeAsString(json.encode({'patients': []}));
      await roomFile.writeAsString(json.encode({'rooms': []}));

      // ✅ Initialize repositories
      patientRepo = await PatientRepository.create(filePath: patientFile.path);
      roomRepo = await RoomRepository.create(filePath: roomFile.path);
      hospitalService = HospitalService(patientRepo, roomRepo);
    });

    // ✅ Test 1: Register a new patient
    test('Register new patient successfully', () async {
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

    // ✅ Test 2: Add new room and initialize beds
    test('Add new room and initialize beds', () async {
      final message = await hospitalService.addRoom('R101', RoomType.icu, 2);
      expect(message.contains('created successfully'), true);

      final addedRoom = roomRepo.findRoomByNumber('R101');
      expect(addedRoom, isNotNull);
      expect(addedRoom!.beds.length, 2);
    });

    // ✅ Test 3: Assign patient to available bed
    test('Assign patient to available bed', () async {
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

    // ✅ Test 4: Discharge patient frees up bed
    test('Discharge patient frees up bed', () async {
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
      expect(patient.assignedBed, isNotNull);

      await roomRepo.dischargePatient(patient);
      expect(patient.assignedBed, isNull);
    });
  },
      // 👇 Globally silence all print() calls
      zoneSpecification: ZoneSpecification(print: (_, __, ___, ____) {}));
}
