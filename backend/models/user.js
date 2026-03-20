const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const User = sequelize.define('User', {
  userId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  nickname: {
    type: DataTypes.STRING(50),
    allowNull: false,
    defaultValue: '萌宠主人',
  },
  avatar: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  phone: {
    type: DataTypes.STRING(20),
    allowNull: true,
    unique: true,
  },
  password: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  token: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  tokenExpire: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  isVip: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0,
  },
  vipExpire: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  versionType: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0,
  },
  createTime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  lastLoginTime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  // 原有字段保留
  is_admin: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  is_online: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  challenge_win: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  challenge_lose: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  challenge_score: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 100,
  },
  manualState: {
    type: DataTypes.TINYINT,
    allowNull: true,
    defaultValue: -1,
  },
  manualStateExpire: {
    type: DataTypes.DATE,
    allowNull: true,
    defaultValue: null,
  },
  // 测试期相关字段
  testPeriodStatus: {
    type: DataTypes.TINYINT,
    allowNull: false,
    defaultValue: 0,
  },
  testStartTime: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  testEndTime: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  testContinuousFinish: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  testLimitFinish: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  evaluateScore: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  evaluateTime: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'users',
  timestamps: false,
});

module.exports = User;
