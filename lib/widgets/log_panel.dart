import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

enum LogType { info, success, error, warn }

class LogEntry {
  final String time;
  final String message;
  final LogType type;
  LogEntry({required this.time, required this.message, this.type = LogType.info});
}

/// Mixin for pages that need logging
mixin LoggerMixin<T extends StatefulWidget> on State<T> {
  final List<LogEntry> logs = [];

  String _now() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  void log(String msg, {bool isError = false, bool isSuccess = false, bool isWarn = false}) {
    if (!mounted) return;
    setState(() {
      logs.add(LogEntry(
        time: _now(),
        message: msg,
        type: isError ? LogType.error : isSuccess ? LogType.success : isWarn ? LogType.warn : LogType.info,
      ));
    });
  }

  void clearLogs() {
    if (!mounted) return;
    setState(() => logs.clear());
  }
}

class LogPanel extends StatefulWidget {
  final List<LogEntry> logs;
  const LogPanel({super.key, required this.logs});

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant LogPanel old) {
    super.didUpdateWidget(old);
    if (widget.logs.length > old.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Color _color(LogType t) {
    switch (t) {
      case LogType.success: return AppColors.success;
      case LogType.error: return const Color(0xFFF87171);
      case LogType.warn: return const Color(0xFFFBBF24);
      case LogType.info: return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.logs.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: AppColors.logBg,
        border: Border.all(color: AppColors.logBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.builder(
        controller: _scroll,
        itemCount: widget.logs.length,
        itemBuilder: (_, i) {
          final l = widget.logs[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.jetBrainsMono(fontSize: 11.5, height: 1.5),
                children: [
                  TextSpan(text: '${l.time}  ', style: TextStyle(color: AppColors.textMuted.withOpacity(0.5))),
                  TextSpan(text: l.message, style: TextStyle(color: _color(l.type))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
