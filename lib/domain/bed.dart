class Bed {
  final String bedId;
  final String roomNumber;
  String? patientId;

  Bed({
    required this.bedId,
    required this.roomNumber,
    this.patientId,
  });

  bool isAvailable() {
    return patientId == null;
  }

  void assignPatient(String id) {
    if (isAvailable()) {
      patientId = id;
    }
  }

  void removePatient() {
    patientId = null;
  }

  // For JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'bedId': bedId,
      'roomNumber': roomNumber,
      'patientId': patientId,
    };
  }

  // For JSON deserialization
  factory Bed.fromJson(Map<String, dynamic> json) {
    return Bed(
      bedId: json['bedId'] as String,
      roomNumber: json['roomNumber'] as String,
      patientId: json['patientId'] as String?,
    );
  }
}