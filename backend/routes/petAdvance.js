const express = require('express');
const router = express.Router();
const { User, Pet, PetAdvance, PetAlbum, EvaluationLevel, EvaluationCalc, Incentive } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');

// 模块八：宠物养成进阶与图鉴模块

// 宠物进阶查询接口
router.get('/advance', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const advanceData = await PetAdvance.findOne({
      where: { userId, petId },
    });

    if (!advanceData) {
      // 创建默认进阶数据
      const newAdvanceData = await PetAdvance.create({
        userId,
        petId,
        currentStage: '幼年期',
        stageExp: 0,
        stageExpMax: 100,
        skillPoint: 0,
        skillList: JSON.stringify([]),
        stageRecord: JSON.stringify([]),
        evolveCondition: JSON.stringify({
          exp: 100,
          intimacy: 50,
          taskCount: 10,
        }),
      });

      // 获取宠物基础数据
      const petData = await Pet.findOne({
        where: { userId, petId },
      });

      return res.json({
        code: 200,
        data: {
          pet: {
            id: petData?.id || petId,
            name: petData?.petName || '我的宠物',
            type: petData?.petType || 'chick',
            form: petData?.form || '幼年期',
            level: petData?.level || 1,
            exp: petData?.exp || 0,
            expThreshold: petData?.expThreshold || 100,
            nutrition: petData?.nutrition || 0,
            happiness: petData?.happiness || 0,
            intimacy: petData?.intimacy || 0,
          },
          advance: {
            currentStage: newAdvanceData.currentStage,
            stageExp: newAdvanceData.stageExp,
            stageExpMax: newAdvanceData.stageExpMax,
            stageProgress: 0,
            skillPoint: newAdvanceData.skillPoint,
            skillList: [],
            stageRecord: [],
            evolveCondition: JSON.parse(newAdvanceData.evolveCondition),
            canEvolve: false,
            nextStage: '成长期',
            stageBenefits: _getStageBenefits(newAdvanceData.currentStage),
          }
        },
        msg: '宠物进阶查询成功',
      });
    }

    const stageRecord = JSON.parse(advanceData.stageRecord || '[]');
    const skillList = JSON.parse(advanceData.skillList || '[]');
    const evolveCondition = JSON.parse(advanceData.evolveCondition || '{}');

    // 计算进化条件是否满足
    const petData = await Pet.findOne({
      where: { userId, petId },
    });

    const calcData = await EvaluationCalc.findOne({
      where: { userId, petId },
    });

    const canEvolve =
      advanceData.stageExp >= evolveCondition.exp &&
      (petData?.intimacy || 0) >= evolveCondition.intimacy &&
      (calcData?.taskCompletionCount || 0) >= evolveCondition.taskCount;

    const stageProgress = Math.round((advanceData.stageExp / advanceData.stageExpMax) * 100);
    const nextStage = _getNextStage(advanceData.currentStage);

    res.json({
      code: 200,
      data: {
        pet: {
          id: petData?.id || petId,
          name: petData?.petName || '我的宠物',
          type: petData?.petType || 'chick',
          form: petData?.form || '幼年期',
          level: petData?.level || 1,
          exp: petData?.exp || 0,
          expThreshold: petData?.expThreshold || 100,
          nutrition: petData?.nutrition || 0,
          happiness: petData?.happiness || 0,
          intimacy: petData?.intimacy || 0,
        },
        advance: {
          currentStage: advanceData.currentStage,
          stageExp: advanceData.stageExp,
          stageExpMax: advanceData.stageExpMax,
          stageProgress,
          skillPoint: advanceData.skillPoint,
          skillList,
          stageRecord,
          evolveCondition,
          canEvolve,
          nextStage,
          stageBenefits: _getStageBenefits(advanceData.currentStage),
        }
      },
      msg: '宠物进阶查询成功',
    });
  } catch (error) {
    console.error('宠物进阶查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 宠物进化接口
router.post('/evolve', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.body;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const advanceData = await PetAdvance.findOne({
      where: { userId, petId },
    });

    if (!advanceData) {
      return res.json({ code: 400, data: {}, msg: '进阶数据不存在' });
    }

    const evolveCondition = JSON.parse(advanceData.evolveCondition || '{}');

    // 检查进化条件
    const petData = await Pet.findOne({
      where: { userId, petId },
    });

    const calcData = await EvaluationCalc.findOne({
      where: { userId, petId },
    });

    if (advanceData.stageExp < evolveCondition.exp) {
      return res.json({ code: 400, data: {}, msg: '阶段经验不足，无法进化' });
    }

    if ((petData?.intimacy || 0) < evolveCondition.intimacy) {
      return res.json({ code: 400, data: {}, msg: '亲密度不足，无法进化' });
    }

    if ((calcData?.taskCompletionCount || 0) < evolveCondition.taskCount) {
      return res.json({ code: 400, data: {}, msg: '任务完成数不足，无法进化' });
    }

    // 执行进化
    const oldStage = advanceData.currentStage;
    const newStage = _getNextStage(oldStage);

    if (!newStage) {
      return res.json({ code: 400, data: {}, msg: '已达到最高阶段，无法继续进化' });
    }

    // 更新阶段记录
    const stageRecord = JSON.parse(advanceData.stageRecord || '[]');
    stageRecord.push({
      date: new Date().toISOString(),
      oldStage,
      newStage,
    });

    // 更新进阶数据
    await PetAdvance.update(
      {
        currentStage: newStage,
        stageExp: 0,
        stageExpMax: _getStageExpMax(newStage),
        stageRecord: JSON.stringify(stageRecord),
        evolveTime: new Date(),
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    // 更新宠物等级
    await Pet.update(
      { level: (petData?.level || 1) + 1 },
      { where: { userId, petId } }
    );

    // 发放进化奖励
    const integralReward = 100;
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (incentiveData) {
      await Incentive.update(
        {
          integral: (incentiveData.integral || 0) + integralReward,
          integralGet: (incentiveData.integralGet || 0) + integralReward,
          updateTime: new Date(),
        },
        { where: { userId, petId } }
      );
    }

    res.json({
      code: 200,
      data: {
        oldStage,
        newStage,
        integralReward,
        stageBenefits: _getStageBenefits(newStage),
        message: `恭喜！宠物已进化至${newStage}，获得${integralReward}积分`,
      },
      msg: '宠物进化成功',
    });
  } catch (error) {
    console.error('宠物进化失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 技能学习接口
router.post('/learnSkill', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, skillId } = req.body;

    if (!userId || !petId || !skillId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const advanceData = await PetAdvance.findOne({
      where: { userId, petId },
    });

    if (!advanceData) {
      return res.json({ code: 400, data: {}, msg: '进阶数据不存在' });
    }

    // 检查技能点是否足够
    if (advanceData.skillPoint < 1) {
      return res.json({ code: 400, data: {}, msg: '技能点不足，无法学习技能' });
    }

    // 检查技能是否已学习
    const skillList = JSON.parse(advanceData.skillList || '[]');
    if (skillList.find(skill => skill.id === skillId)) {
      return res.json({ code: 400, data: {}, msg: '该技能已学习' });
    }

    // 获取技能信息
    const skillInfo = _getSkillInfo(skillId);
    if (!skillInfo) {
      return res.json({ code: 400, data: {}, msg: '技能不存在' });
    }

    // 检查技能解锁条件
    if (skillInfo.unlockLevel && advanceData.currentStage !== skillInfo.unlockLevel) {
      return res.json({ code: 400, data: {}, msg: `该技能需要${skillInfo.unlockLevel}才能学习` });
    }

    // 学习技能
    skillList.push({
      id: skillId,
      name: skillInfo.name,
      level: 1,
      unlockTime: new Date().toISOString(),
    });

    await PetAdvance.update(
      {
        skillList: JSON.stringify(skillList),
        skillPoint: advanceData.skillPoint - 1,
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    res.json({
      code: 200,
      data: {
        skillInfo,
        remainingSkillPoint: advanceData.skillPoint - 1,
        message: `成功学习技能【${skillInfo.name}】`,
      },
      msg: '技能学习成功',
    });
  } catch (error) {
    console.error('技能学习失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 图鉴查询接口
router.get('/album', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const albumData = await PetAlbum.findOne({
      where: { userId, petId },
    });

    if (!albumData) {
      // 创建默认图鉴数据
      const newAlbumData = await PetAlbum.create({
        userId,
        petId,
        albumName: '默认图鉴',
        petList: JSON.stringify([]),
        collectCount: 0,
        totalCount: 10,
        unlockProgress: JSON.stringify([]),
        rareUnlock: JSON.stringify([]),
      });

      return res.json({
        code: 200,
        data: {
          albumName: newAlbumData.albumName,
          petList: [],
          collectCount: 0,
          totalCount: 10,
          collectProgress: 0,
          unlockProgress: [],
          rareUnlock: [],
          albumShare: [],
          canShare: false,
        },
        msg: '图鉴查询成功',
      });
    }

    const petList = JSON.parse(albumData.petList || '[]');
    const unlockProgress = JSON.parse(albumData.unlockProgress || '[]');
    const rareUnlock = JSON.parse(albumData.rareUnlock || '[]');
    const albumShare = JSON.parse(albumData.albumShare || '[]');

    const collectProgress = Math.round((albumData.collectCount / albumData.totalCount) * 100);
    const canShare = albumData.collectCount >= albumData.totalCount;

    res.json({
      code: 200,
      data: {
        albumName: albumData.albumName,
        petList,
        collectCount: albumData.collectCount,
        totalCount: albumData.totalCount,
        collectProgress,
        unlockProgress,
        rareUnlock,
        albumShare,
        canShare,
      },
      msg: '图鉴查询成功',
    });
  } catch (error) {
    console.error('图鉴查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 稀有宠物解锁接口
router.post('/unlockAlbum', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, petIdToUnlock } = req.body;

    if (!userId || !petId || !petIdToUnlock) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const albumData = await PetAlbum.findOne({
      where: { userId, petId },
    });

    if (!albumData) {
      return res.json({ code: 400, data: {}, msg: '图鉴数据不存在' });
    }

    // 检查宠物是否已解锁
    const petList = JSON.parse(albumData.petList || '[]');
    if (petList.find(pet => pet.id === petIdToUnlock)) {
      return res.json({ code: 400, data: {}, msg: '该宠物已解锁' });
    }

    // 获取宠物信息
    const petInfo = _getPetInfo(petIdToUnlock);
    if (!petInfo) {
      return res.json({ code: 400, data: {}, msg: '宠物不存在' });
    }

    // 检查解锁条件
    if (petInfo.unlockCondition) {
      const condition = petInfo.unlockCondition;
      const petData = await Pet.findOne({
        where: { userId, petId },
      });

      const calcData = await EvaluationCalc.findOne({
        where: { userId, petId },
      });

      if (condition.level && (petData?.level || 0) < condition.level) {
        return res.json({ code: 400, data: {}, msg: `需要宠物等级达到${condition.level}才能解锁` });
      }

      if (condition.intimacy && (petData?.intimacy || 0) < condition.intimacy) {
        return res.json({ code: 400, data: {}, msg: `需要亲密度达到${condition.intimacy}才能解锁` });
      }

      if (condition.taskCount && (calcData?.taskCompletionCount || 0) < condition.taskCount) {
        return res.json({ code: 400, data: {}, msg: `需要完成${condition.taskCount}个任务才能解锁` });
      }
    }

    // 解锁宠物
    petList.push({
      id: petIdToUnlock,
      name: petInfo.name,
      type: petInfo.type,
      rarity: petInfo.rarity,
      unlockTime: new Date().toISOString(),
    });

    const rareUnlock = JSON.parse(albumData.rareUnlock || '[]');
    if (petInfo.rarity === 'rare' && !rareUnlock.includes(petIdToUnlock)) {
      rareUnlock.push(petIdToUnlock);
    }

    await PetAlbum.update(
      {
        petList: JSON.stringify(petList),
        collectCount: petList.length,
        rareUnlock: JSON.stringify(rareUnlock),
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    // 发放解锁奖励
    const integralReward = petInfo.rarity === 'rare' ? 200 : 50;
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (incentiveData) {
      await Incentive.update(
        {
          integral: (incentiveData.integral || 0) + integralReward,
          integralGet: (incentiveData.integralGet || 0) + integralReward,
          updateTime: new Date(),
        },
        { where: { userId, petId } }
      );
    }

    res.json({
      code: 200,
      data: {
        petInfo,
        integralReward,
        collectCount: petList.length,
        message: `成功解锁宠物【${petInfo.name}】，获得${integralReward}积分`,
      },
      msg: '宠物解锁成功',
    });
  } catch (error) {
    console.error('宠物解锁失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 图鉴分享接口
router.post('/album/share', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.body;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const albumData = await PetAlbum.findOne({
      where: { userId, petId },
    });

    if (!albumData) {
      return res.json({ code: 400, data: {}, msg: '图鉴数据不存在' });
    }

    if (albumData.collectCount < albumData.totalCount) {
      return res.json({ code: 400, data: {}, msg: '图鉴未完成，无法分享' });
    }

    // 生成分享记录
    const albumShare = JSON.parse(albumData.albumShare || '[]');
    const newShare = {
      id: Date.now(),
      shareTime: new Date().toISOString(),
      collectCount: albumData.collectCount,
      rareCount: JSON.parse(albumData.rareUnlock || '[]').length,
    };

    albumShare.push(newShare);

    await PetAlbum.update(
      { albumShare: JSON.stringify(albumShare) },
      { where: { userId, petId } }
    );

    // 发放分享奖励
    const integralReward = 50;
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (incentiveData) {
      await Incentive.update(
        {
          integral: (incentiveData.integral || 0) + integralReward,
          integralGet: (incentiveData.integralGet || 0) + integralReward,
          updateTime: new Date(),
        },
        { where: { userId, petId } }
      );
    }

    res.json({
      code: 200,
      data: {
        shareCard: {
          id: newShare.id,
          shareTime: newShare.shareTime,
          collectCount: albumData.collectCount,
          rareCount: newShare.rareCount,
        },
        shareLink: `https://app.example.com/album/share/${newShare.id}`,
        integralReward,
        message: `图鉴分享成功，获得${integralReward}积分`,
      },
      msg: '图鉴分享成功',
    });
  } catch (error) {
    console.error('图鉴分享失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 进阶与激励联动接口
router.post('/link/incentive', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, advanceType, advanceData } = req.body;

    if (!userId || !petId || !advanceType || !advanceData) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    let integralReward = 0;
    let chestUnlock = null;

    // 根据进阶类型计算奖励
    if (advanceType === 'evolve') {
      const stage = advanceData.stage || '';
      if (stage === '成长期') {
        integralReward = 100;
        chestUnlock = 'basic';
      } else if (stage === '成熟期') {
        integralReward = 200;
        chestUnlock = 'elite';
      } else if (stage === '完全体') {
        integralReward = 500;
        chestUnlock = 'exclusive';
      }
    } else if (advanceType === 'skill') {
      integralReward = 50;
    } else if (advanceType === 'album') {
      const collectCount = advanceData.collectCount || 0;
      if (collectCount >= 10) {
        integralReward = 300;
        chestUnlock = 'elite';
      }
    }

    // 更新激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (incentiveData) {
      const updateData = {
        integral: (incentiveData.integral || 0) + integralReward,
        integralGet: (incentiveData.integralGet || 0) + integralReward,
        updateTime: new Date(),
      };

      if (chestUnlock) {
        const currentChestUnlock = JSON.parse(incentiveData.chestUnlock || '[]');
        if (!currentChestUnlock.includes(chestUnlock)) {
          currentChestUnlock.push(chestUnlock);
          updateData.chestUnlock = JSON.stringify(currentChestUnlock);
        }
      }

      await Incentive.update(updateData, { where: { userId, petId } });
    }

    res.json({
      code: 200,
      data: {
        integralReward,
        chestUnlock,
        message: '进阶激励联动成功',
      },
      msg: '进阶激励联动成功',
    });
  } catch (error) {
    console.error('进阶激励联动失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 辅助函数：获取下一阶段
function _getNextStage(currentStage) {
  const stageMap = {
    '幼年期': '成长期',
    '成长期': '成熟期',
    '成熟期': '完全体',
    '完全体': null,
  };
  return stageMap[currentStage];
}

// 辅助函数：获取阶段经验上限
function _getStageExpMax(stage) {
  const expMap = {
    '幼年期': 100,
    '成长期': 200,
    '成熟期': 500,
    '完全体': 1000,
  };
  return expMap[stage] || 100;
}

// 辅助函数：获取阶段收益
function _getStageBenefits(stage) {
  const benefitsMap = {
    '幼年期': { integralBonus: 1.0, expBonus: 1.0 },
    '成长期': { integralBonus: 1.2, expBonus: 1.1 },
    '成熟期': { integralBonus: 1.5, expBonus: 1.2 },
    '完全体': { integralBonus: 2.0, expBonus: 1.5 },
  };
  return benefitsMap[stage] || { integralBonus: 1.0, expBonus: 1.0 };
}

// 辅助函数：获取技能信息
function _getSkillInfo(skillId) {
  const skillMap = {
    1: { id: 1, name: '快速成长', unlockLevel: '幼年期', effect: '宠物经验获取+10%' },
    2: { id: 2, name: '亲密度提升', unlockLevel: '幼年期', effect: '亲密度获取+20%' },
    3: { id: 3, name: '任务加速', unlockLevel: '成长期', effect: '任务完成时间-10%' },
    4: { id: 4, name: '积分加成', unlockLevel: '成长期', effect: '积分获取+15%' },
    5: { id: 5, name: '稀有发现', unlockLevel: '成熟期', effect: '稀有宠物解锁概率+5%' },
    6: { id: 6, name: '双倍经验', unlockLevel: '成熟期', effect: '每日首次任务双倍经验' },
    7: { id: 7, name: '全能进化', unlockLevel: '完全体', effect: '进化条件降低20%' },
    8: { id: 8, name: '图鉴大师', unlockLevel: '完全体', effect: '图鉴解锁奖励+50%' },
  };
  return skillMap[skillId];
}

// 辅助函数：获取宠物信息
function _getPetInfo(petId) {
  const petMap = {
    1: { id: 1, name: '小火龙', type: '火', rarity: 'common', unlockCondition: null },
    2: { id: 2, name: '杰尼龟', type: '水', rarity: 'common', unlockCondition: null },
    3: { id: 3, name: '妙蛙种子', type: '草', rarity: 'common', unlockCondition: null },
    4: { id: 4, name: '皮卡丘', type: '电', rarity: 'rare', unlockCondition: { level: 5, intimacy: 50 } },
    5: { id: 5, name: '伊布', type: '普通', rarity: 'rare', unlockCondition: { level: 10, taskCount: 20 } },
    6: { id: 6, name: '超梦', type: '超能', rarity: 'legendary', unlockCondition: { level: 20, intimacy: 100, taskCount: 50 } },
    7: { id: 7, name: '梦幻', type: '超能', rarity: 'legendary', unlockCondition: { level: 30, intimacy: 200, taskCount: 100 } },
    8: { id: 8, name: '裂空座', type: '龙', rarity: 'legendary', unlockCondition: { level: 40, intimacy: 300, taskCount: 150 } },
  };
  return petMap[petId];
}

// 获取技能列表接口
router.get('/skills', authMiddleware, async (req, res) => {
  try {
    const skills = [
      { id: 1, name: '快速成长', description: '经验值获取速度+10%', unlockLevel: '幼年期' },
      { id: 2, name: '亲密度提升', description: '亲密度获取+20%', unlockLevel: '幼年期' },
      { id: 3, name: '任务加速', description: '任务完成时间-10%', unlockLevel: '成长期' },
      { id: 4, name: '积分加成', description: '积分获取+15%', unlockLevel: '成长期' },
      { id: 5, name: '稀有发现', description: '稀有宠物解锁概率+5%', unlockLevel: '成熟期' },
      { id: 6, name: '双倍经验', description: '每日首次任务双倍经验', unlockLevel: '成熟期' },
      { id: 7, name: '全能进化', description: '进化条件降低20%', unlockLevel: '完全体' },
      { id: 8, name: '图鉴大师', description: '图鉴解锁奖励+50%', unlockLevel: '完全体' },
    ];

    res.json({
      code: 200,
      data: { skills },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('获取技能列表失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

module.exports = router;