import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/chat/chat_header.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/network_config.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  List<dynamic> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.baseUrl}/workspace?type=roadmap'),
        headers: {
          'Authorization': 'Bearer mock-token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final items = body['data']['items'] as List<dynamic>? ?? [];
          final allTasks = [];
          for (final item in items) {
            final roadmapData = item['data'] ?? {};
            final milestones = roadmapData['milestones'] as List<dynamic>? ?? [];
            for (final m in milestones) {
              final phase = m['phase'] as String? ?? 'Next Phase';
              final tasks = m['tasks'] as List<dynamic>? ?? [];
              for (final t in tasks) {
                allTasks.add({
                  'phase': phase,
                  'task': t,
                  'roadmapId': item['id'],
                });
              }
            }
          }

          setState(() {
            _tasks = allTasks;
            _loading = false;
          });
          return;
        }
      }
      throw Exception('Failed to load roadmaps');
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error fetching tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            ChatHeader(
              isWide: isWide,
              leading: HeaderBtn(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
              title: const Text(
                'Task Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: HeaderBtn(
                onTap: _fetchTasks,
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightCyan)),
                    )
                  : _tasks.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return _buildTaskItem(task);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: AppColors.lightCyan.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Tasks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a roadmap in the AI chat to populate your tasks.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Map<dynamic, dynamic> task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textGray, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['task'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task['phase'].toString(),
                    style: const TextStyle(
                      color: AppColors.lightCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
