const express = require('express');
const router = express.Router();
const { Pet, PetAdvance, PetAlbum, EvaluationCalc, Incentive } = require('../models');
const authMiddleware = require('../middleware/auth');

// 获取宠物进阶数据
router.get('/advance', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const pet = await Pet.findOne({ where: { userId, id: petId } });
    if (!pet) {
      return res.json({ code: 400, data: {}, msg: '宠物不存在' });
    }

    const advanceData = await PetAdvance.findOne({
      where: { userId, petId },
    });

    res.json({
      code: 200,
      data: {
        pet: {
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
        },
        advance: advanceData ? {
          id: advanceData.id,
          currentStage: advanceData.currentStage,
          stageExp: advanceData.stageExp,
          stageExpMax: advanceData.stageExpMax,
          skillPoint: advanceData.skillPoint,
          skillList: JSON.parse(advanceData.skillList || '[]'),
          stageRecord: JSON.parse(advanceData.stageRecord || '[]'),
          evolveCondition: JSON.parse(advanceData.evolveCondition || '{}'),
        } : {
          currentStage: '幼年期',
          stageExp: 0,
          stageExpMax: 100,
          skillPoint: 0,
          skillList: [],
          stageRecord: [],
          evolveCondition: { exp: 100, intimacy: 50, taskCount: 10 },
        },
      },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('获取宠物进阶数据失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 宠物进化
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

    if (advanceData.stageExp < evolveCondition.exp) {
      return res.json({ code: 400, data: {}, msg: '阶段经验不足，无法进化' });
    }

    const pet = await Pet.findOne({ where: { userId, id: petId } });
    if (!pet) {
      return res.json({ code: 400, data: {}, msg: '宠物不存在' });
    }

    const calcData = await EvaluationCalc.findOne({
      where: { userId, petId },
    });

    if ((calcData?.taskCompletionCount || 0) < evolveCondition.taskCount) {
      return res.json({ code: 400, data: {}, msg: '任务完成数不足，无法进化' });
    }

    const oldStage = advanceData.currentStage;
    const newStage = _getNextStage(oldStage);

    if (!newStage) {
      return res.json({ code: 400, data: {}, msg: '已达到最高阶段，无法继续进化' });
    }

    const stageRecord = JSON.parse(advanceData.stageRecord || '[]');
    stageRecord.push({
      date: new Date().toISOString(),
      oldStage,
      newStage,
    });

    await PetAdvance.update(
      {
        currentStage: newStage,
        stageExp: 0,
        stageExpMax: _getStageExpMax(newStage),
        stageRecord: JSON.stringify(stageRecord),
        evolveTime: new Date(),
      },
      { where: { userId, petId } }
    );

    await Pet.update(
      { level: pet.level + 1 },
      { where: { userId, id: petId } }
    );

    const integralReward = 100;
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (incentiveData) {
      await Incentive.update(
        {
          integral: (incentiveData.integral || 0) + integralReward,
          integralGet: (incentiveData.integralGet || 0) + integralReward,
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
        message: `恭喜！宠物已进化至${newStage}，获得${integralReward}积分`,
      },
      msg: '宠物进化成功',
    });
  } catch (error) {
    console.error('宠物进化失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 学习技能
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

    if (advanceData.skillPoint < 1) {
      return res.json({ code: 400, data: {}, msg: '技能点不足，无法学习技能' });
    }

    const skillList = JSON.parse(advanceData.skillList || '[]');
    if (skillList.find(skill => skill.id === skillId)) {
      return res.json({ code: 400, data: {}, msg: '该技能已学习' });
    }

    const skillInfo = _getSkillInfo(skillId);
    if (!skillInfo) {
      return res.json({ code: 400, data: {}, msg: '技能不存在' });
    }

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

// 获取图鉴数据
router.get('/album', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const albumData = await PetAlbum.findOne({
      where: { userId, petId },
    });

    const allPets = [
      { id: 1, name: '小火龙', type: '火', rarity: 'common', description: '会喷火的蜥蜴' },
      { id: 2, name: '杰尼龟', type: '水', rarity: 'common', description: '会喷射水流的海龟' },
      { id: 3, name: '妙蛙种子', type: '草', rarity: 'common', description: '背上长着种子的青蛙' },
      { id: 4, name: '皮卡丘', type: '电', rarity: 'rare', description: '会放电的黄色老鼠' },
      { id: 5, name: '伊布', type: '普通', rarity: 'rare', description: '可以进化成多种形态' },
      { id: 6, name: '超梦', type: '超能', rarity: 'legendary', description: '最强的超能力宝可梦' },
      { id: 7, name: '梦幻', type: '超能', rarity: 'legendary', description: '传说中的宝可梦' },
      { id: 8, name: '阿尔宙斯', type: '普通', rarity: 'legendary', description: '创造世界的宝可梦' },
    ];

    const unlockedPetIds = albumData ? JSON.parse(albumData.petList || '[]') : [];
    const petList = allPets.map(pet => ({
      ...pet,
      isUnlocked: unlockedPetIds.includes(pet.id),
    }));

    res.json({
      code: 200,
      data: {
        petList,
        unlockedCount: unlockedPetIds.length,
        totalCount: allPets.length,
      },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('获取图鉴数据失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 解锁图鉴
router.post('/unlockAlbum', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, petIdToUnlock } = req.body;

    if (!userId || !petId || !petIdToUnlock) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    let albumData = await PetAlbum.findOne({
      where: { userId, petId },
    });

    if (!albumData) {
      albumData = await PetAlbum.create({
        userId,
        petId,
        albumName: '我的图鉴',
        petList: JSON.stringify([]),
        collectCount: 0,
        totalCount: 8,
      });
    }

    const petList = JSON.parse(albumData.petList || '[]');
    if (petList.includes(petIdToUnlock)) {
      return res.json({ code: 400, data: {}, msg: '图鉴已解锁' });
    }

    const petInfo = _getPetInfo(petIdToUnlock);
    if (!petInfo) {
      return res.json({ code: 400, data: {}, msg: '宠物不存在' });
    }

    petList.push(petIdToUnlock);

    await PetAlbum.update(
      {
        petList: JSON.stringify(petList),
        collectCount: petList.length,
      },
      { where: { userId, petId } }
    );

    const integralReward = petInfo.rarity === 'legendary' ? 200 : 50;
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (incentiveData) {
      await Incentive.update(
        {
          integral: (incentiveData.integral || 0) + integralReward,
          integralGet: (incentiveData.integralGet || 0) + integralReward,
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
      msg: '图鉴解锁成功',
    });
  } catch (error) {
    console.error('解锁图鉴失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 获取技能列表
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

function _getNextStage(currentStage) {
  const stageMap = {
    '幼年期': '成长期',
    '成长期': '成熟期',
    '成熟期': '完全体',
    '完全体': null,
  };
  return stageMap[currentStage];
}

function _getStageExpMax(stage) {
  const expMap = {
    '幼年期': 100,
    '成长期': 200,
    '成熟期': 500,
    '完全体': 1000,
  };
  return expMap[stage] || 100;
}

function _getSkillInfo(skillId) {
  const skillMap = {
    1: { id: 1, name: '快速成长', description: '经验值获取速度+10%', unlockLevel: '幼年期' },
    2: { id: 2, name: '亲密度提升', description: '亲密度获取+20%', unlockLevel: '幼年期' },
    3: { id: 3, name: '任务加速', description: '任务完成时间-10%', unlockLevel: '成长期' },
    4: { id: 4, name: '积分加成', description: '积分获取+15%', unlockLevel: '成长期' },
    5: { id: 5, name: '稀有发现', description: '稀有宠物解锁概率+5%', unlockLevel: '成熟期' },
    6: { id: 6, name: '双倍经验', description: '每日首次任务双倍经验', unlockLevel: '成熟期' },
    7: { id: 7, name: '全能进化', description: '进化条件降低20%', unlockLevel: '完全体' },
    8: { id: 8, name: '图鉴大师', description: '图鉴解锁奖励+50%', unlockLevel: '完全体' },
  };
  return skillMap[skillId];
}

function _getPetInfo(petId) {
  const petMap = {
    1: { id: 1, name: '小火龙', type: '火', rarity: 'common' },
    2: { id: 2, name: '杰尼龟', type: '水', rarity: 'common' },
    3: { id: 3, name: '妙蛙种子', type: '草', rarity: 'common' },
    4: { id: 4, name: '皮卡丘', type: '电', rarity: 'rare' },
    5: { id: 5, name: '伊布', type: '普通', rarity: 'rare' },
    6: { id: 6, name: '超梦', type: '超能', rarity: 'legendary' },
    7: { id: 7, name: '梦幻', type: '超能', rarity: 'legendary' },
    8: { id: 8, name: '阿尔宙斯', type: '普通', rarity: 'legendary' },
  };
  return petMap[petId];
}

module.exports = router;