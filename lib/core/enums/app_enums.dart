/// Centralized enums for the VoltShare platform.

/// User roles with ascending privilege levels.
enum UserRole {
  user,
  host,
  admin;

  String get label => switch (this) {
        UserRole.user => 'User',
        UserRole.host => 'Host',
        UserRole.admin => 'Admin',
      };

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => UserRole.user,
    );
  }
}

/// Account status.
enum AccountStatus {
  active,
  suspended,
  deactivated;

  static AccountStatus fromString(String value) {
    return AccountStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AccountStatus.active,
    );
  }
}

/// Booking lifecycle statuses.
enum BookingStatus {
  pending,
  confirmed,
  active,
  completed,
  cancelled,
  expired;

  String get label => switch (this) {
        BookingStatus.pending => 'Pending',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.active => 'Active',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.expired => 'Expired',
      };

  bool get isTerminal =>
      this == BookingStatus.completed ||
      this == BookingStatus.cancelled ||
      this == BookingStatus.expired;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => BookingStatus.pending,
    );
  }
}

/// Charging session statuses.
enum SessionStatus {
  starting,
  active,
  stopping,
  completed,
  failed;

  String get label => switch (this) {
        SessionStatus.starting => 'Starting',
        SessionStatus.active => 'Active',
        SessionStatus.stopping => 'Stopping',
        SessionStatus.completed => 'Completed',
        SessionStatus.failed => 'Failed',
      };

  static SessionStatus fromString(String value) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => SessionStatus.starting,
    );
  }
}

/// Charger operational status.
enum ChargerListingStatus {
  pendingApproval,
  active,
  disabled,
  rejected;

  String get label => switch (this) {
        ChargerListingStatus.pendingApproval => 'Pending Approval',
        ChargerListingStatus.active => 'Active',
        ChargerListingStatus.disabled => 'Disabled',
        ChargerListingStatus.rejected => 'Rejected',
      };

  static ChargerListingStatus fromString(String value) {
    return ChargerListingStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ChargerListingStatus.pendingApproval,
    );
  }
}

/// EV connector types.
enum ConnectorType {
  type1,
  type2,
  ccs1,
  ccs2,
  chademo,
  teslaWall,
  gbtAc,
  gbtDc,
  universal;

  String get label => switch (this) {
        ConnectorType.type1 => 'Type 1 (J1772)',
        ConnectorType.type2 => 'Type 2 (Mennekes)',
        ConnectorType.ccs1 => 'CCS1',
        ConnectorType.ccs2 => 'CCS2',
        ConnectorType.chademo => 'CHAdeMO',
        ConnectorType.teslaWall => 'Tesla Wall Connector',
        ConnectorType.gbtAc => 'GB/T AC',
        ConnectorType.gbtDc => 'GB/T DC',
        ConnectorType.universal => 'Universal',
      };

  static ConnectorType fromString(String value) {
    return ConnectorType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ConnectorType.type2,
    );
  }
}

/// Charger power type.
enum ChargerType {
  ac,
  dc;

  String get label => switch (this) {
        ChargerType.ac => 'AC',
        ChargerType.dc => 'DC',
      };

  static ChargerType fromString(String value) {
    return ChargerType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ChargerType.ac,
    );
  }
}

/// Notification types for in-app notifications.
enum NotificationType {
  bookingConfirmed,
  bookingCancelled,
  bookingReminder,
  sessionStarted,
  sessionCompleted,
  chargerApproved,
  chargerRejected,
  newReview,
  accountSecurity,
  system;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }
}

/// Day of week (0 = Monday, 6 = Sunday).
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get shortLabel => switch (this) {
        DayOfWeek.monday => 'Mon',
        DayOfWeek.tuesday => 'Tue',
        DayOfWeek.wednesday => 'Wed',
        DayOfWeek.thursday => 'Thu',
        DayOfWeek.friday => 'Fri',
        DayOfWeek.saturday => 'Sat',
        DayOfWeek.sunday => 'Sun',
      };

  static DayOfWeek fromInt(int value) {
    return DayOfWeek.values[value.clamp(0, 6)];
  }
}
