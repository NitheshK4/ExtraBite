import 'package:flutter/material.dart';

enum OrderType {
  dineIn,
  takeAway,
}

extension OrderTypeExtension on OrderType {
  String get displayName {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine In';
      case OrderType.takeAway:
        return 'Take Away';
    }
  }

  String get code {
    switch (this) {
      case OrderType.dineIn:
        return 'dine_in';
      case OrderType.takeAway:
        return 'take_away';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderType.dineIn:
        return Icons.restaurant;
      case OrderType.takeAway:
        return Icons.takeout_dining;
    }
  }

  String get description {
    switch (this) {
      case OrderType.dineIn:
        return 'Eat fresh meal at PG dining area';
      case OrderType.takeAway:
        return 'Packed parcel for home or room';
    }
  }

  static OrderType? fromCode(String? code) {
    if (code == 'dine_in') return OrderType.dineIn;
    if (code == 'take_away') return OrderType.takeAway;
    return null;
  }
}
