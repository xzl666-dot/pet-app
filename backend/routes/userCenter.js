const express = require('express');
const router = express.Router();
const { User, Pet, UserCenter, EvaluationLevel, EvaluationCalc, Incentive, Social } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');

// 模块七：个人中心与设置模块

// 个人核心数据聚合接口
router.get('/core', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 聚合模块1-6核心数据
    const levelData = await EvaluationLevel.findOne({
      where: { userId, petId },
    });

    const petData = await Pet.findOne({
      where: { userId },
    });

    const calcData = await EvaluationCalc.findOne({
      where: { userId, petId },
      order: [['evaluationDate', 'DESC']],
    });

    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    const socialData = await Social.findOne({
      where: { userId, petId },
    });

    const userCenterData = await UserCenter.findOne({
      where: { userId },
    });

    // 生成核心数据卡片
    const coreCard = {
      evaluation: {
        level: levelData?.currentLevel || 'D',
        score: levelData?.currentScore || 0,
        expireTime: levelData?.levelExpireTime,
      },
      pet: {
        level: petData?.level || 1,
        exp: petData?.exp || 0,
        intimacy: petData?.intimacy || 0,
        skillPoint: petData?.skillPoint || 0,
      },
      task: {
        completionCount: calcData?.taskCompletionCount || 0,
        highQualityCount: calcData?.highQualityCount || 0,
        averageQuality: calcData?.qualityScore || 0,
      },
      incentive: {
        integral: incentiveData?.integral || 0,
        chestUnlock: JSON.parse(incentiveData?.chestUnlock || '[]'),
        achievementUnlock: JSON.parse(incentiveData?.achievementUnlock || '[]'),
      },
      social: {
        friendCount: JSON.parse(socialData?.friendList || '[]').length,
        interactNum: (socialData?.likeNum || 0) + (socialData?.helpNum || 0),
        shareNum: JSON.parse(socialData?.shareRecord || '[]').length,
      },
    };

    // 生成本周数据趋势
    const weekStart = moment().startOf('week');
    const weekCalcData = await EvaluationCalc.findAll({
      where: {
        userId,
        petId,
        evaluationDate: {
          [require('sequelize').Op.gte]: weekStart.toDate(),
        },
      },
    });

    const trendData = {
      petGrow: weekCalcData.map(item => item.totalScore),
      taskFinish: weekCalcData.map(item => item.taskCompletionCount),
      integralGet: weekCalcData.map(item => Math.round(item.totalScore * 10)),
    };

    // 获取待办事项
    const toDoList = userCenterData ? JSON.parse(userCenterData.toDoList || '[]') : [];

    // 获取常用入口
    const commonEntry = userCenterData ? JSON.parse(userCenterData.commonEntry || '[]') : [];

    res.json({
      code: 200,
      data: {
        coreCard,
        trendData,
        toDoList,
        commonEntry,
      },
      msg: '个人核心数据查询成功',
    });
  } catch (error) {
    console.error('个人核心数据查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 配置查询接口
router.get('/set/query', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const userCenterData = await UserCenter.findOne({
      where: { userId },
    });

    if (!userCenterData) {
      // 创建默认配置
      const defaultConfig = {
        interactSet: {
          buttonFeedback: true,
          vibrationStrength: 'medium',
          lightEffect: true,
        },
        privacySet: {
          showLevel: true,
          showTaskCount: true,
          showPetLevel: true,
        },
        remindSet: {
          redDot: true,
          banner: true,
          levelChange: true,
          scoreUpdate: true,
        },
        dataSet: {
          syncFrequency: 'daily',
          exportFormat: 'excel',
        },
      };

      const newUserCenterData = await UserCenter.create({
        userId,
        petId: 1, // 默认petId
        interactSet: JSON.stringify(defaultConfig.interactSet),
        privacySet: JSON.stringify(defaultConfig.privacySet),
        remindSet: JSON.stringify(defaultConfig.remindSet),
        dataSet: JSON.stringify(defaultConfig.dataSet),
      });

      return res.json({
        code: 200,
        data: defaultConfig,
        msg: '配置查询成功',
      });
    }

    const config = {
      interactSet: JSON.parse(userCenterData.interactSet || '{}'),
      privacySet: JSON.parse(userCenterData.privacySet || '{}'),
      remindSet: JSON.parse(userCenterData.remindSet || '{}'),
      dataSet: JSON.parse(userCenterData.dataSet || '{}'),
    };

    res.json({
      code: 200,
      data: config,
      msg: '配置查询成功',
    });
  } catch (error) {
    console.error('配置查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 配置保存接口
router.post('/set/save', authMiddleware, async (req, res) => {
  try {
    const { userId, interactSet, privacySet, remindSet, dataSet } = req.body;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const userCenterData = await UserCenter.findOne({
      where: { userId },
    });

    const updateData = {
      updateTime: new Date(),
    };

    if (interactSet) {
      updateData.interactSet = JSON.stringify(interactSet);
    }
    if (privacySet) {
      updateData.privacySet = JSON.stringify(privacySet);
    }
    if (remindSet) {
      updateData.remindSet = JSON.stringify(remindSet);
    }
    if (dataSet) {
      updateData.dataSet = JSON.stringify(dataSet);
    }

    if (userCenterData) {
      await UserCenter.update(updateData, { where: { userId } });
    } else {
      await UserCenter.create({
        userId,
        petId: 1,
        ...updateData,
      });
    }

    // 同步配置至对应模块
    if (privacySet) {
      const socialData = await Social.findOne({
        where: { userId },
      });

      if (socialData) {
        await Social.update(
          { rankPrivacy: JSON.stringify(privacySet) },
          { where: { userId } }
        );
      }
    }

    res.json({
      code: 200,
      data: {
        message: '设置已生效',
        syncModules: ['social'],
      },
      msg: '配置保存成功',
    });
  } catch (error) {
    console.error('配置保存失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 数据报表导出接口
router.post('/data/export', authMiddleware, async (req, res) => {
  try {
    const { userId, moduleType, timeType, fileFormat } = req.body;

    if (!userId || !moduleType || !timeType || !fileFormat) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 根据模块类型统计数据
    let exportData = [];
    let fileName = '';

    if (moduleType === 'evaluation') {
      const calcData = await EvaluationCalc.findAll({
        where: { userId },
      });
      exportData = calcData.map(item => ({
        日期: moment(item.evaluationDate).format('YYYY-MM-DD HH:mm:ss'),
        准确率: `${item.accuracy}%`,
        完成效率: `${item.completionEfficiency}%`,
        质量评分: item.qualityScore,
        总分: item.totalScore,
        任务完成数: item.taskCompletionCount,
        高质量任务数: item.highQualityCount,
      }));
      fileName = '评估数据报表';
    } else if (moduleType === 'task') {
      const tasks = await Task.findAll({
        where: { userId },
      });
      exportData = tasks.map(item => ({
        任务名称: item.name,
        难度: item.difficulty,
        截止时间: moment.unix(item.deadline).format('YYYY-MM-DD HH:mm:ss'),
        完成状态: item.is_completed === 1 ? '已完成' : '未完成',
        完成时间: item.completed_at ? moment.unix(item.completed_at).format('YYYY-MM-DD HH:mm:ss') : '',
      }));
      fileName = '任务数据报表';
    } else if (moduleType === 'incentive') {
      const incentiveData = await Incentive.findOne({
        where: { userId },
      });
      exportData = [{
        当前积分: incentiveData?.integral || 0,
        积分获取: incentiveData?.integralGet || 0,
        积分消耗: incentiveData?.integralConsume || 0,
        宝箱解锁: JSON.parse(incentiveData?.chestUnlock || '[]').join(','),
        成就解锁: JSON.parse(incentiveData?.achievementUnlock || '[]').join(','),
      }];
      fileName = '激励数据报表';
    } else if (moduleType === 'social') {
      const socialData = await Social.findOne({
        where: { userId },
      });
      exportData = [{
        好友数: JSON.parse(socialData?.friendList || '[]').length,
        今日点赞数: socialData?.likeNum || 0,
        今日助力数: socialData?.helpNum || 0,
        分享记录数: JSON.parse(socialData?.shareRecord || '[]').length,
      }];
      fileName = '社交数据报表';
    } else {
      return res.json({ code: 400, data: {}, msg: '无效的模块类型' });
    }

    // 生成CSV格式数据
    const csvData = exportData.map(item => Object.values(item).join(',')).join('\n');
    const csvContent = Object.keys(exportData[0]).join(',') + '\n' + csvData;

    // 记录导出记录
    const userCenterData = await UserCenter.findOne({
      where: { userId },
    });

    if (userCenterData) {
      const dataExportRecord = userCenterData.dataExportRecord ? JSON.parse(userCenterData.dataExportRecord) : [];
      dataExportRecord.push({
        moduleType,
        timeType,
        fileFormat,
        exportTime: new Date().toISOString(),
      });

      await UserCenter.update(
        { dataExportRecord: JSON.stringify(dataExportRecord) },
        { where: { userId } }
      );
    }

    res.json({
      code: 200,
      data: {
        fileName: `${fileName}_${moment().format('YYYY-MM-DD')}.${fileFormat}`,
        content: csvContent,
        recordCount: exportData.length,
      },
      msg: '数据报表导出成功',
    });
  } catch (error) {
    console.error('数据报表导出失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 信息修改接口
router.post('/info/edit', authMiddleware, async (req, res) => {
  try {
    const { userId, nickname, avatar, signature } = req.body;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const updateData = {
      updateTime: new Date(),
    };

    if (nickname) {
      updateData.nickname = nickname;
    }
    if (avatar) {
      updateData.avatar = avatar;
    }
    if (signature) {
      updateData.signature = signature;
    }

    const userCenterData = await UserCenter.findOne({
      where: { userId },
    });

    if (userCenterData) {
      await UserCenter.update(updateData, { where: { userId } });
    } else {
      await UserCenter.create({
        userId,
        petId: 1,
        ...updateData,
      });
    }

    // 同步至User表
    if (nickname || avatar) {
      const userUpdateData = {};
      if (nickname) userUpdateData.nickname = nickname;
      if (avatar) userUpdateData.avatar = avatar;

      await User.update(userUpdateData, { where: { userId } });
    }

    res.json({
      code: 200,
      data: {
        message: '信息修改成功，已同步至所有模块',
        syncModules: ['user', 'social', 'rank'],
      },
      msg: '信息修改成功',
    });
  } catch (error) {
    console.error('信息修改失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 密码修改接口
router.post('/pwd/change', authMiddleware, async (req, res) => {
  try {
    const { userId, oldPassword, newPassword, confirmPassword } = req.body;

    if (!userId || !oldPassword || !newPassword || !confirmPassword) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    if (newPassword !== confirmPassword) {
      return res.json({ code: 400, data: {}, msg: '两次输入的新密码不一致' });
    }

    if (newPassword.length < 6) {
      return res.json({ code: 400, data: {}, msg: '新密码长度不能少于6位' });
    }

    const user = await User.findOne({
      where: { userId },
    });

    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    // 验证旧密码
    const crypto = require('crypto');
    const oldPasswordHash = crypto.createHash('sha256').update(oldPassword).digest('hex');
    if (user.password !== oldPasswordHash) {
      return res.json({ code: 400, data: {}, msg: '旧密码错误' });
    }

    // 更新新密码
    const newPasswordHash = crypto.createHash('sha256').update(newPassword).digest('hex');
    await User.update(
      { password: newPasswordHash },
      { where: { userId } }
    );

    res.json({
      code: 200,
      data: {
        message: '密码修改成功，请重新登录',
      },
      msg: '密码修改成功',
    });
  } catch (error) {
    console.error('密码修改失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

module.exports = router;