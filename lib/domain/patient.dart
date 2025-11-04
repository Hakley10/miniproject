import 'person.dart';
import 'bed.dart';
import 'enums.dart';

class Patient extends Person {
  int age;
  String phone;
  String address;
  PriorityLevel priority;
  DateTime registrationDate;
  Bed? assignedBed;
  
  Patient({
    required String id,
    required String name,
    required String gender,
    required String email,
    required this.age,
    required this.phone,
    required this.address,
    required this.priority,
  })  : registrationDate = DateTime.now(),
        super(id: id, name: name, gender: gender, email: email);
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'email': email,
      'age': age,
      'phone': phone,
      'address': address,
      'priority': priority.toString(),
      'registrationDate': registrationDate.toIso8601String(),
      'assignedBed': assignedBed?.toJson(), // Serialize entire bed object
    };
  }
  
  factory Patient.fromJson(Map<String, dynamic> json) {
    Patient patient = Patient(
      id: json['id'],
      name: json['name'],
      gender: json['gender'],
      email: json['email'],
      age: json['age'],
      phone: json['phone'],
      address: json['address'],
      priority: PriorityLevel.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => PriorityLevel.Stable,
      ),
    );
    patient.registrationDate = DateTime.parse(json['registrationDate']);
    
    // Deserialize bed if it exists
    if (json['assignedBed'] != null) {
      patient.assignedBed = Bed.fromJson(Map<String, dynamic>.from(json['assignedBed']));
    }
    
    return patient;
  }
  
  @override
  String toString() {
    return 'Patient $name (ID: $id) - Priority: ${priority.toString().split('.').last}';
  }
}