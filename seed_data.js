const { User, Pet, Task, Incentive } = require('./backend/models');
const moment = require('moment');

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
        lastLoginTime: new Date()
      }
    });
    console.log('用户创建/确认成功');

    // 2. 创建测试宠物
    const [pet] = await Pet.findOrCreate({
      where: { petId: 23 },
      defaults: {
        userId: 9,
        name: '小皮',
        type: 'kitten',
        level: 1,
        exp: 0,
        isSelected: 1
      }
    });
    console.log('宠物创建/确认成功');

    // 3. 创建基础任务数据 (用于推荐)
    const categories = ['核心学习类', '健康作息类', '校园生活类', '休闲放松类'];
    for (let i = 0; i < 20; i++) {
      await Task.create({
        name: `基础任务 ${i}`,
        difficulty: (i % 3) + 1,
        deadline: moment().add(1, 'days').unix(),
        benefit_type: 1,
        benefit_value: 10,
        created_at: moment().unix(),
        task_type: i % 3, // 0, 1, 2
        category: categories[i % 4],
        is_custom: 0,
        is_test_task: 0
      });
    }
    console.log('基础任务种子数据创建成功');

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
        incentivePrefer: '{}'
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
