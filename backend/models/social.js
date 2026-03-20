const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Social = sequelize.define('Social', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  petId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  friendList: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  likeNum: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  helpNum: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  beLikedNum: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  beHelpedNum: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  shareRecord: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  rankScore: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  rankPrivacy: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  createTime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  updateTime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'social',
  timestamps: false,
});

module.exports = Social;