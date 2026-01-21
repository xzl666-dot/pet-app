import 'package:flutter/material.dart';
import '../managers/notification_manager.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationManager _notificationManager = NotificationManager.instance;
  late Map<String, dynamic> _settings;
  late String _currentPlatform;
  late String _currentMethod;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _settings = _notificationManager.getNotificationSettings();
    _currentPlatform = _notificationManager.getCurrentPlatform();
    _currentMethod = _notificationManager.getRecommendedNotificationMethod();
  }

  void _toggleNotifications(bool value) {
    _notificationManager.setNotificationsEnabled(value);
    setState(() {
      _settings['enabled'] = value;
    });
  }

  void _changeNotificationMethod(String method) {
    _notificationManager.setNotificationPreference(_currentPlatform, method);
    setState(() {
      _currentMethod = method;
      _settings['platform_preferences'][_currentPlatform] = method;
    });
  }

  void _changeTaskReminderTime(int minutes) {
    _notificationManager.setTaskReminderTime(minutes);
    setState(() {
      _settings['task_reminder_before_minutes'] = minutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知设置'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本设置
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '启用通知',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _settings['enabled'],
                          onChanged: _toggleNotifications,
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '任务提醒',
                          style: TextStyle(fontSize: 16),
                        ),
                        Switch(
                          value: _settings['task_reminder_enabled'],
                          onChanged: (value) {
                            setState(() {
                              _settings['task_reminder_enabled'] = value;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 平台信息
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前设备',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.device_hub, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          _getPlatformDisplayName(_currentPlatform),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 提醒方式设置
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '提醒方式',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        _buildMethodOption('notification', '系统通知', Icons.notifications),
                        const SizedBox(height: 8),
                        _buildMethodOption('alert', '弹窗提醒', Icons.info),
                        const SizedBox(height: 8),
                        _buildMethodOption('email', '邮件通知', Icons.email),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 任务提醒时间设置
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '任务提醒时间',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('任务截止前提醒时间：'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _settings['task_reminder_before_minutes'].toDouble(),
                            min: 5,
                            max: 120,
                            divisions: 23,
                            label: '${_settings['task_reminder_before_minutes']}分钟',
                            onChanged: (value) {
                              _changeTaskReminderTime(value.toInt());
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_settings['task_reminder_before_minutes']}分钟',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 每日提醒时间设置
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '每日提醒时间',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...(_settings['reminder_times'] as Map<String, dynamic>).entries.map((entry) {
                      final timeType = entry.key;
                      final time = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_getTimeTypeName(timeType)),
                            Text(time),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 智能调整按钮
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _notificationManager.adjustNotificationMethod();
                  setState(() {
                    _loadSettings();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已智能调整提醒方式')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('智能调整提醒方式'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodOption(String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _currentMethod,
      onChanged: (value) {
        if (value != null) {
          _changeNotificationMethod(value);
        }
      },
      title: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
      activeColor: Colors.blue,
    );
  }

  String _getPlatformDisplayName(String platform) {
    final platformMap = {
      'web': 'Web浏览器',
      'android': 'Android设备',
      'ios': 'iOS设备',
      'windows': 'Windows电脑',
      'macos': 'Mac电脑',
      'linux': 'Linux电脑',
      'unknown': '未知设备',
    };
    return platformMap[platform] ?? platform;
  }

  String _getTimeTypeName(String timeType) {
    final timeTypeMap = {
      'morning': '上午',
      'afternoon': '下午',
      'evening': '晚上',
    };
    return timeTypeMap[timeType] ?? timeType;
  }
}
