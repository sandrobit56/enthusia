// File: lib/features/tasks/add_task_screen.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.28
// Description: Add Task screen. User enters task title, picks date option
// (Today / Every day / Custom), and optionally sets a reminder. v0.28:
// Save is always enabled and shows specific inline validation errors
// instead of silently disabling the button.

import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/primary_button.dart';
import 'recurrence.dart';
import 'task.dart';
import 'task_service.dart';

enum WhenOption { today, everyDay, custom }

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  WhenOption? _selectedWhen;
  DateTime? _selectedDate;
  TimeOfDay? _selectedReminder;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatCustomDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().substring(2)}';
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              onSurface: AppColors.headingDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedWhen = WhenOption.custom;
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedReminder ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              onSurface: AppColors.headingDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedReminder = picked);
    }
  }

  void _saveTask() {
    final title = _titleController.text.trim();

    // Specific, actionable validation — never fail silently.
    if (title.isEmpty) {
      setState(() => _validationError = 'Please enter a task name.');
      return;
    }
    if (_selectedWhen == null) {
      setState(() =>
          _validationError = 'Please pick when: Today, Every day, or Custom.');
      return;
    }
    if (_validationError != null) {
      setState(() => _validationError = null);
    }

    Recurrence rec;
    if (_selectedWhen == WhenOption.everyDay) {
      rec = Recurrence.daily();
    } else {
      final date = _selectedDate ?? DateTime.now();
      rec = Recurrence.dates([date]);
    }

    final newTask = Task(
      id: '', // Firestore generates the id, this field is ignored on write
      title: title,
      createdAt: DateTime.now(),
      recurrence: rec,
      reminderTime: _selectedReminder,
    );

    // Fire-and-forget: Firestore's local cache confirms the write instantly
    // (online or offline) and syncs in the background. Awaiting this would
    // stall navigation offline and cause "Bad state: No element" on pop.
    // Errors are swallowed because they're either network errors (Firestore
    // will retry on reconnect) or logged by TaskService/NotificationService
    // internally.
    // ignore: discarded_futures
    TaskService.instance.addTask(newTask).catchError((_) {});

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  BoxDecoration _whenOptionDecoration(WhenOption option) {
    final isSelected = _selectedWhen == option;
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isSelected ? AppColors.accent : const Color(0xFFE8E8EC),
        width: isSelected ? 2 : 1,
      ),
    );
  }

  TextStyle get _whenOptionTextStyle => AppTextStyles.body.copyWith(
    fontWeight: FontWeight.w500,
    color: const Color(0xFF394E41),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.l),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.close,
                          size: 24,
                          color: AppColors.headingDark,
                        ),
                        // Invisible 48x48-minimum tap zone, independent of
                        // the visible icon's size (Material touch target).
                        Positioned.fill(
                          top: -12,
                          bottom: -12,
                          left: -12,
                          right: -12,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'New Task',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.active,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  'WHAT DO YOU WANT TO DO?',
                  style: AppTextStyles.micro.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                TextField(
                  controller: _titleController,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.headingDark,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                      vertical: 18,
                    ),
                    hintText: 'Morning run',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.placeholder,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Or try one of these:',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuickChip(
                      icon: Icons.menu_book,
                      label: 'Read',
                      onTap: () {
                        setState(() => _titleController.text = 'Read');
                      },
                    ),
                    const SizedBox(width: AppSpacing.s),
                    _QuickChip(
                      icon: Icons.directions_run,
                      label: 'Exercise',
                      onTap: () {
                        setState(() => _titleController.text = 'Exercise');
                      },
                    ),
                    const SizedBox(width: AppSpacing.s),
                    _QuickChip(
                      icon: Icons.water_drop_outlined,
                      label: 'Drink water',
                      onTap: () {
                        setState(() => _titleController.text = 'Drink water');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  'WHEN?',
                  style: AppTextStyles.micro.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedWhen = WhenOption.today;
                      _selectedDate = DateTime.now();
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                      vertical: 10,
                    ),
                    decoration: _whenOptionDecoration(WhenOption.today),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [Text('Today', style: _whenOptionTextStyle)],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedWhen = WhenOption.everyDay;
                      _selectedDate = DateTime.now();
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                      vertical: 10,
                    ),
                    decoration: _whenOptionDecoration(WhenOption.everyDay),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Every day', style: _whenOptionTextStyle),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: _pickCustomDate,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                      vertical: 10,
                    ),
                    decoration: _whenOptionDecoration(WhenOption.custom),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Custom', style: _whenOptionTextStyle),
                        Text(
                          _selectedWhen == WhenOption.custom &&
                                  _selectedDate != null
                              ? _formatCustomDate(_selectedDate!)
                              : '--/--/--',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F0F0),
                    borderRadius: BorderRadius.circular(51),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                GestureDetector(
                  onTap: _pickReminderTime,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE8E8EC),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              size: 24,
                              color: AppColors.headingMid,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Reminder',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.headingMid,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _selectedReminder == null
                              ? '----'
                              : _selectedReminder!.format(context),
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.headingMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_validationError != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Text(
                      _validationError!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.streakBroken,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                PrimaryButton(
                  label: 'Save Task',
                  onPressed: _saveTask,
                ),
                const SizedBox(height: AppSpacing.l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.onboarding,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
