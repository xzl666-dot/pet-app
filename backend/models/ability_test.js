const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const AbilityTest = sequelize.define('AbilityTest', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true,
    comment: '用户ID',
  },
  score: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: '测试得分',
  },
  level: {
    type: DataTypes.STRING(10),
    allowNull: false,
    comment: '评估等级',
  },
  testDate: {
    type: DataTypes.DATE,
    allowNull: false,
    comment: '测试日期',
  },
}, {
  tableName: 'ability_tests',
  timestamps: false,
  comment: '能力评估测试表',
  indexes: [
    {
      fields: ['userId'],
      unique: true,
      name: 'idx_ability_test_user_id',
    },
  ],
});

module.exports = AbilityTest;