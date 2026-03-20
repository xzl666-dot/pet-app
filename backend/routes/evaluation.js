const express = require('express');
const router = express.Router();
const { User, Pet, EvaluationLevel, EvaluationCalc, Incentive, AbilityTest } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');

// 新用户评估接口
router.post('/newUser/evaluate', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.body;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 检查是否已经进行过新用户评估
    const existingLevel = await EvaluationLevel.findOne({
      where: { userId, petId },
    });

    if (existingLevel && existingLevel.levelHistory) {
      const levelHistory = JSON.parse(existingLevel.levelHistory || '[]');
      if (levelHistory.length > 0) {
        return res.json({ code: 400, data: {}, msg: '已经进行过新用户评估' });
      }
    }

    // 模拟新用户评估（实际项目中应该让用户完成一些测试任务）
    // 这里随机生成评估分数，模拟真实评估结果
    const accuracy = Math.floor(Math.random() * 20) + 80;
    const completionEfficiency = Math.floor(Math.random() * 20) + 80;
    const qualityScore = Math.floor(Math.random() * 20) + 80;

    const totalScore = Math.round(
      accuracy * 0.4 +
      completionEfficiency * 0.3 +
      qualityScore * 0.3
    );

    // 计算评估等级
    const newLevel = _calculateLevel(totalScore);

    // 计算奖励
    const rewards = _calculateRewards(newLevel, totalScore);

    // 保存评估计算数据
    await EvaluationCalc.create({
      userId,
      petId,
      accuracy,
      completionEfficiency,
      qualityScore,
      totalScore,
      taskCompletionCount: 0,
      highQualityCount: 0,
      evaluationDate: new Date(),
      isAbnormal: false,
      abnormalReason: null,
    });

    // 保存评估等级数据
    const levelExpireTime = moment().add(30, 'days').toDate();
    const levelHistory = [{
      date: new Date().toISOString(),
      oldLevel: 'D',
      newLevel,
      score: totalScore,
    }];

    if (existingLevel) {
      await EvaluationLevel.update({
        currentLevel: newLevel,
        currentScore: totalScore,
        levelExpireTime,
        levelHistory: JSON.stringify(levelHistory),
        updateTime: new Date(),
      }, { where: { userId, petId } });
    } else {
      await EvaluationLevel.create({
        userId,
        petId,
        currentLevel: newLevel,
        currentScore: totalScore,
        levelExpireTime,
        levelHistory: JSON.stringify(levelHistory),
        upgradeConditions: JSON.stringify({ score: 60, tasks: 5 }),
        downgradeConditions: JSON.stringify({ score: 50, tasks: 3 }),
      });
    }

    // 更新宠物等级（跳过指定等级）
    const pet = await Pet.findOne({ where: { userId, petId } });
    if (pet) {
      const newLevel = pet.level + rewards.skipLevels;
      await Pet.update({
        level: newLevel,
        abilityLevel: newLevel,
      }, { where: { userId, petId } });
    }

    // 更新激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (incentiveData) {
      await Incentive.update(
        { abilityLevel: newLevel },
        { where: { userId, petId } }
      );
    }

    res.json({
      code: 200,
      data: {
        totalScore,
        newLevel,
        oldLevel: 'D',
        expReward: rewards.expReward,
        skipLevels: rewards.skipLevels,
        levelBenefits: _getLevelBenefits(newLevel),
      },
      msg: '新用户评估成功',
    });
  } catch (error) {
    console.error('新用户评估失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 模块一：评估等级模块

// 评估等级查询接口
router.get('/level/query', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const levelData = await EvaluationLevel.findOne({
      where: { userId, petId },
    });

    if (!levelData) {
      // 如果没有评估等级数据，创建默认数据
      const newLevelData = await EvaluationLevel.create({
        userId,
        petId,
        currentLevel: 'D',
        currentScore: 0,
        levelExpireTime: moment().add(30, 'days').toDate(),
        levelHistory: JSON.stringify([]),
        upgradeConditions: JSON.stringify({ score: 60, tasks: 5 }),
        downgradeConditions: JSON.stringify({ score: 50, tasks: 3 }),
      });

      return res.json({
        code: 200,
        data: {
          currentLevel: newLevelData.currentLevel,
          currentScore: newLevelData.currentScore,
          levelExpireTime: newLevelData.levelExpireTime,
          levelHistory: JSON.parse(newLevelData.levelHistory || '[]'),
          upgradeConditions: JSON.parse(newLevelData.upgradeConditions),
          downgradeConditions: JSON.parse(newLevelData.downgradeConditions),
          levelBenefits: _getLevelBenefits(newLevelData.currentLevel),
        },
        msg: '评估等级查询成功',
      });
    }

    const levelHistory = JSON.parse(levelData.levelHistory || '[]');
    const upgradeConditions = JSON.parse(levelData.upgradeConditions || '{}');
    const downgradeConditions = JSON.parse(levelData.downgradeConditions || '{}');

    // 检查等级是否即将过期
    const daysUntilExpire = moment(levelData.levelExpireTime).diff(moment(), 'days');
    const isExpiringSoon = daysUntilExpire <= 7 && daysUntilExpire > 0;
    const isExpired = daysUntilExpire <= 0;

    res.json({
      code: 200,
      data: {
        currentLevel: levelData.currentLevel,
        currentScore: levelData.currentScore,
        levelExpireTime: levelData.levelExpireTime,
        daysUntilExpire,
        isExpiringSoon,
        isExpired,
        levelHistory,
        upgradeConditions,
        downgradeConditions,
        levelBenefits: _getLevelBenefits(levelData.currentLevel),
      },
      msg: '评估等级查询成功',
    });
  } catch (error) {
    console.error('评估等级查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 评估等级刷新接口
router.post('/level/refresh', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.body;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取最新的评估计算数据
    const calcData = await EvaluationCalc.findOne({
      where: { userId, petId },
      order: [['evaluationDate', 'DESC']],
    });

    if (!calcData) {
      return res.json({ code: 400, data: {}, msg: '暂无评估数据' });
    }

    // 计算新的评估等级
    const newLevel = _calculateLevel(calcData.totalScore);

    // 获取当前等级数据
    const levelData = await EvaluationLevel.findOne({
      where: { userId, petId },
    });

    const levelHistory = levelData ? JSON.parse(levelData.levelHistory || '[]') : [];
    const oldLevel = levelData ? levelData.currentLevel : 'D';

    // 更新等级历史
    if (oldLevel !== newLevel) {
      levelHistory.push({
        date: new Date().toISOString(),
        oldLevel,
        newLevel,
        score: calcData.totalScore,
      });
    }

    // 更新或创建等级数据
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

    // 更新激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (incentiveData) {
      await Incentive.update(
        { abilityLevel: newLevel },
        { where: { userId, petId } }
      );
    }

    res.json({
      code: 200,
      data: {
        currentLevel: newLevel,
        oldLevel,
        currentScore: calcData.totalScore,
        levelBenefits: _getLevelBenefits(newLevel),
        isLevelUp: oldLevel !== newLevel && _compareLevel(newLevel, oldLevel) > 0,
        isLevelDown: oldLevel !== newLevel && _compareLevel(newLevel, oldLevel) < 0,
      },
      msg: '评估等级刷新成功',
    });
  } catch (error) {
    console.error('评估等级刷新失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 评估等级申诉接口
router.post('/level/appeal', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, appealReason, appealData } = req.body;

    if (!userId || !petId || !appealReason) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 这里应该记录申诉数据到数据库，暂时返回成功
    // 实际项目中应该创建appeal表来存储申诉记录

    res.json({
      code: 200,
      data: {
        appealId: Date.now(),
        status: 'processing',
        message: '申诉已提交，我们将在3个工作日内处理',
      },
      msg: '申诉提交成功',
    });
  } catch (error) {
    console.error('评估等级申诉失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 模块二：评估计算模块

// 评估数据查询接口
router.get('/calc/query', authMiddleware, async (req, res) => {
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

    // 计算统计数据
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

// 评估计算接口
router.post('/calc/calculate', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, accuracy, completionEfficiency, qualityScore, taskCompletionCount, highQualityCount } = req.body;

    if (!userId || !petId || accuracy === undefined || completionEfficiency === undefined || qualityScore === undefined) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 计算总分（准确率权重最高）
    const totalScore = Math.round(
      accuracy * 0.4 +
      completionEfficiency * 0.3 +
      qualityScore * 0.3
    );

    // 检查数据是否异常
    const isAbnormal = accuracy > 100 || accuracy < 0 || completionEfficiency > 100 || completionEfficiency < 0 || qualityScore > 100 || qualityScore < 0;
    const abnormalReason = isAbnormal ? '评估数据超出正常范围' : null;

    // 保存评估计算数据
    const calcData = await EvaluationCalc.create({
      userId,
      petId,
      accuracy,
      completionEfficiency,
      qualityScore,
      totalScore,
      taskCompletionCount: taskCompletionCount || 0,
      highQualityCount: highQualityCount || 0,
      evaluationDate: new Date(),
      isAbnormal,
      abnormalReason,
    });

    // 自动刷新评估等级
    const newLevel = _calculateLevel(totalScore);
    const levelData = await EvaluationLevel.findOne({
      where: { userId, petId },
    });

    const levelHistory = levelData ? JSON.parse(levelData.levelHistory || '[]') : [];
    const oldLevel = levelData ? levelData.currentLevel : 'D';

    if (oldLevel !== newLevel) {
      levelHistory.push({
        date: new Date().toISOString(),
        oldLevel,
        newLevel,
        score: totalScore,
      });
    }

    const levelExpireTime = moment().add(30, 'days').toDate();
    const updateData = {
      currentLevel: newLevel,
      currentScore: totalScore,
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

    res.json({
      code: 200,
      data: {
        calcId: calcData.id,
        totalScore,
        newLevel,
        oldLevel,
        isLevelUp: oldLevel !== newLevel && _compareLevel(newLevel, oldLevel) > 0,
        isLevelDown: oldLevel !== newLevel && _compareLevel(newLevel, oldLevel) < 0,
        levelBenefits: _getLevelBenefits(newLevel),
        isAbnormal,
        abnormalReason,
      },
      msg: '评估计算成功',
    });
  } catch (error) {
    console.error('评估计算失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 评估规则查询接口
router.get('/calc/rules', authMiddleware, async (req, res) => {
  try {
    const rules = {
      levelThresholds: {
        S: { minScore: 90, benefits: '激励加成1.5倍，解锁精英宝箱、专属成就、月度稀有福利' },
        A: { minScore: 80, benefits: '激励加成1.4倍，解锁进阶宝箱、高阶积分兑换项' },
        B: { minScore: 70, benefits: '激励加成1.2倍，解锁基础宝箱、中等积分兑换项' },
        C: { minScore: 60, benefits: '激励加成1.0倍，解锁基础积分兑换项' },
        D: { minScore: 0, benefits: '激励加成0.8倍，基础权限' },
      },
      scoreWeights: {
        accuracy: 0.4,
        completionEfficiency: 0.3,
        qualityScore: 0.3,
      },
      qualityBonus: {
        highQuality: { minScore: 80, bonus: 1.2 },
        excellent: { minScore: 90, bonus: 1.5 },
      },
      levelValidity: 30,
    };

    res.json({
      code: 200,
      data: rules,
      msg: '评估规则查询成功',
    });
  } catch (error) {
    console.error('评估规则查询失败:', error);
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

// 辅助函数：计算奖励
function _calculateRewards(level, score) {
  const rewards = {
    S: { expReward: 500, skipLevels: 5 },
    A: { expReward: 400, skipLevels: 4 },
    B: { expReward: 300, skipLevels: 3 },
    C: { expReward: 100, skipLevels: 2 },
    D: { expReward: 0, skipLevels: 0 },
  };

  return rewards[level] || rewards['D'];
}

// 辅助函数：比较等级
function _compareLevel(level1, level2) {
  const levelOrder = { 'S': 5, 'A': 4, 'B': 3, 'C': 2, 'D': 1 };
  return levelOrder[level1] - levelOrder[level2];
}

// 辅助函数：获取等级权益
function _getLevelBenefits(level) {
  const benefits = {
    S: {
      incentiveBonus: 1.5,
      unlockedChests: ['basic', 'advanced', 'elite', 'exclusive'],
      unlockedAchievements: ['S级评估', '精英宝箱', '专属成就'],
      unlockedWelfare: '月度稀有福利',
      description: '激励加成1.5倍，解锁精英宝箱、专属成就、月度稀有福利',
    },
    A: {
      incentiveBonus: 1.4,
      unlockedChests: ['basic', 'advanced', 'elite'],
      unlockedAchievements: ['A级评估', '进阶宝箱'],
      unlockedWelfare: '高级福利',
      description: '激励加成1.4倍，解锁进阶宝箱、高阶积分兑换项',
    },
    B: {
      incentiveBonus: 1.2,
      unlockedChests: ['basic', 'advanced'],
      unlockedAchievements: ['B级评估', '基础宝箱'],
      unlockedWelfare: '中等福利',
      description: '激励加成1.2倍，解锁基础宝箱、中等积分兑换项',
    },
    C: {
      incentiveBonus: 1.0,
      unlockedChests: ['basic'],
      unlockedAchievements: ['C级评估'],
      unlockedWelfare: '基础福利',
      description: '激励加成1.0倍，解锁基础积分兑换项',
    },
    D: {
      incentiveBonus: 0.8,
      unlockedChests: [],
      unlockedAchievements: ['D级评估'],
      unlockedWelfare: '基础权限',
      description: '激励加成0.8倍，基础权限',
    },
  };

  return benefits[level] || benefits['D'];
}

// 模块三：能力评估测试模块

// 检查测试状态接口
router.get('/test/status', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查询用户是否已参加测试
    const testRecord = await AbilityTest.findOne({
      where: { userId },
    });

    // 查询当前评估等级
    const levelRecord = await EvaluationLevel.findOne({
      where: { userId },
    });

    res.json({
      code: 200,
      data: {
        hasTakenTest: !!testRecord,
        currentLevel: levelRecord ? levelRecord.currentLevel : 'D',
      },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('查询测试状态失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 提交测试结果接口
router.post('/test/submit', authMiddleware, async (req, res) => {
  try {
    const { userId, score, level } = req.body;

    if (!userId || !score || !level) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 检查是否已参加过测试
    const existingTest = await AbilityTest.findOne({
      where: { userId },
    });

    if (existingTest) {
      return res.json({ code: 400, data: {}, msg: '每个用户只能参加一次能力测试' });
    }

    // 保存测试记录
    await AbilityTest.create({
      userId,
      score,
      level,
      testDate: new Date(),
    });

    // 更新评估等级
    const existingLevel = await EvaluationLevel.findOne({
      where: { userId },
    });

    if (existingLevel) {
      const levelHistory = JSON.parse(existingLevel.levelHistory || '[]');
      levelHistory.push({
        date: new Date().toISOString(),
        oldLevel: existingLevel.currentLevel,
        newLevel: level,
        score: score,
        reason: '能力评估测试',
      });

      await EvaluationLevel.update({
        currentLevel: level,
        currentScore: score,
        levelHistory: JSON.stringify(levelHistory),
        updateTime: new Date(),
      }, { where: { userId } });
    } else {
      await EvaluationLevel.create({
        userId,
        petId: 1,
        currentLevel: level,
        currentScore: score,
        levelExpireTime: moment().add(30, 'days').toDate(),
        levelHistory: JSON.stringify([{
          date: new Date().toISOString(),
          oldLevel: 'D',
          newLevel: level,
          score: score,
          reason: '能力评估测试',
        }]),
        upgradeConditions: JSON.stringify({ score: 60, tasks: 5 }),
        downgradeConditions: JSON.stringify({ score: 50, tasks: 3 }),
      });
    }

    // 更新激励数据
    const existingIncentive = await Incentive.findOne({
      where: { userId, petId: 1 },
    });

    if (existingIncentive) {
      await Incentive.update({
        abilityLevel: level,
      }, { where: { userId, petId: 1 } });
    } else {
      await Incentive.create({
        userId,
        petId: 1,
        abilityLevel: level,
        integral: 0,
        integralGet: 0,
        integralConsume: 0,
        integralExpire: 0,
        chestUnlock: '[]',
        chestOpenNum: 0,
        achievementUnlock: '[]',
        signInDays: 0,
        welfareGet: '[]',
        incentivePrefer: '{}',
      });
    }

    res.json({
      code: 200,
      data: {
        level,
        score,
        benefits: _getLevelBenefits(level),
      },
      msg: '测试提交成功',
    });
  } catch (error) {
    console.error('提交测试失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

module.exports = router;