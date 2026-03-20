const express = require('express');
const router = express.Router();
const { User, UserState } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');

// 状态识别
router.get('/recognize', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    // 查找用户
    const user = await User.findByPk(userId);
    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    // 检查手动标记状态是否有效
    if (user.manualState !== -1 && user.manualStateExpire) {
      const now = moment();
      const expireTime = moment(user.manualStateExpire);
      if (now.isBefore(expireTime)) {
        // 手动标记状态有效
        const stateName = user.manualState === 0 ? '正常' :
                          user.manualState === 1 ? '疲惫' :
                          user.manualState === 2 ? '懈怠' : '专注';

        return res.json({
          code: 200,
          data: {
            stateCode: user.manualState,
            stateName,
            coreFeature: '',
            isManual: true,
            expireTime: user.manualStateExpire,
          },
          msg: '操作成功',
        });
      }
    }

    // 手动标记状态无效，重置
    await user.update({
      manualState: -1,
      manualStateExpire: null,
    });

    // 模拟自动识别状态（实际应基于用户行为数据）
    const stateCode = 0; // 默认正常
    const stateName = '正常';
    const coreFeature = '任务完成率≥80%，效率≥平均水平';

    // 记录状态
    await UserState.create({
      userId,
      stateCode,
      stateName,
      coreFeature,
      isManual: 0,
      recognizeTime: moment().format('YYYY-MM-DD HH:mm:ss'),
      expireTime: null,
      adaptStrategy: '正常推荐任务（跳一跳够得着）',
    });

    res.json({
      code: 200,
      data: {
        stateCode,
        stateName,
        coreFeature,
        isManual: false,
        expireTime: null,
      },
      msg: '操作成功',
    });
  } catch (error) {
    console.error('状态识别失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 手动标记状态
router.post('/manual', authMiddleware, async (req, res) => {
  try {
    const { stateCode } = req.body;
    const userId = req.userId;

    if (stateCode === undefined || stateCode < 0 || stateCode > 3) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查找用户
    const user = await User.findByPk(userId);
    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    let expireTime = null;
    if (stateCode === 0) {
      // 正常状态，清空手动标记
      await user.update({
        manualState: -1,
        manualStateExpire: null,
      });
    } else {
      // 其他状态，设置2小时有效期
      expireTime = moment().add(2, 'hours').toDate();
      await user.update({
        manualState: stateCode,
        manualStateExpire: expireTime,
      });
    }

    const stateName = stateCode === 0 ? '正常' :
                      stateCode === 1 ? '疲惫' :
                      stateCode === 2 ? '懈怠' : '专注';

    const adaptStrategy = stateCode === 0 ? '正常推荐任务（跳一跳够得着）' :
                          stateCode === 1 ? '推荐轻量任务，减少任务量' :
                          stateCode === 2 ? '推荐趣味型任务，增加即时反馈' :
                          '推荐进阶任务，提升宠物收益';

    // 记录状态
    await UserState.create({
      userId,
      stateCode,
      stateName,
      coreFeature: '',
      isManual: 1,
      recognizeTime: moment().format('YYYY-MM-DD HH:mm:ss'),
      expireTime: expireTime,
      adaptStrategy,
    });

    res.json({
      code: 200,
      data: {
        stateCode,
        stateName,
        expireTime: expireTime,
        adaptStrategy,
      },
      msg: '操作成功',
    });
  } catch (error) {
    console.error('手动标记状态失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

module.exports = router;
