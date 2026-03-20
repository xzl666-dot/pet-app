const { User, Pet, Task, Incentive } = require('./models');

async function seed() {
  try {
    // 1. 创建测试用户
    const [user] = await User.findOrCreate({
      where: { userId: 9 },
      defaults: {
        nickname: '测试用户',
        phone: '13800138000',
        password: 'password123',
        createTime: new Date(),
        lastLoginTime: new Date(),
        testPeriodStatus: 0,
        manualState: -1 // 初始为自动判断
      }
    });
    console.log('用户创建/确认成功');

    // 2. 创建测试宠物
    const [pet] = await Pet.findOrCreate({
      where: { petId: 23 },
      defaults: {
        userId: 9,
        petName: '小皮',
        petType: 'kitten',
        level: 1,
        exp: 0,
        isSelected: 1,
        nutrition: 80,
        happiness: 80,
        intimacy: 50
      }
    });
    console.log('宠物创建/确认成功');

    // 3. 创建基础任务数据 (用于推荐)
    const nowUnix = Math.floor(Date.now() / 1000);
    const tomorrowUnix = nowUnix + 86400;

    // 定义符合策略的分类任务
    const taskPool = [
      // 核心学习类
      { name: '完成 1 节专业课网课≥20 分钟', category: '核心学习类', difficulty: 2, benefit_value: 20 },
      { name: '完成 10 道练习题', category: '核心学习类', difficulty: 1, benefit_value: 15 },
      { name: '完成 1 篇课程小论文≥800 字', category: '核心学习类', difficulty: 3, benefit_value: 50 },
      { name: '进行 1 小时深度学习', category: '核心学习类', difficulty: 3, benefit_value: 40 },
      
      // 健康作息类
      { name: '7:00 前早起打卡', category: '健康作息类', difficulty: 1, benefit_value: 10 },
      { name: '进行 10 分钟拉伸', category: '健康作息类', difficulty: 1, benefit_value: 10 },
      { name: '23:00 前上床睡觉', category: '健康作息类', difficulty: 1, benefit_value: 15 },
      
      // 校园生活类
      { name: '图书馆打卡≥1 小时', category: '校园生活类', difficulty: 2, benefit_value: 20 },
      { name: '在校园内散步 10 分钟', category: '校园生活类', difficulty: 1, benefit_value: 10 },
      { name: '参加一次社团活动', category: '校园生活类', difficulty: 2, benefit_value: 25 },
      
      // 休闲放松类
      { name: '听 15 分钟舒缓音乐', category: '休闲放松类', difficulty: 1, benefit_value: 5 },
      { name: '看一集轻松的短视频', category: '休闲放松类', difficulty: 1, benefit_value: 5 },
      { name: '玩一局轻松的小游戏', category: '休闲放松类', difficulty: 1, benefit_value: 10 },
      { name: '看一个搞笑视频', category: '休闲放松类', difficulty: 1, benefit_value: 5 },
      
      // 社交实践类
      { name: '和好友组队学习打卡≥30 分钟', category: '社交实践类', difficulty: 2, benefit_value: 30 },
      { name: '和好友分享一个学习技巧', category: '社交实践类', difficulty: 1, benefit_value: 15 },
      
      // 学业进阶类
      { name: '完成 1 本课外书的一个章节并写读后感', category: '学业进阶类', difficulty: 3, benefit_value: 45 },
      { name: '制定一个月的学习计划', category: '学业进阶类', difficulty: 2, benefit_value: 35 },
      
      // 自我提升类
      { name: '学习一项新技能的入门课程', category: '自我提升类', difficulty: 3, benefit_value: 50 }
    ];

    // 清理旧任务 (使用 try-catch 绕过外键约束问题)
    try {
      await Task.destroy({ where: { userId: null, is_custom: 0, is_test_task: 0 } });
    } catch (e) {
      console.log('清理旧任务跳过 (可能存在外键引用)');
    }

    // 插入系统任务池 (userId 为 null)
    for (const t of taskPool) {
      // 插入每日任务版本
      await Task.create({
        name: t.name,
        category: t.category,
        difficulty: t.difficulty,
        benefit_value: t.benefit_value,
        benefit_type: 1, // 显式设置
        userId: null,
        deadline: tomorrowUnix,
        created_at: nowUnix,
        is_test_task: 0,
        task_type: 0,
        is_custom: 0
      });
      
      // 插入每周任务版本 (随机选一些)
      if (Math.random() > 0.5) {
        await Task.create({
          name: `[每周] ${t.name}`,
          category: t.category,
          difficulty: t.difficulty,
          benefit_value: t.benefit_value * 2,
          benefit_type: 1, // 显式设置
          userId: null,
          deadline: nowUnix + 86400 * 7,
          created_at: nowUnix,
          is_test_task: 0,
          task_type: 1,
          is_custom: 0
        });
      }

      // 插入每月任务版本 (随机选一些)
      if (Math.random() > 0.3) {
        await Task.create({
          name: `[每月] ${t.name}`,
          category: t.category,
          difficulty: t.difficulty,
          benefit_value: t.benefit_value * 5,
          benefit_type: 1,
          userId: null,
          deadline: nowUnix + 86400 * 30,
          created_at: nowUnix,
          is_test_task: 0,
          task_type: 2,
          is_custom: 0
        });
      }
    }
    console.log('系统任务池种子数据创建成功');

    // 4. 创建激励数据
    await Incentive.findOrCreate({
      where: { userId: 9, petId: 23 },
      defaults: {
        abilityLevel: 'D',
        integral: 100,
        integralGet: 100,
        integralConsume: 0,
        integralExpire: 0,
        chestUnlock: '[]',
        achievementUnlock: '[]',
        welfareGet: '[]',
        incentivePrefer: '{}',
        inventory: '{}'
      }
    });
    console.log('激励数据创建成功');

    process.exit(0);
  } catch (error) {
    console.error('Seed 失败:', error);
    process.exit(1);
  }
}

seed();
