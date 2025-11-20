import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/medication_service.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'edit_medication_screen.dart';

class MedicationSchedule extends StatefulWidget {
  final String userId;
  const MedicationSchedule({super.key, required this.userId});

  @override
  State<MedicationSchedule> createState() => _MedicationScheduleState();
}

class _MedicationScheduleState extends State<MedicationSchedule> {
  final MedicationService _service = MedicationService();
  late Future<List<Medication>> _medicationsFuture;
  final Set<String> _takenMedIds = {};
  final Set<String> _skippedMedIds = {};

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Medication>> _medicationsByDate = {};
  bool _isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    _takenMedIds.clear();
    _skippedMedIds.clear();

    setState(() {
      _medicationsFuture = _service.getMedications(widget.userId);
    });

    _medicationsFuture.then((meds) {
      _updateMedicationsByDate(meds);
    });
  }

  String _convertDayName(String shortDayName) {
    switch (shortDayName) {
      case 'Sun': return 'Sunday';
      case 'Mon': return 'Monday';
      case 'Tue': return 'Tuesday';
      case 'Wed': return 'Wednesday';
      case 'Thu': return 'Thursday';
      case 'Fri': return 'Friday';
      case 'Sat': return 'Saturday';
      default: return shortDayName;
    }
  }

  String _convertToShortDayName(String fullDayName) {
    switch (fullDayName) {
      case 'Sunday': return 'Sun';
      case 'Monday': return 'Mon';
      case 'Tuesday': return 'Tue';
      case 'Wednesday': return 'Wed';
      case 'Thursday': return 'Thu';
      case 'Friday': return 'Fri';
      case 'Saturday': return 'Sat';
      default: return fullDayName;
    }
  }

  bool _shouldTakeOnDate(Medication med, DateTime date) {
    if (!med.isActiveOnDate(date)) {
      return false;
    }

    final currentDayShort = _convertToShortDayName(DateFormat('EEEE').format(date));
    return med.weekDays.contains(currentDayShort);
  }

  void _updateMedicationsByDate(List<Medication> medications) {
    final Map<DateTime, List<Medication>> medicationsMap = {};

    for (final med in medications) {
      final fullDayNames = med.weekDays.map(_convertDayName).toList();

      for (int i = 0; i < 60; i++) {
        final date = DateTime.now().add(Duration(days: i));
        if (_shouldTakeOnDate(med, date)) {
          medicationsMap.putIfAbsent(DateTime(date.year, date.month, date.day), () => []).add(med);
        }
      }
    }

    setState(() {
      _medicationsByDate = medicationsMap;
    });
  }

  void _navigateToAddScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(
          userId: widget.userId,
          medicationToEdit: null,
        ),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }

  void _navigateToEditScreen(Medication med) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(
          userId: widget.userId,
          medicationToEdit: med,
        ),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }

  String _getDurationInfo(Medication med) {
    if (med.endDate == null) return 'No end date';

    final now = DateTime.now();
    final daysLeft = med.endDate!.difference(now).inDays;

    if (daysLeft < 0) return 'Expired';
    if (daysLeft == 0) return 'Ends today';
    if (daysLeft == 1) return '1 day left';
    if (daysLeft < 7) return '$daysLeft days left';
    if (daysLeft < 30) return '${(daysLeft / 7).round()} weeks left';

    return '${(daysLeft / 30).round()} months left';
  }

  bool _shouldCollapseCalendar(List<Medication> meds, DateTime selectedDay) {
    if (meds.isEmpty) return false;

    int medicationsCount = 0;
    for (final med in meds) {
      if (_shouldTakeOnDate(med, selectedDay)) {
        medicationsCount += med.times.length;
      }
    }

    return medicationsCount > 3 || meds.length > 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: FutureBuilder<List<Medication>>(
        future: _medicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          }
          final meds = snapshot.data ?? [];

          final bool shouldCollapse = _shouldCollapseCalendar(meds, _selectedDay);
          final bool showCollapsedCalendar = shouldCollapse && !_isCalendarExpanded;

          final Map<String, List<Medication>> groupedMeds = {};
          for (final med in meds) {
            final shouldTakeToday = _shouldTakeOnDate(med, _selectedDay);

            if (shouldTakeToday) {
              for (final time in med.times) {
                groupedMeds.putIfAbsent(time.time, () => []).add(med);
              }
            }
          }
          final sortedTimes = groupedMeds.keys.toList()..sort();

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (shouldCollapse)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _isCalendarExpanded ? 'Minimize' : 'Maximize',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isCalendarExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isCalendarExpanded = !_isCalendarExpanded;
                                });
                              },
                            ),
                          ],
                        ),

                      if (showCollapsedCalendar)
                        _buildCompactCalendar()
                      else
                        _buildFullCalendar(),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Scheduled medication',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Medication for ${DateFormat('dd.MM.yyyy').format(_selectedDay)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    if (!isSameDay(_selectedDay, DateTime.now()))
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDay = DateTime.now();
                            _focusedDay = DateTime.now();
                          });
                        },
                        child: Text(
                          'Today',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),


              if (meds.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "No medications scheduled.\nTap '+' to add one.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else if (sortedTimes.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "No medications scheduled for ${DateFormat('dd.MM.yyyy').format(_selectedDay)}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Day of week: ${_convertToShortDayName(DateFormat('EEEE').format(_selectedDay))}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Active medications: ${meds.length}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: Text(
                                "Time",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Medication",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...sortedTimes.map((time) {
                        final medsAtTime = groupedMeds[time]!;
                        final bool isActive = _isTimeActive(time);
                        return _buildTimeGroup(context, time, medsAtTime, isActive: isActive);
                      }).toList(),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactCalendar() {
    final weekStart = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final day = weekStart.add(Duration(days: index));
            final isSelected = isSameDay(_selectedDay, day);
            final isToday = isSameDay(DateTime.now(), day);
            final hasMedications = _medicationsByDate[DateTime(day.year, day.month, day.day)]?.isNotEmpty ?? false;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                    _focusedDay = day;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      width: 1,
                    )
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(day)[0],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (hasMedications)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFullCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2023, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      eventLoader: (day) {
        return _medicationsByDate[DateTime(day.year, day.month, day.day)] ?? [];
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        markerSize: 6,
        markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        defaultTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        weekendTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        outsideTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: Theme.of(context).iconTheme.color,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: Theme.of(context).iconTheme.color,
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        weekendStyle: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isNotEmpty) {
            return Positioned(
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  bool _isTimeActive(String time) {
    if (!isSameDay(_selectedDay, DateTime.now())) {
      return false;
    }

    final now = TimeOfDay.now();
    final groupTime = TimeOfDay(
      hour: int.parse(time.split(':')[0]),
      minute: int.parse(time.split(':')[1]),
    );

    final nowInMinutes = now.hour * 60 + now.minute;
    final groupTimeInMinutes = groupTime.hour * 60 + groupTime.minute;

    return groupTimeInMinutes <= nowInMinutes;
  }

  Widget _buildTimeGroup(BuildContext context, String rawTime, List<Medication> meds, {bool isActive = false}) {
    final displayTime = _formatDisplayTime(context, rawTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              displayTime,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: -25,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < meds.length; i++) ...[
                      _buildMedicationCard(meds[i], isActive: isActive),
                      if (i < meds.length - 1)
                        Divider(
                          color: (isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor)
                              .withOpacity(0.5),
                          height: 16,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                        )
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Medication med, {bool isActive = false}) {
    final bool isTaken = med.id != null && _takenMedIds.contains(med.id);
    final bool isSkipped = med.id != null && _skippedMedIds.contains(med.id);
    final bool isDone = isTaken || isSkipped;
    final bool isExpired = med.endDate != null && DateTime.now().isAfter(med.endDate!);

    final Color bgColor = isExpired
        ? Colors.red.shade100.withOpacity(0.3)
        : isTaken
        ? Colors.green.shade100.withOpacity(0.4)
        : isSkipped
        ? Colors.red.shade100.withOpacity(0.4)
        : isActive
        ? Theme.of(context).colorScheme.primary.withOpacity(0.18)
        : Theme.of(context).cardColor.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: isExpired
            ? Border.all(color: Colors.red.shade300, width: 1)
            : Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.nameOfMedication,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isExpired
                        ? Colors.red.shade700
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDoseSubtitle(med),
                  style: TextStyle(
                    fontSize: 14,
                    color: isExpired
                        ? Colors.red.shade600
                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${med.duration} • ${_getDurationInfo(med)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired
                        ? Colors.red.shade600
                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
                if (med.endDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Ends: ${DateFormat('dd.MM.yyyy').format(med.endDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isExpired
                          ? Colors.red.shade600
                          : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Days: ${med.weekDays.join(", ")}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isExpired
                        ? Colors.red.shade600
                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'take' && med.id != null) {
                setState(() {
                  _takenMedIds.add(med.id!);
                  _skippedMedIds.remove(med.id!);
                });
              } else if (value == 'skip' && med.id != null) {
                setState(() {
                  _skippedMedIds.add(med.id!);
                  _takenMedIds.remove(med.id!);
                });
              } else if (value == 'edit') {
                _navigateToEditScreen(med);
              } else if (value == 'delete' && med.id != null) {
                _showDeleteDialog(med);
              }
            },
            itemBuilder: (context) => [
              if (!isExpired) ...[
                PopupMenuItem<String>(
                  value: 'take',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Taken',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'skip',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Skip',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
              child: _getMedicationIcon(med, isExpired),
            ),
          )
        ],
      ),
    );
  }

  Widget _getMedicationIcon(Medication med, bool isExpired) {
    if (isExpired) {
      return Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
        size: 24,
      );
    }

    switch (med.type) {
      case MedicationType.tablet:
        return SvgPicture.asset(
          'assets/icons/pill.svg',
          color: Colors.green,
        );
      case MedicationType.capsule:
        return Icon(
          LucideIcons.pill,
          color: Colors.blue,
          size: 26,
        );
      case MedicationType.drops:
        return Icon(
          LucideIcons.droplet,
          color: Colors.orange,
          size: 26,
        );
      default:
        return Icon(
          LucideIcons.pill,
          color: Theme.of(context).textTheme.bodyMedium?.color,
          size: 26,
        );
    }
  }

  void _showDeleteDialog(Medication med) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Delete Medication',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${med.nameOfMedication}"?',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _service.deleteMedication(med.id!);
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${med.nameOfMedication}" deleted successfully'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting medication: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getDoseSubtitle(Medication med) {
    switch (med.type) {
      case MedicationType.capsule:
        return "1 capsule • ${med.dose}";
      case MedicationType.tablet:
        return "1 tablet • ${med.dose}";
      case MedicationType.drops:
        return "${med.dose.split(' ')[0]} drops";
      default:
        return med.dose;
    }
  }

  String _formatDisplayTime(BuildContext context, String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute).format(context);
    } catch (e) {
      return time;
    }
  }
}
