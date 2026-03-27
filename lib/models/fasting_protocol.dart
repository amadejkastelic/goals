enum FastingProtocol {
  sixteenEight,
  eighteenSix,
  twentyFour,
  omad,
  altDayFasting,
  custom;

  String get displayName {
    switch (this) {
      case FastingProtocol.sixteenEight:
        return '16:8';
      case FastingProtocol.eighteenSix:
        return '18:6';
      case FastingProtocol.twentyFour:
        return '20:4';
      case FastingProtocol.omad:
        return 'OMAD';
      case FastingProtocol.altDayFasting:
        return 'Alternate Day';
      case FastingProtocol.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case FastingProtocol.sixteenEight:
        return '16h fast, 8h eating window';
      case FastingProtocol.eighteenSix:
        return '18h fast, 6h eating window';
      case FastingProtocol.twentyFour:
        return '20h fast, 4h eating window';
      case FastingProtocol.omad:
        return 'One meal a day (~23h fast)';
      case FastingProtocol.altDayFasting:
        return 'Fast every other day (24h)';
      case FastingProtocol.custom:
        return 'Set your own fasting hours';
    }
  }

  double get targetFastingHours {
    switch (this) {
      case FastingProtocol.sixteenEight:
        return 16.0;
      case FastingProtocol.eighteenSix:
        return 18.0;
      case FastingProtocol.twentyFour:
        return 20.0;
      case FastingProtocol.omad:
        return 23.0;
      case FastingProtocol.altDayFasting:
        return 24.0;
      case FastingProtocol.custom:
        return 16.0;
    }
  }

  String get icon {
    switch (this) {
      case FastingProtocol.sixteenEight:
        return '🕐';
      case FastingProtocol.eighteenSix:
        return '🕑';
      case FastingProtocol.twentyFour:
        return '🕒';
      case FastingProtocol.omad:
        return '🍽️';
      case FastingProtocol.altDayFasting:
        return '🔄';
      case FastingProtocol.custom:
        return '⚙️';
    }
  }

  static FastingProtocol fromName(String name) {
    return FastingProtocol.values.firstWhere(
      (e) => e.name == name,
      orElse: () => FastingProtocol.sixteenEight,
    );
  }
}
