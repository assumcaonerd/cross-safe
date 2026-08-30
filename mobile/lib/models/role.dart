enum UserRole { driver, rider, pedestrian }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.driver:
        return 'Motorista';
      case UserRole.rider:
        return 'E-bike / patinete';
      case UserRole.pedestrian:
        return 'Pedestre';
    }
  }
}
