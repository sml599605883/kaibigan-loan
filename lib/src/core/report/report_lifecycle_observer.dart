import 'dart:async';

import 'package:flutter/widgets.dart';

import 'report_manager.dart';

class ReportLifecycleObserver extends WidgetsBindingObserver {
  ReportLifecycleObserver(this._manager);

  final ReportManager _manager;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_manager.onAppStarted());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_manager.onAppResumed());
    }
  }
}
