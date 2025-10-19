import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';

/// A log entry with message, timestamp, and formatted timestamp
class DemoAppLogEntry {
  final String message;
  final DateTime timestamp;
  final String formattedTimestamp;

  DemoAppLogEntry({
    required this.message,
    DateTime? timestamp,
  })  : timestamp = timestamp ?? DateTime.now(),
        formattedTimestamp = DateFormat('HH:mm:ss.SSS').format(timestamp ?? DateTime.now());
}

/// Singleton logger for the demo app
class DemoAppLogger {
  static final DemoAppLogger _instance = DemoAppLogger._internal();
  
  factory DemoAppLogger() => _instance;
  
  DemoAppLogger._internal();
  
  static DemoAppLogger get sharedInstance => _instance;
  
  final List<DemoAppLogEntry> _logs = [];
  final StreamController<List<DemoAppLogEntry>> _logsController = 
      StreamController<List<DemoAppLogEntry>>.broadcast();
  
  /// Stream of log updates
  Stream<List<DemoAppLogEntry>> get logsStream => _logsController.stream;
  
  /// Log a simple message
  void logMessage(String message) {
    if (message.isEmpty) return;
    
    final entry = DemoAppLogEntry(message: message);
    _logs.add(entry);
    
    // Also log to console for debugging
    print('📱 [DemoApp] $message');
    
    // Keep only the last 500 logs to prevent memory issues
    if (_logs.length > 500) {
      _logs.removeAt(0);
    }
    
    _logsController.add(List.unmodifiable(_logs));
  }
  
  /// Log an ad event with ad details
  void logAdEvent(String eventName, CLXAd? ad) {
    final adDetails = _formatAdDetails(ad);
    final fullMessage = '$eventName$adDetails';
    logMessage(fullMessage);
  }
  
  /// Clear all logs
  void clearLogs() {
    _logs.clear();
    _logsController.add(List.unmodifiable(_logs));
  }
  
  /// Get all logs as an immutable list
  List<DemoAppLogEntry> getAllLogs() {
    return List.unmodifiable(_logs);
  }
  
  /// Get log count
  int get logCount => _logs.length;
  
  /// Format ad details for logging (mirrors ObjC DemoAppLogger formatAdDetails)
  String _formatAdDetails(CLXAd? ad) {
    if (ad == null) {
      return ' - Ad: (null)';
    }
    
    final details = StringBuffer(' - Ad Details:');
    
    // Placement Name
    details.write('\n  📍 Placement: ${ad.placementName ?? '(null)'}');
    
    // Placement ID
    details.write('\n  🆔 Placement ID: ${ad.placementId ?? '(null)'}');
    
    // Bidder/Network
    details.write('\n  🏢 Bidder: ${ad.bidder ?? '(null)'}');
    
    // External Placement ID
    details.write('\n  🔗 External ID: ${ad.externalPlacementId ?? '(null)'}');
    
    // Revenue
    if (ad.revenue != null) {
      details.write('\n  💰 Revenue: \$${ad.revenue!.toStringAsFixed(6)}');
    } else {
      details.write('\n  💰 Revenue: (null)');
    }
    
    return details.toString();
  }
  
  void dispose() {
    _logsController.close();
  }
}

