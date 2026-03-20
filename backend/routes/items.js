const express = require('express');
const router = express.Router();
const { Incentive, Pet } = require('../models');

// 物品使用接口
router.post('/use', async (req, res) => {
  try {
    console.log('收到物品使用请求:', req.body);
    const { userId, petId, itemId, itemNum } = req.body;

    if (userId === undefined || petId === undefined || !itemId || !itemNum) {
      return res.json({
        code: 400,
        data: null,
        msg: `参数不完整: userId=${userId}, petId=${petId}, itemId=${itemId}, itemNum=${itemNum}`,
      });
    }

    // 查询宠物数据
    const pet = await Pet.findOne({
      where: { petId },
    });

    if (!pet) {
      return res.json({
        code: 404,
        data: null,
        msg: '宠物不存在',
      });
    }

    // 处理不同类型的物品
    let message = '';
    let updateData = {};

    // 根据前端 items_page.dart 中的 itemId 进行适配
    switch (itemId) {
      case 'fresh_milk_pack': // 营养值 +10
        updateData.nutrition = Math.min(pet.nutrition + 10 * itemNum, 100);
        message = `营养值增加了${10 * itemNum}点`;
        break;
      case 'rainbow_cat_stick': // 快乐值 +10
        updateData.happiness = Math.min(pet.happiness + 10 * itemNum, 100);
        message = `快乐值增加了${10 * itemNum}点`;
        break;
      case 'frozen_salmon': // 营养值 +25
        updateData.nutrition = Math.min(pet.nutrition + 25 * itemNum, 100);
        message = `营养值增加了${25 * itemNum}点`;
        break;
      case 'star_bubble_machine': // 快乐值 +25
        updateData.happiness = Math.min(pet.happiness + 25 * itemNum, 100);
        message = `快乐值增加了${25 * itemNum}点`;
        break;
      case 'love_cookie': // 亲密度 +8，快乐值 +5
        updateData.intimacy = pet.intimacy + 8 * itemNum;
        updateData.happiness = Math.min(pet.happiness + 5 * itemNum, 100);
        message = `亲密度增加了${8 * itemNum}点，快乐值增加了${5 * itemNum}点`;
        break;
      case 'growth_shake': // 经验 +15，营养值 +10
        const shakeExp = 15 * itemNum;
        updateData.exp = pet.exp + shakeExp;
        updateData.nutrition = Math.min(pet.nutrition + 10 * itemNum, 100);
        message = `经验增加了${shakeExp}点，营养值增加了${10 * itemNum}点`;
        break;
      case 'exp_cookie': // 经验 +30
        const cookieExp = 30 * itemNum;
        updateData.exp = pet.exp + cookieExp;
        message = `经验增加了${cookieExp}点`;
        break;
      case 'super_exp_cake': // 经验 +60
        const cakeExp = 60 * itemNum;
        updateData.exp = pet.exp + cakeExp;
        message = `经验增加了${cakeExp}点`;
        break;
      case 'spring_cherry_cake': // 营养 +40，快乐 +40，亲密度 +15
        updateData.nutrition = Math.min(pet.nutrition + 40 * itemNum, 100);
        updateData.happiness = Math.min(pet.happiness + 40 * itemNum, 100);
        updateData.intimacy = pet.intimacy + 15 * itemNum;
        message = `营养+${40 * itemNum}，快乐+${40 * itemNum}，亲密度+${15 * itemNum}`;
        break;
      
      // 保留原有的兼容性
      case 'nutrition_dan':
        updateData.nutrition = Math.min(pet.nutrition + 20 * itemNum, 100);
        message = `营养值增加了${20 * itemNum}点`;
        break;
      case 'happy_fruit':
        updateData.happiness = Math.min(pet.happiness + 20 * itemNum, 100);
        message = `快乐值增加了${20 * itemNum}点`;
        break;
      case 'skill_book':
        // 如果模型中没有 skillPoint，暂时忽略或记录
        message = `技能点增加了${2 * itemNum}点 (暂未记录到数据库)`;
        break;
        
      default:
        console.log('不支持的物品类型:', itemId);
        return res.json({
          code: 400,
          data: null,
          msg: `不支持的物品类型: ${itemId}`,
        });
    }

    // 使用统一的 PetLogic 处理经验和升级
    const PetLogic = require('../utils/pet_logic');
    let isUpgrade = false;
    let gainedExp = 0;

    // 先更新非经验属性，因为经验倍率受这些属性影响
    const expValue = updateData.exp;
    delete updateData.exp; // 暂时移除经验，由 PetLogic 处理

    // 更新非经验属性
    if (Object.keys(updateData).length > 0) {
      await pet.update(updateData);
    }

    // 处理经验增加
    if (expValue !== undefined) {
      const expAmount = expValue - pet.exp;
      const result = await PetLogic.addExp(pet, expAmount);
      isUpgrade = result.isUpgrade;
      gainedExp = result.gainedExp;
      if (isUpgrade) message += '！宠物升级了！';
    }

    // 扣除物品数量
    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (incentiveData) {
      let items = {};
      try {
        items = JSON.parse(incentiveData.inventory || '{}');
        if (items[itemId] >= itemNum) {
          items[itemId] -= itemNum;
          await incentiveData.update({ inventory: JSON.stringify(items) });
        }
      } catch (e) {
        console.error('更新物品栏失败:', e);
      }
    }

    return res.json({
      code: 200,
      data: {
        petId,
        itemId,
        itemNum,
        newStatus: updateData,
        isUpgrade,
      },
      msg: message,
    });
  } catch (error) {
    console.error('使用物品失败:', error);
    return res.json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 获取物品列表接口
router.get('/list', async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据中的物品栏
    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    let items = {};
    
    if (incentiveData && incentiveData.inventory) {
      try {
        items = JSON.parse(incentiveData.inventory);
      } catch (e) {
        console.error('解析物品栏失败:', e);
      }
    }

    // 如果物品栏为空，初始化一些默认物品（仅用于演示或新用户）
    if (Object.keys(items).length === 0) {
      items = {
        'fresh_milk_pack': 10,
        'rainbow_cat_stick': 10,
        'frozen_salmon': 5,
        'star_bubble_machine': 5,
        'love_cookie': 20,
        'growth_shake': 10,
        'exp_cookie': 5,
        'super_exp_cake': 2,
        'spring_cherry_cake': 1,
      };
      // 保存初始物品
      if (incentiveData) {
        await incentiveData.update({ inventory: JSON.stringify(items) });
      }
    }

    return res.json({
      code: 200,
      data: {
        items,
      },
      msg: '获取物品列表成功',
    });
  } catch (error) {
    console.error('获取物品列表失败:', error);
    return res.json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

module.exports = router;
