const express = require('express');
const router = express.Router();
const { Incentive, User, Pet } = require('../models');

// 激励核心数据接口
router.get('/core', async (req, res) => {
  try {
    const { userId, petId, versionType } = req.query;

    if (!userId || !petId) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励核心数据
    let incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      // 如果不存在，创建默认数据
      incentiveData = await Incentive.create({
        userId,
        petId,
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

    // 计算收益系数
    const abilityLevel = incentiveData.abilityLevel;
    let baseRate = 1.0;
    switch (abilityLevel) {
      case 'S': baseRate = 1.5; break;
      case 'A': baseRate = 1.4; break;
      case 'B': baseRate = 1.2; break;
      case 'C': baseRate = 1.0; break;
      case 'D': baseRate = 0.8; break;
      default: baseRate = 1.0;
    }

    return res.json({
      code: 200,
      data: {
        userId: incentiveData.userId,
        petId: incentiveData.petId,
        abilityLevel: incentiveData.abilityLevel,
        integral: incentiveData.integral,
        integralGet: incentiveData.integralGet,
        integralConsume: incentiveData.integralConsume,
        integralExpire: incentiveData.integralExpire,
        signInDays: incentiveData.signInDays,
        achievementUnlock: (() => { try { return JSON.parse(incentiveData.achievementUnlock || '[]'); } catch(e) { return []; } })(),
        welfareGet: (() => { try { return JSON.parse(incentiveData.welfareGet || '[]'); } catch(e) { return []; } })(),
        incentivePrefer: (() => { try { return JSON.parse(incentiveData.incentivePrefer || '{}'); } catch(e) { return {}; } })(),
        baseRate,
        canInteract: true,
      },
      msg: '激励核心数据查询成功',
    });
  } catch (error) {
    console.error('激励核心数据查询失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 积分兑换接口
router.post('/integral/exchange', async (req, res) => {
  try {
    const { userId, petId, itemId, itemNum } = req.body;

    if (!userId || !petId || !itemId || !itemNum) {
      return res.status(400).json({ code: 400, msg: '参数不完整' });
    }

    let incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (!incentiveData) return res.status(404).json({ code: 404, msg: '激励数据不存在' });

    const itemPrices = {
      'exp_dan': 100, 'advanced_exp_dan': 250, 'nutrition_dan': 50, 'advanced_nutrition_dan': 120,
      'intimacy_prop': 80, 'advanced_intimacy_prop': 150, 'skill_book': 300, 'exp_double_card': 50,
      'universal_prop': 100, 'growth_package': 80, 'happy_fruit': 50,
      'fresh_milk_pack': 50, 'frozen_salmon': 120, 'rainbow_cat_stick': 50, 'star_bubble_machine': 120,
      'love_cookie': 150, 'spring_cherry_cake': 300, 'growth_shake': 200, 'exp_cookie': 250, 'super_exp_cake': 400
    };

    const price = itemPrices[itemId];
    if (!price) return res.json({ code: 400, msg: '无效的商品ID: ' + itemId });

    const cost = price * itemNum;
    if (incentiveData.integral < cost) {
      return res.json({ code: 400, msg: `积分不足，需要 ${cost}，当前 ${incentiveData.integral}` });
    }

    const newIntegral = incentiveData.integral - cost;
    const newConsume = incentiveData.integralConsume + cost;

    // 更新积分和背包
    let inventory = {};
    try {
      inventory = JSON.parse(incentiveData.inventory || '{}');
    } catch (e) {
      console.error('解析背包失败:', e);
    }
    inventory[itemId] = (inventory[itemId] || 0) + itemNum;

    await Incentive.update(
      {
        integral: newIntegral,
        integralConsume: newConsume,
        inventory: JSON.stringify(inventory),
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    return res.json({
      code: 200,
      msg: '兑换成功',
      data: {
        remainingIntegral: newIntegral,
        integralConsume: newConsume,
        inventory: inventory
      }
    });
  } catch (error) {
    console.error('积分兑换失败:', error);
    return res.status(500).json({ code: 500, msg: '服务器错误' });
  }
});

// 同步偏好接口
router.post('/prefer/sync', async (req, res) => {
  try {
    const { userId, petId, preference } = req.body;
    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (!incentiveData) return res.status(404).json({ code: 404, msg: '激励数据不存在' });

    let currentPrefer = {};
    try { currentPrefer = JSON.parse(incentiveData.incentivePrefer && incentiveData.incentivePrefer !== '' ? incentiveData.incentivePrefer : '{}'); } catch (e) {}
    const newPrefer = { ...currentPrefer, ...preference, lastUpdateTime: new Date().toISOString() };

    await Incentive.update({ incentivePrefer: JSON.stringify(newPrefer), updateTime: new Date() }, { where: { userId, petId } });
    return res.json({ code: 200, data: { incentivePrefer: newPrefer }, msg: '偏好同步成功' });
  } catch (error) {
    return res.status(500).json({ code: 500, msg: '服务器错误' });
  }
});

// 每日签到接口
router.post('/sign-in', async (req, res) => {
  try {
    const { userId, petId } = req.body;
    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (!incentiveData) return res.status(404).json({ code: 404, msg: '激励数据不存在' });

    let welfareGet = [];
    try { welfareGet = JSON.parse(incentiveData.welfareGet && incentiveData.welfareGet !== '' ? incentiveData.welfareGet : '[]'); } catch (e) {}
    const today = new Date().toISOString().split('T')[0];
    if (welfareGet.some(w => w.type === 'daily_sign' && w.date === today)) return res.json({ code: 400, msg: '今日已签到' });

    let newSignInDays = 1;
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split('T')[0];
    if (welfareGet.some(w => w.type === 'daily_sign' && w.date === yesterdayStr)) newSignInDays = (incentiveData.signInDays || 0) + 1;

    let signReward = 10;
    if (newSignInDays >= 7) signReward = 50;
    else if (newSignInDays >= 3) signReward = 30;

    await Incentive.update({
      integral: incentiveData.integral + signReward,
      integralGet: incentiveData.integralGet + signReward,
      signInDays: newSignInDays,
      welfareGet: JSON.stringify([...welfareGet, { type: 'daily_sign', date: today }]),
      updateTime: new Date(),
    }, { where: { userId, petId } });

    return res.json({ code: 200, msg: '签到成功', data: { reward: { type: 'integral', value: signReward } } });
  } catch (error) {
    return res.status(500).json({ code: 500, msg: '服务器错误' });
  }
});

// 福利领取接口
router.post('/welfare/receive', async (req, res) => {
  try {
    const { userId, petId, welfareType } = req.body;
    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (!incentiveData) return res.status(404).json({ code: 404, msg: '激励数据不存在' });

    let welfareGet = [];
    try { welfareGet = JSON.parse(incentiveData.welfareGet && incentiveData.welfareGet !== '' ? incentiveData.welfareGet : '[]'); } catch (e) {}
    const today = new Date().toISOString().split('T')[0];
    if (welfareGet.some(w => w.type === welfareType && w.date === today)) return res.json({ code: 400, msg: '今日福利已领取' });

    const reward = { type: 'integral', value: 100 };
    await Incentive.update({
      integral: incentiveData.integral + reward.value,
      integralGet: incentiveData.integralGet + reward.value,
      welfareGet: JSON.stringify([...welfareGet, { type: welfareType, date: today }]),
      updateTime: new Date(),
    }, { where: { userId, petId } });

    return res.json({ code: 200, data: { reward }, msg: '福利领取成功' });
  } catch (error) {
    return res.status(500).json({ code: 500, msg: '服务器错误' });
  }
});

// 每周任务奖励接口
router.post('/weekly-task/reward', async (req, res) => {
  try {
    const { userId, petId, weeklyTaskCount } = req.body;
    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (!incentiveData) return res.status(404).json({ code: 404, msg: '激励数据不存在' });

    let welfareGet = [];
    try { welfareGet = JSON.parse(incentiveData.welfareGet && incentiveData.welfareGet !== '' ? incentiveData.welfareGet : '[]'); } catch (e) {}
    const now = new Date();
    const startOfYear = new Date(now.getFullYear(), 0, 1);
    const weekNumber = Math.ceil((((now - startOfYear) / 86400000) + startOfYear.getDay() + 1) / 7);
    const currentWeek = `${now.getFullYear()}-W${weekNumber}`;

    if (welfareGet.some(w => w.type === 'weekly_task' && w.week === currentWeek)) return res.json({ code: 400, msg: '本周奖励已领取' });

    let weeklyReward = 0;
    if (weeklyTaskCount >= 20) weeklyReward = 200;
    else if (weeklyTaskCount >= 15) weeklyReward = 150;
    else if (weeklyTaskCount >= 10) weeklyReward = 100;
    else if (weeklyTaskCount >= 5) weeklyReward = 50;
    else return res.json({ code: 400, msg: '每周任务完成数量不足5个' });

    await Incentive.update({
      integral: incentiveData.integral + weeklyReward,
      integralGet: incentiveData.integralGet + weeklyReward,
      welfareGet: JSON.stringify([...welfareGet, { type: 'weekly_task', week: currentWeek, date: now.toISOString().split('T')[0] }]),
      updateTime: new Date(),
    }, { where: { userId, petId } });

    return res.json({ code: 200, data: { weeklyReward }, msg: '每周任务奖励领取成功' });
  } catch (error) {
    return res.status(500).json({ code: 500, msg: '服务器错误' });
  }
});

// 月度等级福利接口
router.post('/monthly-welfare/receive', async (req, res) => {
  try {
    const { userId, petId, abilityLevel } = req.body;
    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (!incentiveData) return res.status(404).json({ code: 404, msg: '激励数据不存在' });

    let welfareGet = [];
    try { welfareGet = JSON.parse(incentiveData.welfareGet && incentiveData.welfareGet !== '' ? incentiveData.welfareGet : '[]'); } catch (e) {}
    const currentMonth = `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`;
    if (welfareGet.some(w => w.type === 'monthly_welfare' && w.month === currentMonth)) return res.json({ code: 400, msg: '本月福利已领取' });

    let monthlyReward = 0;
    switch (abilityLevel) {
      case 'S': monthlyReward = 500; break;
      case 'A': monthlyReward = 300; break;
      case 'B': monthlyReward = 200; break;
      case 'C': monthlyReward = 100; break;
      case 'D': monthlyReward = 50; break;
      default: return res.json({ code: 400, msg: '不支持的评估等级' });
    }

    await Incentive.update({
      integral: incentiveData.integral + monthlyReward,
      integralGet: incentiveData.integralGet + monthlyReward,
      welfareGet: JSON.stringify([...welfareGet, { type: 'monthly_welfare', month: currentMonth, date: new Date().toISOString().split('T')[0] }]),
      updateTime: new Date(),
    }, { where: { userId, petId } });

    return res.json({ code: 200, data: { monthlyReward }, msg: '月度福利领取成功' });
  } catch (error) {
    return res.status(500).json({ code: 500, msg: '服务器错误' });
  }
});

// 成就解锁接口
router.post('/achievement/unlock', async (req, res) => {
  try {
    const { userId, petId, achievementId } = req.body;
    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (!incentiveData) return res.status(404).json({ code: 404, msg: '激励数据不存在' });

    let achievementUnlock = [];
    try { achievementUnlock = JSON.parse(incentiveData.achievementUnlock && incentiveData.achievementUnlock !== '' ? incentiveData.achievementUnlock : '[]'); } catch (e) {}
    if (achievementUnlock.includes(achievementId)) return res.json({ code: 400, msg: '成就已解锁' });

    const reward = { type: 'integral', value: 500 };
    await Incentive.update({
      integral: incentiveData.integral + reward.value,
      integralGet: incentiveData.integralGet + reward.value,
      achievementUnlock: JSON.stringify([...achievementUnlock, achievementId]),
      updateTime: new Date(),
    }, { where: { userId, petId } });

    return res.json({ code: 200, data: { reward }, msg: '成就解锁成功' });
  } catch (error) {
    return res.status(500).json({ code: 500, msg: '服务器错误' });
  }
});

// 宝箱开启接口
router.post('/chest/open', async (req, res) => {
  try {
    const { userId, petId, chestType } = req.body;

    if (!userId || !petId || !chestType) {
      return res.status(400).json({ code: 400, data: null, msg: '参数不完整' });
    }

    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (!incentiveData) return res.status(404).json({ code: 404, data: null, msg: '激励数据不存在' });

    let chestUnlock = [];
    try { chestUnlock = JSON.parse(incentiveData.chestUnlock || '[]'); } catch (e) {}
    if (!chestUnlock.includes(chestType)) {
      return res.status(400).json({ code: 400, data: null, msg: '宝箱未解锁' });
    }

    const rewards = [
      { type: 'integral', value: 100 },
      { type: 'integral', value: 150 },
      { type: 'integral', value: 200 },
      { type: 'prop', value: 'nutrition_dan' },
      { type: 'prop', value: 'happy_fruit' },
    ];
    const reward = rewards[Math.floor(Math.random() * rewards.length)];

    const updateData = {
      chestOpenNum: incentiveData.chestOpenNum + 1,
      updateTime: new Date(),
    };

    if (reward.type === 'integral') {
      updateData.integral = incentiveData.integral + reward.value;
      updateData.integralGet = incentiveData.integralGet + reward.value;
    }

    await Incentive.update(updateData, { where: { userId, petId } });

    return res.json({
      code: 200,
      data: { reward, chestOpenNum: updateData.chestOpenNum },
      msg: '宝箱开启成功',
    });
  } catch (error) {
    console.error('宝箱开启失败:', error);
    return res.status(500).json({ code: 500, data: null, msg: '服务器错误' });
  }
});

// 激励联动接口（任务完成时触发）
router.post('/link', async (req, res) => {
  try {
    const { userId, petId, taskScore, taskQuality } = req.body;

    if (!userId || !petId) {
      return res.status(400).json({ code: 400, data: null, msg: '参数不完整' });
    }

    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (!incentiveData) return res.status(404).json({ code: 404, data: null, msg: '激励数据不存在' });

    const abilityLevel = incentiveData.abilityLevel;
    let baseRate = 1.0;
    switch (abilityLevel) {
      case 'S': baseRate = 1.5; break;
      case 'A': baseRate = 1.4; break;
      case 'B': baseRate = 1.2; break;
      case 'C': baseRate = 1.0; break;
      case 'D': baseRate = 0.8; break;
      default: baseRate = 1.0;
    }

    let qualityRate = 1.0;
    if (taskQuality >= 90) qualityRate = 1.5;
    else if (taskQuality >= 80) qualityRate = 1.2;

    const totalRate = baseRate * qualityRate;
    const baseIntegral = 10;
    const finalIntegral = Math.round(baseIntegral * totalRate);

    await Incentive.update(
      {
        integral: incentiveData.integral + finalIntegral,
        integralGet: incentiveData.integralGet + finalIntegral,
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    return res.json({
      code: 200,
      data: { baseRate, qualityRate, totalRate, baseIntegral, finalIntegral, abilityLevel },
      msg: '激励联动成功',
    });
  } catch (error) {
    console.error('激励联动失败:', error);
    return res.status(500).json({ code: 500, data: null, msg: '服务器错误' });
  }
});

// 获取激励偏好接口
router.get('/prefer/get', async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.status(400).json({ code: 400, data: null, msg: '参数不完整' });
    }

    const incentiveData = await Incentive.findOne({ where: { userId, petId } });
    if (!incentiveData) return res.status(404).json({ code: 404, data: null, msg: '激励数据不存在' });

    let incentivePrefer = {};
    try { incentivePrefer = JSON.parse(incentiveData.incentivePrefer || '{}'); } catch (e) {}

    return res.json({
      code: 200,
      data: { incentivePrefer },
      msg: '偏好查询成功',
    });
  } catch (error) {
    console.error('偏好查询失败:', error);
    return res.status(500).json({ code: 500, data: null, msg: '服务器错误' });
  }
});

module.exports = router;
