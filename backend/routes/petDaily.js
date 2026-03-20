const express = require('express');
const router = express.Router();
const { Pet } = require('../models');

// 每日属性下降接口
router.post('/dailyDecay', async (req, res) => {
  try {
    const pets = await Pet.findAll();

    for (const pet of pets) {
      let nutritionDecay = 10;
      let happinessDecay = 15;

      // 营养值低于60时，额外扣除5点
      if (pet.nutrition < 60) {
        nutritionDecay += 5;
      }

      // 计算新的属性值，确保不低于0
      const newNutrition = Math.max(0, pet.nutrition - nutritionDecay);
      const newHappiness = Math.max(0, pet.happiness - happinessDecay);

      // 更新宠物属性
      await Pet.update(
        {
          nutrition: newNutrition,
          happiness: newHappiness,
        },
        { where: { petId: pet.petId } }
      );
    }

    res.json({
      code: 200,
      data: { affectedCount: pets.length },
      msg: '每日属性下降处理完成',
    });
  } catch (error) {
    console.error('每日属性下降处理失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 检查宠物属性状态
router.get('/checkStatus', async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const pet = await Pet.findOne({
      where: { userId, petId },
    });

    if (!pet) {
      return res.json({ code: 400, data: {}, msg: '宠物不存在' });
    }

    const warnings = [];

    // 营养值警告
    if (pet.nutrition < 60) {
      warnings.push({
        type: 'nutrition',
        message: '营养值过低，宠物无法参与挑战',
        severity: pet.nutrition < 30 ? 'critical' : 'warning',
      });
    }

    // 快乐值警告
    if (pet.happiness < 60) {
      warnings.push({
        type: 'happiness',
        message: '快乐值过低，无法互动，亲密度停止增长',
        severity: pet.happiness < 30 ? 'critical' : 'warning',
      });
    }

    res.json({
      code: 200,
      data: {
        petId: pet.petId,
        nutrition: pet.nutrition,
        happiness: pet.happiness,
        intimacy: pet.intimacy,
        warnings,
        canChallenge: pet.nutrition >= 60,
        canInteract: pet.happiness >= 60,
      },
      msg: '查询成功',
    });
  } catch (error) {
    console.error('检查宠物状态失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

module.exports = router;