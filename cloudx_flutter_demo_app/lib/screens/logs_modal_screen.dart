import 'package:flutter/material.dart';
import '../utils/demo_app_logger.dart';

/// Modal screen for displaying logs
class LogsModalScreen extends StatefulWidget {
  final String title;
  
  const LogsModalScreen({
    super.key,
    this.title = 'Logs',
  });
  
  @override
  State<LogsModalScreen> createState() => _LogsModalScreenState();
}

class _LogsModalScreenState extends State<LogsModalScreen> {
  final ScrollController _scrollController = ScrollController();
  List<DemoAppLogEntry> _logs = [];
  
  @override
  void initState() {
    super.initState();
    _refreshLogs();
    
    // Scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _refreshLogs() {
    setState(() {
      _logs = DemoAppLogger.sharedInstance.getAllLogs();
    });
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  void _clearLogs() {
    DemoAppLogger.sharedInstance.clearLogs();
    _refreshLogs();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  // Clear button
                  TextButton(
                    onPressed: _clearLogs,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  // Title
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Close button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            // Logs list
            Expanded(
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return _buildLogEntry(_logs[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLogEntry(DemoAppLogEntry logEntry) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            logEntry.formattedTimestamp,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          // Message
          Text(
            logEntry.message,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

