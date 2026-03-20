const express = require('express');
const router = express.Router();
const { Incentive } = require('../models');

// 积分兑换接口
router.post('/integral/exchange', async (req, res) => {
  try {
    const { userId, petId, itemId, itemNum } = req.body;

    if (!userId || !petId || !itemId || !itemNum) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      return res.status(404).json({
        code: 404,
        data: null,
        msg: '激励数据不存在',
      });
    }

    // 计算所需积分
    const itemPrices = {
      'nutrition_dan': 50,
      'advanced_nutrition_dan': 120,
      'happy_fruit': 50,
      'intimacy_prop': 80,
      'advanced_intimacy_prop': 150,
      'exp_dan': 100,
      'advanced_exp_dan': 250,
      'skill_book': 300
    };
    
    const price = itemPrices[itemId] || 100;
    const requiredIntegral = itemNum * price;

    if (incentiveData.integral < requiredIntegral) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '积分不足',
      });
    }

    // 扣除积分
    await Incentive.update(
      {
        integral: incentiveData.integral - requiredIntegral,
        integralConsume: incentiveData.integralConsume + requiredIntegral,
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    return res.json({
      code: 200,
      data: {
        remainingIntegral: incentiveData.integral - requiredIntegral,
        exchangedItem: itemId,
        exchangedNum: itemNum,
      },
      msg: '积分兑换成功',
    });
  } catch (error) {
    console.error('积分兑换失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 宝箱开启接口
router.post('/chest/open', async (req, res) => {
  try {
    const { userId, petId, chestType } = req.body;

    if (!userId || !petId || !chestType) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      return res.status(404).json({
        code: 404,
        data: null,
        msg: '激励数据不存在',
      });
    }

    // 检查宝箱是否已解锁
    const chestUnlock = JSON.parse(incentiveData.chestUnlock);
    if (!chestUnlock.includes(chestType)) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '宝箱未解锁',
      });
    }

    // 随机生成奖励（简化处理）
    const rewards = [
      { type: 'integral', value: 100 },
      { type: 'integral', value: 150 },
      { type: 'integral', value: 200 },
      { type: 'prop', value: 'nutrition_dan' },
      { type: 'prop', value: 'happy_fruit' },
    ];
    const reward = rewards[Math.floor(Math.random() * rewards.length)];

    // 更新宝箱开启数量
    await Incentive.update(
      {
        chestOpenNum: incentiveData.chestOpenNum + 1,
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    // 如果奖励是积分，增加积分
    if (reward.type === 'integral') {
      await Incentive.update(
        {
          integral: incentiveData.integral + reward.value,
          integralGet: incentiveData.integralGet + reward.value,
          updateTime: new Date(),
        },
        { where: { userId, petId } }
      );
    }

    return res.json({
      code: 200,
      data: {
        reward,
        chestOpenNum: incentiveData.chestOpenNum + 1,
      },
      msg: '宝箱开启成功',
    });
  } catch (error) {
    console.error('宝箱开启失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 成就解锁接口
router.post('/achievement/unlock', async (req, res) => {
  try {
    const { userId, petId, achievementId } = req.body;

    if (!userId || !petId || !achievementId) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      return res.status(404).json({
        code: 404,
        data: null,
        msg: '激励数据不存在',
      });
    }

    // 检查成就是否已解锁
    const achievementUnlock = JSON.parse(incentiveData.achievementUnlock);
    if (achievementUnlock.includes(achievementId)) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '成就已解锁',
      });
    }

    // 成就解锁条件检查
    let canUnlock = false;
    let unlockCondition = '';

    switch (achievementId) {
      case 'task_master':
        // 任务达人：完成50个任务
        const completedTasks = 50; // 这里应该从任务表查询实际完成数
        canUnlock = completedTasks >= 50;
        unlockCondition = '完成50个任务';
        break;
      case 'pet_master':
        // 宠物大师：宠物达到10级
        const petLevel = 10; // 这里应该从宠物表查询实际等级
        canUnlock = petLevel >= 10;
        unlockCondition = '宠物达到10级';
        break;
      case 'sign_7_days':
        // 连续签到7天
        canUnlock = incentiveData.signInDays >= 7;
        unlockCondition = '连续签到7天';
        break;
      case 'sign_30_days':
        // 连续签到30天
        canUnlock = incentiveData.signInDays >= 30;
        unlockCondition = '连续签到30天';
        break;
      case 'ability_S':
        // 评估等级达到S级
        canUnlock = incentiveData.abilityLevel === 'S';
        unlockCondition = '评估等级达到S级';
        break;
      case 'high_quality_tasks':
        // 完成10个高质量任务（效果分≥80）
        const highQualityTasks = 10; // 这里应该从任务表查询
        canUnlock = highQualityTasks >= 10;
        unlockCondition = '完成10个高质量任务';
        break;
      default:
        return res.status(400).json({
          code: 400,
          data: null,
          msg: '不支持的成就类型',
        });
    }

    if (!canUnlock) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: `成就解锁条件未满足：${unlockCondition}`,
      });
    }

    // 解锁成就
    const newAchievementUnlock = [...achievementUnlock, achievementId];
    await Incentive.update(
      {
        achievementUnlock: JSON.stringify(newAchievementUnlock),
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    // 成就奖励（简化处理）
    const reward = { type: 'integral', value: 500 };

    // 增加积分
    await Incentive.update(
      {
        integral: incentiveData.integral + reward.value,
        integralGet: incentiveData.integralGet + reward.value,
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    return res.json({
      code: 200,
      data: {
        achievementId,
        reward,
        achievementUnlock: newAchievementUnlock,
      },
      msg: '成就解锁成功',
    });
  } catch (error) {
    console.error('成就解锁失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 福利领取接口
router.post('/welfare/receive', async (req, res) => {
  try {
    const { userId, petId, welfareType } = req.body;

    if (!userId || !petId || !welfareType) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      return res.status(404).json({
        code: 404,
        data: null,
        msg: '激励数据不存在',
      });
    }

    // 检查福利是否已领取
    const welfareGet = JSON.parse(incentiveData.welfareGet);
    if (welfareGet.some(w => w.type === welfareType && w.date === new Date().toISOString().split('T')[0])) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '今日福利已领取',
      });
    }

    // 领取福利
    const newWelfareGet = [...welfareGet, { type: welfareType, date: new Date().toISOString().split('T')[0] }];
    const reward = { type: 'integral', value: 100 };

    // 增加积分
    await Incentive.update(
      {
        integral: incentiveData.integral + reward.value,
        integralGet: incentiveData.integralGet + reward.value,
        welfareGet: JSON.stringify(newWelfareGet),
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    return res.json({
      code: 200,
      data: {
        welfareType,
        reward,
        welfareGet: newWelfareGet,
      },
      msg: '福利领取成功',
    });
  } catch (error) {
    console.error('福利领取失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 每日签到接口
router.post('/sign-in', async (req, res) => {
  try {
    const { userId, petId } = req.body;

    if (!userId || !petId) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      return res.status(404).json({
        code: 404,
        data: null,
        msg: '激励数据不存在',
      });
    }

    // 检查今日是否已签到
    const welfareGet = JSON.parse(incentiveData.welfareGet);
    const today = new Date().toISOString().split('T')[0];
    const hasSignedToday = welfareGet.some(w => w.type === 'daily_sign' && w.date === today);

    if (hasSignedToday) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '今日已签到',
      });
    }

    // 计算连续签到天数
    let newSignInDays = 1;
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split('T')[0];
    
    const signedYesterday = welfareGet.some(w => w.type === 'daily_sign' && w.date === yesterdayStr);
    if (signedYesterday) {
      newSignInDays = incentiveData.signInDays + 1;
    }

    // 计算签到奖励（连续签到奖励递增）
    let signReward = 10;
    if (newSignInDays >= 7) {
      signReward = 50; // 连续7天奖励50积分
    } else if (newSignInDays >= 3) {
      signReward = 30; // 连续3天奖励30积分
    }

    // 更新签到数据
    const newWelfareGet = [...welfareGet, { type: 'daily_sign', date: today }];
    await Incentive.update(
      {
        integral: incentiveData.integral + signReward,
        integralGet: incentiveData.integralGet + signReward,
        signInDays: newSignInDays,
        welfareGet: JSON.stringify(newWelfareGet),
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    return res.json({
      code: 200,
      data: {
        signInDays: newSignInDays,
        reward: { type: 'integral', value: signReward },
        welfareGet: newWelfareGet,
      },
      msg: '签到成功',
    });
  } catch (error) {
    console.error('签到失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 激励联动接口（任务完成时触发）
router.post('/link', async (req, res) => {
  try {
    const { userId, petId, taskScore, taskQuality } = req.body;

    if (!userId || !petId) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      return res.status(404).json({
        code: 404,
        data: null,
        msg: '激励数据不存在',
      });
    }

    // 计算评估等级基础收益系数
    const abilityLevel = incentiveData.abilityLevel;
    let baseRate = 1.0;
    switch (abilityLevel) {
      case 'S':
        baseRate = 1.5;
        break;
      case 'A':
        baseRate = 1.4;
        break;
      case 'B':
        baseRate = 1.2;
        break;
      case 'C':
        baseRate = 1.0;
        break;
      case 'D':
        baseRate = 0.8;
        break;
      default:
        baseRate = 1.0;
    }

    // 计算任务质量加成
    let qualityRate = 1.0;
    if (taskQuality >= 90) {
      qualityRate = 1.5;
    } else if (taskQuality >= 80) {
      qualityRate = 1.2;
    }

    // 计算总收益系数
    const totalRate = baseRate * qualityRate;

    // 计算基础积分奖励（假设每个任务基础奖励10积分）
    const baseIntegral = 10;
    const finalIntegral = Math.round(baseIntegral * totalRate);

    // 更新激励数据
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
      data: {
        baseRate,
        qualityRate,
        totalRate,
        baseIntegral,
        finalIntegral,
        abilityLevel,
      },
      msg: '激励联动成功',
    });
  } catch (error) {
    console.error('激励联动失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 每周任务奖励接口
router.post('/weekly-task/reward', async (req, res) => {
  try {
    const { userId, petId, weeklyTaskCount } = req.body;

    if (!userId || !petId || weeklyTaskCount === undefined) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      return res.status(404).json({
        code: 404,
        data: null,
        msg: '激励数据不存在',
      });
    }

    // 检查本周是否已领取
    const welfareGet = JSON.parse(incentiveData.welfareGet);
    const currentWeek = _getCurrentWeek();
    const hasReceivedThisWeek = welfareGet.some(w => w.type === 'weekly_task' && w.week === currentWeek);

    if (hasReceivedThisWeek) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '本周奖励已领取',
      });
    }

    // 计算奖励（每周任务完成数量越多，奖励越高）
    let weeklyReward = 0;
    if (weeklyTaskCount >= 20) {
      weeklyReward = 200; // 完成20个任务奖励200积分
    } else if (weeklyTaskCount >= 15) {
      weeklyReward = 150; // 完成15个任务奖励150积分
    } else if (weeklyTaskCount >= 10) {
      weeklyReward = 100; // 完成10个任务奖励100积分
    } else if (weeklyTaskCount >= 5) {
      weeklyReward = 50; // 完成5个任务奖励50积分
    } else {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '每周任务完成数量不足5个',
      });
    }

    // 更新福利数据
    const newWelfareGet = [...welfareGet, { type: 'weekly_task', week: currentWeek, date: new Date().toISOString().split('T')[0] }];
    await Incentive.update(
      {
        integral: incentiveData.integral + weeklyReward,
        integralGet: incentiveData.integralGet + weeklyReward,
        welfareGet: JSON.stringify(newWelfareGet),
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    return res.json({
      code: 200,
      data: {
        weeklyReward,
        weeklyTaskCount,
        currentWeek,
        welfareGet: newWelfareGet,
      },
      msg: '每周任务奖励领取成功',
    });
  } catch (error) {
    console.error('每周任务奖励领取失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 月度等级福利接口
router.post('/monthly-welfare/receive', async (req, res) => {
  try {
    const { userId, petId, abilityLevel } = req.body;

    if (!userId || !petId || !abilityLevel) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      return res.status(404).json({
        code: 404,
        data: null,
        msg: '激励数据不存在',
      });
    }

    // 检查本月是否已领取
    const welfareGet = JSON.parse(incentiveData.welfareGet);
    const currentMonth = _getCurrentMonth();
    const hasReceivedThisMonth = welfareGet.some(w => w.type === 'monthly_welfare' && w.month === currentMonth);

    if (hasReceivedThisMonth) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '本月福利已领取',
      });
    }

    // 计算月度福利（根据评估等级）
    let monthlyReward = 0;
    let monthlyProp = '';
    switch (abilityLevel) {
      case 'S':
        monthlyReward = 500;
        monthlyProp = '专属宝箱碎片';
        break;
      case 'A':
        monthlyReward = 300;
        monthlyProp = '精英宝箱碎片';
        break;
      case 'B':
        monthlyReward = 200;
        monthlyProp = '进阶宝箱碎片';
        break;
      case 'C':
        monthlyReward = 100;
        monthlyProp = '基础宝箱碎片';
        break;
      case 'D':
        monthlyReward = 50;
        monthlyProp = '营养丹';
        break;
      default:
        return res.status(400).json({
          code: 400,
          data: null,
          msg: '不支持的评估等级',
        });
    }

    // 更新福利数据
    const newWelfareGet = [...welfareGet, { type: 'monthly_welfare', month: currentMonth, date: new Date().toISOString().split('T')[0] }];
    await Incentive.update(
      {
        integral: incentiveData.integral + monthlyReward,
        integralGet: incentiveData.integralGet + monthlyReward,
        welfareGet: JSON.stringify(newWelfareGet),
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    return res.json({
      code: 200,
      data: {
        monthlyReward,
        monthlyProp,
        abilityLevel,
        currentMonth,
        welfareGet: newWelfareGet,
      },
      msg: '月度福利领取成功',
    });
  } catch (error) {
    console.error('月度福利领取失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 获取当前周数
function _getCurrentWeek() {
  const now = new Date();
  const startOfYear = new Date(now.getFullYear(), 0, 1);
  const weekNumber = Math.ceil((((now - startOfYear) / 86400000) + startOfYear.getDay() + 1) / 7);
  return `${now.getFullYear()}-W${weekNumber}`;
}

// 获取当前月份
function _getCurrentMonth() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

// 激励偏好同步接口
router.post('/prefer/sync', async (req, res) => {
  try {
    const { userId, petId, preference } = req.body;

    if (!userId || !petId || !preference) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      return res.status(404).json({
        code: 404,
        data: null,
        msg: '激励数据不存在',
      });
    }

    // 解析现有偏好
    const currentPrefer = JSON.parse(incentiveData.incentivePrefer);

    // 更新偏好
    const newPrefer = {
      ...currentPrefer,
      ...preference,
      lastUpdateTime: new Date().toISOString(),
    };

    // 保存偏好
    await Incentive.update(
      {
        incentivePrefer: JSON.stringify(newPrefer),
        updateTime: new Date(),
      },
      { where: { userId, petId } }
    );

    return res.json({
      code: 200,
      data: {
        incentivePrefer: newPrefer,
      },
      msg: '偏好同步成功',
    });
  } catch (error) {
    console.error('偏好同步失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

// 获取激励偏好接口
router.get('/prefer/get', async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.status(400).json({
        code: 400,
        data: null,
        msg: '参数不完整',
      });
    }

    // 查询激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (!incentiveData) {
      return res.status(404).json({
        code: 404,
        data: null,
        msg: '激励数据不存在',
      });
    }

    return res.json({
      code: 200,
      data: {
        incentivePrefer: JSON.parse(incentiveData.incentivePrefer),
      },
      msg: '偏好查询成功',
    });
  } catch (error) {
    console.error('偏好查询失败:', error);
    return res.status(500).json({
      code: 500,
      data: null,
      msg: '服务器错误',
    });
  }
});

module.exports = router;
