const express = require('express');
const router = express.Router();
const { User, Pet, EvaluationLevel, EvaluationCalc, StudyTask } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');

// 计算评估分数
router.post('/calculate', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.body;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取用户的所有学习任务
    const allTasks = await StudyTask.findAll({
      where: { userId },
    });

    if (allTasks.length === 0) {
      return res.json({
        code: 400,
        data: {},
        msg: '暂无学习任务数据',
      });
    }

    // 计算准确率（完成任务占比）
    const completedTasks = allTasks.filter(t => t.isCompleted === 1);
    const accuracy = Math.round((completedTasks.length / allTasks.length) * 100);

    // 计算完成效率（按时完成占比）
    const onTimeTasks = completedTasks.filter(t => {
      const completedAt = moment(t.completedAt);
      const deadline = moment(t.deadline);
      return completedAt.isSameOrBefore(deadline);
    });
    const completionEfficiency = completedTasks.length > 0
      ? Math.round((onTimeTasks.length / completedTasks.length) * 100)
      : 0;

    // 计算质量分数（基于任务难度）
    let qualityScore = 0;
    completedTasks.forEach(task => {
      switch (task.difficulty) {
        case 0: // 简单
          qualityScore += 60;
          break;
        case 1: // 中等
          qualityScore += 80;
          break;
        case 2: // 困难
          qualityScore += 100;
          break;
      }
    });
    qualityScore = completedTasks.length > 0
      ? Math.round(qualityScore / completedTasks.length)
      : 0;

    // 计算总分
    const totalScore = Math.round(
      accuracy * 0.4 +
      completionEfficiency * 0.3 +
      qualityScore * 0.3
    );

    // 计算评估等级
    const level = _calculateLevel(totalScore);

    // 保存评估计算数据
    await EvaluationCalc.create({
      userId,
      petId,
      accuracy,
      completionEfficiency,
      qualityScore,
      totalScore,
      taskCompletionCount: completedTasks.length,
      highQualityCount: completedTasks.filter(t => t.difficulty === 2).length,
      evaluationDate: new Date(),
      isAbnormal: false,
      abnormalReason: null,
    });

    // 更新评估等级
    const existingLevel = await EvaluationLevel.findOne({
      where: { userId, petId },
    });

    const levelExpireTime = moment().add(30, 'days').toDate();
    const levelHistory = [{
      date: new Date().toISOString(),
      oldLevel: existingLevel ? existingLevel.currentLevel : 'D',
      newLevel: level,
      score: totalScore,
      reason: '自动评估计算',
    }];

    if (existingLevel) {
      const history = JSON.parse(existingLevel.levelHistory || '[]');
      history.push(levelHistory[0]);

      await EvaluationLevel.update({
        currentLevel: level,
        currentScore: totalScore,
        levelExpireTime,
        levelHistory: JSON.stringify(history),
        updateTime: new Date(),
      }, { where: { userId, petId } });
    } else {
      await EvaluationLevel.create({
        userId,
        petId,
        currentLevel: level,
        currentScore: totalScore,
        levelExpireTime,
        levelHistory: JSON.stringify(levelHistory),
        upgradeConditions: JSON.stringify({ score: 60, tasks: 5 }),
        downgradeConditions: JSON.stringify({ score: 50, tasks: 3 }),
      });
    }

    res.json({
      code: 200,
      data: {
        accuracy,
        completionEfficiency,
        qualityScore,
        totalScore,
        level,
        taskCompletionCount: completedTasks.length,
        highQualityCount: completedTasks.filter(t => t.difficulty === 2).length,
      },
      msg: '评估计算成功',
    });
  } catch (error) {
    console.error('评估计算失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 查询评估数据
router.get('/query', authMiddleware, async (req, res) => {
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
      order: [['evaluationDate', 'DESC']],
    });

    const totalAccuracy = calcDataList.reduce((sum, item) => sum + item.accuracy, 0) / (calcDataList.length || 1);
    const totalEfficiency = calcDataList.reduce((sum, item) => sum + item.completionEfficiency, 0) / (calcDataList.length || 1);
    const totalQualityScore = calcDataList.reduce((sum, item) => sum + item.qualityScore, 0) / (calcDataList.length || 1);
    const totalTasks = calcDataList.reduce((sum, item) => sum + item.taskCompletionCount, 0);
    const highQualityTasks = calcDataList.reduce((sum, item) => sum + item.highQualityCount, 0);

    res.json({
      code: 200,
      data: {
        calcDataList: calcDataList.map(item => ({
          accuracy: item.accuracy,
          completionEfficiency: item.completionEfficiency,
          qualityScore: item.qualityScore,
          totalScore: item.totalScore,
          taskCompletionCount: item.taskCompletionCount,
          highQualityCount: item.highQualityCount,
          evaluationDate: item.evaluationDate,
          isAbnormal: item.isAbnormal,
          abnormalReason: item.abnormalReason,
        })),
        statistics: {
          averageAccuracy: Math.round(totalAccuracy * 100) / 100,
          averageEfficiency: Math.round(totalEfficiency * 100) / 100,
          averageQualityScore: Math.round(totalQualityScore),
          totalTasks,
          highQualityTasks,
          highQualityRate: totalTasks > 0 ? Math.round((highQualityTasks / totalTasks) * 100) : 0,
        },
      },
      msg: '评估数据查询成功',
    });
  } catch (error) {
    console.error('评估数据查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 辅助函数：计算评估等级
function _calculateLevel(score) {
  if (score >= 90) return 'S';
  if (score >= 80) return 'A';
  if (score >= 70) return 'B';
  if (score >= 60) return 'C';
  return 'D';
}

module.exports = router;