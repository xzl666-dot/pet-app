import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/study_task_model.dart';
import '../managers/auth_manager.dart';
import '../utils/token_util.dart';

class StudyTaskPage extends StatefulWidget {
  const StudyTaskPage({Key? key}) : super(key: key);

  @override
  State<StudyTaskPage> createState() => _StudyTaskPageState();
}

class _StudyTaskPageState extends State<StudyTaskPage> {
  final _authManager = AuthManager.instance;
  List<StudyTaskModel> _tasks = [];
  bool _isLoading = true;
  int _selectedSubject = -1;
  int _selectedDifficulty = -1;
  final List<StudyTaskModel> _recommendedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadRecommendedTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      String url = 'http://localhost:3000/api/studyTask/list?userId=$userId';
      if (_selectedSubject != -1) {
        url += '&subject=$_selectedSubject';
      }
      if (_selectedDifficulty != -1) {
        url += '&difficulty=$_selectedDifficulty';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          setState(() {
            _tasks = (data['data']['taskList'] as List)
                .map((taskData) => StudyTaskModel.fromMap(taskData))
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('加载学习任务失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecommendedTasks() async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/studyTask/recommend?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final recommendedTasksData = data['data']['recommendedTasks'] as List;
          setState(() {
            _recommendedTasks.clear();
            _recommendedTasks.addAll(
              recommendedTasksData.map((taskData) => StudyTaskModel(
                name: taskData['name'],
                subject: SubjectType.values[taskData['subject']],
                difficulty: TaskDifficulty.values[taskData['difficulty']],
                deadline: DateTime.now().add(const Duration(days: 7)),
                benefitType: PetBenefitType.values[0],
                benefitValue: taskData['benefitValue'],
              )),
            );
          });
        }
      }
    } catch (e) {
      print('加载推荐任务失败: $e');
    }
  }

  Future<void> _completeTask(StudyTaskModel task) async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/studyTask/complete'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'taskId': task.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          setState(() {
            final index = _tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              _tasks[index] = task.copyWith(
                isCompleted: true,
                completedAt: DateTime.now(),
              );
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('任务完成！获得 ${data['data']['expReward']} 经验值'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('完成任务失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('完成任务失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(StudyTaskModel task) async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/studyTask/delete'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'taskId': task.id,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _tasks.removeWhere((t) => t.id == task.id);
        });
      }
    } catch (e) {
      print('删除任务失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习任务'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateTaskDialog,
            tooltip: '创建任务',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSubjectFilter(),
          _buildDifficultyFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? const Center(child: Text('暂无学习任务'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskCard(_tasks[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: SubjectType.values.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterChip('全部', -1 == _selectedSubject, () {
              setState(() {
                _selectedSubject = -1;
              });
              _loadTasks();
            });
          }
          final subject = SubjectType.values[index - 1];
          return _buildFilterChip(
            subject.getSubjectIcon() + ' ' + subject.getSubjectName(),
            subject.index == _selectedSubject,
            () {
              setState(() {
                _selectedSubject = subject.index;
              });
              _loadTasks();
            },
          );
        },
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: TaskDifficulty.values.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterChip('全部难度', -1 == _selectedDifficulty, () {
              setState(() {
                _selectedDifficulty = -1;
              });
              _loadTasks();
            });
          }
          final difficulty = TaskDifficulty.values[index - 1];
          return _buildFilterChip(
            difficulty.getDifficultyName(),
            difficulty.index == _selectedDifficulty,
            () {
              setState(() {
                _selectedDifficulty = difficulty.index;
              });
              _loadTasks();
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.blue.withOpacity(0.2),
        checkmarkColor: Colors.blue,
      ),
    );
  }

  Widget _buildTaskCard(StudyTaskModel task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.subject.getSubjectColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        task.subject.getSubjectIcon(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.subject.getSubjectName(),
                        style: TextStyle(
                          color: task.subject.getSubjectColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(task.difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.difficulty.getDifficultyName(),
                    style: TextStyle(
                      color: _getDifficultyColor(task.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '截止: ${DateFormat('yyyy-MM-dd').format(task.deadline)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (!task.isCompleted)
                  ElevatedButton(
                    onPressed: () => _completeTask(task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('完成'),
                  )
                else
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
    }
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateTaskDialog(),
    ).then((result) {
      if (result == true) {
        _loadTasks();
      }
    });
  }
}

class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({Key? key}) : super(key: key);

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  SubjectType _selectedSubject = SubjectType.math;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authManager = AuthManager.instance;
      final user = authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/studyTask/create'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'name': _nameController.text,
          'description': _descriptionController.text,
          'subject': _selectedSubject.index,
          'difficulty': _selectedDifficulty.index,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('任务创建成功'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('创建任务失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建任务失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建学习任务'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '任务名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入任务名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '任务描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SubjectType>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: '科目',
                  border: OutlineInputBorder(),
                ),
                items: SubjectType.values.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Row(
                      children: [
                        Text(subject.getSubjectIcon()),
                        const SizedBox(width: 8),
                        Text(subject.getSubjectName()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskDifficulty>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: '难度',
                  border: OutlineInputBorder(),
                ),
                items: TaskDifficulty.values.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(difficulty.getDifficultyName()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _createTask,
          child: const Text('创建'),
        ),
      ],
    );
  }
}