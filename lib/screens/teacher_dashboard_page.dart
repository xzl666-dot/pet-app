import 'package:flutter/material.dart';
import '../managers/school_home_link_manager.dart';
import '../models/task_model.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final SchoolHomeLinkManager _manager = SchoolHomeLinkManager.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _taskTemplates = [];
  List<Map<String, dynamic>> _filteredTemplates = [];
  String _selectedSubject = '全部';
  String _selectedGrade = '全部';
  String _selectedCategory = '全部';
  
  @override
  void initState() {
    super.initState();
    _loadTaskTemplates();
  }
  
  Future<void> _loadTaskTemplates() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 加载任务模板
      final templates = _manager.getTaskTemplates();
      
      setState(() {
        _taskTemplates = templates;
        _filteredTemplates = templates;
      });
    } catch (e) {
      print('加载任务模板失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 筛选模板
  void _filterTemplates() {
    var filtered = _taskTemplates;
    
    if (_selectedSubject != '全部') {
      filtered = filtered.where((template) => template['subject'] == _selectedSubject).toList();
    }
    
    if (_selectedGrade != '全部') {
      filtered = filtered.where((template) => template['grade'] == _selectedGrade).toList();
    }
    
    if (_selectedCategory != '全部') {
      filtered = filtered.where((template) => template['category'] == _selectedCategory).toList();
    }
    
    setState(() {
      _filteredTemplates = filtered;
    });
  }
  
  // 打开创建模板对话框
  void _openCreateTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTemplateDialog(
        onCreated: (template) {
          _manager.createTaskTemplate(template);
          _loadTaskTemplates();
        },
      ),
    );
  }
  
  // 打开编辑模板对话框
  void _openEditTemplateDialog(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => EditTemplateDialog(
        template: template,
        onUpdated: (updatedTemplate) {
          _manager.updateTaskTemplate(template['id'], updatedTemplate);
          _loadTaskTemplates();
        },
      ),
    );
  }
  
  // 删除模板
  void _deleteTemplate(String templateId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个任务模板吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _manager.deleteTaskTemplate(templateId);
              _loadTaskTemplates();
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  // 构建模板卡片
  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  template['name'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(template['subject']),
                  backgroundColor: Colors.blue[100],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              template['description'],
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(template['grade']),
                  backgroundColor: Colors.green[100],
                ),
                Chip(
                  label: Text(_getDifficultyText(template['difficulty'])),
                  backgroundColor: Colors.orange[100],
                ),
                Chip(
                  label: Text('${template['duration']}分钟'),
                  backgroundColor: Colors.purple[100],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '创建者: ${template['creator']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _openEditTemplateDialog(template),
                      icon: const Icon(Icons.edit),
                      tooltip: '编辑',
                    ),
                    if (template['creator'] != '系统')
                      IconButton(
                        onPressed: () => _deleteTemplate(template['id']),
                        icon: const Icon(Icons.delete),
                        tooltip: '删除',
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 获取难度文本
  String _getDifficultyText(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return '简单';
      case TaskDifficulty.medium:
        return '中等';
      case TaskDifficulty.hard:
        return '困难';
      default:
        return '未知';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教师工作台'),
        centerTitle: true,
        actions: [
          ElevatedButton(
            onPressed: _openCreateTemplateDialog,
            child: const Text('创建模板'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 筛选条件
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '筛选条件',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField(
                                  value: _selectedSubject,
                                  items: ['全部', '数学', '语文', '英语'].map((subject) {
                                    return DropdownMenuItem(
                                      value: subject,
                                      child: Text(subject),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSubject = value!;
                                    });
                                    _filterTemplates();
                                  },
                                  decoration: const InputDecoration(
                                    labelText: '学科',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField(
                                  value: _selectedGrade,
                                  items: ['全部', '小学', '初中'].map((grade) {
                                    return DropdownMenuItem(
                                      value: grade,
                                      child: Text(grade),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGrade = value!;
                                    });
                                    _filterTemplates();
                                  },
                                  decoration: const InputDecoration(
                                    labelText: '年级',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField(
                                  value: _selectedCategory,
                                  items: ['全部', '基础训练', '阅读理解', '口语训练', '思维训练', '写作训练'].map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                    });
                                    _filterTemplates();
                                  },
                                  decoration: const InputDecoration(
                                    labelText: '类别',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 模板列表
                  Text(
                    '任务模板库 (${_filteredTemplates.length})',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_filteredTemplates.isEmpty)
                    Center(
                      child: Text('暂无符合条件的模板'),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _filteredTemplates.length,
                      itemBuilder: (context, index) {
                        final template = _filteredTemplates[index];
                        return _buildTemplateCard(template);
                      },
                    ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// 创建模板对话框
class CreateTemplateDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onCreated;
  
  const CreateTemplateDialog({Key? key, required this.onCreated}) : super(key: key);
  
  @override
  State<CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _subject = '数学';
  String _grade = '小学';
  String _description = '';
  TaskDifficulty _difficulty = TaskDifficulty.medium;
  int _duration = 30;
  int _benefitValue = 10;
  String _category = '基础训练';
  bool _isPublic = false;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建任务模板'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: '模板名称'),
                onSaved: (value) => _name = value!,
                validator: (value) => value?.isEmpty ?? true ? '请输入模板名称' : null,
              ),
              
              DropdownButtonFormField(
                value: _subject,
                items: ['数学', '语文', '英语'].map((subject) {
                  return DropdownMenuItem(value: subject, child: Text(subject));
                }).toList(),
                onChanged: (value) => setState(() => _subject = value!),
                decoration: const InputDecoration(labelText: '学科'),
              ),
              
              DropdownButtonFormField(
                value: _grade,
                items: ['小学', '初中'].map((grade) {
                  return DropdownMenuItem(value: grade, child: Text(grade));
                }).toList(),
                onChanged: (value) => setState(() => _grade = value!),
                decoration: const InputDecoration(labelText: '年级'),
              ),
              
              TextFormField(
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 2,
                onSaved: (value) => _description = value!,
              ),
              
              DropdownButtonFormField(
                value: _difficulty,
                items: [
                  DropdownMenuItem(value: TaskDifficulty.easy, child: Text('简单')),
                  DropdownMenuItem(value: TaskDifficulty.medium, child: Text('中等')),
                  DropdownMenuItem(value: TaskDifficulty.hard, child: Text('困难')),
                ],
                onChanged: (value) => setState(() => _difficulty = value!),
                decoration: const InputDecoration(labelText: '难度'),
              ),
              
              TextFormField(
                decoration: const InputDecoration(labelText: '预计时长（分钟）'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _duration = int.parse(value!),
                validator: (value) => value?.isEmpty ?? true ? '请输入时长' : null,
              ),
              
              TextFormField(
                decoration: const InputDecoration(labelText: '收益值'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _benefitValue = int.parse(value!),
                validator: (value) => value?.isEmpty ?? true ? '请输入收益值' : null,
              ),
              
              DropdownButtonFormField(
                value: _category,
                items: ['基础训练', '阅读理解', '口语训练', '思维训练', '写作训练'].map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) => setState(() => _category = value!),
                decoration: const InputDecoration(labelText: '类别'),
              ),
              
              CheckboxListTile(
                title: const Text('公开模板'),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value!),
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
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              widget.onCreated({
                'name': _name,
                'subject': _subject,
                'grade': _grade,
                'description': _description,
                'difficulty': _difficulty,
                'duration': _duration,
                'benefit_value': _benefitValue,
                'category': _category,
                'is_public': _isPublic,
                'creator': 'teacher',
              });
              Navigator.pop(context);
            }
          },
          child: const Text('创建'),
        ),
      ],
    );
  }
}

// 编辑模板对话框
class EditTemplateDialog extends StatefulWidget {
  final Map<String, dynamic> template;
  final Function(Map<String, dynamic>) onUpdated;
  
  const EditTemplateDialog({Key? key, required this.template, required this.onUpdated}) : super(key: key);
  
  @override
  State<EditTemplateDialog> createState() => _EditTemplateDialogState();
}

class _EditTemplateDialogState extends State<EditTemplateDialog> {
  late String _name;
  late String _subject;
  late String _grade;
  late String _description;
  late TaskDifficulty _difficulty;
  late int _duration;
  late int _benefitValue;
  late String _category;
  late bool _isPublic;
  
  @override
  void initState() {
    super.initState();
    _name = widget.template['name'];
    _subject = widget.template['subject'];
    _grade = widget.template['grade'];
    _description = widget.template['description'];
    _difficulty = widget.template['difficulty'];
    _duration = widget.template['duration'];
    _benefitValue = widget.template['benefit_value'];
    _category = widget.template['category'];
    _isPublic = widget.template['is_public'];
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑任务模板'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: '模板名称'),
              onChanged: (value) => _name = value,
            ),
            
            DropdownButtonFormField(
              value: _subject,
              items: ['数学', '语文', '英语'].map((subject) {
                return DropdownMenuItem(value: subject, child: Text(subject));
              }).toList(),
              onChanged: (value) => setState(() => _subject = value!),
              decoration: const InputDecoration(labelText: '学科'),
            ),
            
            DropdownButtonFormField(
              value: _grade,
              items: ['小学', '初中'].map((grade) {
                return DropdownMenuItem(value: grade, child: Text(grade));
              }).toList(),
              onChanged: (value) => setState(() => _grade = value!),
              decoration: const InputDecoration(labelText: '年级'),
            ),
            
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: '描述'),
              maxLines: 2,
              onChanged: (value) => _description = value,
            ),
            
            DropdownButtonFormField(
              value: _difficulty,
              items: [
                DropdownMenuItem(value: TaskDifficulty.easy, child: Text('简单')),
                DropdownMenuItem(value: TaskDifficulty.medium, child: Text('中等')),
                DropdownMenuItem(value: TaskDifficulty.hard, child: Text('困难')),
              ],
              onChanged: (value) => setState(() => _difficulty = value!),
              decoration: const InputDecoration(labelText: '难度'),
            ),
            
            TextFormField(
              initialValue: _duration.toString(),
              decoration: const InputDecoration(labelText: '预计时长（分钟）'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _duration = int.tryParse(value) ?? _duration,
            ),
            
            TextFormField(
              initialValue: _benefitValue.toString(),
              decoration: const InputDecoration(labelText: '收益值'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _benefitValue = int.tryParse(value) ?? _benefitValue,
            ),
            
            DropdownButtonFormField(
              value: _category,
              items: ['基础训练', '阅读理解', '口语训练', '思维训练', '写作训练'].map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) => setState(() => _category = value!),
              decoration: const InputDecoration(labelText: '类别'),
            ),
            
            CheckboxListTile(
              title: const Text('公开模板'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onUpdated({
              'name': _name,
              'subject': _subject,
              'grade': _grade,
              'description': _description,
              'difficulty': _difficulty,
              'duration': _duration,
              'benefit_value': _benefitValue,
              'category': _category,
              'is_public': _isPublic,
            });
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
