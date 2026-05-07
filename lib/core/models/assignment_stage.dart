enum AssignmentStage {
  assigned,
  enRoute,
  arrived,
  completed,
  cancelled,
}

extension AssignmentStageUi on AssignmentStage {
  String get label {
    switch (this) {
      case AssignmentStage.assigned:
        return 'Assigned';
      case AssignmentStage.enRoute:
        return 'En route';
      case AssignmentStage.completed:
        return 'Completed';
      case AssignmentStage.cancelled:
        return 'Cancelled';
      default:
        return 'Waiting';
    }
  }

  String get primaryActionLabel {
    switch (this) {
      case AssignmentStage.assigned:
        return 'Start response';
      case AssignmentStage.arrived:
        return 'arrived at scene';
      case AssignmentStage.completed:
        return 'Reload dashboard';
      case AssignmentStage.cancelled:
        return 'Cancelled';
      case AssignmentStage.enRoute:
        return 'En Route';
    }
  }

  String get driverStatus {
    switch (this) {
      case AssignmentStage.cancelled:
        return 'Available';
      case AssignmentStage.assigned:
        return 'busy';
      case AssignmentStage.enRoute:
        return 'busy';
      case AssignmentStage.arrived:
        return 'busy';
      case AssignmentStage.completed:
        return 'Available';
    }
  }

  String get assignmentState {
    switch (this) {
      case AssignmentStage.assigned:
        return 'ASSIGNED';
      case AssignmentStage.enRoute:
        return 'EN_ROUTE';
      case AssignmentStage.arrived:
        return 'ARRIVED';
      case AssignmentStage.completed:
        return 'COMPLETED';
      case AssignmentStage.cancelled:
        return 'CANCELLED';
    }
  }
}
