const express = require('express');
const router = express.Router();
const { User, Pet, EvaluationLevel, EvaluationCalc, StudyTask, Challenge, Incentive, CheckIn, Achievement } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');

// 获取个人中心数据
router.get('/dashboard', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取用户信息
    const user = await User.findOne({ where: { userId } });
    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    // 获取宠物信息 (获取当前选中的宠物)
    const pet = await Pet.findOne({ where: { userId, isSelected: 1 } });

    // 获取评估等级
    const evaluationLevel = await EvaluationLevel.findOne({
      where: { userId, petId: pet ? pet.petId : 0 },
    });

    // 获取评估计算数据
    const calcData = await EvaluationCalc.findAll({
      where: { userId },
      order: [['evaluationDate', 'DESC']],
      limit: 7,
    });

    // 获取学习任务统计 (统一使用 Task 模型)
    const { Task, ChallengeRecord } = require('../models');
    const allTasks = await Task.findAll({ where: { userId } });
    const completedTasks = allTasks.filter(t => t.is_completed === 1);
    const todayTasks = allTasks.filter(t =>
      moment.unix(t.created_at).isSame(moment(), 'day')
    );
    const todayCompletedTasks = todayTasks.filter(t => t.is_completed === 1);

    // 获取挑战统计 (使用 ChallengeRecord)
    const challenges = await ChallengeRecord.findAll({
      where: { userId },
    });
    const winChallenges = challenges.filter(c => c.result === 'win');
    const todayChallenges = challenges.filter(c =>
      moment(c.createTime).isSame(moment(), 'day')
    );

    // 获取激励数据
    const incentives = await Incentive.findAll({ where: { userId } });
    // 优先获取当前选中宠物的积分，如果没有则累加
    let totalPoints = 0;
    if (pet) {
      // 注意：Pet 模型的 PK 是 petId
      let currentIncentive = incentives.find(i => i.petId === pet.petId);
      
      // 如果没有找到激励数据，尝试创建一个
      if (!currentIncentive) {
        currentIncentive = await Incentive.create({
          userId,
          petId: pet.petId,
          abilityLevel: 'D',
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
      totalPoints = currentIncentive ? currentIncentive.integral : 0;
    } else {
      totalPoints = incentives.reduce((sum, i) => sum + (i.integral || 0), 0);
    }

    res.json({
      code: 200,
      data: {
        user: {
          userId: user.userId,
          nickname: user.nickname,
          avatar: user.avatar,
          phone: user.phone,
          isVip: user.isVip === 1,
          vipExpire: user.vipExpire,
          createTime: user.createTime,
          lastLoginTime: user.lastLoginTime,
        },
        pet: pet ? {
          id: pet.id,
          name: pet.name,
          type: pet.type,
          form: pet.form,
          level: pet.level,
          exp: pet.exp,
          expThreshold: pet.expThreshold,
          nutrition: pet.nutrition,
          happiness: pet.happiness,
          skillPoint: pet.skillPoint,
        } : null,
        evaluation: evaluationLevel ? {
          currentLevel: evaluationLevel.currentLevel,
          currentScore: evaluationLevel.currentScore,
          levelExpireTime: evaluationLevel.levelExpireTime,
        } : null,
        evaluationHistory: calcData.map(item => ({
          accuracy: item.accuracy,
          completionEfficiency: item.completionEfficiency,
          qualityScore: item.qualityScore,
          totalScore: item.totalScore,
          evaluationDate: item.evaluationDate,
        })),
        statistics: {
          tasks: {
            total: allTasks.length,
            completed: completedTasks.length,
            todayTotal: todayTasks.length,
            todayCompleted: todayCompletedTasks.length,
            completionRate: allTasks.length > 0
              ? Math.round((completedTasks.length / allTasks.length) * 100)
              : 0,
          },
          challenges: {
            total: challenges.length,
            wins: winChallenges.length,
            todayTotal: todayChallenges.length,
            winRate: challenges.length > 0
              ? Math.round((winChallenges.length / challenges.length) * 100)
              : 0,
          },
          incentives: {
            totalPoints,
            totalIncentives: incentives.length,
          },
        },
      },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('获取个人中心数据失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 获取打卡数据
router.get('/check-in', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const checkIns = await CheckIn.findAll({
      where: { userId },
      order: [['checkInDate', 'DESC']],
      limit: 30
    });

    const today = moment().format('YYYY-MM-DD');
    const hasCheckedInToday = checkIns.some(c => c.checkInDate === today);

    res.json({
      code: 200,
      data: {
        checkIns,
        hasCheckedInToday
      },
      msg: '查询成功'
    });
  } catch (error) {
    console.error('获取打卡数据失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 执行打卡
router.post('/check-in', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const today = moment().format('YYYY-MM-DD');
    const yesterday = moment().subtract(1, 'days').format('YYYY-MM-DD');

    // 检查今日是否已打卡
    const existingCheckIn = await CheckIn.findOne({
      where: { userId, checkInDate: today }
    });

    if (existingCheckIn) {
      return res.json({ code: 400, data: {}, msg: '今日已打卡' });
    }

    // 检查昨日是否打卡以计算连续天数
    const lastCheckIn = await CheckIn.findOne({
      where: { userId, checkInDate: yesterday }
    });

    let continuousDays = 1;
    if (lastCheckIn) {
      continuousDays = lastCheckIn.continuousDays + 1;
    }

    // 奖励积分
    const rewardPoints = 10 + Math.min(continuousDays, 7) * 2; // 基础10分，连续打卡额外奖励，最高额外14分

    const newCheckIn = await CheckIn.create({
      userId,
      checkInDate: today,
      continuousDays,
      rewardPoints
    });

    // 更新用户积分
    const pet = await Pet.findOne({ where: { userId } });
    if (pet) {
      const incentive = await Incentive.findOne({ where: { userId, petId: pet.petId } });
      if (incentive) {
        await incentive.update({
          integral: incentive.integral + rewardPoints,
          integralGet: incentive.integralGet + rewardPoints
        });
      }
    }

    res.json({
      code: 200,
      data: newCheckIn,
      msg: '打卡成功'
    });
  } catch (error) {
    console.error('打卡失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 获取成就列表
router.get('/achievements', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    let achievements = await Achievement.findAll({ where: { userId } });

    // 如果没有成就记录，初始化默认成就
    if (achievements.length === 0) {
      const defaultAchievements = [
        { achievementKey: 'task_10', achievementName: '初露锋芒', targetValue: 10 },
        { achievementKey: 'task_50', achievementName: '任务达人', targetValue: 50 },
        { achievementKey: 'checkin_7', achievementName: '坚持不懈', targetValue: 7 },
        { achievementKey: 'pet_level_10', achievementName: '伙伴成长', targetValue: 10 }
      ];

      achievements = await Promise.all(defaultAchievements.map(a =>
        Achievement.create({ ...a, userId })
      ));
    }

    res.json({
      code: 200,
      data: achievements,
      msg: '查询成功'
    });
  } catch (error) {
    console.error('获取成就失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 领取成就奖励
router.post('/achievement/reward', authMiddleware, async (req, res) => {
  try {
    const { achievementId } = req.body;
    const userId = req.userId;

    const achievement = await Achievement.findOne({ where: { id: achievementId, userId } });
    if (!achievement) {
      return res.json({ code: 400, data: {}, msg: '成就不存在' });
    }

    if (achievement.status !== 1) {
      return res.json({ code: 400, data: {}, msg: '成就未达成或已领取奖励' });
    }

    // 更新状态
    await achievement.update({ status: 2 });

    // 发放奖励 (例如 100 积分)
    const rewardPoints = 100;
    const pet = await Pet.findOne({ where: { userId } });
    if (pet) {
      const incentive = await Incentive.findOne({ where: { userId, petId: pet.petId } });
      if (incentive) {
        await incentive.update({
          integral: incentive.integral + rewardPoints,
          integralGet: incentive.integralGet + rewardPoints
        });
      }
    }

    res.json({
      code: 200,
      data: { rewardPoints },
      msg: '奖励领取成功'
    });
  } catch (error) {
    console.error('获取个人中心数据失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 更新用户信息
router.post('/update', authMiddleware, async (req, res) => {
  try {
    const { userId, nickname, avatar } = req.body;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const updateData = {};
    if (nickname !== undefined) updateData.nickname = nickname;
    if (avatar !== undefined) updateData.avatar = avatar;

    await User.update(updateData, { where: { userId } });

    const user = await User.findOne({ where: { userId } });

    res.json({
      code: 200,
      data: {
        userId: user.userId,
        nickname: user.nickname,
        avatar: user.avatar,
      },
      msg: '更新成功',
    });
  } catch (error) {
    console.error('更新用户信息失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 导出用户数据
router.get('/export', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取所有相关数据
    const user = await User.findOne({ where: { userId } });
    const pet = await Pet.findOne({ where: { userId } });
    const evaluationLevel = await EvaluationLevel.findOne({
      where: { userId, petId: 1 },
    });
    const evaluationCalc = await EvaluationCalc.findAll({ where: { userId } });
    const tasks = await Task.findAll({ where: { userId } });
    const challenges = await ChallengeRecord.findAll({ where: { userId } });
    const incentives = await Incentive.findAll({ where: { userId } });

    const exportData = {
      exportTime: new Date().toISOString(),
      user: {
        userId: user.userId,
        nickname: user.nickname,
        avatar: user.avatar,
        phone: user.phone,
        createTime: user.createTime,
        lastLoginTime: user.lastLoginTime,
      },
      pet: pet ? {
        name: pet.name,
        type: pet.type,
        form: pet.form,
        level: pet.level,
        exp: pet.exp,
        nutrition: pet.nutrition,
        happiness: pet.happiness,
        skillPoint: pet.skillPoint,
      } : null,
      evaluation: {
        level: evaluationLevel ? evaluationLevel.currentLevel : null,
        history: evaluationCalc.map(item => ({
          accuracy: item.accuracy,
          completionEfficiency: item.completionEfficiency,
          qualityScore: item.qualityScore,
          totalScore: item.totalScore,
          evaluationDate: item.evaluationDate,
        })),
      },
      tasks: tasks.map(task => ({
        name: task.name,
        difficulty: task.difficulty,
        isCompleted: task.is_completed === 1,
        createdAt: task.created_at,
        completedAt: task.completed_at,
      })),
      challenges: challenges.map(challenge => ({
        opponentId: challenge.opponentId,
        result: challenge.result,
        score: challenge.score,
        createTime: challenge.createTime,
      })),
      incentives: incentives.map(incentive => ({
        type: incentive.type,
        points: incentive.points,
        createdAt: incentive.createdAt,
      })),
    };

    res.json({
      code: 200,
      data: exportData,
      msg: '导出成功',
    });
  } catch (error) {
    console.error('导出用户数据失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 获取用户设置
router.get('/settings', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const user = await User.findOne({ where: { userId } });

    res.json({
      code: 200,
      data: {
        notificationEnabled: true,
        notificationTime: '09:00',
        theme: 'light',
        language: 'zh-CN',
        autoSync: true,
        privacyMode: false,
      },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('获取用户设置失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 更新用户设置
router.post('/settings', authMiddleware, async (req, res) => {
  try {
    const { userId, settings } = req.body;

    if (!userId || !settings) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 这里可以将设置保存到数据库或配置文件
    // 目前暂时返回成功

    res.json({
      code: 200,
      data: settings,
      msg: '设置更新成功',
    });
  } catch (error) {
    console.error('更新用户设置失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

module.exports = router;