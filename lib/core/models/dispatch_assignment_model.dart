import 'package:incident_reporter/core/models/assignment_stage.dart';

class DispatchAssignmentModel {
  const DispatchAssignmentModel({
    required this.assignmentId,
    required this.incidentId,
    required this.incidentTitle,
    required this.vehicleId,
    required this.vehicleName,
    required this.driverId,
    required this.driverName,
    required this.hospitalId,
    required this.hospitalName,
    required this.dispatcher,
    required this.notes,
    required this.vehicleStatus,
    required this.state,
    required this.stage,
    required this.dispatchedAt,
    required this.incidentTags,
  });

  final String assignmentId;
  final String incidentId;
  final String incidentTitle;
  final String vehicleId;
  final String vehicleName;
  final String driverId;
  final String driverName;
  final String hospitalId;
  final String hospitalName;
  final String dispatcher;
  final String notes;
  final String vehicleStatus;
  final String state;
  final AssignmentStage stage;
  final String dispatchedAt;
  final List<String> incidentTags;

  factory DispatchAssignmentModel.fromJson(Map<String, dynamic> json) {
    return DispatchAssignmentModel(
      assignmentId: json['assignmentId']?.toString() ?? '',
      incidentId: json['incidentId']?.toString() ?? '',
      incidentTitle: json['incidentTitle']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleName: json['vehicleName']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      driverName: json['driverName']?.toString() ?? '',
      hospitalId: json['hospitalId']?.toString() ?? '',
      hospitalName: json['hospitalName']?.toString() ?? '',
      dispatcher: json['dispatcher']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      vehicleStatus: json['vehicleStatus']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      stage: _stageFromApi(json['state']?.toString()),
      dispatchedAt: json['dispatchedAt']?.toString() ?? '',
      incidentTags: (json['incidentTags'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
    );
  }
}

AssignmentStage _stageFromApi(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'EN_ROUTE':
      return AssignmentStage.enRoute;
    case 'ARRIVED':
      return AssignmentStage.arrived;
    case 'COMPLETED':
      return AssignmentStage.completed;
    case 'CANCELLED':
      return AssignmentStage.cancelled;
    default:
      return AssignmentStage.assigned;
  }
}
