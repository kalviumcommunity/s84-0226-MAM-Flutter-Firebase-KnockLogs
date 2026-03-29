import 'package:flutter/material.dart';

class AnalyticsProvider extends ChangeNotifier {
  List<int> _visitorWeek = [0, 0, 0, 0, 0, 0, 0];
  int _visitorsToday = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;

  List<int> get visitorWeek => _visitorWeek;
  int get visitorsToday => _visitorsToday;
  int get approvedCount => _approvedCount;
  int get rejectedCount => _rejectedCount;

  void updateData(List<int> week, int today, int approved, int rejected) {
    _visitorWeek = week;
    _visitorsToday = today;
    _approvedCount = approved;
    _rejectedCount = rejected;
    notifyListeners();
  }
}
