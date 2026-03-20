const express = require('express');
const router = express.Router();
const { StudyTask, User, Pet, EvaluationLevel } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');

// 预设学习任务模板
const taskTemplates = {
  math: [
    { name: '完成数学作业', difficulty: 0, benefitValue: 15 },
    { name: '复习数学公式', difficulty: 0, benefitValue: 10 },
    { name: '做10道数学题', difficulty: 1, benefitValue: 20 },
    { name: '完成数学测试', difficulty: 1, benefitValue: 25 },
    { name: '解决数学难题', difficulty: 2, benefitValue: 35 },
    { name: '参加数学竞赛', difficulty: 2, benefitValue: 40 },
  ],
  english: [
    { name: '背诵英语单词', difficulty: 0, benefitValue: 15 },
    { name: '阅读英语文章', difficulty: 0, benefitValue: 10 },
    { name: '完成英语听力', difficulty: 1, benefitValue: 20 },
    { name: '写英语作文', difficulty: 1, benefitValue: 25 },
    { name: '进行英语对话', difficulty: 2, benefitValue: 35 },
    { name: '参加英语演讲', difficulty: 2, benefitValue: 40 },
  ],
  physics: [
    { name: '完成物理作业', difficulty: 0, benefitValue: 15 },
    { name: '复习物理概念', difficulty: 0, benefitValue: 10 },
    { name: '做物理实验', difficulty: 1, benefitValue: 20 },
    { name: '解决物理问题', difficulty: 1, benefitValue: 25 },
    { name: '设计物理项目', difficulty: 2, benefitValue: 35 },
    { name: '参加物理竞赛', difficulty: 2, benefitValue: 40 },
  ],
  biology: [
    { name: '完成生物作业', difficulty: 0, benefitValue: 15 },
    { name: '复习生物知识点', difficulty: 0, benefitValue: 10 },
    { name: '观察生物现象', difficulty: 1, benefitValue: 20 },
    { name: '做生物实验', difficulty: 1, benefitValue: 25 },
    { name: '研究生物课题', difficulty: 2, benefitValue: 35 },
    { name: '参加生物竞赛', difficulty: 2, benefitValue: 40 },
  ],
  worldHistory: [
    { name: '完成历史作业', difficulty: 0, benefitValue: 15 },
    { name: '复习历史事件', difficulty: 0, benefitValue: 10 },
    { name: '阅读历史资料', difficulty: 1, benefitValue: 20 },
    { name: '分析历史事件', difficulty: 1, benefitValue: 25 },
    { name: '研究历史课题', difficulty: 2, benefitValue: 35 },
    { name: '参加历史竞赛', difficulty: 2, benefitValue: 40 },
  ],
  chemistry: [
    { name: '完成化学作业', difficulty: 0, benefitValue: 15 },
    { name: '复习化学元素', difficulty: 0, benefitValue: 10 },
    { name: '做化学实验', difficulty: 1, benefitValue: 20 },
    { name: '解决化学问题', difficulty: 1, benefitValue: 25 },
    { name: '设计化学实验', difficulty: 2, benefitValue: 35 },
    { name: '参加化学竞赛', difficulty: 2, benefitValue: 40 },
  ],
};

// 创建学习任务
router.post('/create', authMiddleware, async (req, res) => {
  try {
    const { userId, name, description, subject, difficulty, benefitType, benefitValue } = req.body;

    if (!userId || !name || !subject) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const deadline = moment().add(7, 'days').toDate();

    const newTask = await StudyTask.create({
      userId,
      name,
      description,
      subject,
      difficulty: difficulty || 0,
      deadline,
      benefitType: benefitType || 0,
      benefitValue: benefitValue || 10,
      isCompleted: 0,
      createdAt: new Date(),
    });

    res.json({
      code: 200,
      data: {
        id: newTask.id,
        name: newTask.name,
        description: newTask.description,
        subject: newTask.subject,
        difficulty: newTask.difficulty,
        deadline: newTask.deadline,
        benefitType: newTask.benefitType,
        benefitValue: newTask.benefitValue,
      },
      msg: '学习任务创建成功',
    });
  } catch (error) {
    console.error('创建学习任务失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 获取学习任务列表
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { userId, subject, difficulty, isCompleted } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    let whereCondition = { userId };
    if (subject !== undefined && subject !== '') {
      whereCondition.subject = parseInt(subject);
    }
    if (difficulty !== undefined && difficulty !== '') {
      whereCondition.difficulty = parseInt(difficulty);
    }
    if (isCompleted !== undefined && isCompleted !== '') {
      whereCondition.isCompleted = parseInt(isCompleted);
    }

    const tasks = await StudyTask.findAll({
      where: whereCondition,
      order: [['createdAt', 'DESC']],
    });

    res.json({
      code: 200,
      data: {
        taskList: tasks.map(task => ({
          id: task.id,
          userId: task.userId,
          name: task.name,
          description: task.description,
          subject: task.subject,
          difficulty: task.difficulty,
          deadline: task.deadline,
          benefitType: task.benefitType,
          benefitValue: task.benefitValue,
          isCompleted: task.isCompleted === 1,
          createdAt: task.createdAt,
          completedAt: task.completedAt,
        })),
        total: tasks.length,
      },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('查询学习任务列表失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 完成学习任务
router.post('/complete', authMiddleware, async (req, res) => {
  try {
    const { userId, taskId } = req.body;

    if (!userId || !taskId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const task = await StudyTask.findOne({
      where: { userId, id: taskId },
    });

    if (!task) {
      return res.json({ code: 400, data: {}, msg: '任务不存在' });
    }

    if (task.isCompleted === 1) {
      return res.json({ code: 400, data: {}, msg: '任务已完成' });
    }

    // 更新任务状态
    await StudyTask.update(
      {
        isCompleted: 1,
        completedAt: new Date(),
      },
      { where: { userId, id: taskId } }
    );

    // 计算经验奖励
    const expReward = _getExpReward(task.difficulty);

    // 更新宠物经验
    const pet = await Pet.findOne({ where: { userId } });
    if (pet) {
      const newExp = pet.exp + expReward;
      const isUpgrade = newExp >= pet.expThreshold;

      const updateData = { exp: newExp };
      if (isUpgrade) {
        updateData.level = pet.level + 1;
        updateData.expThreshold = pet.expThreshold * 2;
      }

      await Pet.update(updateData, { where: { userId } });

      res.json({
        code: 200,
        data: {
          taskId,
          expReward,
          isUpgrade,
          newLevel: isUpgrade ? pet.level + 1 : pet.level,
          benefitType: task.benefitType,
          benefitValue: task.benefitValue,
        },
        msg: '任务完成成功',
      });
    } else {
      res.json({
        code: 200,
        data: {
          taskId,
          expReward,
          isUpgrade: false,
          benefitType: task.benefitType,
          benefitValue: task.benefitValue,
        },
        msg: '任务完成成功',
      });
    }
  } catch (error) {
    console.error('完成学习任务失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 获取推荐任务（基于评估等级）
router.get('/recommend', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查询用户评估等级
    const evaluationLevel = await EvaluationLevel.findOne({
      where: { userId },
    });

    const currentLevel = evaluationLevel ? evaluationLevel.currentLevel : 'D';

    // 根据评估等级推荐任务难度
    let recommendedDifficulty;
    switch (currentLevel) {
      case 'S':
        recommendedDifficulty = 2; // 困难
        break;
      case 'A':
        recommendedDifficulty = 1; // 中等
        break;
      case 'B':
        recommendedDifficulty = 1; // 中等
        break;
      case 'C':
        recommendedDifficulty = 0; // 简单
        break;
      case 'D':
        recommendedDifficulty = 0; // 简单
        break;
      default:
        recommendedDifficulty = 0;
    }

    // 获取推荐任务
    const recommendedTasks = [];
    Object.keys(taskTemplates).forEach(subject => {
      const tasks = taskTemplates[subject].filter(t => t.difficulty === recommendedDifficulty);
      if (tasks.length > 0) {
        const randomTask = tasks[Math.floor(Math.random() * tasks.length)];
        recommendedTasks.push({
          ...randomTask,
          subject: _getSubjectIndex(subject),
        });
      }
    });

    res.json({
      code: 200,
      data: {
        currentLevel,
        recommendedDifficulty,
        recommendedTasks,
      },
      msg: '推荐任务查询成功',
    });
  } catch (error) {
    console.error('查询推荐任务失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 删除学习任务
router.post('/delete', authMiddleware, async (req, res) => {
  try {
    const { userId, taskId } = req.body;

    if (!userId || !taskId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    await StudyTask.destroy({
      where: { userId, id: taskId },
    });

    res.json({
      code: 200,
      data: {},
      msg: '任务删除成功',
    });
  } catch (error) {
    console.error('删除学习任务失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 辅助函数：获取经验奖励
function _getExpReward(difficulty) {
  switch (difficulty) {
    case 0: return 10;
    case 1: return 20;
    case 2: return 30;
    default: return 10;
  }
}

// 辅助函数：获取科目索引
function _getSubjectIndex(subjectName) {
  const subjects = ['math', 'english', 'physics', 'biology', 'worldHistory', 'chemistry'];
  return subjects.indexOf(subjectName);
}

module.exports = router;