import 'package:flutter/material.dart';
import '../../app_theme.dart';

class TaskCardWidget extends StatefulWidget {
  final Map<String, dynamic> metadata;
  const TaskCardWidget({super.key, required this.metadata});

  @override
  State<TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends State<TaskCardWidget> {
  final List<_Task> _tasks = [];
  int _overallScore = 84;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(covariant TaskCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metadata != oldWidget.metadata) {
      _loadTasks();
    }
  }

  void _loadTasks() {
    _tasks.clear();
    final valData = widget.metadata['validation'] ?? {};
    _overallScore = valData['overallScore'] ?? 84;
    
    final List<dynamic> nextSteps = valData['nextSteps'] ?? valData['tasks'] ?? [];
    if (nextSteps.isNotEmpty) {
      for (final step in nextSteps) {
        _tasks.add(_Task(step.toString(), false));
      }
    } else {
      _tasks.addAll([
        _Task('Talk to 10 potential customers', true),
        _Task('Set up Shopify store', false),
        _Task('Source products from vendors', false),
        _Task('Launch first Facebook ad campaign', false),
        _Task('Define Target Audience & Find Vendors', false),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _tasks.where((t) => t.done).length;
    final progress = _tasks.isEmpty ? 0.0 : done / _tasks.length;
    final scoreText = (_overallScore / 10.0).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentSuccess.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.accentSuccess.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('✓',
                        style: TextStyle(
                            color: AppColors.accentSuccess,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Validation Checklist',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Score: $scoreText/10',
                    style: const TextStyle(
                      color: AppColors.lightCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.borderDark,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentSuccess),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 14),
            // Tasks list
            ..._tasks.asMap().entries.map(
                  (entry) => _TaskItem(
                    task: entry.value,
                    onChanged: (v) {
                      setState(() => _tasks[entry.key].done = v ?? false);
                    },
                  ),
                ),
            const SizedBox(height: 8),
            // Footer Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$done/${_tasks.length} Completed',
                  style: const TextStyle(
                    color: AppColors.textLightGray,
                    fontSize: 11,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'View Details →',
                    style: TextStyle(
                      color: AppColors.lightCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Task {
  String text;
  bool done;
  _Task(this.text, this.done);
}

class _TaskItem extends StatelessWidget {
  final _Task task;
  final ValueChanged<bool?> onChanged;

  const _TaskItem({required this.task, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: task.done,
              onChanged: onChanged,
              activeColor: AppColors.accentSuccess,
              checkColor: Colors.white,
              side: const BorderSide(color: AppColors.borderDark, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.text,
              style: TextStyle(
                color: task.done ? AppColors.textLightGray : AppColors.textWhite,
                fontSize: 13,
                height: 1.3,
                decoration: task.done ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: AppColors.textLightGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
