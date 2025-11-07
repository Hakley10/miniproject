import 'dart:io';
import '../data/patient_repository.dart';
import '../data/room_repository.dart';
import '../domain/patient.dart';
import '../domain/enums.dart';
import '../domain/hospital_service.dart';
import '../domain/room.dart';

class HospitalUI {
  late final HospitalService hospitalService;

  Future<void> run() async {
    final patientRepo = await PatientRepository.create();
    final roomRepo = await RoomRepository.create();
    hospitalService = HospitalService(patientRepo, roomRepo);

    print('🏥 WELCOME TO HOSPITAL MANAGEMENT SYSTEM');

    while (true) {
      stdout.write('\x1B[2J\x1B[0;0H'); // Clear console
      _showMainMenu();
      final choice = _getInput('Enter your choice: ');

      switch (choice) {
        case '1':
          await _registerPatient();
          break;
        case '2':
          _listPatients();
          break;
        case '3':
          _searchPatient();
          break;
        case '4':
          await _addRoom();
          break;
        case '5':
          _listRooms();
          break;
        case '6':
          await _assignPatientToBed();
          break;
        case '7':
          await _dischargePatient();
          break;
        case '8':
          _viewPatientBedInfo();
          break;
        case '9':
          print('👋 Thank you for using Hospital Management System!');
          return;
        default:
          print('❌ Invalid choice.');
      }

      _getInput('\nPress Enter to continue...');
    }
  }

  void _showMainMenu() {
    print('''
      === HOSPITAL MANAGEMENT SYSTEM ===
      1. Register Patient
      2. List Patients
      3. Search Patient
      4. Add Room
      5. List Rooms
      6. Assign Patient to Bed
      7. Discharge Patient
      8. View Patient Bed Info
      9. Exit
      '''
    );
  }

  Future<void> _registerPatient() async {
    print('--- PATIENT REGISTRATION ---');

    final id = _getInput('Enter patient ID: ');
    if (hospitalService.getAllPatients().any((p) => p.id == id)) {
      print('❌ Patient ID "$id" already exists!');
      return;
    }

    final name = _getInput('Enter name: ');
    final gender = _getInput('Enter gender: ');
    final email = _getInput('Enter email: ');
    final age = int.tryParse(_getInput('Enter age: ')) ?? 0;
    final phone = _getInput('Enter phone: ');
    final address = _getInput('Enter address: ');

    print('\n1. Critical  2. Serious  3. Stable');
    final level = _getInput('Priority: ');
    final priority = switch (level) {
      '1' => PriorityLevel.critical,
      '2' => PriorityLevel.serious,
      _ => PriorityLevel.stable,
    };

    final patient = Patient(
      id: id,
      name: name,
      gender: gender,
      email: email,
      age: age,
      phone: phone,
      address: address,
      priority: priority,
    );

    print(await hospitalService.registerPatient(patient));
  }

  Future<void> _addRoom() async {
    print('\n--- ADD ROOM ---');
    final roomNumber = _getInput('Room Number: ');
    print('1. ICU  2. Ward  3. General  4. Private');
    final choice = _getInput('Type: ');

    final type = switch (choice) {
      '1' => RoomType.icu,
      '2' => RoomType.ward,
      '3' => RoomType.general,
      '4' => RoomType.private,
      _ => RoomType.general,
    };

    final capacity = int.tryParse(_getInput('Capacity: ')) ?? 1;
    print(await hospitalService.addRoom(roomNumber, type, capacity));
  }

  void _listPatients() {
    final list = hospitalService.getAllPatients();
    if (list.isEmpty) {
      print('No patients registered.');
      return;
    }

    print('\n--- PATIENT LIST ---');
    for (final p in list) {
      print('${p.id} - ${p.name} (${p.priority.name})');
    }
  }

  void _searchPatient() {
    final term = _getInput('Search term: ').toLowerCase();
    final results = hospitalService
        .getAllPatients()
        .where((p) =>
            p.name.toLowerCase().contains(term) ||
            p.id.toLowerCase().contains(term))
        .toList();

    if (results.isEmpty) {
      print('No matching patients found.');
    } else {
      print('\n--- SEARCH RESULTS ---');
      for (final p in results) {
        print('${p.id} - ${p.name}');
      }
    }
  }

  void _listRooms() {
    final rooms = hospitalService.getAllRooms();
    if (rooms.isEmpty) {
      print('No rooms available.');
      return;
    }

    print('\n--- ROOM LIST ---');
    for (final r in rooms) {
      print('${r.roomNumber} (${r.type.name}) - ${r.capacity} beds');
    }
  }

  Future<void> _assignPatientToBed() async {
    print('\n--- ASSIGN PATIENT TO BED ---');
    final id = _getInput('Patient ID: ');
    print(await hospitalService.assignPatientToBed(id));
  }

  Future<void> _dischargePatient() async {
    print('\n--- DISCHARGE PATIENT ---');
    final id = _getInput('Patient ID: ');
    print(await hospitalService.dischargePatient(id));
  }

  void _viewPatientBedInfo() {
    print('\n--- PATIENT BED INFO ---');
    final id = _getInput('Patient ID: ');
    print(hospitalService.viewPatientBedInfo(id));
  }

  String _getInput(String prompt) {
    stdout.write(prompt);
    return stdin.readLineSync()?.trim() ?? '';
  }
}
