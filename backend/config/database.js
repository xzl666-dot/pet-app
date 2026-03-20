const { Sequelize } = require('sequelize');
const path = require('path');

// 创建Sequelize实例
const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: path.join(__dirname, '../database/pet_app.db'),
  logging: console.log,
  define: {
    constraints: false
  },
  dialectOptions: {
    foreign_keys: false
  }
});

// 测试数据库连接
const testConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log('数据库连接成功');
  } catch (error) {
    console.error('数据库连接失败:', error);
  }
};

module.exports = {
  sequelize,
  testConnection,
};
