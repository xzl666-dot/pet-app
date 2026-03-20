const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./backend/database/pet_app.db');

console.log('=== 数据库诊断 ===\n');

// 列出所有表
db.all("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;", (err, tables) => {
  if (err) {
    console.error('查询表失败:', err);
    db.close();
    return;
  }

  console.log('数据库中的表:');
  tables.forEach(t => console.log('  -', t.name));
  
  console.log('\n=== 关键数据检查 ===\n');

  // 检查用户数据
  db.all("SELECT id, username, nickname FROM Users LIMIT 3;", (err, users) => {
    console.log('Users 表 (前3条):');
    if (err) {
      console.log('  查询失败:', err.message);
    } else {
      console.log('  共', users.length, '条记录');
      users.forEach(u => console.log(`  - ID:${u.id}, Username:${u.username}, Nickname:${u.nickname}`));
    }

    // 检查宠物数据
    db.all("SELECT petId, userId, petName, isSelected FROM Pets;", (err, pets) => {
      console.log('\nPets 表:');
      if (err) {
        console.log('  查询失败:', err.message);
      } else {
        console.log('  共', pets.length, '条记录');
        pets.forEach(p => console.log(`  - PetID:${p.petId}, UserID:${p.userId}, Name:${p.petName}, Selected:${p.isSelected}`));
      }

      // 检查激励数据
      db.all("SELECT userId, petId, integral, abilityLevel FROM Incentives;", (err, incentives) => {
        console.log('\nIncentives 表:');
        if (err) {
          console.log('  查询失败:', err.message);
        } else {
          console.log('  共', incentives.length, '条记录');
          incentives.forEach(i => console.log(`  - UserID:${i.userId}, PetID:${i.petId}, Integral:${i.integral}, Level:${i.abilityLevel}`));
        }

        // 检查任务数据
        db.all("SELECT id, name, benefit_value FROM Tasks LIMIT 5;", (err, tasks) => {
          console.log('\nTasks 表 (前5条):');
          if (err) {
            console.log('  查询失败:', err.message);
          } else {
            console.log('  共', tasks.length, '条记录');
            tasks.forEach(t => console.log(`  - ID:${t.id}, Name:${t.name}, BenefitValue:${t.benefit_value}`));
          }

          db.close();
          console.log('\n=== 诊断完成 ===');
        });
      });
    });
  });
});
