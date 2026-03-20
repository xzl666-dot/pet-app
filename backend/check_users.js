const { sequelize, User, Pet, Incentive } = require('./models');

(async () => {
  try {
    console.log('\n========== 当前用户登录状态诊断 ==========\n');
    
    await sequelize.authenticate();

    // 检查最近登录的用户
    const users = await User.findAll({
      order: [['lastLoginTime', 'DESC']],
      limit: 3,
    });

    console.log(`=== 最近登录的3个用户 ===`);
    for (const user of users) {
      console.log(`\n用户 ID: ${user.userId}, 昵称: ${user.nickname}`);
      console.log(`  最后登录: ${user.lastLoginTime}`);
      
      // 获取该用户选中的宠物
      const selectedPet = await Pet.findOne({
        where: { userId: user.userId, isSelected: 1 }
      });

      if (!selectedPet) {
        console.log(`  ⚠️  未选中宠物`);
        continue;
      }

      console.log(`  选中宠物: PetID=${selectedPet.petId}, Name=${selectedPet.petName}`);

      // 获取该宠物的积分记录
      const incentive = await Incentive.findOne({
        where: { userId: user.userId, petId: selectedPet.petId }
      });

      if (!incentive) {
        console.log(`  ❌ Incentive 表中无记录（应该会自动创建）`);
      } else {
        console.log(`  积分: ${incentive.integral}`);
        console.log(`  获得的积分: ${incentive.integralGet}`);
        console.log(`  消耗的积分: ${incentive.integralConsume}`);
      }
    }

    // 查看所有有积分数据的用户
    console.log(`\n=== 所有有积分数据的用户 ===`);
    const incentivesWithData = await sequelize.query(`
      SELECT DISTINCT userId FROM incentive WHERE integral > 0;
    `, { type: sequelize.QueryTypes.SELECT });

    for (const record of incentivesWithData) {
      const user = await User.findByPk(record.userId);
      const incentives = await Incentive.findAll({
        where: { userId: record.userId }
      });

      console.log(`\n用户 ${record.userId} (${user?.nickname || 'Unknown'})`);
      incentives.forEach(i => {
        const pet = `PetID=${i.petId}`;
        console.log(`  ${pet}: 积分=${i.integral}`);
      });
    }

    console.log('\n==========================================\n');
    process.exit(0);
  } catch (error) {
    console.error('诊断失败:', error);
    process.exit(1);
  }
})();
