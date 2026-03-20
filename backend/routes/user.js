const express = require('express');
const router = express.Router();
const { User, Social, Pet, ChallengeRecord } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');
const bcrypt = require('bcryptjs');
const { generateDoubleToken } = require('../utils/jwt');

// 检查用户名是否存在（仅优化版）
router.get('/check-username', async (req, res) => {
  try {
    const { username } = req.query;

    if (!username) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const user = await User.findOne({ where: { phone: username } });
    if (user) {
      res.json({ code: 200, data: { exists: true }, msg: '用户名存在' });
    } else {
      res.json({ code: 400, data: { exists: false }, msg: '用户名不存在' });
    }
  } catch (error) {
    console.error('检查用户名失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 注册接口（仅优化版）
router.post('/register', async (req, res) => {
  try {
    const { username, password, nickname, versionType } = req.body;

    if (!username || !password || parseInt(versionType) !== 1) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 校验密码长度
    if (password.length < 6) {
      return res.json({ code: 400, data: {}, msg: '密码长度不足6位' });
    }

    // 唯一性校验
    const existingUser = await User.findOne({ where: { phone: username } });
    if (existingUser) {
      return res.json({ code: 400, data: {}, msg: '该用户名已注册，请直接登录' });
    }

    // 密码加密
    const hashedPassword = await bcrypt.hash(password, 10);

    // 数据插入
    const user = await User.create({
      nickname: nickname || '萌宠主人',
      phone: username,
      password: hashedPassword,
      versionType: 1,
      createTime: new Date(),
      lastLoginTime: new Date(),
    });

    // 根据要求，新用户流程为：注册-登录-挑选宠物
    // 因此注册时不自动创建宠物和社交记录，由用户登录后自行挑选

    // 确保新用户没有任何预设的挑战记录或社交数据
    // 彻底清理可能存在的脏数据
    try {
      const { ChallengeRecord, Social, Pet, Incentive, EvaluationCalc, EvaluationLevel, CheckIn, Achievement, FriendRequest, Task } = require('../models');
      const userId = user.userId;
      await ChallengeRecord.destroy({ where: { userId } });
      await Social.destroy({ where: { userId } });
      await Pet.destroy({ where: { userId } });
      await Incentive.destroy({ where: { userId } });
      await EvaluationCalc.destroy({ where: { userId } });
      await EvaluationLevel.destroy({ where: { userId } });
      await CheckIn.destroy({ where: { userId } });
      await Achievement.destroy({ where: { userId } });
      await Task.destroy({ where: { userId } });
      // 清理好友申请
      const { Op } = require('sequelize');
      await FriendRequest.destroy({
        where: {
          [Op.or]: [{ senderId: userId }, { targetId: userId }]
        }
      });
    } catch (e) {
      console.warn('清理新用户预设数据失败 (非致命):', e.message);
    }

    res.json({
      code: 200,
      data: {
        userId: user.userId,
        phone: user.phone,
        nickname: user.nickname,
      },
      msg: '注册成功，请登录',
    });
  } catch (error) {
    console.error('注册失败:', error);
    res.json({ code: 500, data: {}, msg: '注册失败，请重试' });
  }
});

// 登录接口（双版本通用）
router.post('/login', async (req, res) => {
  try {
    const { userId, username, password, versionType } = req.body;

    if (!versionType) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    let user;

    // 版本适配
    if (versionType === 0) {
      // 基础版（游客登录）
      user = await User.findOne({ where: { userId: 0 } });
      if (!user) {
        // 自动创建游客账号
        user = await User.create({
          userId: 0,
          nickname: '萌宠主人',
          versionType: 0,
          createTime: new Date(),
          lastLoginTime: new Date(),
        });
      }
    } else {
      // 优化版（用户名登录）
      if (!username || !password) {
        return res.json({ code: 400, data: {}, msg: '参数错误' });
      }

      user = await User.findOne({ where: { phone: username } });
      if (!user) {
        return res.json({ code: 400, data: {}, msg: '用户名或密码错误' });
      }

      // 校验密码
      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        return res.json({ code: 400, data: {}, msg: '用户名或密码错误' });
      }
    }

    // 更新登录时间
    user.lastLoginTime = new Date();
    await user.save();

    // 生成JWT双令牌
    const tokenData = generateDoubleToken(user.userId, 'web_device');

    // 获取用户的宠物ID
    const pet = await Pet.findOne({ where: { userId: user.userId } });

    res.json({
      code: 200,
      data: {
        userId: user.userId,
        nickname: user.nickname,
        avatar: user.avatar,
        petId: pet ? pet.petId : null,
        accessToken: tokenData.accessToken,
        accessExpire: moment(tokenData.accessExpire).unix(),
        refreshToken: tokenData.refreshToken,
        refreshExpire: moment(tokenData.refreshExpire).unix(),
        versionType: user.versionType,
      },
      msg: '登录成功',
    });
  } catch (error) {
    console.error('登录失败:', error);
    res.json({ code: 500, data: {}, msg: '登录失败，请重试' });
  }
});

// 退出接口（仅优化版）
router.post('/logout', async (req, res) => {
  try {
    const { userId, token, versionType } = req.body;

    if (!userId || !token || versionType !== 1) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查找用户
    const user = await User.findOne({ where: { userId, token } });
    if (!user) {
      return res.json({ code: 401, data: {}, msg: '令牌无效或已过期，请重新登录' });
    }

    // 令牌清空
    user.token = null;
    user.tokenExpire = null;
    await user.save();

    res.json({ code: 200, data: {}, msg: '退出成功' });
  } catch (error) {
    console.error('退出失败:', error);
    res.json({ code: 500, data: {}, msg: '退出失败，请重试' });
  }
});

// 密码找回接口（仅优化版）
router.post('/reset-password', async (req, res) => {
  try {
    const { username, password, versionType } = req.body;

    if (!username || !password || versionType !== 1) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 校验密码长度
    if (password.length < 6) {
      return res.json({ code: 400, data: {}, msg: '密码长度不足6位' });
    }

    // 用户名校验
    const user = await User.findOne({ where: { phone: username } });
    if (!user) {
      return res.json({ code: 400, data: {}, msg: '该用户名未注册，请先注册' });
    }

    // 密码更新
    const hashedPassword = await bcrypt.hash(password, 10);
    user.password = hashedPassword;
    await user.save();

    res.json({ code: 200, data: {}, msg: '密码修改成功，请重新登录' });
  } catch (error) {
    console.error('密码找回失败:', error);
    res.json({ code: 500, data: {}, msg: '密码找回失败，请重试' });
  }
});

// 个人信息查询接口（双版本通用）
router.get('/info', async (req, res) => {
  try {
    const { userId, versionType, token } = req.query;

    if (!userId || !versionType) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 优化版令牌校验
    if (versionType === '1' && token) {
      const user = await User.findOne({ where: { userId, token } });
      if (!user || user.tokenExpire < new Date()) {
        return res.json({ code: 401, data: {}, msg: '令牌无效或已过期' });
      }
    }

    // 数据查询
    const user = await User.findOne({ where: { userId } });
    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    // 不返回密码字段
    const userInfo = {
      userId: user.userId,
      nickname: user.nickname,
      avatar: user.avatar,
      phone: user.phone,
      isVip: user.isVip,
      vipExpire: user.vipExpire,
      versionType: user.versionType,
      createTime: user.createTime,
      lastLoginTime: user.lastLoginTime,
    };

    res.json({
      code: 200,
      data: userInfo,
      msg: '查询成功',
    });
  } catch (error) {
    console.error('信息查询失败:', error);
    res.json({ code: 500, data: {}, msg: '信息查询失败，请重试' });
  }
});

// 个人信息修改接口（双版本通用）
router.post('/update', async (req, res) => {
  try {
    const { userId, versionType, token, nickname, avatar } = req.body;

    if (!userId || !versionType) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 优化版令牌校验
    if (versionType === 1 && token) {
      const user = await User.findOne({ where: { userId, token } });
      if (!user || user.tokenExpire < new Date()) {
        return res.json({ code: 401, data: {}, msg: '令牌无效或已过期' });
      }
    }

    // 数据更新
    const user = await User.findOne({ where: { userId } });
    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    if (nickname) user.nickname = nickname;
    if (avatar) user.avatar = avatar;
    await user.save();

    res.json({
      code: 200,
      data: {
        nickname: user.nickname,
        avatar: user.avatar,
      },
      msg: '信息修改成功',
    });
  } catch (error) {
    console.error('信息修改失败:', error);
    res.json({ code: 500, data: {}, msg: '信息修改失败，请重试' });
  }
});

// 修改密码
router.post('/change-pwd', async (req, res) => {
  try {
    const { userId, oldPassword, newPassword, versionType, token } = req.body;

    if (!userId || !oldPassword || !newPassword || !versionType) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 优化版令牌校验
    if (versionType === 1 && token) {
      const user = await User.findOne({ where: { userId, token } });
      if (!user || user.tokenExpire < new Date()) {
        return res.json({ code: 401, data: {}, msg: '令牌无效或已过期' });
      }
    }

    // 查找用户
    const user = await User.findByPk(userId);
    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    // 校验原密码
    const isPasswordValid = await bcrypt.compare(oldPassword, user.password);
    if (!isPasswordValid) {
      return res.json({ code: 400, data: {}, msg: '原密码错误' });
    }

    // 更新密码
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    res.json({ code: 200, data: {}, msg: '密码修改成功，请重新登录' });
  } catch (error) {
    console.error('修改密码失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

module.exports = router;
