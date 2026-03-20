const express = require('express');
const router = express.Router();
const { NPC, User, Pet, NPCChallenge } = require('../models');
const authMiddleware = require('../middleware/auth');

// 获取NPC列表
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { level, difficulty } = req.query;

    let whereCondition = { isAvailable: 1 };
    if (level !== undefined) {
      whereCondition.level = parseInt(level);
    }
    if (difficulty !== undefined) {
      whereCondition.difficulty = parseInt(difficulty);
    }

    const npcs = await NPC.findAll({
      where: whereCondition,
      order: [['level', 'ASC']],
    });

    res.json({
      code: 200,
      data: {
        npcList: npcs.map(npc => ({
          id: npc.id,
          name: npc.name,
          avatar: npc.avatar,
          level: npc.level,
          difficulty: npc.difficulty,
          petType: npc.petType,
          petForm: npc.petForm,
          petLevel: npc.petLevel,
          challengeCount: npc.challengeCount,
          winCount: npc.winCount,
          rewardExp: npc.rewardExp,
          rewardPoints: npc.rewardPoints,
          description: npc.description,
        })),
        total: npcs.length,
      },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('获取NPC列表失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 创建NPC挑战
router.post('/challenge', authMiddleware, async (req, res) => {
  try {
    const { userId, npcId } = req.body;

    if (!userId || !npcId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const npc = await NPC.findOne({ where: { id: npcId } });
    if (!npc) {
      return res.json({ code: 400, data: {}, msg: 'NPC不存在' });
    }

    const user = await User.findOne({ where: { userId } });
    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    const pet = await Pet.findOne({ where: { userId } });
    if (!pet) {
      return res.json({ code: 400, data: {}, msg: '宠物不存在' });
    }

    // 创建挑战记录
    const challenge = await NPCChallenge.create({
      publisherId: userId,
      opponentId: npcId,
      challengeType: 'NPC',
      status: 'ongoing',
      startTime: new Date(),
      endTime: null,
      winnerId: null,
      publisherScore: 0,
      opponentScore: 0,
    });

    // 更新NPC挑战次数
    await NPC.update(
      { challengeCount: npc.challengeCount + 1 },
      { where: { id: npcId } }
    );

    res.json({
      code: 200,
      data: {
        challengeId: challenge.id,
        npc: {
          id: npc.id,
          name: npc.name,
          avatar: npc.avatar,
          level: npc.level,
          difficulty: npc.difficulty,
          petType: npc.petType,
          petForm: npc.petForm,
          petLevel: npc.petLevel,
          rewardExp: npc.rewardExp,
          rewardPoints: npc.rewardPoints,
        },
        user: {
          userId: user.userId,
          nickname: user.nickname,
          avatar: user.avatar,
          challengeScore: user.challengeScore,
        },
        pet: {
          name: pet.name,
          type: pet.type,
          form: pet.form,
          level: pet.level,
        },
      },
      msg: '挑战创建成功',
    });
  } catch (error) {
    console.error('创建NPC挑战失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 完成NPC挑战
router.post('/complete', authMiddleware, async (req, res) => {
  try {
    const { userId, challengeId, isWin, userScore, npcScore } = req.body;

    if (!userId || !challengeId || isWin === undefined) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const challenge = await NPCChallenge.findOne({ where: { id: challengeId } });
    if (!challenge) {
      return res.json({ code: 400, data: {}, msg: '挑战不存在' });
    }

    if (challenge.publisherId !== userId) {
      return res.json({ code: 400, data: {}, msg: '无权操作此挑战' });
    }

    const npc = await NPC.findOne({ where: { id: challenge.opponentId } });
    if (!npc) {
      return res.json({ code: 400, data: {}, msg: 'NPC不存在' });
    }

    const user = await User.findOne({ where: { userId } });
    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    const pet = await Pet.findOne({ where: { userId } });
    if (!pet) {
      return res.json({ code: 400, data: {}, msg: '宠物不存在' });
    }

    // 更新挑战状态
    await NPCChallenge.update(
      {
        status: 'completed',
        endTime: new Date(),
        winnerId: isWin ? userId : challenge.opponentId,
        publisherScore: userScore || 0,
        opponentScore: npcScore || 0,
      },
      { where: { id: challengeId } }
    );

    let rewardExp = 0;
    let rewardPoints = 0;

    if (isWin) {
      rewardExp = npc.rewardExp;
      rewardPoints = npc.rewardPoints;

      // 更新用户挑战数据
      await User.update(
        {
          challenge_win: user.challenge_win + 1,
          challenge_score: user.challenge_score + rewardPoints,
        },
        { where: { userId } }
      );

      // 更新宠物经验
      const newExp = pet.exp + rewardExp;
      const isUpgrade = newExp >= pet.expThreshold;

      const updateData = { exp: newExp };
      if (isUpgrade) {
        updateData.level = pet.level + 1;
        updateData.expThreshold = pet.expThreshold * 2;
      }

      await Pet.update(updateData, { where: { userId } });

      // 更新NPC胜利次数
      await NPC.update(
        { winCount: npc.winCount + 1 },
        { where: { id: npc.id } }
      );
    } else {
      // 更新用户失败次数
      await User.update(
        {
          challenge_lose: user.challenge_lose + 1,
          challenge_score: user.challenge_score - 2,
        },
        { where: { userId } }
      );
    }

    res.json({
      code: 200,
      data: {
        isWin,
        rewardExp,
        rewardPoints,
        userScore: userScore || 0,
        npcScore: npcScore || 0,
        newPetLevel: isWin ? (pet.level + (pet.exp + rewardExp >= pet.expThreshold ? 1 : 0)) : pet.level,
        newChallengeScore: isWin ? user.challengeScore + rewardPoints : user.challengeScore - 2,
      },
      msg: isWin ? '挑战胜利！' : '挑战失败',
    });
  } catch (error) {
    console.error('完成NPC挑战失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 初始化NPC数据
router.post('/init', authMiddleware, async (req, res) => {
  try {
    const existingNPCs = await NPC.findAll();
    if (existingNPCs.length > 0) {
      return res.json({
        code: 200,
        data: { count: existingNPCs.length },
        msg: 'NPC数据已存在',
      });
    }

    const npcData = [
      {
        name: '小明',
        avatar: '👦',
        level: 1,
        difficulty: 1,
        petType: 'cat',
        petForm: 'baby',
        petLevel: 1,
        rewardExp: 10,
        rewardPoints: 5,
        description: '一个热爱学习的初中生，擅长数学和英语。',
      },
      {
        name: '小红',
        avatar: '👧',
        level: 2,
        difficulty: 1,
        petType: 'dog',
        petForm: 'baby',
        petLevel: 2,
        rewardExp: 15,
        rewardPoints: 8,
        description: '一个勤奋努力的高中生，物理和化学成绩优异。',
      },
      {
        name: '学霸张',
        avatar: '🧑‍🎓',
        level: 3,
        difficulty: 2,
        petType: 'cat',
        petForm: 'adolescent',
        petLevel: 3,
        rewardExp: 20,
        rewardPoints: 12,
        description: '年级第一的学霸，所有科目都很强。',
      },
      {
        name: '科学怪人',
        avatar: '🧑‍🔬',
        level: 4,
        difficulty: 2,
        petType: 'dog',
        petForm: 'adolescent',
        petLevel: 4,
        rewardExp: 25,
        rewardPoints: 15,
        description: '痴迷于科学研究的怪人，生物和物理是他的强项。',
      },
      {
        name: '历史博士',
        avatar: '👨‍🏫',
        level: 5,
        difficulty: 2,
        petType: 'cat',
        petForm: 'adult',
        petLevel: 5,
        rewardExp: 30,
        rewardPoints: 18,
        description: '世界历史专家，对历史事件了如指掌。',
      },
      {
        name: '数学天才',
        avatar: '👨‍💻',
        level: 6,
        difficulty: 3,
        petType: 'dog',
        petForm: 'adult',
        petLevel: 6,
        rewardExp: 40,
        rewardPoints: 25,
        description: '数学竞赛冠军，解题速度极快。',
      },
      {
        name: '全能学霸',
        avatar: '🏆',
        level: 7,
        difficulty: 3,
        petType: 'cat',
        petForm: 'advanced',
        petLevel: 7,
        rewardExp: 50,
        rewardPoints: 30,
        description: '全科满分的天才，无人能敌。',
      },
      {
        name: '终极挑战者',
        avatar: '👑',
        level: 8,
        difficulty: 3,
        petType: 'dog',
        petForm: 'advanced',
        petLevel: 8,
        rewardExp: 60,
        rewardPoints: 35,
        description: '传说中的学霸，挑战他的勇气可嘉。',
      },
    ];

    await NPC.bulkCreate(npcData);

    res.json({
      code: 200,
      data: { count: npcData.length },
      msg: 'NPC数据初始化成功',
    });
  } catch (error) {
    console.error('初始化NPC数据失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

module.exports = router;