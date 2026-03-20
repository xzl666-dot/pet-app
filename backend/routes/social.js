const express = require('express');
const router = express.Router();
const { User, Pet, Social, EvaluationLevel, EvaluationCalc, Incentive, PetAdvance, PetAlbum, FriendRequest } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');
const sequelize = require('sequelize');

// 模块六：社交互动模块

// 社交核心数据接口
router.get('/core', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const socialData = await Social.findOne({
      where: { userId, petId },
    });

    if (!socialData) {
      // 创建默认社交数据
      const newSocialData = await Social.create({
        userId,
        petId,
        friendList: JSON.stringify([]),
        likeNum: 0,
        helpNum: 0,
        beLikedNum: 0,
        beHelpedNum: 0,
        shareRecord: JSON.stringify([]),
        rankScore: 0,
        rankPrivacy: JSON.stringify({
          showLevel: true,
          showTaskCount: true,
          showPetLevel: true,
        }),
      });

      return res.json({
        code: 200,
        data: {
          friendList: [],
          interactInfo: {
            likeNum: 0,
            helpNum: 0,
            beLikedNum: 0,
            beHelpedNum: 0,
            maxLikeNum: 10,
            maxHelpNum: 5,
          },
          shareRecord: [],
          privacySet: {
            showLevel: true,
            showTaskCount: true,
            showPetLevel: true,
          },
          canInteract: true,
        },
        msg: '社交核心数据查询成功',
      });
    }

    const friendList = JSON.parse(socialData.friendList || '[]');
    const shareRecord = JSON.parse(socialData.shareRecord || '[]');
    const privacySet = JSON.parse(socialData.rankPrivacy || '{}');

    // 检查今日互动次数是否超限
    const today = moment().format('YYYY-MM-DD');
    const todayLikeNum = socialData.likeNum;
    const todayHelpNum = socialData.helpNum;
    const canInteract = todayLikeNum < 10 && todayHelpNum < 5;

    res.json({
      code: 200,
      data: {
        friendList,
        interactInfo: {
          likeNum: todayLikeNum,
          helpNum: todayHelpNum,
          beLikedNum: socialData.beLikedNum,
          beHelpedNum: socialData.beHelpedNum,
          maxLikeNum: 10,
          maxHelpNum: 5,
        },
        shareRecord,
        privacySet,
        canInteract,
      },
      msg: '社交核心数据查询成功',
    });
  } catch (error) {
    console.error('社交核心数据查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 好友点赞接口
router.post('/friend/like', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, friendId } = req.body;

    if (!userId || !petId || !friendId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取当前用户社交数据
    const socialData = await Social.findOne({
      where: { userId, petId },
    });

    if (!socialData) {
      return res.json({ code: 400, data: {}, msg: '社交数据不存在' });
    }

    // 检查今日点赞次数是否超限
    if (socialData.likeNum >= 10) {
      return res.json({ code: 400, data: {}, msg: '今日点赞次数已用完，明日恢复' });
    }

    // 更新点赞数
    await Social.update(
      { likeNum: socialData.likeNum + 1 },
      { where: { userId, petId } }
    );

    // 更新好友被点赞数
    const friendSocialData = await Social.findOne({
      where: { userId: friendId },
    });

    if (friendSocialData) {
      await Social.update(
        { beLikedNum: friendSocialData.beLikedNum + 1 },
        { where: { userId: friendId } }
      );
    }

    // 给双方发放额外宠物经验
    const expReward = 10;
    await Pet.update(
      { exp: sequelize.literal(`exp + ${expReward}`) },
      { where: { userId, petId } }
    );

    if (friendSocialData) {
      const friendPet = await Pet.findOne({
        where: { userId: friendId },
      });

      if (friendPet) {
        await Pet.update(
          { exp: sequelize.literal(`exp + ${expReward}`) },
          { where: { userId: friendId } }
        );
      }
    }

    res.json({
      code: 200,
      data: {
        likeNum: socialData.likeNum + 1,
        expReward,
        message: '点赞成功！双方获得10点宠物经验',
      },
      msg: '点赞成功',
    });
  } catch (error) {
    console.error('好友点赞失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 好友助力接口
router.post('/friend/help', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, friendId } = req.body;

    if (!userId || !petId || !friendId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取当前用户社交数据
    const socialData = await Social.findOne({
      where: { userId, petId },
    });

    if (!socialData) {
      return res.json({ code: 400, data: {}, msg: '社交数据不存在' });
    }

    // 检查今日助力次数是否超限
    if (socialData.helpNum >= 5) {
      return res.json({ code: 400, data: {}, msg: '今日助力次数已用完，明日恢复' });
    }

    // 检查好友是否拒绝助力
    const friendSocialData = await Social.findOne({
      where: { userId: friendId },
    });

    const privacySet = friendSocialData ? JSON.parse(friendSocialData.rankPrivacy || '{}') : {};
    if (privacySet.rejectHelp) {
      return res.json({ code: 400, data: {}, msg: '对方拒绝助力' });
    }

    // 更新助力数
    await Social.update(
      { helpNum: socialData.helpNum + 1 },
      { where: { userId, petId } }
    );

    // 更新好友被助力数
    if (friendSocialData) {
      await Social.update(
        { beHelpedNum: friendSocialData.beHelpedNum + 1 },
        { where: { userId: friendId } }
      );
    }

    // 给双方发放额外积分
    const integralReward = 20;
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

    if (friendSocialData) {
      const friendIncentiveData = await Incentive.findOne({
        where: { userId: friendId },
      });

      if (friendIncentiveData) {
        await Incentive.update(
          {
            integral: (friendIncentiveData.integral || 0) + integralReward,
            integralGet: (friendIncentiveData.integralGet || 0) + integralReward,
            updateTime: new Date(),
          },
          { where: { userId: friendId } }
        );
      }
    }

    res.json({
      code: 200,
      data: {
        helpNum: socialData.helpNum + 1,
        integralReward,
        message: '助力成功！双方获得20积分',
      },
      msg: '助力成功',
    });
  } catch (error) {
    console.error('好友助力失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 成果分享接口
router.post('/share', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, shareType, shareContent } = req.body;

    if (!userId || !petId || !shareType || !shareContent) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 校验成果是否为可分享类型
    const validShareTypes = ['pet_level', 'skill_unlock', 'high_quality_task', 'rare_achievement', 'rare_chest'];
    if (!validShareTypes.includes(shareType)) {
      return res.json({ code: 400, data: {}, msg: '无效的分享类型' });
    }

    // 获取社交数据
    const socialData = await Social.findOne({
      where: { userId, petId },
    });

    const shareRecord = socialData ? JSON.parse(socialData.shareRecord || '[]') : [];

    // 生成分享记录
    const newShare = {
      id: Date.now(),
      shareType,
      shareContent,
      shareTime: new Date().toISOString(),
      likeCount: 0,
    };

    shareRecord.push(newShare);

    // 更新社交数据
    if (socialData) {
      await Social.update(
        { shareRecord: JSON.stringify(shareRecord) },
        { where: { userId, petId } }
      );
    } else {
      await Social.create({
        userId,
        petId,
        friendList: JSON.stringify([]),
        shareRecord: JSON.stringify(shareRecord),
        rankPrivacy: JSON.stringify({}),
      });
    }

    // 给分享者发放基础分享奖励
    const integralReward = 10;
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
          shareType,
          shareContent,
          shareTime: newShare.shareTime,
          likeCount: 0,
        },
        shareLink: `https://app.example.com/share/${newShare.id}`,
        shareQr: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
        reward: integralReward,
      },
      msg: '成果分享成功',
    });
  } catch (error) {
    console.error('成果分享失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 排行榜查询接口
router.get('/rank', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, rankType, timeType } = req.query;

    if (!userId || !petId || !rankType) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    let orderField = '';
    if (rankType === 'level') {
      orderField = 'abilityLevel';
    } else if (rankType === 'task') {
      orderField = 'taskCompletionCount';
    } else if (rankType === 'pet') {
      orderField = 'level';
    } else {
      return res.json({ code: 400, data: {}, msg: '无效的排行榜类型' });
    }

    // 查询排行榜数据
    let query = `
      SELECT u.userId, u.nickname, u.avatar, p.level, p.abilityLevel, e.taskCompletionCount
      FROM users u
      JOIN pets p ON u.userId = p.userId
      JOIN evaluation_calc e ON u.userId = e.userId
      ORDER BY ${orderField} DESC
      LIMIT 100
    `;

    const rankList = await sequelize.query(query, { type: sequelize.QueryTypes.SELECT });

    // 查询用户自身排名
    const userRank = rankList.findIndex(item => item.userId === parseInt(userId)) + 1;

    // 查询用户数据
    const userData = await User.findOne({
      where: { userId },
      attributes: ['userId', 'nickname', 'avatar'],
    });

    const petData = await Pet.findOne({
      where: { userId },
    });

    const calcData = await EvaluationCalc.findOne({
      where: { userId },
    });

    // 计算与上一名的差距
    let gapToPrevious = null;
    if (userRank > 1 && userRank <= 100) {
      const previousUser = rankList[userRank - 2];
      if (previousUser) {
        if (rankType === 'level') {
          gapToPrevious = _compareLevel(previousUser.abilityLevel, petData?.abilityLevel || 'D');
        } else if (rankType === 'task') {
          gapToPrevious = previousUser.taskCompletionCount - (calcData?.taskCompletionCount || 0);
        } else if (rankType === 'pet') {
          gapToPrevious = previousUser.level - (petData?.level || 1);
        }
      }
    }

    res.json({
      code: 200,
      data: {
        rankList: rankList.map((item, index) => ({
          rank: index + 1,
          userId: item.userId,
          nickname: item.nickname,
          avatar: item.avatar,
          petLevel: item.level,
          abilityLevel: item.abilityLevel,
          taskCompletionCount: item.taskCompletionCount,
          isTop3: index < 3,
          isTop10: index < 10,
        })),
        userRank,
        userData: {
          userId: userData?.userId,
          nickname: userData?.nickname,
          avatar: userData?.avatar,
          petLevel: petData?.level,
          abilityLevel: petData?.abilityLevel,
          taskCompletionCount: calcData?.taskCompletionCount || 0,
        },
        gapToPrevious,
      },
      msg: '排行榜查询成功',
    });
  } catch (error) {
    console.error('排行榜查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 排行榜奖励领取接口
router.post('/rank/receive', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.body;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查询用户昨日排名（这里简化处理，实际应该查询昨日排名）
    const userRank = 1; // 暂时设为1

    let rewardType = '';
    let rewardValue = 0;

    if (userRank >= 1 && userRank <= 3) {
      rewardType = 'exclusive';
      rewardValue = 100;
    } else if (userRank >= 4 && userRank <= 10) {
      rewardType = 'elite';
      rewardValue = 50;
    } else if (userRank >= 11 && userRank <= 100) {
      rewardType = 'basic';
      rewardValue = 20;
    } else {
      return res.json({ code: 400, data: {}, msg: '昨日未上榜，无法领取奖励' });
    }

    // 更新激励数据
    const incentiveData = await Incentive.findOne({
      where: { userId, petId },
    });

    if (incentiveData) {
      const chestUnlock = JSON.parse(incentiveData.chestUnlock || '[]');
      if (!chestUnlock.includes(rewardType)) {
        chestUnlock.push(rewardType);
      }

      await Incentive.update(
        {
          integral: (incentiveData.integral || 0) + rewardValue,
          integralGet: (incentiveData.integralGet || 0) + rewardValue,
          chestUnlock: JSON.stringify(chestUnlock),
          updateTime: new Date(),
        },
        { where: { userId, petId } }
      );
    }

    res.json({
      code: 200,
      data: {
        rewardType,
        rewardValue,
        message: `领取成功！获得${rewardValue}积分和${rewardType}宝箱`,
      },
      msg: '排行榜奖励领取成功',
    });
  } catch (error) {
    console.error('排行榜奖励领取失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 隐私设置接口
router.post('/set/privacy', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, privacySet } = req.body;

    if (!userId || !petId || !privacySet) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    const socialData = await Social.findOne({
      where: { userId, petId },
    });

    if (socialData) {
      await Social.update(
        { rankPrivacy: JSON.stringify(privacySet) },
        { where: { userId, petId } }
      );
    } else {
      await Social.create({
        userId,
        petId,
        rankPrivacy: JSON.stringify(privacySet),
      });
    }

    res.json({
      code: 200,
      data: {
        privacySet,
        message: '隐私设置已生效',
      },
      msg: '隐私设置成功',
    });
  } catch (error) {
    console.error('隐私设置失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 社交与激励联动接口
router.post('/link/incentive', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, socialType, socialData } = req.body;

    if (!userId || !petId || !socialType || !socialData) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    let integralReward = 0;
    let chestUnlock = null;

    // 根据社交类型计算奖励
    if (socialType === 'like') {
      integralReward = 5;
    } else if (socialType === 'help') {
      integralReward = 20;
    } else if (socialType === 'share') {
      integralReward = 10;
    } else if (socialType === 'rank') {
      const rank = socialData.rank || 0;
      if (rank >= 1 && rank <= 3) {
        chestUnlock = 'exclusive';
        integralReward = 100;
      } else if (rank >= 4 && rank <= 10) {
        chestUnlock = 'elite';
        integralReward = 50;
      } else if (rank >= 11 && rank <= 100) {
        chestUnlock = 'basic';
        integralReward = 20;
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
        message: '社交激励联动成功',
      },
      msg: '社交激励联动成功',
    });
  } catch (error) {
    console.error('社交激励联动失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 搜索用户接口
router.get('/search-user', authMiddleware, async (req, res) => {
  try {
    const { keyword } = req.query;

    if (!keyword) {
      return res.json({ code: 400, data: { users: [] }, msg: '请输入搜索关键词' });
    }

    const { Op } = require('sequelize');
    const users = await User.findAll({
      where: {
        [Op.or]: [
          { nickname: { [Op.like]: `%${keyword}%` } },
          { phone: { [Op.like]: `%${keyword}%` } }
        ]
      },
      attributes: ['userId', 'nickname', 'avatar'],
      limit: 20
    });

    // 获取每个用户的宠物信息
    const usersWithDetails = await Promise.all(users.map(async (user) => {
      const pet = await Pet.findOne({
        where: { userId: user.userId },
        attributes: ['level', 'abilityLevel']
      });
      
      return {
        userId: user.userId.toString(),
        nickname: user.nickname,
        avatar: user.avatar || '',
        major: '学生', 
        grade: pet ? `等级 ${pet.level}` : '新用户',
        abilityLevel: pet ? pet.abilityLevel : 'D'
      };
    }));

    res.json({
      code: 200,
      data: { users: usersWithDetails },
      msg: '搜索成功'
    });
  } catch (error) {
    console.error('搜索用户失败:', error);
    res.json({ code: 500, data: { users: [] }, msg: '服务器错误' });
  }
});

// 好友申请创建接口
router.post('/add-friend', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, targetNickname } = req.body;

    if (!userId || !petId || !targetNickname) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查找目标用户 (支持昵称或手机号/用户名)
    const { Op } = require('sequelize');
    const targetUser = await User.findOne({
      where: {
        [Op.or]: [
          { nickname: targetNickname },
          { phone: targetNickname }
        ]
      }
    });

    if (!targetUser) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    if (targetUser.userId === parseInt(userId)) {
      return res.json({ code: 400, data: {}, msg: '不能添加自己为好友' });
    }

    // 检查是否已经是好友
    const socialData = await Social.findOne({
      where: { userId, petId }
    });

    const friendList = socialData ? JSON.parse(socialData.friendList || '[]') : [];
    if (friendList.some(friend => friend.userId === targetUser.userId.toString())) {
      return res.json({ code: 400, data: {}, msg: '已经是好友' });
    }

    // 检查是否已经发送过申请
    const existingRequest = await FriendRequest.findOne({
      where: {
        senderId: userId,
        targetId: targetUser.userId,
        status: 'pending'
      }
    });

    if (existingRequest) {
      return res.json({ code: 400, data: {}, msg: '已经发送过好友申请' });
    }

    // 创建好友申请
    const newRequest = await FriendRequest.create({
      senderId: userId,
      targetId: targetUser.userId,
      status: 'pending'
    });

    res.json({
      code: 200,
      data: {
        requestId: newRequest.id,
        message: '好友申请发送成功'
      },
      msg: '好友申请发送成功'
    });
  } catch (error) {
    console.error('好友申请发送失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 获取好友申请列表接口
router.get('/friend-requests', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 收到的申请
    const receivedRequests = await FriendRequest.findAll({
      where: {
        targetId: userId,
        status: 'pending'
      }
    });

    const receivedWithSender = await Promise.all(receivedRequests.map(async (req) => {
      const sender = await User.findOne({ where: { userId: req.senderId }, attributes: ['userId', 'nickname', 'avatar'] });
      return {
        id: req.id,
        senderId: req.senderId,
        senderNickname: sender?.nickname || '未知用户',
        senderAvatar: sender?.avatar || '',
        createdAt: req.createTime
      };
    }));

    // 发出的申请
    const sentRequests = await FriendRequest.findAll({
      where: {
        senderId: userId,
        status: 'pending'
      }
    });

    const sentWithReceiver = await Promise.all(sentRequests.map(async (req) => {
      const receiver = await User.findOne({ where: { userId: req.targetId }, attributes: ['userId', 'nickname', 'avatar'] });
      return {
        id: req.id,
        receiverId: req.targetId,
        receiverNickname: receiver?.nickname || '未知用户',
        receiverAvatar: receiver?.avatar || '',
        createdAt: req.createTime
      };
    }));

    res.json({
      code: 200,
      data: {
        receivedRequests: receivedWithSender,
        sentRequests: sentWithReceiver
      },
      msg: '好友申请列表查询成功'
    });
  } catch (error) {
    console.error('好友申请列表查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 接受好友申请接口
router.post('/friend-request/accept', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, requestId } = req.body;

    if (!userId || !petId || !requestId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查找好友申请
    const request = await FriendRequest.findOne({
      where: { id: requestId, targetId: userId, status: 'pending' }
    });

    if (!request) {
      return res.json({ code: 400, data: {}, msg: '好友申请不存在或已处理' });
    }

    // 更新申请状态
    await request.update({ status: 'accepted' });

    // 添加到双方的好友列表
    // 获取发送方信息
    const senderUser = await User.findOne({ where: { userId: request.senderId } });
    const senderPet = await Pet.findOne({ where: { userId: request.senderId } });
    
    // 获取接收方信息
    const receiverUser = await User.findOne({ where: { userId } });
    const receiverPet = await Pet.findOne({ where: { userId } });

    if (!senderUser || !receiverUser) {
      return res.json({ code: 400, data: {}, msg: '用户数据异常' });
    }

    // 更新接收方的好友列表
    let receiverSocialData = await Social.findOne({ where: { userId, petId } });
    if (!receiverSocialData) {
      receiverSocialData = await Social.create({ userId, petId, friendList: '[]' });
    }
    
    const receiverFriendList = JSON.parse(receiverSocialData.friendList || '[]');
    if (!receiverFriendList.some(f => f.userId === request.senderId.toString())) {
      receiverFriendList.push({
        userId: request.senderId.toString(),
        nickname: senderUser.nickname,
        avatar: senderUser.avatar || '',
        addTime: new Date().toISOString()
      });
      await receiverSocialData.update({ friendList: JSON.stringify(receiverFriendList) });
    }

    // 更新发送方的好友列表
    if (senderPet) {
      let senderSocialData = await Social.findOne({ where: { userId: request.senderId, petId: senderPet.petId } });
      if (!senderSocialData) {
        senderSocialData = await Social.create({ userId: request.senderId, petId: senderPet.petId, friendList: '[]' });
      }
      
      const senderFriendList = JSON.parse(senderSocialData.friendList || '[]');
      if (!senderFriendList.some(f => f.userId === userId.toString())) {
        senderFriendList.push({
          userId: userId.toString(),
          nickname: receiverUser.nickname,
          avatar: receiverUser.avatar || '',
          addTime: new Date().toISOString()
        });
        await senderSocialData.update({ friendList: JSON.stringify(senderFriendList) });
      }
    }

    res.json({
      code: 200,
      data: {
        message: '好友申请接受成功'
      },
      msg: '好友申请接受成功'
    });
  } catch (error) {
    console.error('好友申请接受失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 拒绝好友申请接口
router.post('/friend-request/reject', authMiddleware, async (req, res) => {
  try {
    const { userId, requestId } = req.body;

    if (!userId || !requestId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查找好友申请
    const request = await FriendRequest.findOne({
      where: { id: requestId, targetId: userId, status: 'pending' }
    });

    if (!request) {
      return res.json({ code: 400, data: {}, msg: '好友申请不存在或已处理' });
    }

    // 更新申请状态
    await request.update({ status: 'rejected' });

    res.json({
      code: 200,
      data: {
        message: '好友申请拒绝成功'
      },
      msg: '好友申请拒绝成功'
    });
  } catch (error) {
    console.error('好友申请拒绝失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 撤回好友申请接口
router.post('/friend-request/withdraw', authMiddleware, async (req, res) => {
  try {
    const { userId, requestId } = req.body;

    if (!userId || !requestId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查找好友申请
    const request = await FriendRequest.findOne({
      where: { id: requestId, senderId: userId, status: 'pending' }
    });

    if (!request) {
      return res.json({ code: 400, data: {}, msg: '好友申请不存在或已处理' });
    }

    // 删除申请
    await request.destroy();

    res.json({
      code: 200,
      data: {
        message: '好友申请已撤回'
      },
      msg: '好友申请已撤回'
    });
  } catch (error) {
    console.error('好友申请撤回失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 获取好友列表接口
router.get('/friends', authMiddleware, async (req, res) => {
  try {
    const { userId, petId } = req.query;

    if (!userId || !petId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取社交数据
    const socialData = await Social.findOne({
      where: { userId, petId }
    });

    if (!socialData) {
      return res.json({
        code: 200,
        data: {
          friends: []
        },
        msg: '好友列表查询成功'
      });
    }

    const friendList = JSON.parse(socialData.friendList || '[]');

    // 获取每个好友的详细信息
    const friendsWithDetails = await Promise.all(friendList.map(async (friend) => {
      const user = await User.findOne({
        where: { userId: friend.userId }
      });

      const pet = await Pet.findOne({
        where: { userId: friend.userId }
      });

      const social = await Social.findOne({
        where: { userId: friend.userId }
      });

      return {
        userId: friend.userId,
        nickname: user?.nickname || friend.nickname,
        remark: friend.remark || '',
        avatar: user?.avatar || friend.avatar,
        major: '学生',
        grade: pet ? `等级 ${pet.level}` : '新用户',
        addTime: friend.addTime || '',
        pet: {
          species: pet?.petType === 1 ? '小猫' : pet?.petType === 2 ? '小狗' : pet?.petType === 3 ? '小鸡' : '小兔',
          stage: pet?.level < 10 ? '幼年' : pet?.level < 20 ? '青春' : '成年',
          level: pet?.level || 1,
          nutrition: pet?.nutrition || 50,
          happiness: pet?.happiness || 50
        },
        intimacy: friend.intimacy || 0,
        isOnline: user?.is_online || false,
        lastOnline: user?.lastLoginTime || '',
        petGrowthValue: pet?.exp || 0,
        likeNum: social?.likeNum || 0,
        helpNum: social?.helpNum || 0
      };
    }));

    res.json({
      code: 200,
      data: {
        friends: friendsWithDetails
      },
      msg: '好友列表查询成功'
    });
  } catch (error) {
    console.error('好友列表查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 获取用户详细信息接口
router.get('/user-detail', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取用户基本信息
    const user = await User.findOne({
      where: { userId }
    });

    if (!user) {
      return res.json({ code: 400, data: {}, msg: '用户不存在' });
    }

    // 获取宠物信息
    const pet = await Pet.findOne({
      where: { userId }
    });

    // 获取社交数据
    const social = await Social.findOne({
      where: { userId }
    });

    // 获取激励数据
    const incentive = await Incentive.findOne({
      where: { userId }
    });

    // 获取评价计算数据
    const evaluationCalc = await EvaluationCalc.findOne({
      where: { userId }
    });

    // 获取宠物进阶数据
    const petAdvance = await PetAdvance.findOne({
      where: { userId, petId: pet?.petId || 1 }
    });

    // 获取宠物图鉴数据
    const petAlbum = await PetAlbum.findOne({
      where: { userId, petId: pet?.petId || 1 }
    });

    res.json({
      code: 200,
      data: {
        user: {
          userId: user.userId,
          nickname: user.nickname,
          avatar: user.avatar,
          isOnline: user.is_online,
          lastLoginTime: user.lastLoginTime,
          challengeWin: user.challenge_win || 0,
          challengeLose: user.challenge_lose || 0,
          challengeScore: user.challenge_score || 100
        },
        pet: pet ? {
          petId: pet.petId,
          petName: pet.petName,
          petAvatar: pet.petAvatar,
          petType: pet.petType,
          level: pet.level,
          exp: pet.exp,
          expThreshold: pet.expThreshold,
          nutrition: pet.nutrition,
          happiness: pet.happiness,
          intimacy: pet.intimacy,
          skillPoint: pet.skillPoint,
          abilityLevel: pet.abilityLevel,
          petDesc: pet.petDesc
        } : null,
        social: social ? {
          likeNum: social.likeNum,
          helpNum: social.helpNum,
          beLikedNum: social.beLikedNum,
          beHelpedNum: social.beHelpedNum
        } : null,
        incentive: incentive ? {
          integral: incentive.integral,
          integralGet: incentive.integralGet,
          integralConsume: incentive.integralConsume,
          chestUnlock: JSON.parse(incentive.chestUnlock || '[]'),
          achievementUnlock: JSON.parse(incentive.achievementUnlock || '[]')
        } : null,
        evaluationCalc: evaluationCalc ? {
          taskCompletionCount: evaluationCalc.taskCompletionCount,
          totalScore: evaluationCalc.totalScore
        } : null,
        petAdvance: petAdvance ? {
          currentStage: petAdvance.currentStage,
          stageExp: petAdvance.stageExp,
          stageExpMax: petAdvance.stageExpMax,
          skillPoint: petAdvance.skillPoint,
          skillList: JSON.parse(petAdvance.skillList || '[]')
        } : null,
        petAlbum: petAlbum ? {
          collectCount: petAlbum.collectCount,
          totalCount: petAlbum.totalCount,
          unlockProgress: petAlbum.unlockProgress,
          rareUnlock: petAlbum.rareUnlock
        } : null
      },
      msg: '用户详细信息查询成功'
    });
  } catch (error) {
    console.error('用户详细信息查询失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 删除好友接口
router.post('/delete-friend', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, friendId } = req.body;

    if (!userId || !petId || !friendId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取当前用户的社交数据
    const socialData = await Social.findOne({
      where: { userId, petId }
    });

    if (!socialData) {
      return res.json({ code: 400, data: {}, msg: '社交数据不存在' });
    }

    // 更新当前用户的好友列表
    const friendList = JSON.parse(socialData.friendList || '[]');
    const updatedFriendList = friendList.filter(friend => friend.userId !== friendId);

    await Social.update(
      { friendList: JSON.stringify(updatedFriendList) },
      { where: { userId, petId } }
    );

    // 更新好友的好友列表
    const friendUser = await User.findOne({ where: { userId: friendId } });
    if (friendUser) {
      const friendPet = await Pet.findOne({ where: { userId: friendId } });
      if (friendPet) {
        const friendSocialData = await Social.findOne({
          where: { userId: friendId, petId: friendPet.petId }
        });

        if (friendSocialData) {
          const friendFriendList = JSON.parse(friendSocialData.friendList || '[]');
          const updatedFriendFriendList = friendFriendList.filter(friend => friend.userId !== userId.toString());

          await Social.update(
            { friendList: JSON.stringify(updatedFriendFriendList) },
            { where: { userId: friendId, petId: friendPet.petId } }
          );
        }
      }
    }

    res.json({
      code: 200,
      data: {
        message: '好友删除成功'
      },
      msg: '好友删除成功'
    });
  } catch (error) {
    console.error('删除好友失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 设置好友备注接口
router.post('/set-remark', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, friendId, remark } = req.body;

    if (!userId || !petId || !friendId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取当前用户的社交数据
    const socialData = await Social.findOne({
      where: { userId, petId }
    });

    if (!socialData) {
      return res.json({ code: 400, data: {}, msg: '社交数据不存在' });
    }

    // 更新好友备注
    const friendList = JSON.parse(socialData.friendList || '[]');
    const updatedFriendList = friendList.map(friend => {
      if (friend.userId === friendId) {
        return { ...friend, remark: remark || '' };
      }
      return friend;
    });

    await Social.update(
      { friendList: JSON.stringify(updatedFriendList) },
      { where: { userId, petId } }
    );

    res.json({
      code: 200,
      data: {
        message: '备注设置成功'
      },
      msg: '备注设置成功'
    });
  } catch (error) {
    console.error('设置备注失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 拉黑好友接口
router.post('/block-friend', authMiddleware, async (req, res) => {
  try {
    const { userId, petId, friendId } = req.body;

    if (!userId || !petId || !friendId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 获取当前用户的社交数据
    const socialData = await Social.findOne({
      where: { userId, petId }
    });

    if (!socialData) {
      return res.json({ code: 400, data: {}, msg: '社交数据不存在' });
    }

    // 更新黑名单
    const blacklist = JSON.parse(socialData.blacklist || '[]');
    if (!blacklist.includes(friendId)) {
      blacklist.push(friendId);
    }

    // 从好友列表中移除
    const friendList = JSON.parse(socialData.friendList || '[]');
    const updatedFriendList = friendList.filter(friend => friend.userId !== friendId);

    await Social.update(
      {
        blacklist: JSON.stringify(blacklist),
        friendList: JSON.stringify(updatedFriendList)
      },
      { where: { userId, petId } }
    );

    res.json({
      code: 200,
      data: {
        message: '好友已加入黑名单'
      },
      msg: '好友已加入黑名单'
    });
  } catch (error) {
    console.error('拉黑好友失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 辅助函数：比较等级
function _compareLevel(level1, level2) {
  const levelOrder = { 'S': 5, 'A': 4, 'B': 3, 'C': 2, 'D': 1 };
  return levelOrder[level1] - levelOrder[level2];
}

module.exports = router;
