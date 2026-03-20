const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Achievement = sequelize.define('Achievement', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  achievementKey: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  achievementName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  status: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0, // 0=未达成, 1=已达成, 2=已领取奖励
  },
  progress: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  targetValue: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  unlockTime: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'achievements',
  timestamps: true,
});

module.exports = Achievement;
