const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./database/pet_app.db');

console.log('\n========== SQLite 字段诊断 ==========\n');

// 检查 users 表的字段
db.all("PRAGMA table_info(users);", (err, columns) => {
  console.log('=== users 表字段 ===');
  if (err) {
    console.log('查询失败:', err.message);
  } else {
    columns.forEach(col => {
      console.log(`  ${col.name}: ${col.type} (PK: ${col.pk})`);
    });
  }

  // 检查 pets 表的字段
  db.all("PRAGMA table_info(pets);", (err, columns) => {
    console.log('\n=== pets 表字段 ===');
    if (err) {
      console.log('查询失败:', err.message);
    } else {
      columns.forEach(col => {
        console.log(`  ${col.name}: ${col.type} (PK: ${col.pk})`);
      });
    }

    // 检查 incentive 表的字段
    db.all("PRAGMA table_info(incentive);", (err, columns) => {
      console.log('\n=== incentive 表字段 ===');
      if (err) {
        console.log('查询失败:', err.message);
      } else {
        columns.forEach(col => {
          console.log(`  ${col.name}: ${col.type} (PK: ${col.pk})`);
        });
      }

      // 查看 users 表的前几行原始数据
      db.all("SELECT * FROM users LIMIT 2;", (err, rows) => {
        console.log('\n=== users 表原始数据 (前2行) ===');
        if (err) {
          console.log('查询失败:', err.message);
        } else {
          if (rows.length > 0) {
            console.log('列名:', Object.keys(rows[0]));
            rows.forEach((row, idx) => {
              console.log(`行 ${idx}:`, JSON.stringify(row, null, 2).split('\n').slice(0, 5).join('\n'));
            });
          }
        }

        // 查看选中的宠物和对应的积分
        console.log('\n=== 每个用户的选中宠物 & 积分 ===');
        db.all(`
          SELECT 
            p.userId,
            p.petId, 
            p.petName,
            p.isSelected,
            i.integral
          FROM pets p
          LEFT JOIN incentive i ON p.userId = i.userId AND p.petId = i.petId
          WHERE p.isSelected = 1;
        `, (err, rows) => {
          if (err) {
            console.log('查询失败:', err.message);
          } else {
            rows.forEach(row => {
              console.log(`  UserID: ${row.userId}, PetID: ${row.petId}, Name: ${row.petName}, Integral: ${row.integral || '无数据'}`);
            });
          }

          db.close();
          console.log('\n========================================\n');
        });
      });
    });
  });
});
