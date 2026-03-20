const express = require('express');
const router = express.Router();
const { User, Pet, Social, Incentive } = require('../models');
const authMiddleware = require('../middleware/auth');

// 宠物创建接口
router.post('/create', authMiddleware, async (req, res) => {
  try {
    const { petName, petAvatar, petType } = req.body;
    const userId = req.userId;

    if (!userId || !petName) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查询用户是否已有宠物
    const existingPets = await Pet.findAll({
      where: { userId },
    });

    const isSelected = existingPets.length === 0 ? 1 : 0;

    // 创建宠物
    const newPet = await Pet.create({
      userId,
      petName,
      petAvatar: petAvatar || 'default_avatar.png',
      petType: petType || 'common',
      nutrition: 100,
      happiness: 100,
      intimacy: 0,
      level: 1,
      exp: 0,
      expThreshold: 100,
      isSelected,
      abilityLevel: 'D',
      initialLevel: 1,
      initialExp: 0,
      petDesc: '一只可爱的宠物',
      unlockAvatar: 'default',
    });

    // 创建社交记录
    await Social.create({
      userId,
      petId: newPet.petId,
      friendList: '[]',
      likeNum: 0,
      helpNum: 0,
      beLikedNum: 0,
      beHelpedNum: 0,
      rankScore: 0,
      createTime: new Date(),
      updateTime: new Date(),
    });

    // 创建激励记录
    await Incentive.create({
      userId,
      petId: newPet.petId,
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

    res.json({
      code: 200,
      data: {
        petId: newPet.petId,
        petName: newPet.petName,
        petAvatar: newPet.petAvatar,
        petType: newPet.petType,
        isSelected: newPet.isSelected === 1,
      },
      msg: '宠物创建成功',
    });
  } catch (error) {
    console.error('宠物创建失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 宠物列表查询接口
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const pets = await Pet.findAll({
      where: { userId },
    });

    const selectedPet = pets.find(p => p.isSelected === 1);

    res.json({
      code: 200,
      data: {
        petList: pets.map(pet => ({
          petId: pet.petId,
          userId: pet.userId,
          petName: pet.petName,
          petAvatar: pet.petAvatar,
          petType: pet.petType,
          nutrition: pet.nutrition,
          happiness: pet.happiness,
          intimacy: pet.intimacy,
          level: pet.level,
          exp: pet.exp,
          expThreshold: pet.expThreshold,
          isSelected: pet.isSelected === 1,
          abilityLevel: pet.abilityLevel,
          initialLevel: pet.initialLevel,
          initialExp: pet.initialExp,
          petDesc: pet.petDesc,
          unlockAvatar: pet.unlockAvatar,
          createTime: pet.createTime,
        })),
        total: pets.length,
        selectedPetId: selectedPet?.petId,
      },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('宠物列表查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 宠物选择接口
router.post('/select', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.body;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 取消所有宠物的选中状态
    await Pet.update(
      { isSelected: 0 },
      { where: { userId } }
    );

    // 设置指定宠物为选中状态
    await Pet.update(
      { isSelected: 1 },
      { where: { userId, petId } }
    );

    // 查询用户信息
    const user = await User.findByPk(userId);
    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    // 检查是否需要测试期引导
    const needGuide = user.testPeriodStatus === 0;

    res.json({
      code: 200,
      data: {
        petId,
        petName: '宠物', // 这里应该从数据库中获取宠物名称
        needGuide,
        testPeriodStatus: user.testPeriodStatus,
      },
      msg: '选择成功',
    });
  } catch (error) {
    console.error('宠物选择失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 宠物状态查询接口
router.get('/status', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    let whereCondition = { userId };
    if (petId) {
      whereCondition.petId = petId;
    }

    const pet = await Pet.findOne({
      where: whereCondition,
    });

    if (!pet) {
      return res.json({ code: 400, data: {}, msg: '宠物不存在' });
    }

    // 计算升级进度
    const upgradeProgress = Math.round((pet.exp / pet.expThreshold) * 100);

    // 评估等级描述
    const levelDescriptions = {
      'S': '优秀：您的能力非常出色',
      'A': '良好：您的能力较强',
      'B': '中等：您的能力适中',
      'C': '基础：您的能力处于基础水平',
      'D': '待提升：您的能力有待提升',
    };

    res.json({
      code: 200,
      data: {
        petId: pet.petId,
        userId: pet.userId,
        petName: pet.petName,
        petAvatar: pet.petAvatar,
        nutrition: pet.nutrition,
        happiness: pet.happiness,
        intimacy: pet.intimacy,
        level: pet.level,
        exp: pet.exp,
        expThreshold: pet.expThreshold,
        upgradeProgress,
        abilityLevel: pet.abilityLevel,
        abilityLevelDesc: levelDescriptions[pet.abilityLevel] || levelDescriptions['C'],
      },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('宠物状态查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 宠物状态更新接口
router.post('/updateStatus', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, nutrition, happiness, intimacy, skillPoint, exp } = req.body;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const pet = await Pet.findOne({
      where: { userId, petId },
    });

    if (!pet) {
      return res.json({ code: 400, data: {}, msg: '宠物不存在' });
    }

    // 更新宠物状态
    const updateData = {};
    if (nutrition !== undefined) updateData.nutrition = nutrition;
    if (happiness !== undefined) updateData.happiness = happiness;
    if (intimacy !== undefined) updateData.intimacy = intimacy;
    if (exp !== undefined) updateData.exp = exp;

    // 检查是否升级
    let isUpgrade = false;
    if (exp !== undefined && exp >= pet.expThreshold && pet.level < 100) {
      const newLevel = pet.level + 1;
      // 100级满级，升级经验逐级递增
      const baseExp = 100;
      const levelMultiplier = newLevel;
      const difficultyMultiplier = 1.0 + (newLevel - 1) * 0.1;
      const newExpThreshold = Math.round((baseExp + levelMultiplier * 50) * difficultyMultiplier);
      
      updateData.level = newLevel;
      updateData.expThreshold = newExpThreshold;
      isUpgrade = true;

      // 升级时解锁新形象
      const unlockAvatars = pet.unlockAvatar ? pet.unlockAvatar.split(',') : [];
      if (!unlockAvatars.includes(`level_${newLevel}`)) {
        unlockAvatars.push(`level_${newLevel}`);
        updateData.unlockAvatar = unlockAvatars.join(',');
      }
    }

    await Pet.update(updateData, { where: { userId, petId } });

    const updatedPet = await Pet.findOne({
      where: { userId, petId },
    });

    res.json({
      code: 200,
      data: {
        petId: updatedPet.petId,
        level: updatedPet.level,
        exp: updatedPet.exp,
        expThreshold: updatedPet.expThreshold,
        status: {
          nutrition: updatedPet.nutrition,
          happiness: updatedPet.happiness,
          intimacy: updatedPet.intimacy,
          skillPoint: updatedPet.skillPoint,
        },
        isUpgrade,
      },
      msg: '更新成功',
    });
  } catch (error) {
    console.error('宠物状态更新失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

module.exports = router;