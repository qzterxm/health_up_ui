import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/sleep_service.dart';

class SleepPage extends StatefulWidget {
  final String userId;

  const SleepPage({
    super.key,
    required this.userId,
  });

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  final SleepService _sleepService = SleepService();

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  bool _isLoading = false;
  Map<DateTime, SleepEntry> _sleepData = {};
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _fetchSleepData();
  }

  Future<void> _fetchSleepData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _sleepService.getSleepHistoryWithStats(widget.userId);

      if (mounted) {
        setState(() {
          _sleepData = data['sleepHistory'];
          _statistics = data['statistics'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to load data: $e"),
              backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchSleepData();
  }

  SleepEntry? get _selectedDayData {
    final normalizedKey = DateTime.utc(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    return _sleepData[normalizedKey];
  }

  void _showAddSleepDialog() {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add a sleep record"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Date: ${DateFormat('dd.MM.yyyy').format(_selectedDay)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.bedtime, color: Colors.indigo),
                title: const Text("Sleep time"),
                subtitle: Text(startTime?.format(context) ?? "Click to select"),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 22, minute: 0),
                  );
                  if (time != null) {
                    setDialogState(() => startTime = time);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                title: const Text("Wake-up time"),
                subtitle: Text(endTime?.format(context) ?? "Click to select"),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 7, minute: 0),
                  );
                  if (time != null) {
                    setDialogState(() => endTime = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: startTime != null && endTime != null
                  ? () async {
                Navigator.pop(ctx);
                await _addSleepEntry(startTime!, endTime!);
              }
                  : null,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSleepEntry(TimeOfDay start, TimeOfDay end) async {
    setState(() => _isLoading = true);

    try {
      final baseDate = DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day
      );

      final startDateTime = DateTime(
          baseDate.year, baseDate.month, baseDate.day,
          start.hour, start.minute
      );

      DateTime endDateTime = DateTime(
          baseDate.year, baseDate.month, baseDate.day,
          end.hour, end.minute
      );

      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      final duration = endDateTime.difference(startDateTime);


      final newEntry = SleepEntry(
        id: '',
        userId: widget.userId,
        date: baseDate,
        startTime: startDateTime,
        endTime: endDateTime,
        totalDurationMinutes: duration.inMinutes,
        sleepScore: 0,
        sleepStatus: "Pending",
      );

      final success = await _sleepService.addSleepEntry(newEntry);

      if (success) {
        if (mounted) {
          _fetchSleepData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Saving error"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent': return Colors.green;
      case 'good': return Colors.lightGreen;
      case 'fair': return Colors.orange;
      case 'poor': return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  Widget _infoColumn(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sleep statistics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_statistics.isEmpty)
              const Text("Loading statistics..."),
            if (_statistics['Message'] != null)
              Text(_statistics['Message']),
            if (_statistics['AverageDurationLast7Days'] != null)
              Column(
                children: [
                  _buildStatRow("Avg. duration (7 days)",
                      "${_statistics['AverageDurationLast7Days']?.toStringAsFixed(1)} hours"),
                  _buildStatRow("Avg. rating (7 days)",
                      "${_statistics['AverageScoreLast7Days']?.toStringAsFixed(0)}/100"),
                  const Divider(),
                  _buildStatRow("Best sleep", _statistics['BestSleepDay'] != null
                      ? DateFormat('dd MMM').format(DateTime.parse(_statistics['BestSleepDay']))
                      : "-"),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: TableCalendar(
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        currentDay: DateTime.now(),
        startingDayOfWeek: StartingDayOfWeek.monday,

        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },

        eventLoader: (day) {
          final normalizedKey = DateTime.utc(day.year, day.month, day.day);
          if (_sleepData.containsKey(normalizedKey)) {
            return [true];
          }
          return [];
        },

        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.indigo,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }

  Widget _buildDayDetails() {
    final data = _selectedDayData;

    if (data == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.nightlight_round_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              "No data for ${DateFormat('dd MMM').format(_selectedDay)}",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM').format(data.date),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Text(
                      "Sleep details",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data.sleepStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.sleepStatus,
                    style: TextStyle(
                      color: _getStatusColor(data.sleepStatus),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoColumn(
                    "${data.totalHours.toStringAsFixed(1)} hours",
                    "Duration",
                    Icons.access_time_filled,
                    Colors.blue
                ),
                _infoColumn(
                    "${data.remHours.toStringAsFixed(1)} hours",
                    "REM phase",
                    Icons.psychology,
                    Colors.purple
                ),
                _infoColumn(
                    "${data.sleepScore}",
                    "Score",
                    Icons.insights,
                    _getStatusColor(data.sleepStatus)
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Bed time: ${DateFormat('HH:mm').format(data.startTime.toLocal())}"),
                Text("Wake up: ${DateFormat('HH:mm').format(data.endTime.toLocal())}"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showAddSleepDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add record"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sleep tracker"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: _isLoading
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.4),
            const Center(child: CircularProgressIndicator()),
          ],
        )
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStatisticsCard(),
              const SizedBox(height: 20),
              _buildCalendar(),
              const SizedBox(height: 20),
              _buildDayDetails(),
              const SizedBox(height: 20),
              _buildAddButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}