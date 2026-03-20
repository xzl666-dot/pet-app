const express = require('express');
const router = express.Router();
const { Task, User, Incentive, Pet, EvaluationCalc } = require('../models');
const authMiddleware = require('../middleware/auth');
const moment = require('moment');
const http = require('http');
const { Op } = require('sequelize');

// 智能任务推荐
router.get('/recommend', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const user = await User.findByPk(userId);
    if (!user) return res.json({ code: 400, data: {}, msg: '用户不存在' });

    // 获取用户状态
    let stateCode = -1;
    
    // 1. 优先检查手动标记状态（非 -1 且未过期）
    if (user.manualState !== -1 && user.manualStateExpire && moment().isBefore(moment(user.manualStateExpire))) {
      stateCode = user.manualState;
    } else {
      // 2. 自动判断逻辑：基于完成率、效率、坚持度
      // 获取最近 7 天的任务完成情况
      const sevenDaysAgo = moment().subtract(7, 'days').unix();
      const recentTasks = await Task.findAll({
        where: {
          userId,
          created_at: { [Op.gte]: sevenDaysAgo },
          is_test_task: 0
        }
      });

      if (recentTasks.length > 0) {
        const total = recentTasks.length;
        const completed = recentTasks.filter(t => t.is_completed).length;
        const completionRate = completed / total;
        
        // 计算平均效率 (假设 finish_efficiency 100 为标准)
        const avgEfficiency = recentTasks.filter(t => t.is_completed && t.finish_efficiency)
          .reduce((acc, t) => acc + t.finish_efficiency, 0) / (completed || 1);

        // 坚持度：最近 7 天有任务完成的天数
        const activeDays = new Set(recentTasks.filter(t => t.is_completed && t.completed_at)
          .map(t => moment.unix(t.completed_at).format('YYYY-MM-DD'))).size;

        if (completionRate > 0.8 && avgEfficiency > 110 && activeDays >= 5) {
          stateCode = 3; // 专注：高完成率、高效率、高坚持
        } else if (completionRate < 0.3 && activeDays <= 2) {
          stateCode = 2; // 懈怠：低完成率、低坚持
        } else if (avgEfficiency < 70 && completionRate > 0.5) {
          stateCode = 1; // 疲惫：虽然在坚持，但效率低下
        } else {
          stateCode = 0; // 正常
        }
      } else {
        stateCode = 0; // 无数据默认为正常
      }
    }

    // 问题3: 循环推荐每天，每周，每月任务各五个
    // 并且用户自己添加的任务归为简单类加入循环推荐
    
    // 获取用户评估数据以动态调整难度 (问题4)
    const evaluation = await EvaluationCalc.findOne({
      where: { userId },
      order: [['evaluationDate', 'DESC']]
    });

    // 动态调整难度分布
    let difficultyBias = 0;
    if (evaluation) {
      if (evaluation.totalScore > 80) difficultyBias = 1; // 表现好，增加难度
      else if (evaluation.totalScore < 40) difficultyBias = -1; // 表现差，降低难度
    }

    // 状态奖励倍率
    let rewardMultiplier = 1.0;
    if (stateCode === 2) rewardMultiplier = 1.5; // 懈怠：高收益激发动力
    if (stateCode === 3) rewardMultiplier = 2.0; // 专注：最大化收益

    const getTasksByStrategy = async (strategy, multiplier = 1.0) => {
      let recommendedTasks = [];
      
      // 策略定义 (依据 Require.md 问题4)
      const strategies = {
        0: [ // 正常
          { category: '核心学习类', count: 2, minDiff: 1, maxDiff: 2 },
          { category: '健康作息类', count: 1, minDiff: 1, maxDiff: 1 },
          { category: '校园生活类', count: 1, minDiff: 1, maxDiff: 2 },
          { category: '休闲放松类', count: 1, minDiff: 1, maxDiff: 1 }
        ],
        1: [ // 疲惫
          { category: '健康作息类', count: 2, minDiff: 1, maxDiff: 1 },
          { category: '休闲放松类', count: 2, minDiff: 1, maxDiff: 1 },
          { category: '校园生活类', count: 1, minDiff: 1, maxDiff: 1 }
        ],
        2: [ // 懈怠
          { category: '核心学习类', count: 1, minDiff: 1, maxDiff: 2 },
          { category: '社交实践类', count: 2, minDiff: 1, maxDiff: 1 },
          { category: '休闲放松类', count: 2, minDiff: 1, maxDiff: 1 }
        ],
        3: [ // 专注
          { category: '核心学习类', count: 2, minDiff: 2, maxDiff: 3 },
          { category: '学业进阶类', count: 2, minDiff: 2, maxDiff: 3 },
          { category: '自我提升类', count: 1, minDiff: 2, maxDiff: 3 }
        ]
      };

      const currentStrategy = strategies[stateCode] || strategies[0];

      for (const item of currentStrategy) {
        const tasks = await Task.findAll({
          where: {
            category: item.category,
            difficulty: { [Op.between]: [item.minDiff, item.maxDiff] },
            task_type: 0, // 每日任务
            is_custom: 0,
            is_test_task: 0,
            userId: null // 确保从系统任务池中抽取
          },
          limit: item.count,
          order: Task.sequelize.random()
        });
        recommendedTasks.push(...tasks);
      }

      // 如果策略任务不足5个，补充自定义任务
      if (recommendedTasks.length < 5) {
        const customTasks = await Task.findAll({
          where: { is_custom: 1, userId: userId, is_completed: 0, is_test_task: 0 },
          limit: 5 - recommendedTasks.length,
          order: Task.sequelize.random()
        });
        recommendedTasks.push(...customTasks);
      }

      // 如果还是不足5个，补充随机每日任务
      if (recommendedTasks.length < 5) {
        const extraTasks = await Task.findAll({
          where: {
            task_type: 0,
            is_custom: 0,
            is_test_task: 0,
            id: { [Op.notIn]: recommendedTasks.map(t => t.id) }
          },
          limit: 5 - recommendedTasks.length,
          order: Task.sequelize.random()
        });
        recommendedTasks.push(...extraTasks);
      }

      return recommendedTasks.map(t => ({
        id: t.id,
        name: t.name,
        difficulty: t.difficulty,
        category: t.category,
        benefit_type: t.benefit_type,
        benefit_value: Math.round(t.benefit_value * multiplier),
        task_type: t.task_type,
        is_custom: t.is_custom,
        is_completed: t.is_completed
      }));
    };

    const getTasksByType = async (type, limit = 5, multiplier = 1.0) => {
      let tasks = await Task.findAll({
        where: {
          task_type: type,
          is_custom: 0,
          is_test_task: 0,
          userId: null // 确保从系统任务池中抽取
        },
        limit: limit,
        order: Task.sequelize.random()
      });

      return tasks.map(t => ({
        id: t.id,
        name: t.name,
        difficulty: t.difficulty,
        category: t.category,
        benefit_type: t.benefit_type,
        benefit_value: Math.round(t.benefit_value * multiplier),
        task_type: t.task_type,
        is_custom: t.is_custom,
        is_completed: t.is_completed
      }));
    };

    const dailyTasks = await getTasksByStrategy(stateCode, rewardMultiplier);
    const weeklyTasks = await getTasksByType(1, 5, rewardMultiplier);
    const monthlyTasks = await getTasksByType(2, 5, rewardMultiplier);

    // 确保严格 5/5/5 (如果不足则补充)
    const ensureFive = async (tasks, type, multiplier) => {
      if (tasks.length >= 5) return tasks.slice(0, 5);
      const extra = await getTasksByType(type, 10, multiplier); // 多查一些以防重复
      const existingIds = new Set(tasks.map(t => t.id));
      const uniqueExtra = extra.filter(t => !existingIds.has(t.id));
      return [...tasks, ...uniqueExtra].slice(0, 5);
    };

    const finalDaily = await ensureFive(dailyTasks, 0, rewardMultiplier);
    const finalWeekly = await ensureFive(weeklyTasks, 1, rewardMultiplier);
    const finalMonthly = await ensureFive(monthlyTasks, 2, rewardMultiplier);

    // 检查是否有正在进行的评估 ( 问题2-8)
    let assessment = null;
    if (user.testPeriodStatus === 1) {
      const now = moment();
      const endTime = moment(user.testEndTime);
      if (now.isBefore(endTime)) {
        // 获取评估任务
        const testTasks = await Task.findAll({
          where: { userId: userId, is_test_task: 1, is_completed: 0 }
        });
        assessment = {
          endTime: user.testEndTime,
          remainingTasks: testTasks.length,
          totalTasks: 5 // 假设评估随机抽取5个
        };
      } else {
        // 评估过期，自动结算
        // 这里简化处理，实际应调用结算逻辑
        await user.update({ testPeriodStatus: 0 });
      }
    }

    res.json({
      code: 200,
      data: {
        daily: finalDaily,
        weekly: finalWeekly,
        monthly: finalMonthly,
        stateCode,
        rewardMultiplier,
        assessment
      },
      msg: '操作成功',
    });
  } catch (error) {
    console.error('任务推荐失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 任务完成标记
router.post('/finish', authMiddleware, async (req, res) => {
  try {
    const { taskId, isCompleted, taskQuality } = req.body;
    const userId = req.userId;

    if (!taskId) {
      return res.json({ code: 400, data: {}, msg: '参数错误' });
    }

    // 查找任务
    const task = await Task.findByPk(taskId);
    if (!task) {
      return res.json({ code: 400, data: {}, msg: '任务不存在' });
    }

    // 更新任务状态
    // 计算完成效率 (假设 100 为标准，根据任务难度和完成时间动态计算)
    let finishEfficiency = 100;
    if (isCompleted) {
      const now = moment().unix();
      const duration = now - task.created_at;
      const expectedDuration = task.difficulty * 3600; // 假设每级难度对应 1 小时
      finishEfficiency = Math.max(50, Math.min(150, Math.round((expectedDuration / duration) * 100)));
    }

    await task.update({
      is_completed: isCompleted ? 1 : 0,
      completed_at: isCompleted ? moment().unix() : null,
      finish_efficiency: isCompleted ? finishEfficiency : null,
      finish_score: isCompleted ? (taskQuality || 80) : null
    });

    // 如果任务完成，触发激励联动
    let rewardData = { integral: 0, finalIntegral: 0, abilityLevel: 'D' };
    if (isCompleted) {
      try {
        // 查询激励数据
        // 获取用户当前选中的宠物
        const pet = await Pet.findOne({ where: { userId, isSelected: 1 } });
        if (!pet) {
          console.error('未找到选中的宠物，无法进行激励联动');
          return res.json({ code: 200, data: { integral: 0, finalIntegral: 0 }, msg: '操作成功' });
        }

        const petId = pet.petId;

        // 查询激励数据，如果不存在则创建
        let incentiveData = await Incentive.findOne({
          where: { userId, petId },
        });

        if (!incentiveData) {
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

        if (incentiveData) {
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
          const quality = taskQuality || task.difficulty * 20; // 如果没有提供任务质量，根据难度计算
          let qualityRate = 1.0;
          if (quality >= 90) {
            qualityRate = 1.5;
          } else if (quality >= 80) {
            qualityRate = 1.2;
          }

          // 计算总收益系数
          const totalRate = baseRate * qualityRate;

          // 计算基础积分奖励（使用任务定义的奖励值，如果没有则默认10积分）
          const baseIntegral = task.benefit_value || 10;
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

          // 获取更新后的激励数据
          const updatedIncentive = await Incentive.findOne({
            where: { userId, petId },
          });

          rewardData = {
            integral: updatedIncentive.integral,
            finalIntegral: finalIntegral,
            abilityLevel: updatedIncentive.abilityLevel,
          };

          console.log(`激励联动成功：用户${userId}完成任务${taskId}，获得${finalIntegral}积分（基础${baseIntegral}×等级${baseRate}×质量${qualityRate}=${totalRate}），总积分${updatedIncentive.integral}`);

          //  问题2-3, 2-4, 2-5: 任务完成增加宠物经验，受数值联动影响，自动升级与进化
          const PetLogic = require('../utils/pet_logic');
          const baseExp = 10;
          await PetLogic.addExp(pet, baseExp, totalRate);
        }
      } catch (error) {
        console.error('激励联动失败:', error);
        // 激励联动失败不影响任务完成，但需要返回给前端
      }
    }

    res.json({ code: 200, data: rewardData, msg: '操作成功' });
  } catch (error) {
    console.error('任务完成标记失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 获取任务列表
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    const tasks = await Task.findAll({
      where: {
        [Op.or]: [
          { userId: userId },
          { userId: null, is_custom: 0 }
        ],
        is_test_task: 0
      }
    });

    res.json({
      code: 200,
      data: {
        taskList: tasks.map(task => ({
          id: task.id,
          name: task.name,
          difficulty: task.difficulty,
          deadline: task.deadline,
          benefit_type: task.benefit_type,
          benefit_value: task.benefit_value,
          is_completed: task.is_completed,
          description: task.description || '',
          category: task.category || '',
        })),
      },
      msg: '操作成功',
    });
  } catch (error) {
    console.error('获取任务列表失败:', error);
    res.json({ code: 500, data: {}, msg: '服务器错误' });
  }
});

// 开启能力评估 ( 问题2-8)
router.post('/start-assessment', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const user = await User.findByPk(userId);

    if (!user) {
      return res.json({ code: 400, msg: '用户不存在' });
    }

    if (user.testPeriodStatus === 1) {
      return res.json({ code: 400, msg: '评估已在进行中' });
    }

    const startTime = new Date();
    const endTime = moment(startTime).add(1, 'days').toDate();

    // 随机抽取5个任务作为评估任务
    const randomTasks = await Task.findAll({
      where: {
        is_custom: 0,
        is_test_task: 0,
        userId: null // 确保只从系统任务池中抽取
      },
      limit: 5,
      order: Task.sequelize.random()
    });

    if (randomTasks.length === 0) {
      return res.json({ code: 400, msg: '暂无任务用于评估' });
    }

    // 复制这些任务并标记为测试任务
    for (const task of randomTasks) {
      await Task.create({
        userId: userId,
        name: `[评估] ${task.name}`,
        difficulty: task.difficulty,
        deadline: moment(endTime).unix(),
        benefit_type: task.benefit_type,
        benefit_value: task.benefit_value,
        is_test_task: 1,
        is_custom: 0,
        task_type: 0,
        created_at: moment().unix(),
        category: task.category || ''
      });
    }

    await user.update({
      testPeriodStatus: 1,
      testStartTime: startTime,
      testEndTime: endTime
    });

    res.json({
      code: 200,
      data: { endTime },
      msg: '评估已开启，有效期24小时'
    });
  } catch (error) {
    console.error('开启评估失败:', error);
    res.json({ code: 500, msg: '服务器错误' });
  }
});

// 添加自定义任务 ( 问题 3)
router.post('/add-custom', authMiddleware, async (req, res) => {
  try {
    const { name } = req.body;
    const userId = req.userId;

    if (!name) {
      return res.json({ code: 400, msg: '任务名称不能为空' });
    }

    const task = await Task.create({
      userId: userId,
      name: name,
      difficulty: 1, // 自定义任务归为简单类
      is_custom: 1,
      task_type: 0, // 默认为每日任务
      benefit_type: 1,
      benefit_value: 10,
      created_at: moment().unix(),
      deadline: moment().add(1, 'days').unix(),
      is_test_task: 0,
      category: ''
    });

    res.json({
      code: 200,
      data: task,
      msg: '添加成功'
    });
  } catch (error) {
    console.error('添加自定义任务失败:', error);
    res.json({ code: 500, msg: '服务器错误' });
  }
});

module.exports = router;
