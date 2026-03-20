const { sequelize, User, Pet, Incentive, Task } = require('./models');

(async () => {
  try {
    console.log('\n========== 数据库诊断报告 ==========\n');
    
    await sequelize.authenticate();
    console.log('✓ 数据库连接成功\n');

    // 检查用户
    const users = await User.findAll({ limit: 5 });
    console.log(`=== Users (${users.length} 条) ===`);
    if (users.length === 0) {
      console.log('⚠️  没有用户数据！');
    } else {
      users.forEach(u => {
        console.log(`  ID: ${u.id}, Username: ${u.username}, Nickname: ${u.nickname}`);
      });
    }

    // 检查宠物
    const pets = await Pet.findAll();
    console.log(`\n=== Pets (${pets.length} 条) ===`);
    if (pets.length === 0) {
      console.log('⚠️  没有宠物数据！');
    } else {
      pets.forEach(p => {
        const selected = p.isSelected === 1 ? '✓' : ' ';
        console.log(`  [${selected}] PetID: ${p.petId}, Name: ${p.petName}, UserID: ${p.userId}`);
      });
    }

    // 检查积分
    const incentives = await Incentive.findAll();
    console.log(`\n=== Incentives (${incentives.length} 条) ===`);
    if (incentives.length === 0) {
      console.log('⚠️  没有积分数据！');
    } else {
      incentives.forEach(i => {
        console.log(`  UserID: ${i.userId}, PetID: ${i.petId}, Integral: ${i.integral}, Level: ${i.abilityLevel}`);
      });
    }

    // 检查选中的宠物和对应的积分
    console.log('\n=== 当前用户状态 ===');
    for (const user of users) {
      const selectedPet = await Pet.findOne({ where: { userId: user.id, isSelected: 1 } });
      if (!selectedPet) {
        console.log(`  UserID ${user.id}: ⚠️  未选中宠物`);
      } else {
        const incentive = await Incentive.findOne({ where: { userId: user.id, petId: selectedPet.petId } });
        if (!incentive) {
          console.log(`  UserID ${user.id}: ⚠️  宠物 ${selectedPet.petName} 无积分记录`);
        } else {
          console.log(`  UserID ${user.id}: 宠物=${selectedPet.petName}, 积分=${incentive.integral}`);
        }
      }
    }

    console.log('\n========================================\n');
    
    process.exit(0);
  } catch (error) {
    console.error('诊断失败:', error);
    process.exit(1);
  }
})();
