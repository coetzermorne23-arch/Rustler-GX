enum RigProfileType { vehicle, caravan, camper, portablePower, custom }

extension RigProfileTypeLabel on RigProfileType {
  String get label => switch (this) {
        RigProfileType.vehicle => 'Vehicle',
        RigProfileType.caravan => 'Caravan',
        RigProfileType.camper => 'Camper',
        RigProfileType.portablePower => 'Portable power',
        RigProfileType.custom => 'Custom',
      };
}
