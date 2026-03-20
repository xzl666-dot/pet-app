const express = require('express');
const router = express.Router();
const { User, Pet, Task, EvaluationLevel, EvaluationCalc, Incentive } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');

// 模块四：评估适配任务模块

// 任务推荐接口
router.get('/recommend', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取评估等级
    const levelData = await EvaluationLevel.findOne({
      where: { userId, petId },
    });

    const abilityLevel = levelData ? levelData.currentLevel : 'D';

    // 根据评估等级推荐任务难度
    const difficultyMap = {
      'S': [4, 5],
      'A': [3, 4],
      'B': [2, 3],
      'C': [1, 2],
      'D': [1],
    };

    const recommendedDifficulties = difficultyMap[abilityLevel] || [1, 2];

    // 查询推荐任务
    const tasks = await Task.findAll({
      where: {
        difficulty: recommendedDifficulties,
        is_completed: 0,
        is_test_task: 0,
      },
      limit: 10,
    });

    // 计算每个任务的收益加成
    const tasksWithBonus = tasks.map(task => {
      const levelBonus = _getLevelBonus(abilityLevel);
      const baseValue = task.benefit_value || 0;
      const bonusValue = Math.round(baseValue * (levelBonus - 1));
      const totalValue = baseValue + bonusValue;

      return {
        id: task.id,
        name: task.name,
        difficulty: task.difficulty,
        deadline: task.deadline,
        benefit_type: task.benefit_type,
        baseValue,
        levelBonus,
        bonusValue,
        totalValue,
        isRecommended: true,
      };
    });

    res.json({
      code: 200,
      data: {
        abilityLevel,
        recommendedDifficulties,
        taskList: tasksWithBonus,
        message: `根据你的${abilityLevel}级评估，推荐以下适配任务`,
      },
      msg: '任务推荐成功',
    });
  } catch (error) {
    console.error('任务推荐失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 任务列表查询接口
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, difficulty, status, page = 1, pageSize = 10 } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    let whereCondition = { userId: parseInt(userId) };
    if (difficulty) {
      whereCondition.difficulty = parseInt(difficulty);
    }
    if (status === 'completed') {
      whereCondition.is_completed = 1;
    } else if (status === 'pending') {
      whereCondition.is_completed = 0;
    }

    const offset = (parseInt(page) - 1) * parseInt(pageSize);
    const tasks = await Task.findAll({
      where: whereCondition,
      order: [['created_at', 'DESC']],
      limit: parseInt(pageSize),
      offset,
    });

    const total = await Task.count({ where: whereCondition });

    // 获取评估等级
    const levelData = await EvaluationLevel.findOne({
      where: { userId, petId },
    });
    const abilityLevel = levelData ? levelData.currentLevel : 'D';

    // 计算任务收益
    const tasksWithBonus = tasks.map(task => {
      const levelBonus = _getLevelBonus(abilityLevel);
      const baseValue = task.benefit_value || 0;
      const bonusValue = Math.round(baseValue * (levelBonus - 1));
      const totalValue = baseValue + bonusValue;

      return {
        id: task.id,
        name: task.name,
        difficulty: task.difficulty,
        deadline: task.deadline,
        benefit_type: task.benefit_type,
        baseValue,
        levelBonus,
        bonusValue,
        totalValue,
        is_completed: task.is_completed === 1,
        completed_at: task.completed_at,
        created_at: task.created_at,
      };
    });

    res.json({
      code: 200,
      data: {
        taskList: tasksWithBonus,
        pagination: {
          page: parseInt(page),
          pageSize: parseInt(pageSize),
          total,
          totalPages: Math.ceil(total / parseInt(pageSize)),
        },
        abilityLevel,
      },
      msg: '任务列表查询成功',
    });
  } catch (error) {
    console.error('任务列表查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 任务领取接口
router.post('/claim', authMiddleware, async (req, res) => {
  try {
    const { userId, taskId } = req.body;

    if (!userId || !taskId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const task = await Task.findOne({
      where: { id: taskId },
    });

    if (!task) {
      return res.json({ code: 400, data: {}, msg: '任务不存在' });
    }

    // 检查任务是否已领取
    if (task.userId && task.userId !== parseInt(userId)) {
      return res.json({ code: 400, data: {}, msg: '任务已被他人领取' });
    }

    // 检查任务难度是否需要评估等级
    if (task.difficulty >= 4) {
      const pet = await Pet.findOne({
        where: { userId },
      });

      const abilityLevel = pet ? pet.abilityLevel : 'D';
      const levelOrder = { 'S': 5, 'A': 4, 'B': 3, 'C': 2, 'D': 1 };
      const requiredLevel = task.difficulty >= 5 ? 'A' : 'B';

      if (levelOrder[abilityLevel] < levelOrder[requiredLevel]) {
        return res.json({
          code: 400,
          data: {},
          msg: `需提升至${requiredLevel}级评估才能领取此任务`,
        });
      }
    }

    // 更新任务领取状态
    await Task.update(
      { userId: parseInt(userId) },
      { where: { id: taskId } }
    );

    res.json({
      code: 200,
      data: {
        taskId,
        message: '任务领取成功',
      },
      msg: '任务领取成功',
    });
  } catch (error) {
    console.error('任务领取失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 任务提交接口
router.post('/submit', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, taskId, qualityScore, completionTime } = req.body;

    if (!userId || !taskId || qualityScore === undefined) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const task = await Task.findOne({
      where: { id: taskId, userId: parseInt(userId) },
    });

    if (!task) {
      return res.json({ code: 400, data: {}, msg: '任务不存在或未领取' });
    }

    if (task.is_completed === 1) {
      return res.json({ code: 400, data: {}, msg: '任务已完成' });
    }

    // 检查提交条件
    if (qualityScore < 0 || qualityScore > 100) {
      return res.json({ code: 400, data: {}, msg: '质量评分必须在0-100之间' });
    }

    // 计算任务质量加成
    const qualityBonus = qualityScore >= 90 ? 1.5 : (qualityScore >= 80 ? 1.2 : 1.0);

    // 获取评估等级
    const levelData = await EvaluationLevel.findOne({
      where: { userId, petId },
    });
    const abilityLevel = levelData ? levelData.currentLevel : 'D';
    const levelBonus = _getLevelBonus(abilityLevel);

    // 计算总收益
    const baseValue = task.benefit_value || 0;
    const levelBonusValue = Math.round(baseValue * (levelBonus - 1));
    const qualityBonusValue = Math.round(baseValue * (qualityBonus - 1));
    const totalValue = baseValue + levelBonusValue + qualityBonusValue;

    // 更新任务状态
    await Task.update(
      {
        is_completed: 1,
        completed_at: moment().unix(),
      },
      { where: { id: taskId } }
    );

    // 更新评估计算数据
    const accuracy = Math.round(Math.random() * 20 + 80); // 模拟准确率
    const completionEfficiency = Math.round(Math.random() * 20 + 80); // 模拟完成效率

    await EvaluationCalc.create({
      userId,
      petId,
      accuracy,
      completionEfficiency,
      qualityScore,
      totalScore: Math.round(accuracy * 0.4 + completionEfficiency * 0.3 + qualityScore * 0.3),
      taskCompletionCount: 1,
      highQualityCount: qualityScore >= 80 ? 1 : 0,
      evaluationDate: new Date(),
    });

    // 更新激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (incentiveData) {
      await Incentive.update(
        {
          integral: (incentiveData.integral || 0) + totalValue,
          integralGet: (incentiveData.integralGet || 0) + totalValue,
          updateTime: new Date(),
        },
        { where: { userId, petId } }
      );
    }

    // 自动刷新评估等级
    const calcData = await EvaluationCalc.findOne({
      where: { userId, petId },
      order: [['evaluationDate', 'DESC']],
    });

    if (calcData) {
      const newLevel = _calculateLevel(calcData.totalScore);
      const levelHistory = levelData ? JSON.parse(levelData.levelHistory || '[]') : [];
      const oldLevel = levelData ? levelData.currentLevel : 'D';

      if (oldLevel !== newLevel) {
        levelHistory.push({
          date: new Date().toISOString(),
          oldLevel,
          newLevel,
          score: calcData.totalScore,
        });
      }

      const levelExpireTime = moment().add(30, 'days').toDate();
      const updateData = {
        currentLevel: newLevel,
        currentScore: calcData.totalScore,
        levelExpireTime,
        levelHistory: JSON.stringify(levelHistory),
        updateTime: new Date(),
      };

      if (levelData) {
        await EvaluationLevel.update(updateData, { where: { userId, petId } });
      } else {
        await EvaluationLevel.create({
          userId,
          petId,
          ...updateData,
          upgradeConditions: JSON.stringify({ score: 60, tasks: 5 }),
          downgradeConditions: JSON.stringify({ score: 50, tasks: 3 }),
        });
      }

      // 更新宠物能力等级
      await Pet.update(
        { abilityLevel: newLevel },
        { where: { userId, petId } }
      );
    }

    res.json({
      code: 200,
      data: {
        taskId,
        qualityScore,
        baseValue,
        levelBonus,
        qualityBonus,
        totalValue,
        rewardBreakdown: {
          base: baseValue,
          levelBonus: levelBonusValue,
          qualityBonus: qualityBonusValue,
          total: totalValue,
        },
        newLevel: calcData ? _calculateLevel(calcData.totalScore) : null,
      },
      msg: '任务提交成功',
    });
  } catch (error) {
    console.error('任务提交失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 任务进度统计接口
router.get('/statistics', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, timeType } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    let whereCondition = { userId, petId };
    if (timeType === 'today') {
      whereCondition.evaluationDate = {
        [require('sequelize').Op.gte]: moment().startOf('day').toDate(),
      };
    } else if (timeType === 'week') {
      whereCondition.evaluationDate = {
        [require('sequelize').Op.gte]: moment().startOf('week').toDate(),
      };
    } else if (timeType === 'month') {
      whereCondition.evaluationDate = {
        [require('sequelize').Op.gte]: moment().startOf('month').toDate(),
      };
    }

    const calcDataList = await EvaluationCalc.findAll({
      where: whereCondition,
    });

    const totalTasks = calcDataList.reduce((sum, item) => sum + item.taskCompletionCount, 0);
    const highQualityTasks = calcDataList.reduce((sum, item) => sum + item.highQualityCount, 0);
    const averageQualityScore = calcDataList.length > 0
      ? Math.round(calcDataList.reduce((sum, item) => sum + item.qualityScore, 0) / calcDataList.length)
      : 0;

    // 查询任务列表
    const taskWhereCondition = { userId: parseInt(userId) };
    if (timeType === 'today') {
      taskWhereCondition.completed_at = {
        [require('sequelize').Op.gte]: moment().startOf('day').unix(),
      };
    } else if (timeType === 'week') {
      taskWhereCondition.completed_at = {
        [require('sequelize').Op.gte]: moment().startOf('week').unix(),
      };
    } else if (timeType === 'month') {
      taskWhereCondition.completed_at = {
        [require('sequelize').Op.gte]: moment().startOf('month').unix(),
      };
    }

    const completedTasks = await Task.findAll({
      where: { ...taskWhereCondition, is_completed: 1 },
    });

    res.json({
      code: 200,
      data: {
        totalTasks,
        highQualityTasks,
        averageQualityScore,
        highQualityRate: totalTasks > 0 ? Math.round((highQualityTasks / totalTasks) * 100) : 0,
        completedTaskList: completedTasks.map(task => ({
          id: task.id,
          name: task.name,
          difficulty: task.difficulty,
          completed_at: task.completed_at,
        })),
      },
      msg: '任务进度统计成功',
    });
  } catch (error) {
    console.error('任务进度统计失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 补做任务接口
router.post('/makeup', authMiddleware, async (req, res) => {
  try {
    const { userId, taskId } = req.body;

    if (!userId || !taskId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 检查补做次数限制（每月限3次）
    // 这里应该从数据库查询用户的补做次数
    const makeupCount = 0; // 暂时设为0

    if (makeupCount >= 3) {
      return res.json({ code: 400, data: {}, msg: '本月补做次数已用完' });
    }

    const task = await Task.findOne({
      where: { id: taskId },
    });

    if (!task) {
      return res.json({ code: 400, data: {}, msg: '任务不存在' });
    }

    // 重置任务状态
    await Task.update(
      {
        is_completed: 0,
        completed_at: null,
      },
      { where: { id: taskId } }
    );

    res.json({
      code: 200,
      data: {
        taskId,
        message: '补做成功',
        remainingMakeupCount: 3 - makeupCount - 1,
      },
      msg: '补做成功',
    });
  } catch (error) {
    console.error('补做任务失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 辅助函数：根据分数计算等级
function _calculateLevel(score) {
  if (score >= 90) return 'S';
  if (score >= 80) return 'A';
  if (score >= 70) return 'B';
  if (score >= 60) return 'C';
  return 'D';
}

// 辅助函数：获取等级加成
function _getLevelBonus(level) {
  const bonusMap = {
    'S': 1.5,
    'A': 1.4,
    'B': 1.2,
    'C': 1.0,
    'D': 0.8,
  };
  return bonusMap[level] || 1.0;
}

module.exports = router;