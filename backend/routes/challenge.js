const express = require('express');
const router = express.Router();
const { Challenge, ChallengeRecord, User, Task } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');
const { v4: uuidv4 } = require('uuid');

// 创建挑战
router.post('/create', authMiddleware, async (req, res) => {
  try {
    const { taskId, challengeName } = req.body;
    const userId = req.userId;

    if (!taskId || !challengeName) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 检查任务是否存在
    const task = await Task.findByPk(taskId);
    if (!task) {
      return res.json({ code: 400, data: {}, msg: '任务不存在' });
    }

    // 生成挑战ID
    const challengeId = 'CH' + moment().format('YYYYMMDDHHmmss') + Math.floor(Math.random() * 1000000).toString().padStart(6, '0');
    const now = moment().format('YYYY-MM-DD HH:mm:ss');

    // 创建挑战
    const challenge = await Challenge.create({
      challengeId,
      publisherId: userId,
      opponentId: null,
      taskId: parseInt(taskId),
      challengeName,
      status: 0, // 0=待匹配
      createTime: now,
      matchTime: null,
      settleTime: null,
      winnerId: null,
    });

    res.json({
      code: 200,
      data: {
        challengeId,
        taskId,
        challengeName,
        createTime: now,
        remainMatchTime: 10,
      },
      msg: '操作成功',
    });
  } catch (error) {
    console.error('创建挑战失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 自动匹配对手
router.get('/match/:challengeId', authMiddleware, async (req, res) => {
  try {
    const { challengeId } = req.params;
    const userId = req.userId;

    // 获取挑战信息
    const challenge = await Challenge.findOne({ where: { challengeId } });
    if (!challenge) {
      return res.json({ code: 400, data: {}, msg: '挑战不存在' });
    }

    // 检查挑战状态
    if (challenge.status !== 0) {
      return res.json({ code: 400, data: {}, msg: '挑战状态错误' });
    }

    // 获取所有用户
    const users = await User.findAll();
    // 过滤掉自己
    const otherUsers = users.filter(user => user.userId !== userId);

    if (otherUsers.length === 0) {
      return res.json({ code: 400, data: {}, msg: '暂无匹配对手' });
    }

    // 随机选择一个对手
    const opponent = otherUsers[Math.floor(Math.random() * otherUsers.length)];

    // 更新挑战信息
    await challenge.update({
      opponentId: opponent.userId,
      status: 1, // 1=进行中
      matchTime: moment().format('YYYY-MM-DD HH:mm:ss'),
    });

    res.json({
      code: 200,
      data: {
        opponentId: opponent.userId.toString(),
        opponentNickname: opponent.nickname,
        opponentLevel: opponent.challenge_score,
        opponentAblity: 0.5, // 简化处理，实际应从能力评估模型获取
      },
      msg: '操作成功',
    });
  } catch (error) {
    console.error('匹配对手失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 同步挑战任务完成数据
router.post('/sync', authMiddleware, async (req, res) => {
  try {
    const { challengeId, finishStatus, finishTime, taskScore } = req.body;
    const userId = req.userId;

    if (!challengeId || finishStatus === undefined) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取挑战信息
    const challenge = await Challenge.findOne({ where: { challengeId } });
    if (!challenge) {
      return res.json({ code: 400, data: {}, msg: '挑战不存在' });
    }

    // 检查挑战状态
    if (challenge.status !== 1) {
      return res.json({ code: 400, data: {}, msg: '挑战不在进行中' });
    }

    // 创建挑战记录
    await ChallengeRecord.create({
      challengeId,
      userId,
      finishStatus,
      finishTime,
      taskScore,
      comprehensiveScore: null,
      petExpReward: null,
      challengeScoreChange: null,
      syncTime: moment().format('YYYY-MM-DD HH:mm:ss'),
    });

    // 检查对手是否已提交
    const opponentId = challenge.opponentId;
    const opponentRecord = await ChallengeRecord.findOne({
      where: { challengeId, userId: opponentId },
    });

    res.json({
      code: 200,
      data: {
        syncStatus: 'success',
        opponentFinishStatus: opponentRecord ? opponentRecord.finishStatus : 0,
      },
      msg: '操作成功',
    });
  } catch (error) {
    console.error('同步挑战数据失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 挑战结算
router.get('/settle/:challengeId', authMiddleware, async (req, res) => {
  try {
    const { challengeId } = req.params;
    const userId = req.userId;

    // 获取挑战信息
    const challenge = await Challenge.findOne({ where: { challengeId } });
    if (!challenge) {
      return res.json({ code: 400, data: {}, msg: '挑战不存在' });
    }

    // 获取双方的挑战记录
    const records = await ChallengeRecord.findAll({ where: { challengeId } });
    if (records.length !== 2) {
      return res.json({ code: 400, data: {}, msg: '挑战记录不完整' });
    }

    const publisherId = challenge.publisherId;
    const opponentId = challenge.opponentId;

    const publisherRecord = records.find(r => r.userId === publisherId);
    const opponentRecord = records.find(r => r.userId === opponentId);

    // 计算综合分
    let publisherScore = 0;
    let opponentScore = 0;

    if (publisherRecord.finishStatus === 1) {
      publisherScore = publisherRecord.taskScore * 0.7 + (30 - publisherRecord.finishTime) * 0.3;
    }

    if (opponentRecord.finishStatus === 1) {
      opponentScore = opponentRecord.taskScore * 0.7 + (30 - opponentRecord.finishTime) * 0.3;
    }

    // 判定胜负
    let settleResult;
    let winnerId;
    let loserId;

    if (publisherRecord.finishStatus === 1 && opponentRecord.finishStatus === 1) {
      if (publisherScore > opponentScore) {
        settleResult = '胜';
        winnerId = publisherId;
        loserId = opponentId;
      } else if (opponentScore > publisherScore) {
        settleResult = '负';
        winnerId = opponentId;
        loserId = publisherId;
      } else {
        settleResult = '平';
        winnerId = null;
      }
    } else if (publisherRecord.finishStatus === 1) {
      settleResult = '胜';
      winnerId = publisherId;
      loserId = opponentId;
    } else if (opponentRecord.finishStatus === 1) {
      settleResult = '负';
      winnerId = opponentId;
      loserId = publisherId;
    } else {
      settleResult = '平';
      winnerId = null;
    }

    // 更新用户数据
    let petExpReward = 0;
    let challengeScoreChange = 0;

    if (winnerId && loserId) {
      const winner = await User.findByPk(winnerId);
      const loser = await User.findByPk(loserId);

      if (winner && loser) {
        // 更新胜者
        await winner.update({
          challenge_win: winner.challenge_win + 1,
          challenge_score: winner.challenge_score + 10,
        });

        // 更新败者
        await loser.update({
          challenge_lose: loser.challenge_lose + 1,
          challenge_score: Math.max(0, loser.challenge_score - 5),
        });

        // 更新挑战记录
        await publisherRecord.update({
          comprehensiveScore: publisherScore,
          petExpReward: publisherId === winnerId ? 20 : 0,
          challengeScoreChange: publisherId === winnerId ? 10 : -5,
        });

        await opponentRecord.update({
          comprehensiveScore: opponentScore,
          petExpReward: opponentId === winnerId ? 20 : 0,
          challengeScoreChange: opponentId === winnerId ? 10 : -5,
        });

        // 设置当前用户的奖励
        if (userId === winnerId) {
          petExpReward = 20;
          challengeScoreChange = 10;
        } else if (userId === loserId) {
          petExpReward = 0;
          challengeScoreChange = -5;
        }
      }
    }

    // 更新挑战状态
    await challenge.update({
      status: 2, // 2=已完成
      settleTime: moment().format('YYYY-MM-DD HH:mm:ss'),
      winnerId,
    });

    res.json({
      code: 200,
      data: {
        settleResult,
        selfScore: userId === publisherId ? publisherScore : opponentScore,
        opponentScore: userId === publisherId ? opponentScore : publisherScore,
        petExpReward,
        challengeScoreChange,
      },
      msg: '操作成功',
    });
  } catch (error) {
    console.error('挑战结算失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 查询挑战记录
router.get('/record/:page/:size', authMiddleware, async (req, res) => {
  try {
    const { page = 1, size = 10 } = req.params;
    const userId = req.userId;

    // 获取用户的挑战记录
    const challenges = await Challenge.findAll({
      where: {
        [Challenge.sequelize.Op.or]: [
          { publisherId: userId },
          { opponentId: userId },
        ],
      },
      order: [['createTime', 'DESC']],
    });

    // 分页
    const start = (page - 1) * size;
    const end = start + size;
    const paginatedChallenges = challenges.slice(start, end);

    // 构建响应数据
    const list = await Promise.all(paginatedChallenges.map(async (challenge) => {
      const opponentId = challenge.publisherId === userId ? challenge.opponentId : challenge.publisherId;
      const opponent = await User.findOne({ where: { userId: opponentId } });
      
      return {
        challengeId: challenge.challengeId,
        taskName: challenge.challengeName,
        opponentNickname: opponent ? opponent.nickname : '未知',
        settleResult: challenge.winnerId === null ? '平' :
                     challenge.winnerId === userId ? '胜' : '负',
        createTime: challenge.createTime,
        settleTime: challenge.settleTime,
      };
    }));

    res.json({
      code: 200,
      data: {
        total: challenges.length,
        pages: Math.ceil(challenges.length / size),
        list,
      },
      msg: '操作成功',
    });
  } catch (error) {
    console.error('查询挑战记录失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 挑战大厅列表
router.get('/hall/:page/:size', authMiddleware, async (req, res) => {
  try {
    const { page = 1, size = 10 } = req.params;
    const userId = req.userId;

    // 获取待匹配的挑战
    const challenges = await Challenge.findAll({
      where: {
        status: 0,
        publisherId: { [Challenge.sequelize.Op.ne]: userId },
      },
      order: [['createTime', 'DESC']],
    });

    // 分页
    const start = (page - 1) * size;
    const end = start + size;
    const paginatedChallenges = challenges.slice(start, end);

    // 构建响应数据
    const list = await Promise.all(paginatedChallenges.map(async (challenge) => {
      const publisher = await User.findOne({ where: { userId: challenge.publisherId } });
      return {
        challengeId: challenge.challengeId,
        challengeName: challenge.challengeName,
        taskName: challenge.challengeName,
        publisherNickname: publisher ? publisher.nickname : '未知',
        publisherLevel: publisher ? publisher.challenge_score : 100,
      };
    }));

    res.json({
      code: 200,
      data: {
        total: challenges.length,
        pages: Math.ceil(challenges.length / size),
        list,
      },
      msg: '操作成功',
    });
  } catch (error) {
    console.error('查询挑战大厅失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

module.exports = router;
